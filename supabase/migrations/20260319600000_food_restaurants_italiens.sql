-- Seed: 6 restaurants italiens a Toulouse (rubrique food, theme Italien)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Mantesino',
    'food', 'Creativite culinaire',
    '8 Rue Maury, 31000 Toulouse', 'Toulouse',
    '05 31 54 13 29',
    'Mar-Ven 12h-14h / Mer-Ven 19h30-22h',
    'http://mantesino.fr',
    'https://maps.google.com/?q=Mantesino+8+Rue+Maury+Toulouse',
    '', 43.6045, 1.4445,
    'Italien', 'Capitole', 'Gastronomique'
  ),
  (
    'Prima Lova',
    'food', 'Experiences uniques',
    '1 Place de la Bourse, 31000 Toulouse', 'Toulouse',
    '05 67 68 77 19',
    'Lun-Dim 12h-15h / 19h-23h',
    'http://lova.primafamily.fr',
    'https://maps.google.com/?q=Prima+Lova+1+Place+de+la+Bourse+Toulouse',
    '', 43.6030, 1.4440,
    'Italien', 'Esquirol', 'Romantique'
  ),
  (
    'FOCA FOCA',
    'food', 'Concepts originaux a proximite',
    '7 Rue Temponieres, 31000 Toulouse', 'Toulouse',
    '05 61 83 71 07',
    'Lun-Sam 12h-14h30, 19h-22h30 / Dim 19h-22h30',
    'https://focafoca.fr/fr',
    'https://maps.google.com/?q=Foca+Foca+7+Rue+Temponieres+Toulouse',
    '', 43.6010, 1.4425,
    'Italien', 'Esquirol', 'Street food'
  ),
  (
    'Lo Stivale',
    'food', 'Experiences uniques',
    '10 Rue des Moulins, 31000 Toulouse', 'Toulouse',
    '05 62 26 28 19',
    'Mar-Sam 12h-13h30, 19h30-21h30',
    'https://restaurantlostivale.com',
    'https://maps.google.com/?q=Lo+Stivale+10+Rue+des+Moulins+Toulouse',
    '', 43.5995, 1.4445,
    'Italien', 'Carmes', 'Traditionnel'
  ),
  (
    'Chez Giovanni',
    'food', 'Ambiances insolites / thematiques',
    '2 Chemin de Gabardie, 31200 Toulouse', 'Toulouse',
    '05 61 26 18 67',
    'Lun-Dim 12h-14h30 / 19h30-22h30',
    'https://chezgiovanni.fr',
    'https://maps.google.com/?q=Chez+Giovanni+2+Chemin+de+Gabardie+Toulouse',
    '', 43.6260, 1.4780,
    'Italien', 'Balma', 'Familial'
  ),
  (
    'Volfoni Toulouse',
    'food', 'Ambiances insolites / thematiques',
    '15 Place du President Thomas Wilson, 31000 Toulouse', 'Toulouse',
    '05 62 27 93 20',
    'Lun-Dim 8h30-23h',
    'https://www.volfoni.fr/nos-restaurants/volfoni-toulouse',
    'https://maps.google.com/?q=Volfoni+15+Place+President+Thomas+Wilson+Toulouse',
    '', 43.6085, 1.4505,
    'Italien', 'Capitole', 'Chic'
  );
