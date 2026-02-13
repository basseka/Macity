-- ============================================================
-- Notifications pour les events crees par les utilisateurs
-- A executer dans Supabase SQL Editor APRES 001
-- ============================================================

-- 1. Ajouter user_id a la table user_events (device UUID)
alter table public.user_events
  add column if not exists user_id text;

-- Index pour retrouver les events d'un user
create index if not exists idx_user_events_user_id
  on public.user_events(user_id);

-- 2. Remplacer la contrainte unique pour supporter les user_events (event_id=0)
-- L'ancienne contrainte (user_id, event_id, type) bloque si plusieurs user_events
-- ont event_id=0. On utilise batch_key pour differencier.
alter table public.notification_queue
  drop constraint if exists notification_queue_user_id_event_id_type_key;

create unique index if not exists idx_queue_unique_notif
  on public.notification_queue (user_id, type, batch_key);

-- 2. Trigger : quand un user_event est cree → programmer 3 rappels
create or replace function fn_schedule_user_event_notifications()
returns trigger as $$
declare
  starts_at_ts timestamptz;
  notif_2d timestamptz;
  notif_1d timestamptz;
  notif_1h timestamptz;
begin
  -- Pas de user_id → pas de notification
  if new.user_id is null or new.user_id = '' then
    return new;
  end if;

  -- Construire le timestamp a partir de date (text) + heure (text)
  -- Format attendu: date = '2025-02-15', heure = '20:00'
  if new.date is null or new.date = '' then
    return new;
  end if;

  if new.heure is not null and new.heure != '' then
    starts_at_ts := (new.date || ' ' || new.heure || ':00')::timestamptz;
  else
    starts_at_ts := (new.date || ' 00:00:00')::timestamptz;
  end if;

  notif_2d := starts_at_ts - interval '2 days';
  notif_1d := starts_at_ts - interval '1 day';
  notif_1h := starts_at_ts - interval '1 hour';

  -- Verifier les preferences du user (si elles existent)
  -- Inserer les rappels
  if notif_2d > now() then
    insert into public.notification_queue
      (user_id, event_id, type, scheduled_at, batch_key)
    select
      new.user_id,
      0,  -- pas de FK vers establishment_events, on utilise 0
      '2_days'::notification_type,
      notif_2d,
      'user_event:' || new.id
    from public.notification_preferences np
    where np.user_id = new.user_id
      and np.enabled = true
      and np.remind_2d = true
    union all
    select
      new.user_id, 0, '2_days'::notification_type, notif_2d,
      'user_event:' || new.id
    where not exists (
      select 1 from public.notification_preferences
      where user_id = new.user_id
    )
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  if notif_1d > now() then
    insert into public.notification_queue
      (user_id, event_id, type, scheduled_at, batch_key)
    select
      new.user_id, 0, '1_day'::notification_type, notif_1d,
      'user_event:' || new.id
    from public.notification_preferences np
    where np.user_id = new.user_id
      and np.enabled = true
      and np.remind_1d = true
    union all
    select
      new.user_id, 0, '1_day'::notification_type, notif_1d,
      'user_event:' || new.id
    where not exists (
      select 1 from public.notification_preferences
      where user_id = new.user_id
    )
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  if notif_1h > now() then
    insert into public.notification_queue
      (user_id, event_id, type, scheduled_at, batch_key)
    select
      new.user_id, 0, '1_hour'::notification_type, notif_1h,
      'user_event:' || new.id
    from public.notification_preferences np
    where np.user_id = new.user_id
      and np.enabled = true
      and np.remind_1h = true
    union all
    select
      new.user_id, 0, '1_hour'::notification_type, notif_1h,
      'user_event:' || new.id
    where not exists (
      select 1 from public.notification_preferences
      where user_id = new.user_id
    )
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_user_event_created on public.user_events;
create trigger trg_user_event_created
  after insert on public.user_events
  for each row
  execute function fn_schedule_user_event_notifications();

-- 3. Trigger : quand un user_event est supprime → annuler les notifications
create or replace function fn_cancel_user_event_notifications()
returns trigger as $$
begin
  update public.notification_queue
  set status = 'cancelled'
  where batch_key = 'user_event:' || old.id
    and status = 'pending';

  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_user_event_deleted on public.user_events;
create trigger trg_user_event_deleted
  before delete on public.user_events
  for each row
  execute function fn_cancel_user_event_notifications();

-- 4. Mettre a jour claim_pending_notifications pour inclure les user_events
-- Les user_events n'ont pas d'event_id dans establishment_events (event_id=0)
-- On recupere le titre depuis batch_key
create or replace function claim_pending_notifications(batch_size int default 500)
returns table (
  id                bigint,
  user_id           text,
  event_id          bigint,
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
  -- Establishment events (event_id > 0)
  select
    u.id, u.user_id, u.event_id, u.type, u.batch_key,
    e.title as event_title,
    e.starts_at as event_starts_at,
    e.establishment_id
  from updated u
  join public.establishment_events e on e.id = u.event_id
  where u.event_id > 0

  union all

  -- User events (event_id = 0, batch_key = 'user_event:<id>')
  select
    u.id, u.user_id, u.event_id, u.type, u.batch_key,
    ue.titre as event_title,
    (ue.date || ' ' || coalesce(nullif(ue.heure, ''), '00:00') || ':00')::timestamptz as event_starts_at,
    '' as establishment_id
  from updated u
  join public.user_events ue on ue.id = replace(u.batch_key, 'user_event:', '')
  where u.event_id = 0
    and u.batch_key like 'user_event:%';
end;
$$ language plpgsql;
