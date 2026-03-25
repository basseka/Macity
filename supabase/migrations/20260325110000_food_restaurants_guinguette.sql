-- Seed: 8 restaurants Guinguette à Toulouse et alentours

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'La Centrale',
    'food', 'Experiences uniques',
    '1 Place de la Daurade, 31000 Toulouse', 'Toulouse',
    '',
    '',
    'https://www.lacentralerestaurant.fr/',
    'https://maps.google.com/?q=La+Centrale+Restaurant+Toulouse',
    '', 43.6035, 1.4385,
    'Guinguette', 'Capitole', 'Festif'
  ),
  (
    'La Friche Montaudran',
    'food', 'Ambiances insolites / thematiques',
    '6 Rue Louis Breguet, 31400 Toulouse', 'Toulouse',
    '',
    '',
    'https://www.lafrichegourmandetoulouse.com/',
    'https://maps.google.com/?q=La+Friche+Montaudran+Toulouse',
    '', 43.5720, 1.4820,
    'Guinguette', 'Rangueil', 'Decontracte'
  ),
  (
    'Papí Guinguette Toulouse',
    'food', 'Experiences uniques',
    'Port de la Daurade, 31000 Toulouse', 'Toulouse',
    '',
    '',
    'https://papiguinguette.fr/',
    'https://maps.google.com/?q=Papi+Guinguette+Toulouse',
    '', 43.6030, 1.4370,
    'Guinguette', 'Capitole', 'Festif'
  ),
  (
    'Racines Food',
    'food', 'Creativite culinaire',
    'Île du Ramier, 31400 Toulouse', 'Toulouse',
    '',
    '',
    'https://racines-guinguette.fr/',
    'https://maps.google.com/?q=Racines+Food+Guinguette+Toulouse',
    '', 43.5860, 1.4380,
    'Guinguette', 'Empalot', 'Convivial'
  ),
  (
    'La Guinguette De L''Observatoire',
    'food', 'Ambiances insolites / thematiques',
    '1 Avenue Camille Flammarion, 31500 Toulouse', 'Toulouse',
    '',
    '',
    'https://laguinguettedelobservatoire.com/',
    'https://maps.google.com/?q=La+Guinguette+de+l+Observatoire+Toulouse',
    '', 43.5880, 1.4640,
    'Guinguette', 'Rangueil', 'Nature / vegetal'
  ),
  (
    'MinOu La Guinguette du Grand Marché',
    'food', 'Ambiances insolites / thematiques',
    'Grand Marché MIN, 31200 Toulouse', 'Toulouse',
    '',
    '',
    'https://www.lgm-mintoulouse.com/restaurants/guinguette-min-ou/',
    'https://maps.google.com/?q=MinOu+Guinguette+Grand+Marche+Toulouse',
    '', 43.5750, 1.3980,
    'Guinguette', 'Empalot', 'Decontracte'
  ),
  (
    'Guinguette La Petite Touch',
    'food', 'Concepts originaux a proximite',
    'Lac de Plaisance-du-Touch, 31830 Plaisance-du-Touch', 'Plaisance-du-Touch',
    '',
    '',
    'https://lapetitetouch.fr/',
    'https://maps.google.com/?q=Guinguette+La+Petite+Touch+Plaisance+du+Touch',
    '', 43.5660, 1.2970,
    'Guinguette', 'Plaisance-du-Touch', 'Nature / vegetal'
  ),
  (
    'La Pistoche Toulouse',
    'food', 'Concepts originaux a proximite',
    '2 Chemin de Pinot, 31700 Blagnac', 'Blagnac',
    '',
    '',
    'https://www.lapistoche-toulouse.fr/',
    'https://maps.google.com/?q=La+Pistoche+Toulouse+Blagnac',
    '', 43.6370, 1.3780,
    'Guinguette', 'Blagnac', 'Festif'
  );
