/// Commentaire affiché dans la bottom sheet d'un event boosté.
/// Vient de la vue `event_comments_unified` qui union fake_comments + real_comments.
class EventComment {
  final String id;
  final String eventSource;
  final String eventIdentifiant;
  final String displayName;
  final String gender;        // 'M' | 'F'
  final String? avatarUrl;    // null = sans photo (UI fallback initiale)
  final String text;
  final DateTime createdAt;
  final bool isReal;          // true = vrai user, false = seed
  final String? deviceUuid;   // null pour fake, set pour real (= "mon comment")

  const EventComment({
    required this.id,
    required this.eventSource,
    required this.eventIdentifiant,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.text,
    required this.createdAt,
    required this.isReal,
    this.deviceUuid,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) => EventComment(
        id: json['id'] as String,
        eventSource: json['event_source'] as String,
        eventIdentifiant: json['event_identifiant'] as String,
        displayName: json['display_name'] as String,
        gender: json['gender'] as String,
        avatarUrl: json['avatar_url'] as String?,
        text: json['comment_text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isReal: json['is_real'] as bool? ?? false,
        deviceUuid: json['device_uuid'] as String?,
      );
}
