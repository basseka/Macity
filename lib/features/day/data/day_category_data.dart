class DaySubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String? image;

  const DaySubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    this.image,
  });
}

class ConcertVenue {
  final String label;
  final String searchKeyword;
  final String image;

  const ConcertVenue({
    required this.label,
    required this.searchKeyword,
    required this.image,
  });
}

class DayCategoryData {
  DayCategoryData._();

  static const concertVenues = [
    ConcertVenue(label: 'Zenith', searchKeyword: 'zenith', image: 'assets/images/salle_zenith.png'),
    ConcertVenue(label: 'Halle aux Grains', searchKeyword: 'halle aux grains', image: 'assets/images/salle_halleauxgrains.png'),
    ConcertVenue(label: 'Le Bikini', searchKeyword: 'bikini', image: 'assets/images/salle_bikini.png'),
    ConcertVenue(label: 'Auditorium', searchKeyword: 'auditorium', image: 'assets/images/salle_auditorium.png'),
    ConcertVenue(label: 'Interference', searchKeyword: 'interference', image: 'assets/images/salle_interference.png'),
    ConcertVenue(label: 'Casino Barriere', searchKeyword: 'casino barriere', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'Le Metronum', searchKeyword: 'metronum', image: 'assets/images/pochette_metronum.png'),
    ConcertVenue(label: 'Le Rex', searchKeyword: 'rex', image: 'assets/images/pochette_rex.png'),
    ConcertVenue(label: 'La Dynamo', searchKeyword: 'dynamo', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'Bascala', searchKeyword: 'bascala', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'COMDT', searchKeyword: 'comdt', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'Hall 8', searchKeyword: 'hall 8', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'Senechal', searchKeyword: 'senechal', image: 'assets/images/pochette_concert.png'),
  ];

  static const djsetVenues = [
    ConcertVenue(label: 'Interference', searchKeyword: 'interference', image: 'assets/images/salle_interference.png'),
    ConcertVenue(label: 'Le Bikini', searchKeyword: 'bikini', image: 'assets/images/salle_bikini.png'),
    ConcertVenue(label: 'Le Rex', searchKeyword: 'rex', image: 'assets/images/pochette_rex.png'),
  ];

  static const spectacleVenues = [
    ConcertVenue(label: 'Interference', searchKeyword: 'interference', image: 'assets/images/salle_interference.png'),
    ConcertVenue(label: 'Le Bikini', searchKeyword: 'bikini', image: 'assets/images/salle_bikini.png'),
    ConcertVenue(label: 'Zenith', searchKeyword: 'zenith', image: 'assets/images/salle_zenith.png'),
    ConcertVenue(label: 'Halle aux Grains', searchKeyword: 'halle aux grains', image: 'assets/images/salle_halleauxgrains.png'),
    ConcertVenue(label: 'Bascala', searchKeyword: 'bascala', image: 'assets/images/pochette_concert.png'),
    ConcertVenue(label: 'Casino Barriere', searchKeyword: 'casino barriere', image: 'assets/images/pochette_concert.png'),
  ];

  static final subcategories = [
    DaySubcategory(label: 'Calendrier', searchTag: 'A venir', emoji: '📅', image: 'assets/images/pochette_calendrier.png'),
    DaySubcategory(label: 'Fête de la musique ${DateTime.now().year}', searchTag: 'Fete musique', emoji: '🎉', image: 'assets/images/pochette_fetedelamusique.png'),
    DaySubcategory(label: 'Concert', searchTag: 'Concert', emoji: '🎵', image: 'assets/images/pochette_concert.png'),
    DaySubcategory(label: 'Spectacle', searchTag: 'Spectacle', emoji: '🎭', image: 'assets/images/pochette_spectacle.png'),
    DaySubcategory(label: 'Festival', searchTag: 'Festival', emoji: '🎪', image: 'assets/images/pochette_festival.png'),
    DaySubcategory(label: 'Opera', searchTag: 'Opera', emoji: '🎶', image: 'assets/images/pochette_opera.png'),
    DaySubcategory(label: 'Stand Up', searchTag: 'Stand up', emoji: '🎙️', image: 'assets/images/pochette_standup.png'),
    DaySubcategory(label: 'DJ Set', searchTag: 'DJ set', emoji: '🎧', image: 'assets/images/pochette_discotheque.png'),
    DaySubcategory(label: 'Showcase', searchTag: 'Showcase', emoji: '🎤', image: 'assets/images/pochette_showcase.png'),
    DaySubcategory(label: 'Autres', searchTag: 'Autres', emoji: '🎟️', image: 'assets/images/pochette_autre.png'),
  ];
}
