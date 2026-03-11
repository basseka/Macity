-- Notifications de la Mairie par ville
CREATE TABLE IF NOT EXISTS public.mairie_notifications (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ville       TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL DEFAULT '',
  photo_url   TEXT,
  link_url    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mairie_notif_ville
  ON public.mairie_notifications(ville);
CREATE INDEX IF NOT EXISTS idx_mairie_notif_created
  ON public.mairie_notifications(created_at DESC);

ALTER TABLE public.mairie_notifications ENABLE ROW LEVEL SECURITY;

-- Lecture anon, ecriture service_role
CREATE POLICY "anon_read_mairie_notif"
  ON public.mairie_notifications FOR SELECT
  USING (true);

CREATE POLICY "service_write_mairie_notif"
  ON public.mairie_notifications FOR INSERT
  WITH CHECK (current_setting('role') = 'service_role');

CREATE POLICY "service_update_mairie_notif"
  ON public.mairie_notifications FOR UPDATE
  USING (current_setting('role') = 'service_role');

CREATE POLICY "service_delete_mairie_notif"
  ON public.mairie_notifications FOR DELETE
  USING (current_setting('role') = 'service_role');
