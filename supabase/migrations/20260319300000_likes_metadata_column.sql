-- Ajoute une colonne metadata aux likes pour pouvoir restaurer
-- titre, image et categorie apres reinstallation de l'app.
ALTER TABLE public.establishment_likes
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
