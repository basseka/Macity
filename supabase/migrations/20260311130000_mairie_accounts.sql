-- Comptes mairies pour le dashboard admin SaaS
CREATE TABLE IF NOT EXISTS public.mairie_accounts (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email       TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  commune     TEXT NOT NULL,
  code_postal TEXT NOT NULL DEFAULT '',
  siret       TEXT NOT NULL DEFAULT '',
  nom_contact TEXT NOT NULL DEFAULT '',
  logo_url    TEXT,
  plan        TEXT NOT NULL DEFAULT 'gratuit'
              CHECK (plan IN ('gratuit', 'starter', 'pro')),
  active      BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mairie_accounts_email
  ON public.mairie_accounts(email);
CREATE INDEX IF NOT EXISTS idx_mairie_accounts_commune
  ON public.mairie_accounts(commune);

ALTER TABLE public.mairie_accounts ENABLE ROW LEVEL SECURITY;

-- Lecture/ecriture via service_role uniquement
CREATE POLICY "service_mairie_accounts"
  ON public.mairie_accounts FOR ALL
  USING (current_setting('role') = 'service_role')
  WITH CHECK (current_setting('role') = 'service_role');

-- Lier les notifications a un compte mairie
ALTER TABLE public.mairie_notifications
  ADD COLUMN IF NOT EXISTS mairie_account_id BIGINT REFERENCES public.mairie_accounts(id);
