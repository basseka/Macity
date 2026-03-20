-- Normalise les numéros de téléphone existants dans user_profiles
-- 0612345678 → +33612345678
-- 33612345678 → +33612345678

UPDATE public.user_profiles
SET telephone = '+33' || SUBSTRING(telephone FROM 2)
WHERE telephone ~ '^0[0-9]{9}$';

UPDATE public.user_profiles
SET telephone = '+' || telephone
WHERE telephone ~ '^33[0-9]{9}$';

-- Aussi nettoyer les espaces / tirets résiduels
UPDATE public.user_profiles
SET telephone = '+33' || SUBSTRING(regexp_replace(telephone, '[^0-9]', '', 'g') FROM 2)
WHERE telephone ~ '[ .\-]'
  AND regexp_replace(telephone, '[^0-9]', '', 'g') ~ '^0[0-9]{9}$';

-- Remplacer la RPC pour normaliser côté DB aussi (ceinture + bretelles)
CREATE OR REPLACE FUNCTION public.find_users_by_phones(phones TEXT[])
RETURNS TABLE(user_id TEXT, prenom TEXT, telephone TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT up.user_id, up.prenom, up.telephone
  FROM public.user_profiles up
  WHERE up.telephone = ANY(phones)
    AND up.telephone <> '';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
