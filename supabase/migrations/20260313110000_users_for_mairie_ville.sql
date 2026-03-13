-- Fonction RPC pour trouver les user_ids abonnés à une ville mairie.
-- Cherche dans villes_notifications (match flexible) ET ville (fallback).
-- Ex: ville_search = "toulouse" matche "Toulouse (31000)", "Toulouse", etc.

CREATE OR REPLACE FUNCTION users_for_mairie_ville(ville_search text)
RETURNS TABLE(user_id text) AS $$
  SELECT DISTINCT p.user_id
  FROM user_profiles p
  WHERE p.ville ILIKE ville_search || '%'
     OR EXISTS (
       SELECT 1 FROM unnest(p.villes_notifications) AS v
       WHERE lower(v) LIKE lower(ville_search) || '%'
     );
$$ LANGUAGE sql STABLE;
