class LaserGameVenue {
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

  const LaserGameVenue({
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

class LaserGameVenuesData {
  LaserGameVenuesData._();

  static const venues = <LaserGameVenue>[
    LaserGameVenue(
      id: 'laser_quest_toulouse',
      name: 'Laser Quest',
      description: 'Arene laser game classique avec labyrinthes, materiel et parties pour amis ou familles (~20 min par partie).',
      adresse: '37 Rue Gabriel Bienes, 31300 Toulouse',
      horaires: 'Mer-Dim 14h-22h, Ven-Sam 14h-00h',
      telephone: '05 61 42 04 04',
      latitude: 43.6045,
      longitude: 1.4155,
      websiteUrl: 'https://www.laserquest.fr/toulouse/',
      lienMaps: 'https://maps.google.com/?q=Laser+Quest+37+Rue+Gabriel+Bienes+Toulouse',
    ),
    LaserGameVenue(
      id: 'laser_trampoline_sept_deniers',
      name: 'Laser Game - Trampoline Park Sept Deniers',
      description: 'Laser game integre au Trampoline Park des Sept Deniers, ideal pour activites en famille ou entre amis.',
      adresse: '120 Route de Blagnac, 31200 Toulouse',
      horaires: 'Mer-Dim 10h-20h, Ven-Sam 10h-22h',
      telephone: '05 61 11 52 52',
      latitude: 43.6175,
      longitude: 1.4230,
      websiteUrl: 'https://www.trampolinepark-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Trampoline+Park+Sept+Deniers+120+Route+Blagnac+Toulouse',
    ),
    LaserGameVenue(
      id: 'laser_quest_blagnac',
      name: 'Laser Quest Toulouse / Blagnac',
      description: 'Laser game dans la commune voisine de Blagnac, bonne option pour l\'ouest de l\'agglomeration.',
      adresse: 'Zone Commerciale Ritouret, 31700 Blagnac',
      horaires: 'Mer-Dim 14h-22h, Ven-Sam 14h-00h',
      telephone: '05 61 71 20 20',
      latitude: 43.6340,
      longitude: 1.3780,
      websiteUrl: 'https://www.laserquest.fr/blagnac/',
      lienMaps: 'https://maps.google.com/?q=Laser+Quest+Blagnac',
    ),
    LaserGameVenue(
      id: 'games_factory_laser',
      name: 'Games Factory - Bowling Toulouse',
      description: 'Centre de loisirs a Roques-sur-Garonne avec laser game en plus du bowling, jeux et autres activites.',
      adresse: 'Zone Commerciale, 31120 Roques',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 72 47 47',
      latitude: 43.5060,
      longitude: 1.3870,
      websiteUrl: 'https://www.gamesfactory.fr/',
      lienMaps: 'https://maps.google.com/?q=Games+Factory+Roques',
    ),
    LaserGameVenue(
      id: 'laser_game_evolution_portet',
      name: 'Laser Game Evolution Portet-sur-Garonne',
      description: 'Arene laser game a Portet-sur-Garonne, accessible rapidement depuis Toulouse centre.',
      adresse: 'Zone Commerciale, 31120 Portet-sur-Garonne',
      horaires: 'Mer-Dim 14h-22h, Ven-Sam 14h-00h',
      telephone: '05 34 47 00 10',
      latitude: 43.5230,
      longitude: 1.4010,
      websiteUrl: 'https://www.lasergame-evolution.com/portet-sur-garonne/',
      lienMaps: 'https://maps.google.com/?q=Laser+Game+Evolution+Portet-sur-Garonne',
    ),
  ];
}
