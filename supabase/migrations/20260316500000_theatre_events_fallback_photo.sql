-- Attribuer une photo fallback aux spectacles de theatre qui n'en ont pas.
-- Utilise la photo du theatre (depuis la table venues) ou la pochette generique.

-- Photo par source (venue photo du Storage)
UPDATE scraped_events SET photo_url = v.photo
FROM venues v
WHERE scraped_events.rubrique = 'culture'
  AND scraped_events.photo_url = ''
  AND v.mode = 'culture' AND v.category = 'Theatre'
  AND (
    (scraped_events.source = 'theatre_sorano' AND v.slug = 'sorano-theatre')
    OR (scraped_events.source = 'theatre_pont_neuf' AND v.slug = 'theatre-du-pont-neuf')
    OR (scraped_events.source = 'cave_poesie' AND v.slug = 'la-cave-poesie')
    OR (scraped_events.source = 'theatre_garonne' AND v.slug = 'theatre-garonne')
    OR (scraped_events.source = 'theatre_cite' AND v.slug = 'theatredelacite-cdn-toulouse-occitanie')
    OR (scraped_events.source = 'theatre_capitole' AND v.slug = 'theatre-du-capitole')
    OR (scraped_events.source = 'theatre_grand_rond' AND v.slug = 'theatre-du-grand-rond')
    OR (scraped_events.source = 'grenier_theatre' AND v.slug = 'grenier-theatre')
    OR (scraped_events.source = 'three_t' AND v.slug = 'cafe-theatre-les-3t')
    OR (scraped_events.source = 'theatre_du_pave' AND v.slug = 'theatre-du-pave')
    OR (scraped_events.source = 'fil_a_plomb' AND v.slug = 'theatre-le-fil-a-plomb')
    OR (scraped_events.source = 'theatre_violette' AND v.slug = 'theatre-de-la-violette')
    OR (scraped_events.source = 'theatre_de_poche' AND v.slug = 'theatre-de-poche')
    OR (scraped_events.source = 'theatre_chien_blanc' AND v.slug = 'theatre-du-chien-blanc')
    OR (scraped_events.source = 'theatre_jules_julien' AND v.slug = 'nouveau-theatre-jules-julien')
    OR (scraped_events.source = 'le57' AND v.slug = 'cafe-theatre-le-57')
  );

-- Fallback generique pour ceux qui restent encore sans photo
UPDATE scraped_events
SET photo_url = 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/venues/venues_upload/pochette_spectacle.png'
WHERE rubrique = 'culture'
  AND (photo_url = '' OR photo_url IS NULL)
  AND source NOT IN ('museum_toulouse', 'guided_tours', 'meett', 'balma_events');
