-- ============================================================
-- Promo notifications : rotation toutes les 30 min sur 8 univers
-- ============================================================

-- 1. Table singleton pour garder l'état de rotation
CREATE TABLE IF NOT EXISTS public.promo_notification_state (
  id             integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  current_index  smallint NOT NULL DEFAULT 0,   -- 0..7 rotation sur 8 univers
  last_sent_at   timestamptz NOT NULL DEFAULT now()
);

-- Seed la ligne singleton
INSERT INTO public.promo_notification_state (id, current_index, last_sent_at)
VALUES (1, 0, now())
ON CONFLICT (id) DO NOTHING;

-- RLS : service_role only (pas d'accès anon)
ALTER TABLE public.promo_notification_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only"
  ON public.promo_notification_state
  FOR ALL
  USING (current_setting('role') = 'service_role')
  WITH CHECK (current_setting('role') = 'service_role');

-- 2. CRON toutes les 30 minutes
SELECT cron.schedule(
  'send-promo-notifications',
  '*/30 * * * *',
  $$
  SELECT net.http_post(
    url    := 'https://dpqxefmwjfvoysacwgef.supabase.co/functions/v1/send-promo-notifications',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcXhlZm13amZ2b3lzYWN3Z2VmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDI5OTExOCwiZXhwIjoyMDg1ODc1MTE4fQ.7-Tv6VPoYYY2Kt07hMe1vPFz0iCE9V6SjMIgX1IQVVw',
      'Content-Type',  'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
