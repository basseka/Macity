-- Trigger : quand status passe a 'approved' dans venue_claims,
-- mettre automatiquement is_verified=true sur la venue.
-- Comme ca, changer le status dans le dashboard suffit.

CREATE OR REPLACE FUNCTION auto_verify_on_claim_approved()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    NEW.verified_at = now();
    IF NEW.venue_id IS NOT NULL THEN
      UPDATE venues SET is_verified = true WHERE id = NEW.venue_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_verify_claim ON venue_claims;
CREATE TRIGGER trg_auto_verify_claim
  BEFORE UPDATE ON venue_claims
  FOR EACH ROW
  EXECUTE FUNCTION auto_verify_on_claim_approved();
