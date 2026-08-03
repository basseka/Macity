class Offer {
  final String id;
  final String proProfileId;
  final String businessName;
  final String businessAddress;
  final String title;
  final String description;
  final String emoji;
  final String imageUrl;
  final String imageAsset;
  final String businessUrl;
  final int totalSpots;
  final int claimedSpots;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool isActive;
  final String city;
  final DateTime createdAt;

  /// Commerce mis en avant par l'offre, au format canonique du projet :
  /// `sourceTable` vaut 'etablissements' | 'venues' | 'sport_venues' |
  /// 'family_venues', `sourceId` est l'id dans cette table. Les deux sont
  /// vides/nuls ensemble quand l'offre n'est rattachee a aucune pochette.
  final String sourceTable;
  final int? sourceId;

  /// Cle de rapprochement avec une pochette de commerce. `null` si l'offre
  /// n'est rattachee a rien : elle reste visible dans la rubrique Offres.
  String? get venueKey => venueKeyFor(sourceTable, sourceId);

  /// Construit la cle de rapprochement, en normalisant le nom de table.
  ///
  /// `CommerceModel.sourceTable` n'a jamais ete uniformise : selon le service
  /// qui l'alimente il vaut le SINGULIER ('etablissement', 'venue',
  /// 'family_venue' : reviews et claims) ou le PLURIEL ('etablissements',
  /// 'venues', 'sport_venues' : partners_of_day, sport_venues_service). Cote
  /// offre, la RPC admin ne stocke que le pluriel. Comparer les deux
  /// directement raterait donc silencieusement la moitie des pochettes.
  static String? venueKeyFor(String? table, int? id) {
    if (table == null || table.isEmpty || id == null) return null;
    final plural = table.endsWith('s') ? table : '${table}s';
    return '$plural#$id';
  }

  Offer({
    required this.id,
    required this.proProfileId,
    required this.businessName,
    this.businessAddress = '',
    required this.title,
    this.description = '',
    this.emoji = '',
    this.imageUrl = '',
    this.imageAsset = '',
    this.businessUrl = '',
    this.totalSpots = 10,
    this.claimedSpots = 0,
    required this.startsAt,
    required this.expiresAt,
    this.isActive = true,
    this.city = 'Toulouse',
    required this.createdAt,
    this.sourceTable = '',
    this.sourceId,
  });

  // ─────────────────────────────────────────
  // Proprietes calculees
  // ─────────────────────────────────────────

  /// Sentinelle : totalSpots >= 99999 signifie "places illimitees" cote UI.
  /// On stocke un nombre en DB plutot que NULL pour eviter une migration de
  /// schema (la colonne est NOT NULL). 99999 + DateTime(2099) sont utilises
  /// comme valeurs neutres detectees par les getters ci-dessous.
  static const int unlimitedSpotsSentinel = 99999;

  /// Sentinelle : annee >= 2099 signifie "sans date d'expiration".
  static const int noExpirationYear = 2099;

  /// L'offre a-t-elle des places limitees ?
  bool get isUnlimited => totalSpots >= unlimitedSpotsSentinel;

  /// L'offre a-t-elle une date d'expiration definie ?
  bool get hasNoExpiration => expiresAt.year >= noExpirationYear;

  int get remainingSpots => totalSpots - claimedSpots;
  bool get hasSpots => isUnlimited || remainingSpots > 0;

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
        'imageUrl': imageUrl,
        'businessUrl': businessUrl,
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
        imageUrl: json['imageUrl'] as String? ?? '',
        businessUrl: json['businessUrl'] as String? ?? '',
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
        'image_url': imageUrl,
        'business_url': businessUrl,
        'total_spots': totalSpots,
        'claimed_spots': claimedSpots,
        'starts_at': startsAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': isActive,
        'city': city,
      };

  factory Offer.fromSupabaseJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String,
        // Null pour les offres saisies dans l'admin : elles appartiennent a un
        // client de `partner_clients`, pas a un compte pro. Un cast direct
        // faisait planter le parsing de TOUTE la rubrique Offres des qu'une
        // seule ligne de ce type existait.
        proProfileId: json['pro_profile_id'] as String? ?? '',
        businessName: json['business_name'] as String,
        businessAddress: json['business_address'] as String? ?? '',
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        businessUrl: json['business_url'] as String? ?? '',
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
        sourceTable: json['source_table'] as String? ?? '',
        sourceId: (json['source_id'] as num?)?.toInt(),
      );
}
