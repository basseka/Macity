-- ============================================================
-- Table : appli_activity
-- Log d'activite event-sourced. Chaque action = 1 ligne.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.appli_activity (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     TEXT    NOT NULL,
  action      TEXT    NOT NULL,        -- app_open, event_created, event_shared, like, search, mode_view, onboarding_complete
  metadata    JSONB   DEFAULT '{}',    -- donnees contextuelles (event_id, mode, query, etc.)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_user    ON public.appli_activity(user_id);
CREATE INDEX idx_activity_action  ON public.appli_activity(action);
CREATE INDEX idx_activity_date    ON public.appli_activity(created_at DESC);

ALTER TABLE public.appli_activity ENABLE ROW LEVEL SECURITY;

-- Lecture : service_role uniquement (dashboard admin)
CREATE POLICY "activity_read_service" ON public.appli_activity
  FOR SELECT USING (true);

-- Ecriture : tout le monde peut logger (anon key)
CREATE POLICY "activity_insert_anon" ON public.appli_activity
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- Vues d'aggregation pour le dashboard
-- ============================================================

-- 1. Ouvertures d'app par jour
CREATE OR REPLACE VIEW public.v_daily_opens AS
SELECT
  DATE(created_at) AS jour,
  COUNT(*)         AS nb_ouvertures,
  COUNT(DISTINCT user_id) AS nb_users_uniques
FROM public.appli_activity
WHERE action = 'app_open'
GROUP BY DATE(created_at)
ORDER BY jour DESC;

-- 2. Events crees par jour
CREATE OR REPLACE VIEW public.v_daily_events_created AS
SELECT
  DATE(created_at) AS jour,
  COUNT(*)         AS nb_events,
  COUNT(DISTINCT user_id) AS nb_createurs
FROM public.appli_activity
WHERE action = 'event_created'
GROUP BY DATE(created_at)
ORDER BY jour DESC;

-- 3. Top createurs d'events
CREATE OR REPLACE VIEW public.v_top_creators AS
SELECT
  a.user_id,
  COALESCE(p.prenom, 'Anonyme') AS prenom,
  COALESCE(p.ville, '') AS ville,
  COUNT(*) AS nb_events_crees,
  MAX(a.created_at) AS dernier_event
FROM public.appli_activity a
LEFT JOIN public.user_profiles p ON p.user_id = a.user_id
WHERE a.action = 'event_created'
GROUP BY a.user_id, p.prenom, p.ville
ORDER BY nb_events_crees DESC;

-- 4. Modes les plus visites
CREATE OR REPLACE VIEW public.v_popular_modes AS
SELECT
  metadata->>'mode' AS mode,
  COUNT(*)          AS nb_vues,
  COUNT(DISTINCT user_id) AS nb_users
FROM public.appli_activity
WHERE action = 'mode_view'
  AND metadata->>'mode' IS NOT NULL
GROUP BY metadata->>'mode'
ORDER BY nb_vues DESC;

-- 5. Activite globale (resume)
CREATE OR REPLACE VIEW public.v_activity_summary AS
SELECT
  action,
  COUNT(*)                AS total,
  COUNT(DISTINCT user_id) AS users_uniques,
  MIN(created_at)         AS premiere_action,
  MAX(created_at)         AS derniere_action
FROM public.appli_activity
GROUP BY action
ORDER BY total DESC;

-- 6. Partages par jour
CREATE OR REPLACE VIEW public.v_daily_shares AS
SELECT
  DATE(created_at) AS jour,
  COUNT(*)         AS nb_partages,
  COUNT(DISTINCT user_id) AS nb_partageurs
FROM public.appli_activity
WHERE action = 'event_shared'
GROUP BY DATE(created_at)
ORDER BY jour DESC;

-- 7. Likes par jour
CREATE OR REPLACE VIEW public.v_daily_likes AS
SELECT
  DATE(created_at) AS jour,
  COUNT(*)         AS nb_likes,
  COUNT(DISTINCT user_id) AS nb_likeurs
FROM public.appli_activity
WHERE action = 'like'
GROUP BY DATE(created_at)
ORDER BY jour DESC;

-- 8. Recherches populaires
CREATE OR REPLACE VIEW public.v_popular_searches AS
SELECT
  metadata->>'query' AS recherche,
  COUNT(*)           AS nb_fois,
  COUNT(DISTINCT user_id) AS nb_users
FROM public.appli_activity
WHERE action = 'search'
  AND metadata->>'query' IS NOT NULL
GROUP BY metadata->>'query'
ORDER BY nb_fois DESC
LIMIT 100;

-- 9. Retention : users actifs par semaine
CREATE OR REPLACE VIEW public.v_weekly_active_users AS
SELECT
  DATE_TRUNC('week', created_at)::DATE AS semaine,
  COUNT(DISTINCT user_id) AS users_actifs
FROM public.appli_activity
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY semaine DESC;

-- 10. Activite par heure (pour comprendre les pics d'usage)
CREATE OR REPLACE VIEW public.v_hourly_activity AS
SELECT
  EXTRACT(HOUR FROM created_at)::INT AS heure,
  COUNT(*) AS nb_actions,
  COUNT(DISTINCT user_id) AS nb_users
FROM public.appli_activity
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY heure;
