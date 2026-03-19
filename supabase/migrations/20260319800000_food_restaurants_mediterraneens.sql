-- Seed: 5 restaurants mediterraneens a Toulouse (rubrique food, theme Mediterraneen)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Bistroquet Toulouse',
    'food', 'Experiences uniques',
    '10 Rue Labeda, 31000 Toulouse', 'Toulouse',
    '06 73 45 61 01',
    'Lun-Dim 12h-22h30 (service continu)',
    'https://www.bistroquettoulouse.com',
    'https://maps.google.com/?q=Bistroquet+10+Rue+Labeda+Toulouse',
    '', 43.6080, 1.4500,
    'Mediterraneen', 'Capitole', 'Convivial'
  ),
  (
    'ALBA',
    'food', 'Creativite culinaire',
    '3 Rue Perchepinte, 31000 Toulouse', 'Toulouse',
    '05 34 62 57 51',
    'Mar-Sam 12h-14h / 19h30-22h',
    'https://albatoulouse.fr',
    'https://maps.google.com/?q=Alba+3+Rue+Perchepinte+Toulouse',
    '', 43.5990, 1.4458,
    'Mediterraneen', 'Carmes', 'Chic'
  ),
  (
    'Chez TETA',
    'food', 'Experiences uniques',
    '41 Rue des 7 Troubadours, 31000 Toulouse', 'Toulouse',
    '',
    'Lun-Sam 12h-14h / 18h30-21h30',
    'https://www.chezteta.fr',
    'https://maps.google.com/?q=Chez+Teta+41+Rue+des+7+Troubadours+Toulouse',
    '', 43.6085, 1.4530,
    'Mediterraneen', 'Matabiau', 'Authentique'
  ),
  (
    'Le Semiramis',
    'food', 'Experiences uniques',
    '23 Rue Peyrolieres, 31000 Toulouse', 'Toulouse',
    '05 61 23 66 11',
    'Mar-Sam 12h-14h30, 18h30-22h30 / Dim 12h-14h30 / Lun ferme',
    'https://restaurant-semiramis.com',
    'https://maps.google.com/?q=Le+Semiramis+23+Rue+Peyrolieres+Toulouse',
    '', 43.6010, 1.4395,
    'Mediterraneen', 'Esquirol', 'Traditionnel'
  ),
  (
    'O''tzatziki',
    'food', 'Concepts originaux a proximite',
    '68 Rue Pargaminieres, 31000 Toulouse', 'Toulouse',
    '09 87 15 71 04',
    'Lun 11h30-15h, 18h30-22h / Mar ferme / Mer-Jeu 11h30-15h, 18h30-22h / Ven-Sam 11h30-22h30 / Dim 11h30-22h',
    'https://otzatziki.fr',
    'https://maps.google.com/?q=Otzatziki+68+Rue+Pargaminieres+Toulouse',
    '', 43.6045, 1.4370,
    'Mediterraneen', 'Saint-Cyprien', 'Decontracte'
  );
