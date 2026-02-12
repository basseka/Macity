class BowlingVenue {
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

  const BowlingVenue({
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

class BowlingVenuesData {
  BowlingVenuesData._();

  static const groupOrder = [
    'Bowls & centres de bowling a Toulouse',
    'Autres options proches (agglomeration)',
  ];

  static const venues = <BowlingVenue>[
    // ── Bowls & centres de bowling a Toulouse ──
    BowlingVenue(
      id: 'bowling_gramont',
      name: 'Bowling Gramont',
      description: 'Centre de bowling majeur avec 26 pistes, bar et restaurant. Ouvert tard certains soirs, ideal pour soirees entre amis ou familles.',
      group: 'Bowls & centres de bowling a Toulouse',
      adresse: '64 Route de Lavaur, 31500 Toulouse',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 20 26 26',
      latitude: 43.6285,
      longitude: 1.4885,
      websiteUrl: 'https://www.bowling-gramont.com/',
      lienMaps: 'https://maps.google.com/?q=Bowling+Gramont+64+Route+de+Lavaur+Toulouse',
    ),
    BowlingVenue(
      id: 'bowling_montaudran',
      name: 'Bowling Montaudran',
      description: 'Grand complexe bowling avec jusqu\'a 28 pistes, options party, formules bowling + karting ou laser game.',
      group: 'Bowls & centres de bowling a Toulouse',
      adresse: '1 Impasse Michel Labrousse, 31400 Toulouse',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 80 11 22',
      latitude: 43.5725,
      longitude: 1.4810,
      websiteUrl: 'https://www.bowlingmontaudran.fr/',
      lienMaps: 'https://maps.google.com/?q=Bowling+Montaudran+Impasse+Michel+Labrousse+Toulouse',
    ),
    BowlingVenue(
      id: 'bowling_center',
      name: 'Bowling Center',
      description: 'Bowling central a Toulouse avec formules anniversaires, soirees et restauration.',
      group: 'Bowls & centres de bowling a Toulouse',
      adresse: '68 Avenue des Minimes, 31200 Toulouse',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 47 02 02',
      latitude: 43.6195,
      longitude: 1.4405,
      websiteUrl: 'https://www.bowling-center-toulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Bowling+Center+68+Avenue+des+Minimes+Toulouse',
    ),
    BowlingVenue(
      id: 'games_factory',
      name: 'Games Factory - Bowling Toulouse',
      description: 'Complexe multi-activites a Roques avec bowling, jeux et formules "illimite bowling", super pour familles ou amis.',
      group: 'Bowls & centres de bowling a Toulouse',
      adresse: 'Zone Commerciale, 31120 Roques',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 72 47 47',
      latitude: 43.5060,
      longitude: 1.3870,
      websiteUrl: 'https://www.gamesfactory.fr/',
      lienMaps: 'https://maps.google.com/?q=Games+Factory+Bowling+Roques',
    ),

    // ── Autres options proches (agglomeration) ──
    BowlingVenue(
      id: 'bowling_stadium_colomiers',
      name: 'Bowling Stadium - Colomiers',
      description: 'Bowling avec 20 pistes, laser game et realite virtuelle. Ambiance festive, a l\'ouest de Toulouse.',
      group: 'Autres options proches (agglomeration)',
      adresse: '2 Allee du Languedoc, 31770 Colomiers',
      horaires: 'Lun-Jeu 14h-00h, Ven-Sam 14h-02h, Dim 10h-00h',
      telephone: '05 61 78 61 61',
      latitude: 43.6030,
      longitude: 1.3365,
      websiteUrl: 'https://www.bowling-stadium.fr/',
      lienMaps: 'https://maps.google.com/?q=Bowling+Stadium+Colomiers',
    ),
  ];
}
