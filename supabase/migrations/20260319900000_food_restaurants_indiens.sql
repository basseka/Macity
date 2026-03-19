-- Seed: 10 restaurants indiens a Toulouse (rubrique food, theme Indien)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Bhaiya Kitchen',
    'food', 'Concepts originaux a proximite',
    '29 Rue du Taur, 31000 Toulouse', 'Toulouse',
    '',
    'Lun-Sam 11h30-15h / 18h30-22h',
    'https://www.bhaiyakitchen.com',
    'https://maps.google.com/?q=Bhaiya+Kitchen+29+Rue+du+Taur+Toulouse',
    '', 43.6060, 1.4440,
    'Indien', 'Capitole', 'Street food'
  ),
  (
    'Joshore Road',
    'food', 'Creativite culinaire',
    '10 Rue Maletache, 31000 Toulouse', 'Toulouse',
    '09 75 31 60 69',
    'Lun-Dim 12h-14h30 / 19h-22h30',
    'https://restaurant-joshore-road.fr',
    'https://maps.google.com/?q=Joshore+Road+10+Rue+Maletache+Toulouse',
    '', 43.5995, 1.4450,
    'Indien', 'Carmes', 'Gastronomique'
  ),
  (
    'Le Maharaja',
    'food', 'Experiences uniques',
    '46 Rue Peyrolieres, 31000 Toulouse', 'Toulouse',
    '05 34 30 50 12',
    'Lun-Dim 12h-14h, 18h30-23h30 / Sam midi ferme',
    'https://maharajatoulouse.fr',
    'https://maps.google.com/?q=Le+Maharaja+46+Rue+Peyrolieres+Toulouse',
    '', 43.6005, 1.4390,
    'Indien', 'Esquirol', 'Traditionnel'
  ),
  (
    'Masala Palace',
    'food', 'Experiences uniques',
    '7 Rue des Gestes, 31000 Toulouse', 'Toulouse',
    '05 32 60 57 33',
    'Lun-Dim 12h-14h30 / 19h-22h30',
    'https://masalapalace.fr',
    'https://maps.google.com/?q=Masala+Palace+7+Rue+des+Gestes+Toulouse',
    '', 43.6040, 1.4420,
    'Indien', 'Capitole', 'Convivial'
  ),
  (
    'Curry Cafe',
    'food', 'Ambiances insolites / thematiques',
    '22 Rue Saint-Rome, 31000 Toulouse', 'Toulouse',
    '05 61 23 77 34',
    'Lun-Sam 11h30-22h30',
    'https://currycafetoulouse.com',
    'https://maps.google.com/?q=Curry+Cafe+22+Rue+Saint-Rome+Toulouse',
    '', 43.6025, 1.4445,
    'Indien', 'Capitole', 'Chic'
  ),
  (
    'New Delhi',
    'food', 'Experiences uniques',
    '9 Rue de l''Industrie, 31000 Toulouse', 'Toulouse',
    '05 61 62 20 64',
    'Lun-Dim 12h-14h / 19h-22h',
    'https://newdelhi-toulouse.com',
    'https://maps.google.com/?q=New+Delhi+9+Rue+Industrie+Toulouse',
    '', 43.6100, 1.4540,
    'Indien', 'Matabiau', 'Authentique'
  ),
  (
    'New Delhi Palace',
    'food', 'Ambiances insolites / thematiques',
    '42 Boulevard Lazare Carnot, 31000 Toulouse', 'Toulouse',
    '05 62 80 95 29',
    'Lun-Mar 12h-23h / Mer 12h-00h / Jeu-Ven 12h-02h / Sam 12h-03h / Dim 12h-00h',
    'https://newdelhi-palace.fr',
    'https://maps.google.com/?q=New+Delhi+Palace+42+Boulevard+Lazare+Carnot+Toulouse',
    '', 43.6070, 1.4560,
    'Indien', 'Francois-Verdier', 'Lounge'
  ),
  (
    'New Goa',
    'food', 'Experiences uniques',
    '43 Rue de l''Industrie, 31000 Toulouse', 'Toulouse',
    '05 61 62 87 70',
    'Lun-Dim 12h-15h / 18h45-23h45',
    'https://restaurantindientoulouse.fr',
    'https://maps.google.com/?q=New+Goa+43+Rue+Industrie+Toulouse',
    '', 43.6095, 1.4545,
    'Indien', 'Matabiau', 'Moderne'
  ),
  (
    'Le Namaste',
    'food', 'Experiences uniques',
    '11 Rue de la Colombette, 31000 Toulouse', 'Toulouse',
    '05 61 45 46 21',
    'Lun-Dim 12h-14h / 19h-23h / Ven soir uniquement',
    'https://restaurantindientoulouse.com',
    'https://maps.google.com/?q=Le+Namaste+11+Rue+Colombette+Toulouse',
    '', 43.6065, 1.4555,
    'Indien', 'Francois-Verdier', 'Traditionnel'
  ),
  (
    'La Rajasthani',
    'food', 'Experiences uniques',
    '8 Rue des Gestes, 31000 Toulouse', 'Toulouse',
    '05 62 27 08 91',
    'Lun-Sam 12h-14h / 19h-22h',
    'https://larajasthani.fr',
    'https://maps.google.com/?q=La+Rajasthani+8+Rue+des+Gestes+Toulouse',
    '', 43.6038, 1.4418,
    'Indien', 'Capitole', 'Familial'
  );
