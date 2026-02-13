-- ============================================================
-- PUL'Z — Systeme de notifications push
-- A executer dans Supabase SQL Editor (Dashboard)
-- ============================================================

-- ============================================================
-- 1. TOKENS FCM
-- ============================================================
create table if not exists public.user_fcm_tokens (
  id          bigint generated always as identity primary key,
  user_id     text not null,                -- device UUID (SharedPreferences)
  token       text not null,
  device_id   text not null,
  platform    text not null default 'android'
              check (platform in ('android', 'ios', 'web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  unique (user_id, device_id)
);

create index if not exists idx_fcm_user  on public.user_fcm_tokens(user_id);
create index if not exists idx_fcm_token on public.user_fcm_tokens(token);

-- ============================================================
-- 2. LIKES (etablissements)
-- ============================================================
create table if not exists public.establishment_likes (
  user_id          text not null,            -- device UUID
  establishment_id text not null,
  created_at       timestamptz not null default now(),

  primary key (user_id, establishment_id)
);

create index if not exists idx_likes_establishment
  on public.establishment_likes(establishment_id);

-- ============================================================
-- 3. PREFERENCES NOTIFICATION
-- ============================================================
create table if not exists public.notification_preferences (
  user_id           text primary key,        -- device UUID
  enabled           boolean not null default true,
  remind_2d         boolean not null default true,
  remind_1d         boolean not null default true,
  remind_1h         boolean not null default true,
  quiet_hour_start  time default '23:00',
  quiet_hour_end    time default '07:00',
  updated_at        timestamptz not null default now()
);

-- ============================================================
-- 4. EVENTS (etablissements publient des events)
-- ============================================================
create table if not exists public.establishment_events (
  id                bigint generated always as identity primary key,
  establishment_id  text not null,
  title             text not null,
  description       text,
  starts_at         timestamptz not null,
  timezone          text not null default 'Europe/Paris',
  city              text not null default 'toulouse',
  photo_url         text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists idx_estab_events_establishment
  on public.establishment_events(establishment_id);
create index if not exists idx_estab_events_starts
  on public.establishment_events(starts_at);

-- ============================================================
-- 5. FILE DE NOTIFICATIONS
-- ============================================================
do $$ begin
  create type notification_type as enum ('2_days', '1_day', '1_hour');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type notification_status as enum ('pending', 'sent', 'failed', 'cancelled');
exception when duplicate_object then null;
end $$;

create table if not exists public.notification_queue (
  id                bigint generated always as identity primary key,
  user_id           text not null,
  event_id          bigint not null default 0,
  type              notification_type not null,
  scheduled_at      timestamptz not null,
  status            notification_status not null default 'pending',
  batch_key         text,
  attempts          smallint not null default 0,
  sent_at           timestamptz,
  error_message     text,
  created_at        timestamptz not null default now(),

  unique (user_id, type, batch_key)
);

create index if not exists idx_queue_pending
  on public.notification_queue(scheduled_at)
  where status = 'pending';
create index if not exists idx_queue_event on public.notification_queue(event_id);
create index if not exists idx_queue_user  on public.notification_queue(user_id);

-- ============================================================
-- 6. TRIGGERS
-- ============================================================

-- A. Event cree → programmer les notifications pour les likers
create or replace function fn_schedule_notifications()
returns trigger as $$
begin
  insert into public.notification_queue
    (user_id, event_id, type, scheduled_at, batch_key)
  select
    el.user_id,
    new.id,
    t.type,
    case t.type
      when '2_days' then new.starts_at - interval '2 days'
      when '1_day'  then new.starts_at - interval '1 day'
      when '1_hour' then new.starts_at - interval '1 hour'
    end as scheduled_at,
    new.establishment_id || ':' || date_trunc('day', new.starts_at)::date
  from public.establishment_likes el
  cross join (
    values ('2_days'::notification_type),
           ('1_day'::notification_type),
           ('1_hour'::notification_type)
  ) as t(type)
  left join public.notification_preferences np
    on np.user_id = el.user_id
  where el.establishment_id = new.establishment_id
    and coalesce(np.enabled, true) = true
    and (
      (t.type = '2_days' and coalesce(np.remind_2d, true)) or
      (t.type = '1_day'  and coalesce(np.remind_1d, true)) or
      (t.type = '1_hour' and coalesce(np.remind_1h, true))
    )
    and case t.type
      when '2_days' then new.starts_at - interval '2 days'
      when '1_day'  then new.starts_at - interval '1 day'
      when '1_hour' then new.starts_at - interval '1 hour'
    end > now()
  on conflict (user_id, type, batch_key) do nothing;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_event_created on public.establishment_events;
create trigger trg_event_created
  after insert on public.establishment_events
  for each row
  execute function fn_schedule_notifications();

-- B. Event modifie → recalculer les dates
create or replace function fn_reschedule_notifications()
returns trigger as $$
begin
  if old.starts_at is distinct from new.starts_at then
    update public.notification_queue
    set scheduled_at = case type
          when '2_days' then new.starts_at - interval '2 days'
          when '1_day'  then new.starts_at - interval '1 day'
          when '1_hour' then new.starts_at - interval '1 hour'
        end
    where event_id = new.id
      and status = 'pending';

    update public.notification_queue
    set status = 'cancelled'
    where event_id = new.id
      and status = 'pending'
      and scheduled_at <= now();
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_event_updated on public.establishment_events;
create trigger trg_event_updated
  after update on public.establishment_events
  for each row
  execute function fn_reschedule_notifications();

-- C. Event supprime → annuler les notifications pending
create or replace function fn_cancel_notifications()
returns trigger as $$
begin
  update public.notification_queue
  set status = 'cancelled'
  where event_id = old.id
    and status = 'pending';

  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_event_deleted on public.establishment_events;
create trigger trg_event_deleted
  before delete on public.establishment_events
  for each row
  execute function fn_cancel_notifications();

-- D. Like → rattraper les events futurs
create or replace function fn_like_schedule()
returns trigger as $$
begin
  insert into public.notification_queue
    (user_id, event_id, type, scheduled_at, batch_key)
  select
    new.user_id,
    e.id,
    t.type,
    case t.type
      when '2_days' then e.starts_at - interval '2 days'
      when '1_day'  then e.starts_at - interval '1 day'
      when '1_hour' then e.starts_at - interval '1 hour'
    end,
    e.establishment_id || ':' || date_trunc('day', e.starts_at)::date
  from public.establishment_events e
  cross join (
    values ('2_days'::notification_type),
           ('1_day'::notification_type),
           ('1_hour'::notification_type)
  ) as t(type)
  left join public.notification_preferences np
    on np.user_id = new.user_id
  where e.establishment_id = new.establishment_id
    and e.starts_at > now()
    and coalesce(np.enabled, true) = true
    and (
      (t.type = '2_days' and coalesce(np.remind_2d, true)) or
      (t.type = '1_day'  and coalesce(np.remind_1d, true)) or
      (t.type = '1_hour' and coalesce(np.remind_1h, true))
    )
    and case t.type
      when '2_days' then e.starts_at - interval '2 days'
      when '1_day'  then e.starts_at - interval '1 day'
      when '1_hour' then e.starts_at - interval '1 hour'
    end > now()
  on conflict (user_id, type, batch_key) do nothing;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_like_created on public.establishment_likes;
create trigger trg_like_created
  after insert on public.establishment_likes
  for each row
  execute function fn_like_schedule();

-- E. Unlike → annuler les notifications
create or replace function fn_unlike_cancel()
returns trigger as $$
begin
  update public.notification_queue nq
  set status = 'cancelled'
  from public.establishment_events e
  where nq.event_id = e.id
    and e.establishment_id = old.establishment_id
    and nq.user_id = old.user_id
    and nq.status = 'pending';

  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_like_deleted on public.establishment_likes;
create trigger trg_like_deleted
  after delete on public.establishment_likes
  for each row
  execute function fn_unlike_cancel();

-- ============================================================
-- 7. FONCTION claim_pending_notifications (lock optimiste)
-- ============================================================
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
  select
    u.id, u.user_id, u.event_id, u.type, u.batch_key,
    e.title as event_title,
    e.starts_at as event_starts_at,
    e.establishment_id
  from updated u
  join public.establishment_events e on e.id = u.event_id;
end;
$$ language plpgsql;

-- ============================================================
-- 8. RLS (adapte pour anon key — filtre par user_id en header)
-- ============================================================
alter table public.user_fcm_tokens enable row level security;
alter table public.establishment_likes enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_queue enable row level security;
alter table public.establishment_events enable row level security;

-- user_fcm_tokens : lecture/ecriture via anon key
-- Le filtrage par user_id se fait cote client (comme user_events)
create policy "anon_fcm_all" on public.user_fcm_tokens
  for all using (true) with check (true);

create policy "anon_likes_all" on public.establishment_likes
  for all using (true) with check (true);

create policy "anon_prefs_all" on public.notification_preferences
  for all using (true) with check (true);

create policy "anon_queue_select" on public.notification_queue
  for select using (true);

create policy "anon_events_all" on public.establishment_events
  for all using (true) with check (true);

-- La queue est ecrite par les triggers (SECURITY DEFINER) et
-- lue/modifiee par l'Edge Function (service_role key).
-- Le client n'a besoin que du SELECT pour afficher l'historique.

-- ============================================================
-- 9. CRON JOBS (pg_cron — activer dans Dashboard > Extensions)
-- ============================================================
-- NOTE: Executer APRES avoir active l'extension pg_cron
--       et remplace <PROJECT_REF> et <SERVICE_ROLE_KEY>

-- Envoi des notifications toutes les minutes
-- select cron.schedule(
--   'send-pending-notifications',
--   '* * * * *',
--   $$
--   select net.http_post(
--     url    := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-notifications',
--     headers := jsonb_build_object(
--       'Authorization', 'Bearer <SERVICE_ROLE_KEY>',
--       'Content-Type',  'application/json'
--     ),
--     body := '{}'::jsonb
--   );
--   $$
-- );

-- Nettoyage nocturne des vieilles notifications
-- select cron.schedule(
--   'cleanup-old-notifications',
--   '0 3 * * *',
--   $$
--   delete from public.notification_queue
--   where status in ('sent', 'cancelled', 'failed')
--     and created_at < now() - interval '30 days';
--   $$
-- );

-- Retry des echecs toutes les 5 min
-- select cron.schedule(
--   'retry-failed-notifications',
--   '*/5 * * * *',
--   $$
--   update public.notification_queue
--   set status = 'pending'
--   where status = 'failed'
--     and attempts < 3
--     and scheduled_at <= now();
--   $$
-- );
