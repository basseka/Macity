-- Seed: 7 restaurants fruits de mer a Toulouse (rubrique food, theme Fruits de mer)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Perlostrea',
    'food', 'Experiences uniques',
    '1 Rue de Bayard, 31000 Toulouse', 'Toulouse',
    '05 61 62 43 46',
    'Lun-Dim 10h30-19h30',
    'https://www.restaurant-perlostrea.fr',
    'https://maps.google.com/?q=Perlostrea+1+Rue+de+Bayard+Toulouse',
    '', 43.6115, 1.4545,
    'Fruits de mer', 'Matabiau', 'Gastronomique'
  ),
  (
    'Osmoz',
    'food', 'Creativite culinaire',
    '26 Boulevard Pierre-Paul Riquet, 31000 Toulouse', 'Toulouse',
    '05 62 18 08 01',
    'Mar-Sam 10h-01h',
    'https://www.osmoz-restaurant.fr',
    'https://maps.google.com/?q=Osmoz+26+Boulevard+Pierre+Paul+Riquet+Toulouse',
    '', 43.6100, 1.4530,
    'Fruits de mer', 'Matabiau', 'Moderne'
  ),
  (
    'L''Atelier du Pecheur',
    'food', 'Creativite culinaire',
    '6 Place Laganne, 31300 Toulouse', 'Toulouse',
    '06 49 31 08 88',
    'Mar-Sam 12h-14h / 18h-22h30',
    'https://atelier-du-pecheur.fr',
    'https://maps.google.com/?q=Atelier+du+Pecheur+6+Place+Laganne+Toulouse',
    '', 43.5990, 1.4345,
    'Fruits de mer', 'Saint-Cyprien', 'Moderne'
  ),
  (
    'Tantina de la Playa',
    'food', 'Ambiances insolites / thematiques',
    '59 Avenue de Saint-Exupery, 31400 Toulouse', 'Toulouse',
    '05 61 54 59 59',
    'Lun-Ven midi et soir',
    'https://tantinadelaplaya.com',
    'https://maps.google.com/?q=Tantina+de+la+Playa+59+Avenue+Saint+Exupery+Toulouse',
    '', 43.5830, 1.4720,
    'Fruits de mer', 'Rangueil', 'Convivial'
  ),
  (
    'Le Cabanon',
    'food', 'Ambiances insolites / thematiques',
    '6 Rue Victor Hugo, 31000 Toulouse', 'Toulouse',
    '05 61 23 64 71',
    'Lun 18h-00h / Mar-Ven 11h-14h30, 18h-00h / Sam 11h-00h / Dim 11h-18h',
    'https://le-cabanon-toulouse.fr',
    'https://maps.google.com/?q=Le+Cabanon+6+Rue+Victor+Hugo+Toulouse',
    '', 43.6035, 1.4470,
    'Fruits de mer', 'Capitole', 'Festif'
  ),
  (
    'La Cabane',
    'food', 'Experiences uniques',
    '258 Avenue Jean Chaubet, 31400 Toulouse', 'Toulouse',
    '06 22 28 26 62',
    'Lun-Dim 11h-14h30 / 18h30-23h',
    'http://toulousefruitsdemer.fr',
    'https://maps.google.com/?q=La+Cabane+258+Avenue+Jean+Chaubet+Toulouse',
    '', 43.6100, 1.4750,
    'Fruits de mer', 'Minimes', 'Decontracte'
  ),
  (
    'Boniface Coquillages',
    'food', 'Concepts originaux a proximite',
    '10 Place de la Charte des Libertes Communales, 31100 Toulouse', 'Toulouse',
    '05 67 22 32 41',
    'Mar-Dim 10h-20h',
    'https://www.boniface-coquillages.com',
    'https://maps.google.com/?q=Boniface+Coquillages+Cartoucherie+Toulouse',
    '', 43.5960, 1.4130,
    'Fruits de mer', 'Saint-Cyprien', 'Authentique'
  );
