class IceRinkVenue {
  final String id;
  final String name;
  final String description;
  final String adresse;
  final String horaires;
  final String tarif;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;

  const IceRinkVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.adresse,
    required this.horaires,
    required this.tarif,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
  });
}

class IceRinkVenuesData {
  IceRinkVenuesData._();

  static const venues = <IceRinkVenue>[
    IceRinkVenue(
      id: 'patinoire_alex_jany',
      name: 'Patinoire Alex Jany',
      description:
          'Plus grande patinoire de Toulouse (60x30m), ouverte toute l\'annee sauf juillet. '
          'Port des gants obligatoire.',
      adresse: '7 Chemin du Verdon, 31500 Toulouse',
      horaires: 'Mer 16h-18h45, Ven 16h-19h, Sam 15h-19h, Dim 14h30-19h',
      tarif: '2.30-7.15\u20AC (10.65\u20AC avec location patins)',
      telephone: '05 81 91 78 56',
      latitude: 43.63,
      longitude: 1.48,
      websiteUrl:
          'https://billetterie.sport.toulouse.fr/tickets/patinoires-3',
      lienMaps:
          'https://maps.google.com/?q=Patinoire+Alex+Jany+7+Chemin+du+Verdon+Toulouse',
    ),
    IceRinkVenue(
      id: 'patinoire_bellevue',
      name: 'Patinoire Bellevue',
      description:
          'Petite patinoire conviviale et familiale (30x20m) pres de la faculte Paul Sabatier '
          'et de la base verte de Pech David. Port des gants obligatoire.',
      adresse: '69 ter Route de Narbonne, 31000 Toulouse',
      horaires:
          'Lun-Mar-Ven 12h-14h/16h30-18h30, Mer 16h30-18h30, Jeu 12h-14h/16h30-21h, Sam 11h30-16h, Dim 8h30-18h',
      tarif: '3.00-9.70\u20AC (location patins incluse)',
      telephone: '05 61 22 24 80',
      latitude: 43.57,
      longitude: 1.46,
      websiteUrl:
          'https://billetterie.sport.toulouse.fr/tickets/patinoires-3',
      lienMaps:
          'https://maps.google.com/?q=Patinoire+Bellevue+69+Route+de+Narbonne+Toulouse',
    ),
    IceRinkVenue(
      id: 'patinoire_blagnac',
      name: 'Patinoire Jacques Raynaud - Blagnac',
      description:
          'Grande patinoire municipale de 1800m\u00B2 a Blagnac, ideale pour les premieres '
          'glisses des enfants. Cafeteria sur place.',
      adresse: '10 Avenue du General de Gaulle, 31700 Blagnac',
      horaires:
          'Mer 13h30-17h30, Jeu-Ven 20h30-23h30, Sam 10h30-18h, Dim 10h-18h30',
      tarif: '5\u20AC (4.20\u20AC -12 ans, jardin de glace)',
      telephone: '07 68 45 09 92',
      latitude: 43.6320,
      longitude: 1.3940,
      websiteUrl: 'https://patinoireblagnac.fr/',
      lienMaps:
          'https://maps.google.com/?q=Patinoire+Jacques+Raynaud+Blagnac',
    ),
  ];
}
