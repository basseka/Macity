-- ============================================================
-- 004 – Offres promotionnelles dynamiques
-- ============================================================

CREATE TABLE IF NOT EXISTS public.offers (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_profile_id   UUID        NOT NULL,
  business_name    TEXT        NOT NULL,
  business_address TEXT        NOT NULL DEFAULT '',
  title            TEXT        NOT NULL,
  description      TEXT        NOT NULL DEFAULT '',
  emoji            TEXT        NOT NULL DEFAULT '',
  total_spots      INT         NOT NULL DEFAULT 10,
  claimed_spots    INT         NOT NULL DEFAULT 0,
  starts_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at       TIMESTAMPTZ NOT NULL,
  is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
  city             TEXT        NOT NULL DEFAULT 'Toulouse',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS permissif (meme pattern que les autres tables)
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "offers_select_all" ON public.offers
  FOR SELECT USING (true);

CREATE POLICY "offers_insert_all" ON public.offers
  FOR INSERT WITH CHECK (true);

CREATE POLICY "offers_update_all" ON public.offers
  FOR UPDATE USING (true);

CREATE POLICY "offers_delete_all" ON public.offers
  FOR DELETE USING (true);
