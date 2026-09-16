-- ============================================================
-- PUL'Z : Rappels J-2 / J-1 pour les events LIKES (feed / scraped_events)
--
-- Le systeme existant (001_notification_system.sql) ne programme des
-- rappels que pour les events publies par un PRO via sa fiche
-- etablissement (establishment_events -> trigger fn_like_schedule).
-- Il ne se declenche jamais pour un like "normal" sur un event du feed
-- (scraped_events), qui est pourtant le cas d'usage principal annonce
-- sur le site ("notifie a J-2, J-1 et H-1").
--
-- Pas de H-1 ici volontairement : scraped_events.date_debut n'a pas
-- d'heure, et `horaires` est du texte libre irregulier (vide, "19h",
-- "17h10, 18h00, 20h25"...). Un rappel a une heure fausse est pire que
-- pas de rappel du tout. H-1 continue de fonctionner normalement pour
-- le flux pro (establishment_events.starts_at, un vrai timestamptz).
--
-- A executer dans Supabase SQL Editor (Dashboard). Idempotent : peut
-- etre rejoue sans risque.
-- ============================================================

-- 1. Rattacher une notif a un event scrape (id texte), en plus du
--    event_id bigint existant (establishment_events).
alter table public.notification_queue
  add column if not exists event_identifiant text;

create index if not exists idx_queue_identifiant
  on public.notification_queue(event_identifiant);

-- 2. Like d'un event du feed -> programmer J-2 et J-1 si sa date est
--    resolvable dans scraped_events et encore a venir.
create or replace function fn_like_schedule_scraped_event()
returns trigger as $$
declare
  ev record;
  event_date date;
begin
  select se.identifiant, se.nom_de_la_manifestation, se.date_debut
    into ev
  from public.scraped_events se
  where se.identifiant = new.establishment_id
  limit 1;

  if ev.identifiant is null then
    return new; -- pas un event scrape (venue, restaurant...) : rien a faire
  end if;

  event_date := nullif(ev.date_debut, '')::date;
  if event_date is null then
    return new;
  end if;

  insert into public.notification_queue
    (user_id, event_id, event_identifiant, type, scheduled_at, batch_key)
  select
    new.user_id,
    0,
    ev.identifiant,
    t.type,
    case t.type
      when '2_days' then ((event_date - 2) + time '10:00') at time zone 'Europe/Paris'
      when '1_day'  then ((event_date - 1) + time '10:00') at time zone 'Europe/Paris'
    end as scheduled_at,
    'liked_event:' || ev.identifiant
  from (
    values ('2_days'::notification_type), ('1_day'::notification_type)
  ) as t(type)
  left join public.notification_preferences np
    on np.user_id = new.user_id
  where coalesce(np.enabled, true) = true
    and (
      (t.type = '2_days' and coalesce(np.remind_2d, true)) or
      (t.type = '1_day'  and coalesce(np.remind_1d, true))
    )
    and case t.type
      when '2_days' then ((event_date - 2) + time '10:00') at time zone 'Europe/Paris'
      when '1_day'  then ((event_date - 1) + time '10:00') at time zone 'Europe/Paris'
    end > now()
  on conflict (user_id, type, batch_key) do nothing;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_like_created_scraped_event on public.establishment_likes;
create trigger trg_like_created_scraped_event
  after insert on public.establishment_likes
  for each row
  execute function fn_like_schedule_scraped_event();

-- 3. Unlike -> annuler les rappels pending programmes pour ce like.
create or replace function fn_unlike_cancel_scraped_event()
returns trigger as $$
begin
  update public.notification_queue
  set status = 'cancelled'
  where event_identifiant = old.establishment_id
    and user_id = old.user_id
    and status = 'pending';

  return old;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_like_deleted_scraped_event on public.establishment_likes;
create trigger trg_like_deleted_scraped_event
  after delete on public.establishment_likes
  for each row
  execute function fn_unlike_cancel_scraped_event();

-- 4. claim_pending_notifications : etendre pour resoudre aussi les
--    rappels par event_identifiant (scraped_events), en plus des
--    rappels par event_id (establishment_events, flux pro existant).
--    Signature de retour modifiee (nouvelle colonne) -> drop necessaire.
drop function if exists claim_pending_notifications(int);

create function claim_pending_notifications(batch_size int default 500)
returns table (
  id                bigint,
  user_id           text,
  event_id          bigint,
  event_identifiant text,
  type              notification_type,
  batch_key         text,
  event_title       text,
  event_starts_at   timestamptz,
  establishment_id  text
) as $$
begin
  return query
  with claimed as (
    select nq.id
    from public.notification_queue nq
    where nq.status = 'pending'
      and nq.scheduled_at <= now()
      and nq.attempts < 3
    order by nq.scheduled_at
    limit batch_size
    for update skip locked
  ),
  updated as (
    update public.notification_queue nq
    set attempts = nq.attempts + 1
    from claimed c
    where nq.id = c.id
    returning nq.*
  )
  select
    u.id, u.user_id, u.event_id, u.event_identifiant, u.type, u.batch_key,
    coalesce(e.title, se.nom_de_la_manifestation) as event_title,
    e.starts_at as event_starts_at,
    coalesce(e.establishment_id, u.event_identifiant) as establishment_id
  from updated u
  left join public.establishment_events e on e.id = u.event_id
  left join public.scraped_events se on se.identifiant = u.event_identifiant;
end;
$$ language plpgsql;

-- ============================================================
-- 5. CRON : a activer manuellement (Dashboard > Extensions > pg_cron
--    ET pg_net doivent etre actifs). Remplace <SERVICE_ROLE_KEY> par
--    la vraie cle (Dashboard > Project Settings > API) avant d'executer
--    -- ne jamais commiter la cle en clair dans ce fichier.
--    Si 'send-pending-notifications' existe deja (cf 001_notification_system.sql),
--    ne le recree pas en double : verifie d'abord avec
--    select * from cron.job where jobname = 'send-pending-notifications';
-- ============================================================
-- select cron.schedule(
--   'send-pending-notifications',
--   '* * * * *',
--   $$
--   select net.http_post(
--     url    := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/send-notifications',
--     headers := jsonb_build_object(
--       'Authorization', 'Bearer <SERVICE_ROLE_KEY>',
--       'Content-Type',  'application/json'
--     ),
--     body := '{}'::jsonb
--   );
--   $$
-- );
