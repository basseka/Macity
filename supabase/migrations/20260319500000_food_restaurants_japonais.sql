-- Seed: 5 restaurants japonais a Toulouse (rubrique food, theme Japonais)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'IORI',
    'food', 'Experiences uniques',
    '20 Rue des Paradoux, 31000 Toulouse', 'Toulouse',
    '05 61 28 02 47',
    'Mar-Mer 19h30-00h / Jeu-Ven 12h-14h, 19h30-00h / Sam 19h30-00h',
    'https://www.iori.fr',
    'https://maps.google.com/?q=IORI+20+Rue+des+Paradoux+Toulouse',
    '', 43.5998, 1.4420,
    'Japonais', 'Esquirol', 'Authentique'
  ),
  (
    'Ni''shimai',
    'food', 'Concepts originaux a proximite',
    '2 Rue Joseph Lakanal, 31000 Toulouse', 'Toulouse',
    '05 34 44 70 23',
    'Mar-Jeu 11h30-14h, 19h-21h / Ven 11h30-14h, 19h-21h30 / Sam 11h30-14h30, 19h-21h30',
    'https://natachanishimai.wixsite.com/monsite',
    'https://maps.google.com/?q=Nishimai+2+Rue+Joseph+Lakanal+Toulouse',
    '', 43.6040, 1.4430,
    'Japonais', 'Capitole', 'Decontracte'
  ),
  (
    'KIYOSHI',
    'food', 'Creativite culinaire',
    '10 Rue Palaprat, 31000 Toulouse', 'Toulouse',
    '',
    'Sur reservation uniquement',
    'https://www.kiyoshi.fr',
    'https://maps.google.com/?q=Kiyoshi+10+Rue+Palaprat+Toulouse',
    '', 43.6110, 1.4545,
    'Japonais', 'Matabiau', 'Gastronomique'
  ),
  (
    'Mayumi',
    'food', 'Experiences uniques',
    '57 Rue de la Republique, 31300 Toulouse', 'Toulouse',
    '05 61 31 58 81',
    'Mar-Dim 12h-14h30 / 19h-22h30',
    'https://mayumi-toulouse.com',
    'https://maps.google.com/?q=Mayumi+57+Rue+de+la+Republique+Toulouse',
    '', 43.6055, 1.4415,
    'Japonais', 'Saint-Cyprien', 'Convivial'
  ),
  (
    'Zen-Sai',
    'food', 'Experiences uniques',
    '2 Rue Jean Suau, 31000 Toulouse', 'Toulouse',
    '05 61 12 00 00',
    'Lun-Jeu 11h45-17h30, 18h45-22h / Ven-Sam 12h-17h30, 19h-22h30 / Dim 12h-17h30, 19h-21h30',
    'http://www.zen-sai.com',
    'https://maps.google.com/?q=Zen+Sai+2+Rue+Jean+Suau+Toulouse',
    '', 43.6105, 1.4550,
    'Japonais', 'Matabiau', 'Moderne'
  );
