class Offer {
  final String id;
  final String proProfileId;
  final String businessName;
  final String businessAddress;
  final String title;
  final String description;
  final String emoji;
  final int totalSpots;
  final int claimedSpots;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool isActive;
  final String city;
  final DateTime createdAt;

  Offer({
    required this.id,
    required this.proProfileId,
    required this.businessName,
    this.businessAddress = '',
    required this.title,
    this.description = '',
    this.emoji = '',
    this.totalSpots = 10,
    this.claimedSpots = 0,
    required this.startsAt,
    required this.expiresAt,
    this.isActive = true,
    this.city = 'Toulouse',
    required this.createdAt,
  });

  // ─────────────────────────────────────────
  // Proprietes calculees
  // ─────────────────────────────────────────

  int get remainingSpots => totalSpots - claimedSpots;
  bool get hasSpots => remainingSpots > 0;

  // ─────────────────────────────────────────
  // Serialisation locale (SharedPreferences)
  // ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'proProfileId': proProfileId,
        'businessName': businessName,
        'businessAddress': businessAddress,
        'title': title,
        'description': description,
        'emoji': emoji,
        'totalSpots': totalSpots,
        'claimedSpots': claimedSpots,
        'startsAt': startsAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
        'city': city,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String,
        proProfileId: json['proProfileId'] as String,
        businessName: json['businessName'] as String,
        businessAddress: json['businessAddress'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        totalSpots: json['totalSpots'] as int? ?? 10,
        claimedSpots: json['claimedSpots'] as int? ?? 0,
        startsAt: DateTime.parse(json['startsAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
        city: json['city'] as String? ?? 'Toulouse',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  // ─────────────────────────────────────────
  // Serialisation Supabase (snake_case)
  // ─────────────────────────────────────────

  Map<String, dynamic> toSupabaseJson() => {
        'pro_profile_id': proProfileId,
        'business_name': businessName,
        'business_address': businessAddress,
        'title': title,
        'description': description,
        'emoji': emoji,
        'total_spots': totalSpots,
        'claimed_spots': claimedSpots,
        'starts_at': startsAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': isActive,
        'city': city,
      };

  factory Offer.fromSupabaseJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String,
        proProfileId: json['pro_profile_id'] as String,
        businessName: json['business_name'] as String,
        businessAddress: json['business_address'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        totalSpots: json['total_spots'] as int? ?? 10,
        claimedSpots: json['claimed_spots'] as int? ?? 0,
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : DateTime.now(),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : DateTime.now(),
        isActive: json['is_active'] as bool? ?? true,
        city: json['city'] as String? ?? 'Toulouse',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}
