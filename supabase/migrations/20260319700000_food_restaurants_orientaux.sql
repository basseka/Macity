-- Seed: 5 restaurants orientaux a Toulouse (rubrique food, theme Orientale)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Le Ksar',
    'food', 'Experiences uniques',
    '7 Rue Perchepinte, 31000 Toulouse', 'Toulouse',
    '05 61 53 72 20',
    'Mar-Jeu 12h-14h, 19h30-22h / Ven-Sam 12h-14h, 19h30-23h',
    '',
    'https://maps.google.com/?q=Le+Ksar+7+Rue+Perchepinte+Toulouse',
    '', 43.5990, 1.4460,
    'Orientale', 'Carmes', 'Chic'
  ),
  (
    'Le Marrakech',
    'food', 'Ambiances insolites / thematiques',
    '19 Rue Castellane, 31000 Toulouse', 'Toulouse',
    '05 61 23 82 52',
    'Lun-Jeu 12h-14h30, 19h-22h30 / Ven-Sam 12h-14h30, 19h-23h / Dim 12h-14h30, 19h-22h',
    'https://marrakech-restaurant.fr',
    'https://maps.google.com/?q=Le+Marrakech+19+Rue+Castellane+Toulouse',
    '', 43.6055, 1.4490,
    'Orientale', 'Capitole', 'Authentique'
  ),
  (
    'Le Marocain',
    'food', 'Experiences uniques',
    '47 Rue des Couteliers, 31000 Toulouse', 'Toulouse',
    '05 61 53 28 01',
    'Mar 19h30-22h / Mer-Ven 12h-14h, 19h30-22h / Sam 12h-14h, 19h30-22h30',
    'https://le-marocain.fr',
    'https://maps.google.com/?q=Le+Marocain+47+Rue+des+Couteliers+Toulouse',
    '', 43.5995, 1.4445,
    'Orientale', 'Esquirol', 'Traditionnel'
  ),
  (
    'La Kasbah',
    'food', 'Ambiances insolites / thematiques',
    '30 Rue de la Chaine, 31000 Toulouse', 'Toulouse',
    '05 61 23 55 06',
    'Lun-Mar 12h-14h30, 20h-00h30 / Mer ferme / Jeu-Dim 12h-14h30, 20h-00h30',
    'https://www.lakasbah.fr',
    'https://maps.google.com/?q=La+Kasbah+30+Rue+de+la+Chaine+Toulouse',
    '', 43.6080, 1.4410,
    'Orientale', 'Compans-Caffarelli', 'Festif'
  ),
  (
    'Le Safran',
    'food', 'Concepts originaux a proximite',
    '8 Rue de la Bourse, 31000 Toulouse', 'Toulouse',
    '05 62 27 14 10',
    'Lun-Sam 12h-19h / Dim ferme',
    'https://restaurantlesafran.wixsite.com/website',
    'https://maps.google.com/?q=Le+Safran+8+Rue+de+la+Bourse+Toulouse',
    '', 43.6030, 1.4445,
    'Orientale', 'Esquirol', 'Cosy'
  );
