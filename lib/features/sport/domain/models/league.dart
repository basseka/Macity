class League {
  final int id;
  final int sportId;
  final String name;
  final String country;
  final int level;

  const League({
    required this.id,
    required this.sportId,
    required this.name,
    this.country = 'FR',
    this.level = 1,
  });

  factory League.fromJson(Map<String, dynamic> json) => League(
        id: json['id'] as int,
        sportId: json['sport_id'] as int,
        name: json['name'] as String? ?? '',
        country: json['country'] as String? ?? 'FR',
        level: json['level'] as int? ?? 1,
      );
}
