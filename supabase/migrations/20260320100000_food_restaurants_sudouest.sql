-- Seed: 8 restaurants Sud-Ouest a Toulouse (rubrique food, theme Sud-Ouest)
-- Note: Bistroquet Toulouse deja present en theme Mediterraneen, on ne le duplique pas.

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'Aux Pieds sous la Table',
    'food', 'Experiences uniques',
    '4-6-8 Rue Arnaud Bernard, 31000 Toulouse', 'Toulouse',
    '05 67 11 01 72',
    'Lun-Ven 12h-14h / Lun-Sam 19h15-22h',
    'https://auxpiedssouslatable.fr',
    'https://maps.google.com/?q=Aux+Pieds+sous+la+Table+Rue+Arnaud+Bernard+Toulouse',
    '', 43.6095, 1.4410,
    'Sud-Ouest', 'Compans-Caffarelli', 'Bistronomique'
  ),
  (
    'La Cuisine a Meme',
    'food', 'Ambiances insolites / thematiques',
    '17 Rue des Couteliers, 31000 Toulouse', 'Toulouse',
    '06 25 13 85 92',
    'Lun-Dim 18h30-23h / Sam-Dim 12h-16h aussi',
    'http://www.lacuisineameme.fr',
    'https://maps.google.com/?q=La+Cuisine+a+Meme+17+Rue+des+Couteliers+Toulouse',
    '', 43.5995, 1.4440,
    'Sud-Ouest', 'Esquirol', 'Familial'
  ),
  (
    'L''Os a Moelle',
    'food', 'Experiences uniques',
    '14 Rue Roquelaine, 31000 Toulouse', 'Toulouse',
    '05 61 63 19 30',
    'Lun 19h-22h30 / Mar-Jeu 12h-13h30, 19h-22h30',
    'https://www.losamoelletoulouse.com',
    'https://maps.google.com/?q=Os+a+Moelle+14+Rue+Roquelaine+Toulouse',
    '', 43.6115, 1.4530,
    'Sud-Ouest', 'Matabiau', 'Convivial'
  ),
  (
    'Le Cantou',
    'food', 'Creativite culinaire',
    '98 Rue de Velasquez, 31300 Toulouse', 'Toulouse',
    '05 61 49 20 21',
    'Mar-Sam 12h-14h / 19h30-22h',
    'http://www.cantou.fr',
    'https://maps.google.com/?q=Le+Cantou+98+Rue+Velasquez+Toulouse',
    '', 43.5920, 1.3980,
    'Sud-Ouest', 'Lardenne', 'Gastronomique'
  ),
  (
    'La Cuisine de Jean',
    'food', 'Concepts originaux a proximite',
    '18 Avenue Albert Bedouce, 31400 Toulouse', 'Toulouse',
    '05 61 25 90 76',
    'Mar-Sam midi / Mer-Sam soir',
    'http://lacuisinedejean.fr',
    'https://maps.google.com/?q=La+Cuisine+de+Jean+18+Avenue+Albert+Bedouce+Toulouse',
    '', 43.5780, 1.4580,
    'Sud-Ouest', 'Rangueil', 'Decontracte'
  ),
  (
    'Au Pois Gourmand',
    'food', 'Creativite culinaire',
    '3 Rue Emile Heybrard, 31300 Toulouse', 'Toulouse',
    '05 34 36 42 00',
    'Lun-Ven 12h-16h / Lun-Sam 19h-00h',
    'http://pois-gourmand.fr',
    'https://maps.google.com/?q=Au+Pois+Gourmand+3+Rue+Emile+Heybrard+Toulouse',
    '', 43.5985, 1.4310,
    'Sud-Ouest', 'Saint-Cyprien', 'Gastronomique'
  ),
  (
    'Le Saint Sauvage',
    'food', 'Creativite culinaire',
    '20 Rue des Salenques, 31000 Toulouse', 'Toulouse',
    '05 61 23 56 86',
    'Mar-Ven midi / Sam soir',
    'https://lesaintsauvage.eatbu.com',
    'https://maps.google.com/?q=Le+Saint+Sauvage+20+Rue+des+Salenques+Toulouse',
    '', 43.6095, 1.4460,
    'Sud-Ouest', 'Compans-Caffarelli', 'Bistronomique'
  ),
  (
    'L''Ecorce',
    'food', 'Creativite culinaire',
    '8 Rue de l''Esquile, 31000 Toulouse', 'Toulouse',
    '05 34 30 47 99',
    'Mar-Sam 12h-13h30, 19h15-20h45 / Mer midi ferme',
    'https://www.lecorce.com',
    'https://maps.google.com/?q=Ecorce+8+Rue+Esquile+Toulouse',
    '', 43.6055, 1.4430,
    'Sud-Ouest', 'Capitole', 'Gastronomique'
  );
