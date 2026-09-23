/// Message du chat d'une soiree privee (RPC list_private_event_messages).
/// prenom + avatar joints depuis user_profiles, [isHost] = ecrit par
/// l'organisateur.
class PrivateEventMessage {
  final String id;
  final String userId;
  final String prenom;
  final String? avatarUrl;
  final bool isHost;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const PrivateEventMessage({
    required this.id,
    required this.userId,
    required this.prenom,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
    this.imageUrl,
    this.isHost = false,
  });

  factory PrivateEventMessage.fromJson(Map<String, dynamic> json) {
    final prenom = (json['prenom'] as String?)?.trim() ?? '';
    final avatar = json['avatar_url'] as String?;
    final image = json['image_url'] as String?;
    return PrivateEventMessage(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      prenom: prenom.isNotEmpty ? prenom : 'Anonyme',
      avatarUrl: avatar != null && avatar.isNotEmpty ? avatar : null,
      isHost: json['is_host'] == true,
      content: (json['content'] as String?) ?? '',
      imageUrl: image != null && image.isNotEmpty ? image : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
