/// Totaux affichés pour un event boosté = fake (seed) + real (utilisateurs).
/// Vient de la vue `event_engagement_totals`. Si l'event n'est pas boosté,
/// la vue ne retourne rien et on tombe sur [EventEngagementTotals.empty].
class EventEngagementTotals {
  final String eventSource;       // 'scraped_events' | 'user_events'
  final String eventIdentifiant;  // id text
  final int likesCount;
  final int sharesCount;
  final int commentsCount;
  final String boostType;         // 'featured' | 'top'
  final DateTime? seededAt;

  const EventEngagementTotals({
    required this.eventSource,
    required this.eventIdentifiant,
    required this.likesCount,
    required this.sharesCount,
    required this.commentsCount,
    required this.boostType,
    this.seededAt,
  });

  factory EventEngagementTotals.empty(String source, String id) =>
      EventEngagementTotals(
        eventSource: source,
        eventIdentifiant: id,
        likesCount: 0,
        sharesCount: 0,
        commentsCount: 0,
        boostType: '',
      );

  factory EventEngagementTotals.fromJson(Map<String, dynamic> json) =>
      EventEngagementTotals(
        eventSource: json['event_source'] as String,
        eventIdentifiant: json['event_identifiant'] as String,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
        commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
        boostType: (json['boost_type'] as String?) ?? '',
        seededAt: json['seeded_at'] != null
            ? DateTime.tryParse(json['seeded_at'] as String)
            : null,
      );
}
