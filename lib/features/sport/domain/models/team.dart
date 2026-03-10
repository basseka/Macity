class Team {
  final int id;
  final int sportId;
  final int? leagueId;
  final String name;
  final String shortName;
  final String logoUrl;
  final String city;
  final String stadium;

  const Team({
    required this.id,
    required this.sportId,
    this.leagueId,
    required this.name,
    this.shortName = '',
    this.logoUrl = '',
    this.city = '',
    this.stadium = '',
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as int,
        sportId: json['sport_id'] as int,
        leagueId: json['league_id'] as int?,
        name: json['name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? '',
        city: json['city'] as String? ?? '',
        stadium: json['stadium'] as String? ?? '',
      );
}
