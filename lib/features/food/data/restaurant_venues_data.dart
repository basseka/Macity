class RestaurantVenue {
  final String id;
  final String name;
  final String description;
  final String group;
  final String adresse;
  final String horaires;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;

  const RestaurantVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.group,
    required this.adresse,
    required this.horaires,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
  });
}

class RestaurantVenuesData {
  RestaurantVenuesData._();

  static const groupOrder = [
    'Experiences uniques',
    'Ambiances insolites / thematiques',
    'Creativite culinaire',
    'Concepts originaux a proximite',
  ];

  static const venues = <RestaurantVenue>[
    // ── Experiences uniques ──
    RestaurantVenue(
      id: 'in_the_dark',
      name: 'In The Dark',
      description: 'Restaurant ou l\'on dine dans le noir total, une experience sensorielle unique a Toulouse.',
      group: 'Experiences uniques',
      adresse: '27 Rue de la Garonnette, 31000 Toulouse',
      horaires: 'Mer-Sam 19h30-23h',
      telephone: '05 61 53 97 13',
      latitude: 43.5990,
      longitude: 1.4430,
      websiteUrl: 'https://www.inthedark.fr/',
      lienMaps: 'https://maps.google.com/?q=In+The+Dark+27+Rue+de+la+Garonnette+Toulouse',
    ),
    RestaurantVenue(
      id: 'cockpit',
      name: 'Cockpit',
      description: 'Restaurant theme aviation avec decor immersif de cockpit, ambiance originale pour diner.',
      group: 'Experiences uniques',
      adresse: '13 Boulevard de la Gare, 31500 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h-23h',
      telephone: '05 61 62 88 88',
      latitude: 43.6110,
      longitude: 1.4540,
      websiteUrl: 'https://www.cockpit-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Cockpit+Restaurant+Toulouse',
    ),
    RestaurantVenue(
      id: 'sixta',
      name: 'Sixta',
      description: 'Restaurant-spectacle avec diner et show live, experience immersive et festive.',
      group: 'Experiences uniques',
      adresse: '6 Rue Saint-Pantaleon, 31000 Toulouse',
      horaires: 'Jeu-Sam 20h-01h',
      telephone: '05 61 21 80 80',
      latitude: 43.6040,
      longitude: 1.4410,
      websiteUrl: 'https://www.sixta-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Sixta+6+Rue+Saint-Pantaleon+Toulouse',
    ),

    // ── Ambiances insolites / thematiques ──
    RestaurantVenue(
      id: 'caves_marechale',
      name: 'Les Caves de la Marechale',
      description: 'Restaurant dans des caves voutees historiques, ambiance intimiste et carte gastronomique.',
      group: 'Ambiances insolites / thematiques',
      adresse: '3 Rue Jules Chalande, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h30-22h30',
      telephone: '05 61 23 89 89',
      latitude: 43.6025,
      longitude: 1.4420,
      websiteUrl: 'https://www.lescavesdelamarechale.com/',
      lienMaps: 'https://maps.google.com/?q=Les+Caves+de+la+Marechale+Toulouse',
    ),
    RestaurantVenue(
      id: 'petits_crus',
      name: 'Les Petits Crus',
      description: 'Bar a vins et restaurant avec ambiance cave a vin chaleureuse et plats du terroir.',
      group: 'Ambiances insolites / thematiques',
      adresse: '16 Place Saint-Pierre, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h30 / 18h30-23h',
      telephone: '05 61 22 07 07',
      latitude: 43.6060,
      longitude: 1.4390,
      websiteUrl: 'https://www.lespetitscrus.fr/',
      lienMaps: 'https://maps.google.com/?q=Les+Petits+Crus+Place+Saint-Pierre+Toulouse',
    ),
    RestaurantVenue(
      id: 'pieds_sous_table',
      name: 'Aux Pieds sous la Table',
      description: 'Restaurant insolite avec decor atypique et cuisine creative dans une ambiance decontractee.',
      group: 'Ambiances insolites / thematiques',
      adresse: '4 Rue Mage, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h30-22h',
      telephone: '05 61 25 51 51',
      latitude: 43.5995,
      longitude: 1.4460,
      websiteUrl: 'https://www.auxpiedssouslatable.fr/',
      lienMaps: 'https://maps.google.com/?q=Aux+Pieds+sous+la+Table+4+Rue+Mage+Toulouse',
    ),

    // ── Creativite culinaire ──
    RestaurantVenue(
      id: 'hortus',
      name: 'Hortus',
      description: 'Restaurant gastronomique creatif avec produits locaux et menu degustation surprenant.',
      group: 'Creativite culinaire',
      adresse: '4 Rue du May, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-13h30 / 19h30-21h30',
      telephone: '05 61 12 28 28',
      latitude: 43.6010,
      longitude: 1.4440,
      websiteUrl: 'https://www.hortus-restaurant.fr/',
      lienMaps: 'https://maps.google.com/?q=Hortus+4+Rue+du+May+Toulouse',
    ),
    RestaurantVenue(
      id: 'saint_sauvage',
      name: 'Le Saint Sauvage',
      description: 'Bistrot creatif avec cuisine inventive et ingredients de saison.',
      group: 'Creativite culinaire',
      adresse: '1 Rue des Blanchers, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h30-22h',
      telephone: '05 61 22 45 45',
      latitude: 43.6050,
      longitude: 1.4380,
      websiteUrl: 'https://www.lesaintsauvage.fr/',
      lienMaps: 'https://maps.google.com/?q=Le+Saint+Sauvage+1+Rue+des+Blanchers+Toulouse',
    ),
    RestaurantVenue(
      id: 'hito',
      name: 'Hito',
      description: 'Restaurant japonais creatif fusionnant cuisine nippone et produits du Sud-Ouest.',
      group: 'Creativite culinaire',
      adresse: '22 Rue Maurice Fonvieille, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h-22h30',
      telephone: '05 61 38 90 90',
      latitude: 43.6000,
      longitude: 1.4450,
      websiteUrl: 'https://www.hito-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Hito+22+Rue+Maurice+Fonvieille+Toulouse',
    ),

    // ── Concepts originaux a proximite ──
    RestaurantVenue(
      id: 'speakeasy_centre',
      name: 'Bars caches & speakeasy du centre-ville',
      description: 'Lieux discrets apres reservation : Toulouse regorge de restaurants et bars caches dans les zones pietonnes du centre-ville.',
      group: 'Concepts originaux a proximite',
      adresse: 'Centre-ville pietonne, 31000 Toulouse',
      horaires: 'Sur reservation',
      telephone: '',
      latitude: 43.6040,
      longitude: 1.4440,
      websiteUrl: 'https://www.toulouse-tourisme.com/',
      lienMaps: 'https://maps.google.com/?q=Centre-ville+Toulouse',
    ),
  ];
}
