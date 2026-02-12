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

class DayCategoryData {
  DayCategoryData._();

  static const subcategories = [
    DaySubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '📅', image: 'assets/images/sc_cette_semaine.png'),
    DaySubcategory(label: 'Concert', searchTag: 'Concert', emoji: '🎵', image: 'assets/images/sc_concert.png'),
    DaySubcategory(label: 'Festival', searchTag: 'Festival', emoji: '🎪', image: 'assets/images/sc_festival.png'),
    DaySubcategory(label: 'Opera', searchTag: 'Opera', emoji: '🎶', image: 'assets/images/sc_opera.png'),
    DaySubcategory(label: 'DJ Set', searchTag: 'DJ set', emoji: '🎧', image: 'assets/images/sc_discotheque.png'),
    DaySubcategory(label: 'Showcase', searchTag: 'Showcase', emoji: '🎤', image: 'assets/images/sc_concert.png'),
    DaySubcategory(label: 'Spectacle', searchTag: 'Spectacle', emoji: '🎭', image: 'assets/images/sc_theatre.png'),
  ];
}
