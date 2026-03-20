-- Etape 1 : Essentiel
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS format TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS description_courte TEXT DEFAULT '';

-- Etape 2 : Quand & Ou
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS date_fin TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS heure_fin TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS recurrence JSONB;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS lieu_type TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS pays TEXT DEFAULT 'France';

-- Etape 3 : Tarifs & Billetterie
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS est_gratuit BOOLEAN DEFAULT FALSE;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS prix NUMERIC(10,2);
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS prix_reduit NUMERIC(10,2);
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS prix_groupe NUMERIC(10,2);
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS prix_early_bird NUMERIC(10,2);

-- Etape 4 : Details
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS description_longue TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS public_cible TEXT DEFAULT 'tous publics';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS niveau TEXT DEFAULT 'tous niveaux';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS organisateur_type TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS organisateur_nom TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS organisateur_email TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS organisateur_telephone TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS organisateur_site TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS participants_min INT;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS participants_max INT;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS inscription_type TEXT DEFAULT 'libre';

-- Etape 5 : Extras
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS video_url TEXT DEFAULT '';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS programme JSONB;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS accessibilite JSONB;
ALTER TABLE user_events ADD COLUMN IF NOT EXISTS regles JSONB;
