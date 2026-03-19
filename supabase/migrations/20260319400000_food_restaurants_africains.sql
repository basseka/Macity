-- Seed: 10 restaurants africains a Toulouse (rubrique food, theme Africain)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Escale des Saveurs',
    'food', 'Experiences uniques',
    '30 Rue Bertrand de Born, 31000 Toulouse', 'Toulouse',
    '07 63 00 31 31',
    'Mar-Sam 12h-14h30 / 19h-22h30',
    'https://escale-des-saveurs-fj4g.vercel.app',
    'https://maps.google.com/?q=Escale+des+Saveurs+30+Rue+Bertrand+de+Born+Toulouse',
    '', 43.6115, 1.4540,
    'Africain', 'Matabiau', 'Authentique'
  ),
  (
    'Le MAMI-WATA',
    'food', 'Ambiances insolites / thematiques',
    '25 Rue Heliot, 31000 Toulouse', 'Toulouse',
    '05 61 62 77 04',
    'Lun-Jeu 19h-00h / Ven-Sam 19h-01h / Dim ferme',
    'https://www.mami-wata.com',
    'https://maps.google.com/?q=Mami+Wata+25+Rue+Heliot+Toulouse',
    '', 43.6118, 1.4530,
    'Africain', 'Matabiau', 'Festif'
  ),
  (
    'Yassa Bar',
    'food', 'Experiences uniques',
    '2 bis Rue du Mai, 31000 Toulouse', 'Toulouse',
    '06 62 21 66 64',
    'Mar-Ven 12h-14h / 19h-23h / Sam 19h-23h',
    'https://yassa-bar.fr',
    'https://maps.google.com/?q=Yassa+Bar+2+bis+Rue+du+Mai+Toulouse',
    '', 43.6042, 1.4438,
    'Africain', 'Capitole', 'Convivial'
  ),
  (
    'Abyssinia',
    'food', 'Experiences uniques',
    '44 Rue des 7 Troubadours, 31000 Toulouse', 'Toulouse',
    '09 54 49 32 38',
    'Mar-Dim 12h-14h30 / 19h-23h',
    'https://abyssinia-toulouse.fr',
    'https://maps.google.com/?q=Abyssinia+44+Rue+des+7+Troubadours+Toulouse',
    '', 43.6083, 1.4530,
    'Africain', 'Matabiau', 'Authentique'
  ),
  (
    'Restaurant Le Mayombe',
    'food', 'Ambiances insolites / thematiques',
    '26 Rue de la Republique, 31300 Toulouse', 'Toulouse',
    '05 61 59 50 50',
    'Lun-Sam 19h-02h / Dim ferme',
    'https://mayombe.eatbu.com',
    'https://maps.google.com/?q=Le+Mayombe+26+Rue+Republique+Toulouse',
    '', 43.6060, 1.4420,
    'Africain', 'Capitole', 'Festif'
  ),
  (
    'LE QG - L''Afrique a Table',
    'food', 'Creativite culinaire',
    '58 Rue Louis Plana, 31500 Toulouse', 'Toulouse',
    '09 56 82 77 09',
    'Dim-Jeu 19h-22h30 / Ven-Sam 19h-23h30',
    'https://restaurantleqg.fr',
    'https://maps.google.com/?q=Le+QG+Afrique+a+Table+58+Rue+Louis+Plana+Toulouse',
    '', 43.6175, 1.4720,
    'Africain', 'Minimes', 'Bistronomique'
  ),
  (
    'Chez Lena',
    'food', 'Concepts originaux a proximite',
    '10 Avenue Octave Lery, 31000 Toulouse', 'Toulouse',
    '05 61 00 00 00',
    'Lun-Sam 10h-21h',
    'https://chezlena.fr',
    'https://maps.google.com/?q=Chez+Lena+10+Avenue+Octave+Lery+Toulouse',
    '', 43.5950, 1.4580,
    'Africain', 'Empalot', 'Familial'
  ),
  (
    'Woezon Restaurant',
    'food', 'Experiences uniques',
    '38 Avenue Leon Blum, 31500 Toulouse', 'Toulouse',
    '06 45 81 35 58',
    'Dim-Jeu 12h-23h / Ven-Sam 12h-00h',
    'https://woezon-restaurant.fr',
    'https://maps.google.com/?q=Woezon+Restaurant+38+Avenue+Leon+Blum+Toulouse',
    '', 43.6170, 1.4700,
    'Africain', 'Minimes', 'Convivial'
  ),
  (
    'Le Dakar Restaurant',
    'food', 'Experiences uniques',
    '65 Rue Matabiau, 31000 Toulouse', 'Toulouse',
    '05 67 16 67 27',
    'Mar-Sam 12h-14h30 / 19h-23h',
    'https://ledakar-toulouse.fr',
    'https://maps.google.com/?q=Le+Dakar+Restaurant+65+Rue+Matabiau+Toulouse',
    '', 43.6125, 1.4555,
    'Africain', 'Matabiau', 'Authentique'
  ),
  (
    'Restaurant Chez Nicole',
    'food', 'Ambiances insolites / thematiques',
    '69 Grande Rue Saint-Michel, 31400 Toulouse', 'Toulouse',
    '07 85 74 67 99',
    'Mar-Sam 12h-14h30 / 19h-23h / Dim-Lun ferme',
    'https://www.chez-nicole.com',
    'https://maps.google.com/?q=Chez+Nicole+69+Grande+Rue+Saint-Michel+Toulouse',
    '', 43.5890, 1.4490,
    'Africain', 'Saint-Michel', 'Convivial'
  );
