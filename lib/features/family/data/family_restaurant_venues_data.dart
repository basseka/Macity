class FamilyRestaurantVenue {
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

  const FamilyRestaurantVenue({
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

class FamilyRestaurantVenuesData {
  FamilyRestaurantVenuesData._();

  static const venues = <FamilyRestaurantVenue>[
    FamilyRestaurantVenue(
      id: 'air_de_famille',
      name: 'L\'Air de Famille',
      description: 'Restaurant convivial avec ambiance familiale, parfait pour repas entre parents et enfants.',
      adresse: '24 Rue Pargaminières, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h-22h',
      telephone: '05 61 21 39 06',
      latitude: 43.6040,
      longitude: 1.4390,
      websiteUrl: 'https://www.lairdefamille-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=L+Air+de+Famille+24+Rue+Pargaminieres+Toulouse',
    ),
    FamilyRestaurantVenue(
      id: 'la_belle_famille',
      name: 'Restaurant La Belle Famille',
      description: 'Lieu chaleureux et adapte aux familles avec enfants.',
      adresse: '10 Rue des Filatiers, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h-22h30',
      telephone: '05 61 25 61 77',
      latitude: 43.6005,
      longitude: 1.4435,
      websiteUrl: 'https://www.labellefamille-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=La+Belle+Famille+10+Rue+des+Filatiers+Toulouse',
    ),
    FamilyRestaurantVenue(
      id: 'chez_cesar',
      name: 'Chez Cesar',
      description: 'Buvette situee dans le Jardin des Plantes, tres appreciee des familles pour son cadre et sa simplicite (menu et cadre adaptes aux enfants).',
      adresse: 'Jardin des Plantes, Allee Frederic Mistral, 31400 Toulouse',
      horaires: 'Mar-Dim 10h-19h (selon saison)',
      telephone: '05 61 52 48 48',
      latitude: 43.5895,
      longitude: 1.4510,
      websiteUrl: 'https://www.chezcesar-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Chez+Cesar+Jardin+des+Plantes+Toulouse',
    ),
    FamilyRestaurantVenue(
      id: 'gigiland',
      name: 'Gigiland',
      description: 'Restaurant dans un quartier anime avec une ambiance facile a vivre, souvent recommande pour les sorties en famille.',
      adresse: '3 Rue Jules Chalande, 31000 Toulouse',
      horaires: 'Mar-Sam 12h-14h / 19h-22h30',
      telephone: '05 61 22 09 09',
      latitude: 43.6025,
      longitude: 1.4420,
      websiteUrl: 'https://www.gigiland-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Gigiland+3+Rue+Jules+Chalande+Toulouse',
    ),
    FamilyRestaurantVenue(
      id: 'brunch_club',
      name: 'Brunch Club',
      description: 'Bonne option pour un brunch en famille ou un repas detendu avec enfants (menu et ambiance relax).',
      adresse: '7 Rue de la Bourse, 31000 Toulouse',
      horaires: 'Mer-Dim 9h-16h',
      telephone: '05 61 23 45 00',
      latitude: 43.6035,
      longitude: 1.4455,
      websiteUrl: 'https://www.brunchclub-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Brunch+Club+7+Rue+de+la+Bourse+Toulouse',
    ),
  ];
}
