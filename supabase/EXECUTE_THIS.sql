-- ============================================================
-- PUL'Z — TOUT LE SYSTEME DE NOTIFICATIONS
-- Copier-coller ce fichier ENTIER dans Supabase SQL Editor → Run
-- ============================================================

-- ============================================================
-- 1. TOKENS FCM
-- ============================================================
create table if not exists public.user_fcm_tokens (
  id          bigint generated always as identity primary key,
  user_id     text not null,
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
  user_id          text not null,
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
  user_id           text primary key,
  enabled           boolean not null default true,
  remind_2d         boolean not null default true,
  remind_1d         boolean not null default true,
  remind_1h         boolean not null default true,
  quiet_hour_start  time default '23:00',
  quiet_hour_end    time default '07:00',
  updated_at        timestamptz not null default now()
);

-- ============================================================
-- 4. EVENTS ETABLISSEMENTS
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
-- 5. TYPES ENUM
-- ============================================================
do $$ begin
  create type notification_type as enum ('2_days', '1_day', '1_hour');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type notification_status as enum ('pending', 'sent', 'failed', 'cancelled');
exception when duplicate_object then null;
end $$;

-- ============================================================
-- 6. FILE DE NOTIFICATIONS
-- ============================================================
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
  on public.notification_queue(scheduled_at) where status = 'pending';
create index if not exists idx_queue_event on public.notification_queue(event_id);
create index if not exists idx_queue_user  on public.notification_queue(user_id);

-- ============================================================
-- 7. AJOUTER user_id A user_events
-- ============================================================
alter table public.user_events
  add column if not exists user_id text;
create index if not exists idx_user_events_user_id
  on public.user_events(user_id);

-- ============================================================
-- 8. RLS
-- ============================================================
alter table public.user_fcm_tokens enable row level security;
alter table public.establishment_likes enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_queue enable row level security;
alter table public.establishment_events enable row level security;

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

-- ============================================================
-- 9. TRIGGERS — ESTABLISHMENT EVENTS
-- ============================================================

-- Event cree → notifications pour les likers
create or replace function fn_schedule_notifications()
returns trigger as $$
begin
  insert into public.notification_queue
    (user_id, event_id, type, scheduled_at, batch_key)
  select
    el.user_id, new.id, t.type,
    case t.type
      when '2_days' then new.starts_at - interval '2 days'
      when '1_day'  then new.starts_at - interval '1 day'
      when '1_hour' then new.starts_at - interval '1 hour'
    end,
    new.establishment_id || ':' || date_trunc('day', new.starts_at)::date
  from public.establishment_likes el
  cross join (values ('2_days'::notification_type),('1_day'::notification_type),('1_hour'::notification_type)) as t(type)
  left join public.notification_preferences np on np.user_id = el.user_id
  where el.establishment_id = new.establishment_id
    and coalesce(np.enabled, true)
    and ((t.type='2_days' and coalesce(np.remind_2d,true)) or (t.type='1_day' and coalesce(np.remind_1d,true)) or (t.type='1_hour' and coalesce(np.remind_1h,true)))
    and case t.type when '2_days' then new.starts_at-interval '2 days' when '1_day' then new.starts_at-interval '1 day' when '1_hour' then new.starts_at-interval '1 hour' end > now()
  on conflict (user_id, type, batch_key) do nothing;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_event_created on public.establishment_events;
create trigger trg_event_created after insert on public.establishment_events
  for each row execute function fn_schedule_notifications();

-- Event modifie → recalcul
create or replace function fn_reschedule_notifications()
returns trigger as $$
begin
  if old.starts_at is distinct from new.starts_at then
    update public.notification_queue
    set scheduled_at = case type when '2_days' then new.starts_at-interval '2 days' when '1_day' then new.starts_at-interval '1 day' when '1_hour' then new.starts_at-interval '1 hour' end
    where event_id = new.id and status = 'pending';
    update public.notification_queue set status = 'cancelled'
    where event_id = new.id and status = 'pending' and scheduled_at <= now();
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_event_updated on public.establishment_events;
create trigger trg_event_updated after update on public.establishment_events
  for each row execute function fn_reschedule_notifications();

-- Event supprime → annulation
create or replace function fn_cancel_notifications()
returns trigger as $$
begin
  update public.notification_queue set status='cancelled' where event_id=old.id and status='pending';
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_event_deleted on public.establishment_events;
create trigger trg_event_deleted before delete on public.establishment_events
  for each row execute function fn_cancel_notifications();

-- Like → programmer notifs pour events futurs
create or replace function fn_like_schedule()
returns trigger as $$
begin
  insert into public.notification_queue (user_id, event_id, type, scheduled_at, batch_key)
  select new.user_id, e.id, t.type,
    case t.type when '2_days' then e.starts_at-interval '2 days' when '1_day' then e.starts_at-interval '1 day' when '1_hour' then e.starts_at-interval '1 hour' end,
    e.establishment_id || ':' || date_trunc('day', e.starts_at)::date
  from public.establishment_events e
  cross join (values ('2_days'::notification_type),('1_day'::notification_type),('1_hour'::notification_type)) as t(type)
  left join public.notification_preferences np on np.user_id = new.user_id
  where e.establishment_id = new.establishment_id and e.starts_at > now()
    and coalesce(np.enabled,true)
    and ((t.type='2_days' and coalesce(np.remind_2d,true)) or (t.type='1_day' and coalesce(np.remind_1d,true)) or (t.type='1_hour' and coalesce(np.remind_1h,true)))
    and case t.type when '2_days' then e.starts_at-interval '2 days' when '1_day' then e.starts_at-interval '1 day' when '1_hour' then e.starts_at-interval '1 hour' end > now()
  on conflict (user_id, type, batch_key) do nothing;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_like_created on public.establishment_likes;
create trigger trg_like_created after insert on public.establishment_likes
  for each row execute function fn_like_schedule();

-- Unlike → annuler
create or replace function fn_unlike_cancel()
returns trigger as $$
begin
  update public.notification_queue nq set status='cancelled'
  from public.establishment_events e
  where nq.event_id=e.id and e.establishment_id=old.establishment_id and nq.user_id=old.user_id and nq.status='pending';
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_like_deleted on public.establishment_likes;
create trigger trg_like_deleted after delete on public.establishment_likes
  for each row execute function fn_unlike_cancel();

-- ============================================================
-- 10. TRIGGERS — USER EVENTS (rappels pour le createur)
-- ============================================================

create or replace function fn_schedule_user_event_notifications()
returns trigger as $$
declare
  starts_at_ts timestamptz;
begin
  if new.user_id is null or new.user_id = '' then return new; end if;
  if new.date is null or new.date = '' then return new; end if;

  if new.heure is not null and new.heure != '' then
    starts_at_ts := (new.date || ' ' || new.heure || ':00')::timestamptz;
  else
    starts_at_ts := (new.date || ' 00:00:00')::timestamptz;
  end if;

  -- 2 jours avant
  if starts_at_ts - interval '2 days' > now() then
    insert into public.notification_queue (user_id, event_id, type, scheduled_at, batch_key)
    values (new.user_id, 0, '2_days', starts_at_ts - interval '2 days', 'user_event:' || new.id)
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  -- 1 jour avant
  if starts_at_ts - interval '1 day' > now() then
    insert into public.notification_queue (user_id, event_id, type, scheduled_at, batch_key)
    values (new.user_id, 0, '1_day', starts_at_ts - interval '1 day', 'user_event:' || new.id)
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  -- 1 heure avant
  if starts_at_ts - interval '1 hour' > now() then
    insert into public.notification_queue (user_id, event_id, type, scheduled_at, batch_key)
    values (new.user_id, 0, '1_hour', starts_at_ts - interval '1 hour', 'user_event:' || new.id)
    on conflict (user_id, type, batch_key) do nothing;
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_user_event_created on public.user_events;
create trigger trg_user_event_created after insert on public.user_events
  for each row execute function fn_schedule_user_event_notifications();

-- Suppression user_event → annuler
create or replace function fn_cancel_user_event_notifications()
returns trigger as $$
begin
  update public.notification_queue set status='cancelled'
  where batch_key='user_event:' || old.id and status='pending';
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_user_event_deleted on public.user_events;
create trigger trg_user_event_deleted before delete on public.user_events
  for each row execute function fn_cancel_user_event_notifications();

-- ============================================================
-- 11. CLAIM FUNCTION (pour l'Edge Function)
-- ============================================================

create or replace function claim_pending_notifications(batch_size int default 500)
returns table (
  id bigint, user_id text, event_id bigint,
  type notification_type, batch_key text,
  event_title text, event_starts_at timestamptz, establishment_id text
) as $$
begin
  return query
  with claimed as (
    select nq.id from public.notification_queue nq
    where nq.status='pending' and nq.scheduled_at <= now() and nq.attempts < 3
    order by nq.scheduled_at limit batch_size
    for update skip locked
  ),
  updated as (
    update public.notification_queue nq set attempts=nq.attempts+1
    from claimed c where nq.id=c.id returning nq.*
  )
  -- Establishment events
  select u.id, u.user_id, u.event_id, u.type, u.batch_key,
    e.title, e.starts_at, e.establishment_id
  from updated u join public.establishment_events e on e.id=u.event_id
  where u.event_id > 0
  union all
  -- User events
  select u.id, u.user_id, u.event_id, u.type, u.batch_key,
    ue.titre,
    (ue.date || ' ' || coalesce(nullif(ue.heure,''),'00:00') || ':00')::timestamptz,
    ''
  from updated u
  join public.user_events ue on ue.id = replace(u.batch_key, 'user_event:', '')
  where u.event_id=0 and u.batch_key like 'user_event:%';
end;
$$ language plpgsql;
