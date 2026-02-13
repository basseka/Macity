-- ============================================================
-- 003_pro_auth.sql – Auth pro pour l'ajout d'evenements
-- ============================================================

-- 1. Table des codes d'acces pre-generes
CREATE TABLE IF NOT EXISTS pro_access_codes (
  code    TEXT PRIMARY KEY,
  used    BOOLEAN   NOT NULL DEFAULT FALSE,
  used_by UUID,
  used_at TIMESTAMPTZ
);

-- 2. Table des profils pro
CREATE TABLE IF NOT EXISTS pro_profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL UNIQUE,
  nom         TEXT        NOT NULL,
  type        TEXT        NOT NULL CHECK (type IN ('association', 'etablissement_prive', 'personne_morale')),
  email       TEXT        NOT NULL,
  telephone   TEXT        NOT NULL,
  access_code TEXT        NOT NULL REFERENCES pro_access_codes(code),
  approved    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- RLS
-- ============================================================

ALTER TABLE pro_access_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_profiles      ENABLE ROW LEVEL SECURITY;

-- Codes : tout le monde peut lire (pour valider) et update (pour marquer used)
CREATE POLICY "anon_select_codes" ON pro_access_codes
  FOR SELECT USING (true);

CREATE POLICY "anon_update_codes" ON pro_access_codes
  FOR UPDATE USING (true);

-- Profils : tout le monde peut inserer, lire et update
CREATE POLICY "anon_insert_profiles" ON pro_profiles
  FOR INSERT WITH CHECK (true);

CREATE POLICY "anon_select_profiles" ON pro_profiles
  FOR SELECT USING (true);

CREATE POLICY "anon_update_profiles" ON pro_profiles
  FOR UPDATE USING (true);

-- ============================================================
-- Seed : 5 codes de test
-- ============================================================

INSERT INTO pro_access_codes (code) VALUES
  ('PULZ-PRO-001'),
  ('PULZ-PRO-002'),
  ('PULZ-PRO-003'),
  ('PULZ-PRO-004'),
  ('PULZ-PRO-005')
ON CONFLICT (code) DO NOTHING;
