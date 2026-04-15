class ChatMessage {
  final String id;
  final String reportedEventId;
  final String userId;
  final String prenom;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.reportedEventId,
    required this.userId,
    required this.prenom,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      reportedEventId: json['reported_event_id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      prenom: (json['prenom'] as String?) ?? 'Anonyme',
      avatarUrl: (json['avatar_url'] as String?)?.isNotEmpty == true
          ? json['avatar_url'] as String
          : null,
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
