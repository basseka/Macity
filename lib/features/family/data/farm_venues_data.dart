class FarmVenue {
  final String id;
  final String name;
  final String description;
  final String adresse;
  final String horaires;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;

  const FarmVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.adresse,
    required this.horaires,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
  });
}

class FarmVenuesData {
  FarmVenuesData._();

  static const venues = <FarmVenue>[
    FarmVenue(
      id: 'ferme_de_50',
      name: 'La Ferme de 50',
      description: 'Ferme pedagogique avec diverses races domestiques (lamas, poules, chevaux, lapins). Activites pour les enfants, nourrissage des animaux.',
      adresse: 'Lieu-dit Cinquante, 31530 Merenvielle',
      horaires: 'Mer-Dim 10h-18h',
      telephone: '06 80 21 69 50',
      latitude: 43.6310,
      longitude: 1.1615,
      websiteUrl: 'https://www.lafermede50.fr/',
      lienMaps: 'https://maps.google.com/?q=La+Ferme+de+50+Merenvielle',
    ),
    FarmVenue(
      id: 'ferme_du_paradis',
      name: 'La Ferme du Paradis',
      description: 'Ferme-parc avec plus d\'une centaine d\'animaux (wallabies, daims, emeus, lamas) et aires de jeux gonflables pour enfants.',
      adresse: 'Lieu-dit Le Paradis, 31370 Rieumes',
      horaires: 'Mer-Dim 10h-18h (saison)',
      telephone: '06 73 19 88 52',
      latitude: 43.4085,
      longitude: 1.1150,
      websiteUrl: 'https://www.lafermeduparadis.fr/',
      lienMaps: 'https://maps.google.com/?q=La+Ferme+du+Paradis+Rieumes',
    ),
    FarmVenue(
      id: 'arche_noe_soly_ange',
      name: 'L\'Arche de Noe de Soly-Ange',
      description: 'Parc animalier associatif avec une grande variete d\'animaux recueillis. Experience intimiste et pedagogique pour les enfants.',
      adresse: 'Lieu-dit Soly-Ange, 31410 Lavernose-Lacasse',
      horaires: 'Mer-Dim 10h-17h30',
      telephone: '06 16 48 82 93',
      latitude: 43.3930,
      longitude: 1.2680,
      websiteUrl: 'https://www.arche-de-noe-soly-ange.fr/',
      lienMaps: 'https://maps.google.com/?q=Arche+de+Noe+Soly-Ange+Lavernose-Lacasse',
    ),
    FarmVenue(
      id: 'ferme_capra_de_pau',
      name: 'La Ferme de Capra de Pau',
      description: 'Petite ferme pedagogique avec chevres, moutons, poules et anes. Ateliers decouverte pour les enfants.',
      adresse: 'Chemin de Capra de Pau, 31170 Tournefeuille',
      horaires: 'Mer & Sam 14h-17h',
      telephone: '05 61 06 97 41',
      latitude: 43.5830,
      longitude: 1.3490,
      websiteUrl: '',
      lienMaps: 'https://maps.google.com/?q=Ferme+Capra+de+Pau+Tournefeuille',
    ),
  ];
}
