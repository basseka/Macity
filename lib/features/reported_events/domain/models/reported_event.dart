/// Modele d'un signalement communautaire (style Waze).
///
/// Stocke dans la table Supabase `reported_events`. Une edge function
/// `generate-event-poster` enrichit le champ [generated] apres l'insert
/// avec une affiche prefaite generee par Claude Haiku.
///
/// Quand plusieurs users signalent au meme endroit (< 20m, meme categorie,
/// < 6h), les rows sont mergees cote DB via la fonction RPC
/// `upsert_reported_event` : photos s'accumulent dans [photos],
/// [reportCount] augmente, reporter_ids liste les device UUIDs.
class ReportedEvent {
  final String id;
  final String reportedBy;
  final String rawTitle;
  final String category;
  final double lat;
  final double lng;
  final String? ville;
  final String locationName;

  /// Photos accumulees au fur et a mesure que des users signalent le meme event.
  /// Chaque URL pointe vers le bucket Supabase `user-events`.
  final List<String> photos;

  /// Videos courtes accumulees (10s max chacune).
  final List<String> videos;

  /// Nombre de personnes distinctes qui ont signale cet event.
  /// 1 = uniquement le reporter original, >1 = signalements communautaires.
  final int reportCount;

  /// Device UUIDs des reporters (utilise cote DB pour eviter qu'un meme user
  /// soit compte plusieurs fois).
  final List<String> reporterIds;

  /// Prenom/pseudo du premier reporter (denormalise pour affichage rapide).
  final String? reporterPrenom;

  /// URL avatar du premier reporter (denormalise).
  final String? reporterAvatarUrl;

  /// Liste des contributeurs (multi-reporters) avec prenom + avatar.
  final List<ReportedEventContributor> contributors;

  /// 'ai_generating' | 'published' | 'rejected' | 'expired'
  final String status;

  /// Output Claude (null tant que l'edge function n'a pas tourne).
  final ReportedEventGenerated? generated;

  final DateTime startsAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  const ReportedEvent({
    required this.id,
    required this.reportedBy,
    required this.rawTitle,
    required this.category,
    required this.lat,
    required this.lng,
    this.ville,
    this.locationName = '',
    this.photos = const [],
    this.videos = const [],
    this.reportCount = 1,
    this.reporterIds = const [],
    this.reporterPrenom,
    this.reporterAvatarUrl,
    this.contributors = const [],
    required this.status,
    this.generated,
    required this.startsAt,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isReady => status == 'published' && generated != null;
  bool get isGenerating => status == 'ai_generating';

  /// Premiere photo disponible, ou null.
  /// Utilise pour l'affichage rapide dans la carte poster.
  String? get firstPhoto => photos.isNotEmpty ? photos.first : null;

  /// Le signalement a-t-il ete corrobore par plusieurs users ?
  bool get isCommunityConfirmed => reportCount >= 2;

  factory ReportedEvent.fromSupabaseJson(Map<String, dynamic> json) {
    final gen = json['generated'];
    final photosRaw = json['photos'];
    final reporterIdsRaw = json['reporter_ids'];
    // Legacy : si photos vide mais photo_url set, l'utiliser
    final photos = photosRaw is List
        ? photosRaw.map((e) => e.toString()).toList()
        : <String>[];
    if (photos.isEmpty && json['photo_url'] is String) {
      photos.add(json['photo_url'] as String);
    }

    return ReportedEvent(
      id: json['id'] as String,
      reportedBy: json['reported_by'] as String,
      rawTitle: (json['raw_title'] as String?) ?? '',
      category: json['category'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      ville: json['ville'] as String?,
      locationName: (json['location_name'] as String?) ?? '',
      photos: photos,
      videos: (json['videos'] is List)
          ? (json['videos'] as List).map((e) => e.toString()).toList()
          : (json['video_url'] is String && (json['video_url'] as String).isNotEmpty)
              ? [json['video_url'] as String]
              : const <String>[],
      reportCount: (json['report_count'] as num?)?.toInt() ?? 1,
      reporterIds: reporterIdsRaw is List
          ? reporterIdsRaw.map((e) => e.toString()).toList()
          : const <String>[],
      reporterPrenom: (json['reporter_prenom'] as String?)?.trim().isNotEmpty == true
          ? (json['reporter_prenom'] as String).trim()
          : null,
      reporterAvatarUrl: (json['reporter_avatar_url'] as String?)?.isNotEmpty == true
          ? json['reporter_avatar_url'] as String
          : null,
      contributors: (json['contributors'] is List)
          ? (json['contributors'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ReportedEventContributor.fromJson)
              .toList()
          : const <ReportedEventContributor>[],
      status: json['status'] as String,
      generated: gen is Map<String, dynamic>
          ? ReportedEventGenerated.fromJson(gen)
          : null,
      startsAt: DateTime.parse(json['starts_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Un contributeur d'un signalement (multi-reporters).
class ReportedEventContributor {
  final String userId;
  final String prenom;
  final String? avatarUrl;

  const ReportedEventContributor({
    required this.userId,
    required this.prenom,
    this.avatarUrl,
  });

  factory ReportedEventContributor.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar_url'] as String?;
    return ReportedEventContributor(
      userId: (json['user_id'] as String?) ?? '',
      prenom: (json['prenom'] as String?) ?? 'Anonyme',
      avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
    );
  }
}

/// Affiche prefaite generee par Claude Haiku — stockee en JSONB.
class ReportedEventGenerated {
  final String title;
  final String description;
  final String mood;
  final List<String> tags;
  final String emoji;

  /// Hex #RRGGBB
  final String gradientFrom;
  final String gradientTo;

  /// Ex: "LIVE", "Dans 30 min", "Ce soir", "Demain"
  final String timeLabel;

  final String categoryInferred;

  const ReportedEventGenerated({
    required this.title,
    required this.description,
    required this.mood,
    required this.tags,
    required this.emoji,
    required this.gradientFrom,
    required this.gradientTo,
    required this.timeLabel,
    required this.categoryInferred,
  });

  factory ReportedEventGenerated.fromJson(Map<String, dynamic> json) {
    return ReportedEventGenerated(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      mood: (json['mood'] as String?) ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? const <String>[],
      emoji: (json['emoji'] as String?) ?? '📍',
      gradientFrom: (json['gradient_from'] as String?) ?? '#7C3AED',
      gradientTo: (json['gradient_to'] as String?) ?? '#EC4899',
      timeLabel: (json['time_label'] as String?) ?? 'LIVE',
      categoryInferred: (json['category_inferred'] as String?) ?? '',
    );
  }
}
