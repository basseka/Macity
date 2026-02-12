class EspnRugbyEvent {
  final String id;
  final String name;
  final String shortName;
  final String date;
  final String statusType;
  final String statusDetail;
  final String homeTeamName;
  final String awayTeamName;
  final String homeTeamLogo;
  final String awayTeamLogo;
  final String homeScore;
  final String awayScore;
  final String venueName;
  final String venueCity;

  const EspnRugbyEvent({
    required this.id,
    required this.name,
    required this.shortName,
    required this.date,
    required this.statusType,
    required this.statusDetail,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    required this.venueName,
    required this.venueCity,
  });

  factory EspnRugbyEvent.fromJson(Map<String, dynamic> json) {
    final competitions = (json['competitions'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final competitors = (competitions?['competitors'] as List?) ?? [];
    final venue = competitions?['venue'] as Map<String, dynamic>?;

    Map<String, dynamic>? home;
    Map<String, dynamic>? away;
    for (final c in competitors) {
      if (c['homeAway'] == 'home') home = c as Map<String, dynamic>;
      if (c['homeAway'] == 'away') away = c as Map<String, dynamic>;
    }

    return EspnRugbyEvent(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      date: json['date'] ?? '',
      statusType: json['status']?['type']?['name'] ?? '',
      statusDetail: json['status']?['type']?['detail'] ?? '',
      homeTeamName: home?['team']?['displayName'] ?? '',
      awayTeamName: away?['team']?['displayName'] ?? '',
      homeTeamLogo: home?['team']?['logo'] ?? '',
      awayTeamLogo: away?['team']?['logo'] ?? '',
      homeScore: home?['score'] ?? '',
      awayScore: away?['score'] ?? '',
      venueName: venue?['fullName'] ?? '',
      venueCity: venue?['address']?['city'] ?? '',
    );
  }
}
