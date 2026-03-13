-- Ajoute une colonne tableau pour les villes dont l'utilisateur veut recevoir
-- les notifications mairie. Initialise depuis la colonne `ville` existante.

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS villes_notifications TEXT[] DEFAULT '{}';

-- Migrer les villes existantes dans le tableau (si non vide)
UPDATE user_profiles
  SET villes_notifications = ARRAY[ville]
  WHERE ville IS NOT NULL AND ville != '' AND (villes_notifications IS NULL OR villes_notifications = '{}');

-- Index GIN pour les requêtes ANY()
CREATE INDEX IF NOT EXISTS idx_user_profiles_villes_notif
  ON user_profiles USING GIN (villes_notifications);
