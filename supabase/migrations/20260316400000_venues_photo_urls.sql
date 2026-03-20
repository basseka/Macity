-- Remplacer les chemins assets locaux par des URLs Supabase Storage
-- pour la colonne 'photo' de la table 'venues'.
UPDATE venues
SET photo = REPLACE(
  photo,
  'assets/images/',
  'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/venues/venues_upload/'
)
WHERE photo LIKE 'assets/images/%';
