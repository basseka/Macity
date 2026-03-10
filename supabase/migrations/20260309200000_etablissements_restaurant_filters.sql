-- Ajouter colonnes theme, quartier, style pour les restaurants
ALTER TABLE public.etablissements
  ADD COLUMN IF NOT EXISTS theme TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS quartier TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS style TEXT NOT NULL DEFAULT '';

-- Mettre a jour les restaurants existants
UPDATE public.etablissements SET theme = 'Francais', quartier = 'Carmes', style = 'A theme'
  WHERE rubrique = 'food' AND nom ILIKE '%In The Dark%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Matabiau', style = 'A theme'
  WHERE rubrique = 'food' AND nom ILIKE '%Cockpit%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Capitole', style = 'Festif'
  WHERE rubrique = 'food' AND nom ILIKE '%Sixta%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Esquirol', style = 'Romantique'
  WHERE rubrique = 'food' AND nom ILIKE '%Caves de la Marechale%';

UPDATE public.etablissements SET theme = 'Sud-Ouest', quartier = 'Saint-Georges', style = 'Bar a vin'
  WHERE rubrique = 'food' AND nom ILIKE '%Petits Crus%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Carmes', style = 'Decontracte'
  WHERE rubrique = 'food' AND nom ILIKE '%Pieds sous la Table%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Carmes', style = 'Gastronomique'
  WHERE rubrique = 'food' AND nom ILIKE '%Hortus%';

UPDATE public.etablissements SET theme = 'Francais', quartier = 'Saint-Georges', style = 'Bistronomique'
  WHERE rubrique = 'food' AND nom ILIKE '%Saint Sauvage%';

UPDATE public.etablissements SET theme = 'Japonais', quartier = 'Carmes', style = 'Moderne'
  WHERE rubrique = 'food' AND nom ILIKE '%Hito%';

UPDATE public.etablissements SET theme = 'Fusion', quartier = 'Capitole', style = 'Lounge'
  WHERE rubrique = 'food' AND nom ILIKE '%speakeasy%';
