-- Rendre venue_id et pro_id optionnels, ajouter venue_name et email/telephone
-- pour accepter les claims de n'importe quel utilisateur.

ALTER TABLE venue_claims ALTER COLUMN venue_id DROP NOT NULL;
ALTER TABLE venue_claims ALTER COLUMN pro_id DROP NOT NULL;
ALTER TABLE venue_claims DROP CONSTRAINT IF EXISTS venue_claims_venue_id_key;
ALTER TABLE venue_claims ADD COLUMN IF NOT EXISTS venue_name text NOT NULL DEFAULT '';
ALTER TABLE venue_claims ADD COLUMN IF NOT EXISTS email text NOT NULL DEFAULT '';
ALTER TABLE venue_claims ADD COLUMN IF NOT EXISTS telephone text NOT NULL DEFAULT '';
ALTER TABLE venue_claims ADD COLUMN IF NOT EXISTS user_id text NOT NULL DEFAULT '';
