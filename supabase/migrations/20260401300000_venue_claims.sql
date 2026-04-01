-- Table de revendication des venues par les proprietaires (pros).
-- Un proprio peut revendiquer sa fiche, une fois approuve il peut la modifier.
-- La venue recoit un badge "verifie" apres mise a jour par le proprio.

-- Ajouter le champ is_verified sur venues
ALTER TABLE venues ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;

-- Table des revendications
CREATE TABLE IF NOT EXISTS venue_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id bigint NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  pro_id uuid NOT NULL REFERENCES pro_profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',  -- pending, approved, rejected
  siret text,                              -- preuve : numero SIRET
  proof_url text,                          -- preuve : site web ou doc
  message text,                            -- message du proprio
  claimed_at timestamptz NOT NULL DEFAULT now(),
  verified_at timestamptz,
  UNIQUE(venue_id)                         -- un seul proprio par venue
);

-- Index
CREATE INDEX idx_venue_claims_pro ON venue_claims (pro_id);
CREATE INDEX idx_venue_claims_status ON venue_claims (status);

-- RLS
ALTER TABLE venue_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read_venue_claims" ON venue_claims FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert_venue_claims" ON venue_claims FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "service_write_venue_claims" ON venue_claims FOR ALL TO service_role USING (true);

-- Fonction pour approuver un claim et marquer la venue comme verifiee
CREATE OR REPLACE FUNCTION approve_venue_claim(claim_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE venue_claims SET status = 'approved', verified_at = now() WHERE id = claim_id;
  UPDATE venues SET is_verified = true WHERE id = (SELECT venue_id FROM venue_claims WHERE id = claim_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
