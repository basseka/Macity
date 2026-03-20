-- Centres d'interets detailles pour un meilleur ciblage des notifications.
-- Format: "mode:sous_interet" (ex: "sport:football", "day:festival")
-- La colonne preferences existante reste pour backward compat (modes principaux).
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS preferences_detailed TEXT[] DEFAULT '{}';
