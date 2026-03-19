-- Seed: 7 restaurants vegetariens a Toulouse (rubrique food, theme Vegetarien)

INSERT INTO public.etablissements
  (nom, rubrique, categorie, adresse, ville, telephone, horaires, site_web, lien_maps, photo, latitude, longitude, theme, quartier, style)
VALUES
  (
    'La Faim des Haricots',
    'food', 'Experiences uniques',
    '3 Rue du Puits Vert, 31000 Toulouse', 'Toulouse',
    '05 61 22 49 25',
    'Lun-Dim 12h-21h30 (service continu)',
    'https://lafaimdesharicots.fr',
    'https://maps.google.com/?q=La+Faim+des+Haricots+3+Rue+Puits+Vert+Toulouse',
    '', 43.6030, 1.4445,
    'Vegetarien', 'Capitole', 'Decontracte'
  ),
  (
    'La Sauterelle',
    'food', 'Creativite culinaire',
    '3 Rue Tripiere, 31000 Toulouse', 'Toulouse',
    '09 83 65 18 21',
    'Lun-Sam 12h-14h / 19h-21h30',
    'https://la-sauterelle-restaurant-toulouse.fr',
    'https://maps.google.com/?q=La+Sauterelle+3+Rue+Tripiere+Toulouse',
    '', 43.6005, 1.4425,
    'Vegetarien', 'Esquirol', 'Authentique'
  ),
  (
    'Sixta',
    'food', 'Ambiances insolites / thematiques',
    '28 Rue Bayard, 31000 Toulouse', 'Toulouse',
    '09 54 52 92 67',
    'Mar-Ven 12h-18h30 / Sam 12h-18h30 (brunch)',
    'https://sixta-toulouse.fr',
    'https://maps.google.com/?q=Sixta+28+Rue+Bayard+Toulouse',
    '', 43.6110, 1.4545,
    'Vegetarien', 'Matabiau', 'Cosy'
  ),
  (
    'Bep Chay',
    'food', 'Creativite culinaire',
    '22 Rue des Couteliers, 31000 Toulouse', 'Toulouse',
    '05 61 32 02 72',
    'Mar-Sam midi et soir (soir: 19h et 21h)',
    'https://bep-chay.com',
    'https://maps.google.com/?q=Bep+Chay+22+Rue+des+Couteliers+Toulouse',
    '', 43.5995, 1.4440,
    'Vegetarien', 'Esquirol', 'Moderne'
  ),
  (
    'Peacock',
    'food', 'Concepts originaux a proximite',
    '20 Rue de la Bourse, 31000 Toulouse', 'Toulouse',
    '09 88 32 93 89',
    'Mar-Ven 9h-18h / Sam 9h-19h / Dim 9h-18h / Lun ferme',
    'https://peacock-toulouse.com',
    'https://maps.google.com/?q=Peacock+20+Rue+de+la+Bourse+Toulouse',
    '', 43.6030, 1.4440,
    'Vegetarien', 'Esquirol', 'Branche'
  ),
  (
    'Cafe Brule',
    'food', 'Concepts originaux a proximite',
    '12 Rue Alexandre Fourtanier, 31000 Toulouse', 'Toulouse',
    '09 88 44 78 94',
    'Mer-Ven 9h-18h / Sam 10h30-18h / Dim 10h30-15h',
    'https://cafebrule.fr',
    'https://maps.google.com/?q=Cafe+Brule+12+Rue+Alexandre+Fourtanier+Toulouse',
    '', 43.5990, 1.4430,
    'Vegetarien', 'Carmes', 'Cosy'
  ),
  (
    'Manger Autrement chez Prasad',
    'food', 'Experiences uniques',
    '155 Grande Rue Saint-Michel, 31400 Toulouse', 'Toulouse',
    '05 61 32 68 41',
    'Mar-Sam 12h-14h / 19h30-22h',
    'https://manger-autrement.com',
    'https://maps.google.com/?q=Manger+Autrement+Prasad+155+Grande+Rue+Saint+Michel+Toulouse',
    '', 43.5870, 1.4490,
    'Vegetarien', 'Saint-Michel', 'Authentique'
  );
