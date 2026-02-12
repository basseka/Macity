class CinemaVenue {
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
  final String ticketUrl;
  final String lienMaps;

  const CinemaVenue({
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
    this.ticketUrl = '',
    required this.lienMaps,
  });
}

class CinemaVenuesData {
  CinemaVenuesData._();

  static const groupOrder = [
    'Multiplexes & grands cinemas',
    'Cinemas independants & art',
    'Autres salles interessantes',
  ];

  static const venues = <CinemaVenue>[
    // ── Multiplexes & grands cinemas ──
    CinemaVenue(
      id: 'pathe_wilson',
      name: 'Pathe Wilson',
      description: 'Grand cinema historique au centre-ville avec nombreuses salles et ecrans modernes.',
      group: 'Multiplexes & grands cinemas',
      adresse: '3 Place du President Thomas Wilson, 31000 Toulouse',
      horaires: 'Tous les jours 10h-23h',
      telephone: '0892 69 66 96',
      latitude: 43.6075,
      longitude: 1.4480,
      websiteUrl: 'https://www.pathe.fr/cinemas/cinema-pathe-wilson',
      ticketUrl: 'https://www.pathe.fr/cinemas/cinema-pathe-wilson',
      lienMaps: 'https://maps.google.com/?q=Pathe+Wilson+Place+Wilson+Toulouse',
    ),
    CinemaVenue(
      id: 'ugc_montaudran',
      name: 'UGC Toulouse Montaudran',
      description: 'Multiplexe avec programmation grand public.',
      group: 'Multiplexes & grands cinemas',
      adresse: '3 Impasse Michel Labrousse, 31400 Toulouse',
      horaires: 'Tous les jours 10h-23h',
      telephone: '0892 70 00 00',
      latitude: 43.5720,
      longitude: 1.4815,
      websiteUrl: 'https://www.ugc.fr/cinema/ugc-toulouse-montaudran/',
      ticketUrl: 'https://www.ugc.fr/cinema/ugc-toulouse-montaudran/',
      lienMaps: 'https://maps.google.com/?q=UGC+Toulouse+Montaudran',
    ),
    CinemaVenue(
      id: 'pathe_labege',
      name: 'Pathe Labege',
      description: 'Grand cinema avec IMAX et grands ecrans dans la zone commerciale de Labege.',
      group: 'Multiplexes & grands cinemas',
      adresse: 'Centre Commercial Labege 2, 31670 Labege',
      horaires: 'Tous les jours 10h-23h',
      telephone: '0892 69 66 96',
      latitude: 43.5335,
      longitude: 1.5110,
      websiteUrl: 'https://www.pathe.fr/cinemas/cinema-pathe-labege',
      ticketUrl: 'https://www.pathe.fr/cinemas/cinema-pathe-labege',
      lienMaps: 'https://maps.google.com/?q=Pathe+Labege+Centre+Commercial',
    ),

    // ── Cinemas independants & art ──
    CinemaVenue(
      id: 'american_cosmograph',
      name: 'American Cosmograph',
      description: 'Cinema d\'art & essai avec programmation eclectique.',
      group: 'Cinemas independants & art',
      adresse: '24 Rue Montardy, 31000 Toulouse',
      horaires: 'Tous les jours 13h30-22h30',
      telephone: '05 61 21 22 11',
      latitude: 43.6040,
      longitude: 1.4500,
      websiteUrl: 'https://www.american-cosmograph.fr/',
      ticketUrl: 'https://www.american-cosmograph.fr/horaires/',
      lienMaps: 'https://maps.google.com/?q=American+Cosmograph+24+Rue+Montardy+Toulouse',
    ),
    CinemaVenue(
      id: 'cinema_abc',
      name: 'ABC',
      description: 'Cinema independant et associatif, soutient le cinema europeen.',
      group: 'Cinemas independants & art',
      adresse: '13 Rue Saint-Bernard, 31000 Toulouse',
      horaires: 'Tous les jours 14h-22h',
      telephone: '05 61 21 20 46',
      latitude: 43.6010,
      longitude: 1.4495,
      websiteUrl: 'https://abc-toulouse.fr/',
      ticketUrl: 'https://abc-toulouse.fr/programme/',
      lienMaps: 'https://maps.google.com/?q=Cinema+ABC+13+Rue+Saint-Bernard+Toulouse',
    ),
    CinemaVenue(
      id: 'utopia_borderouge',
      name: 'Utopia Borderouge',
      description: 'Salle d\'art & essai du reseau Utopia.',
      group: 'Cinemas independants & art',
      adresse: '59 Avenue Maurice Bourgues-Maunoury, 31200 Toulouse',
      horaires: 'Tous les jours 14h-22h',
      telephone: '05 61 35 26 28',
      latitude: 43.6340,
      longitude: 1.4530,
      websiteUrl: 'https://www.cinemas-utopia.org/toulouse/',
      ticketUrl: 'https://www.cinemas-utopia.org/toulouse/',
      lienMaps: 'https://maps.google.com/?q=Utopia+Borderouge+Toulouse',
    ),
    CinemaVenue(
      id: 'le_cratere',
      name: 'Le Cratere',
      description: 'Cinema d\'art et essai, petite salle conviviale avec programmation originale.',
      group: 'Cinemas independants & art',
      adresse: '95 Grande Rue Saint-Michel, 31400 Toulouse',
      horaires: 'Tous les jours 14h-22h',
      telephone: '05 61 53 50 53',
      latitude: 43.5880,
      longitude: 1.4465,
      websiteUrl: 'https://www.cinema-lecratere.com/',
      ticketUrl: 'https://www.cinema-lecratere.com/',
      lienMaps: 'https://maps.google.com/?q=Le+Cratere+Cinema+Grande+Rue+Saint-Michel+Toulouse',
    ),
    CinemaVenue(
      id: 'cinematheque_toulouse',
      name: 'Cinematheque de Toulouse',
      description: 'Salle et centre d\'archives dedies au cinema. En travaux, reouverture prevue 2026.',
      group: 'Cinemas independants & art',
      adresse: '69 Rue du Taur, 31000 Toulouse',
      horaires: 'En travaux - reouverture 2026',
      telephone: '05 62 30 30 10',
      latitude: 43.6060,
      longitude: 1.4430,
      websiteUrl: 'https://www.lacinemathequedetoulouse.fr/',
      lienMaps: 'https://maps.google.com/?q=Cinematheque+de+Toulouse+69+Rue+du+Taur',
    ),

    // ── Autres salles interessantes ──
    CinemaVenue(
      id: 'veo_cartoucherie',
      name: 'Cinema Veo Cartoucherie',
      description: 'Salle cinema dans le quartier de la Cartoucherie.',
      group: 'Autres salles interessantes',
      adresse: 'Allee de la Cartoucherie, 31300 Toulouse',
      horaires: 'Tous les jours 10h-22h30',
      telephone: '05 36 09 09 09',
      latitude: 43.6050,
      longitude: 1.4175,
      websiteUrl: 'https://www.veocinemas.fr/',
      ticketUrl: 'https://www.veocinemas.fr/',
      lienMaps: 'https://maps.google.com/?q=Cinema+Veo+Cartoucherie+Toulouse',
    ),
    CinemaVenue(
      id: 'cgr_blagnac',
      name: 'Cinema CGR Blagnac',
      description: 'Grand cinema multiplex a Blagnac, pres de Toulouse.',
      group: 'Autres salles interessantes',
      adresse: 'Zone de Ritouret, 31700 Blagnac',
      horaires: 'Tous les jours 10h-23h',
      telephone: '0892 68 85 89',
      latitude: 43.6335,
      longitude: 1.3785,
      websiteUrl: 'https://www.cgrcinemas.fr/blagnac/',
      ticketUrl: 'https://www.cgrcinemas.fr/blagnac/',
      lienMaps: 'https://maps.google.com/?q=CGR+Blagnac',
    ),
    CinemaVenue(
      id: 'cine_rex_blagnac',
      name: 'Cine Rex',
      description: 'Cinema convivial a Blagnac.',
      group: 'Autres salles interessantes',
      adresse: '41 Avenue du General de Gaulle, 31700 Blagnac',
      horaires: 'Tous les jours 14h-22h',
      telephone: '05 61 71 42 67',
      latitude: 43.6310,
      longitude: 1.3920,
      websiteUrl: 'https://www.rex-blagnac.fr/',
      ticketUrl: 'https://www.rex-blagnac.fr/',
      lienMaps: 'https://maps.google.com/?q=Cine+Rex+41+Avenue+General+de+Gaulle+Blagnac',
    ),
  ];
}
