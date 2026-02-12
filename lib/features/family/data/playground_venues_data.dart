class PlaygroundVenue {
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

  const PlaygroundVenue({
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

class PlaygroundVenuesData {
  PlaygroundVenuesData._();

  static const venues = <PlaygroundVenue>[
    PlaygroundVenue(
      id: 'jardin_royal',
      name: 'Jardin Royal',
      description: 'Grande aire de jeux centrale, ideale pour petits et grands a proximite du centre.',
      adresse: 'Rue du Jardin Royal, 31000 Toulouse',
      horaires: 'Tous les jours 7h30-21h (ete), 7h30-18h30 (hiver)',
      telephone: '',
      latitude: 43.6020,
      longitude: 1.4510,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Jardin+Royal+Toulouse',
    ),
    PlaygroundVenue(
      id: 'jardin_japonais',
      name: 'Jardin Japonais',
      description: 'Ambiance zen + petits jeux pour enfants, tres agreable.',
      adresse: 'Jardin Japonais, 31400 Toulouse',
      horaires: 'Tous les jours 7h45-20h (ete), 7h45-17h30 (hiver)',
      telephone: '',
      latitude: 43.5895,
      longitude: 1.4430,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Jardin+Japonais+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_maourine',
      name: 'Parc de la Maourine',
      description: 'Espaces verts + structures de jeux et zones ombragees.',
      adresse: 'Chemin de la Maourine, 31200 Toulouse',
      horaires: 'Tous les jours 7h30-21h (ete), 7h30-18h (hiver)',
      telephone: '',
      latitude: 43.6340,
      longitude: 1.4250,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Parc+de+la+Maourine+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_reynerie',
      name: 'Parc de la Reynerie',
      description: 'Grand parc avec aires de jeux, lac et pistes cyclables.',
      adresse: 'Chemin de Reynerie, 31100 Toulouse',
      horaires: 'Tous les jours 7h30-21h (ete), 7h30-18h (hiver)',
      telephone: '',
      latitude: 43.5760,
      longitude: 1.3920,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Parc+de+la+Reynerie+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_ramier',
      name: 'Parc du Ramier',
      description: 'Vaste parc au bord de la Garonne + aires de jeux et espaces pique-nique.',
      adresse: 'Ile du Ramier, 31400 Toulouse',
      horaires: 'Tous les jours, acces libre',
      telephone: '',
      latitude: 43.5850,
      longitude: 1.4380,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Parc+du+Ramier+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_grand_rond',
      name: 'Parc Grand Rond',
      description: 'Beaux jardins + aire de jeux pour enfants, idealement situe.',
      adresse: 'Grand Rond, 31400 Toulouse',
      horaires: 'Tous les jours 7h30-21h (ete), 7h30-18h30 (hiver)',
      telephone: '',
      latitude: 43.5940,
      longitude: 1.4520,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Grand+Rond+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_poudrerie',
      name: 'Parc de la Poudrerie',
      description: 'Espace plus naturel, zones d\'exploration et jeux libres.',
      adresse: 'Chemin de la Poudrerie, 31200 Toulouse',
      horaires: 'Tous les jours 7h30-20h (ete), 7h30-17h30 (hiver)',
      telephone: '',
      latitude: 43.6380,
      longitude: 1.4580,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Parc+de+la+Poudrerie+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_paleficat',
      name: 'Parc de Paleficat',
      description: 'Aire de jeux enfants + bancs pour parents.',
      adresse: 'Chemin de Paleficat, 31500 Toulouse',
      horaires: 'Tous les jours, acces libre',
      telephone: '',
      latitude: 43.6400,
      longitude: 1.4900,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Parc+de+Paleficat+Toulouse',
    ),
    PlaygroundVenue(
      id: 'jardin_raymond_vi',
      name: 'Jardin Raymond VI',
      description: 'Espace petit parc avec structure de jeux.',
      adresse: 'Allee Charles de Fitte, 31300 Toulouse',
      horaires: 'Tous les jours, acces libre',
      telephone: '',
      latitude: 43.6070,
      longitude: 1.4310,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Jardin+Raymond+VI+Toulouse',
    ),
    PlaygroundVenue(
      id: 'parc_francois_verdier',
      name: 'Parc Francois Verdier',
      description: 'Espaces verts et petite aire de jeux enfants.',
      adresse: 'Place Francois Verdier, 31000 Toulouse',
      horaires: 'Tous les jours, acces libre',
      telephone: '',
      latitude: 43.6005,
      longitude: 1.4540,
      websiteUrl: 'https://www.toulouse.fr/web/environnement/parcs-et-jardins',
      lienMaps: 'https://maps.google.com/?q=Place+Francois+Verdier+Toulouse',
    ),
  ];
}
