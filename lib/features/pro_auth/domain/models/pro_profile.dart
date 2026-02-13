class ProProfile {
  final String id;
  final String userId;
  final String nom;
  final String type;
  final String email;
  final String telephone;
  final String? accessCode;
  final bool approved;
  final DateTime createdAt;

  ProProfile({
    required this.id,
    required this.userId,
    required this.nom,
    required this.type,
    required this.email,
    required this.telephone,
    this.accessCode,
    this.approved = false,
    required this.createdAt,
  });

  ProProfile copyWith({bool? approved}) {
    return ProProfile(
      id: id,
      userId: userId,
      nom: nom,
      type: type,
      email: email,
      telephone: telephone,
      accessCode: accessCode,
      approved: approved ?? this.approved,
      createdAt: createdAt,
    );
  }

  // ─────────────────────────────────────────
  // Serialisation locale (SharedPreferences)
  // ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nom': nom,
        'type': type,
        'email': email,
        'telephone': telephone,
        'accessCode': accessCode,
        'approved': approved,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProProfile.fromJson(Map<String, dynamic> json) => ProProfile(
        id: json['id'] as String,
        userId: json['userId'] as String,
        nom: json['nom'] as String,
        type: json['type'] as String,
        email: json['email'] as String,
        telephone: json['telephone'] as String,
        accessCode: json['accessCode'] as String?,
        approved: json['approved'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  // ─────────────────────────────────────────
  // Serialisation Supabase (snake_case)
  // ─────────────────────────────────────────

  Map<String, dynamic> toSupabaseJson() => {
        'user_id': userId,
        'nom': nom,
        'type': type,
        'email': email,
        'telephone': telephone,
        if (accessCode != null) 'access_code': accessCode,
      };

  factory ProProfile.fromSupabaseJson(Map<String, dynamic> json) =>
      ProProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        nom: json['nom'] as String,
        type: json['type'] as String,
        email: json['email'] as String,
        telephone: json['telephone'] as String,
        accessCode: json['access_code'] as String?,
        approved: json['approved'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}
