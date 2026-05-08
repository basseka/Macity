// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commerce_review.freezed.dart';
part 'commerce_review.g.dart';

/// Avis utilisateur (note 1-5 + commentaire) sur un commerce (venue ou
/// etablissement). Voir migration `20260504120000_commerce_reviews.sql`.
@freezed
class CommerceReview with _$CommerceReview {
  const factory CommerceReview({
    required String id,
    @JsonKey(name: 'target_kind') required String targetKind,
    @JsonKey(name: 'target_id') required int targetId,
    @JsonKey(name: 'device_uuid') required String deviceUuid,
    required int rating,
    @Default('') String comment,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _CommerceReview;

  factory CommerceReview.fromJson(Map<String, dynamic> json) =>
      _$CommerceReviewFromJson(json);
}

/// Avis unifié (real + fake) pour affichage en lecture seule, vient de la
/// vue `commerce_reviews_unified`. Pour les real reviews, [displayName] et
/// [gender] sont vides et [avatarUrl] null. Pour les fakes, [deviceUuid] est null.
class UnifiedCommerceReview {
  final String id;
  final String targetKind;
  final int targetId;
  final String displayName;
  final String gender;
  final String? avatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isReal;
  final String? deviceUuid;

  const UnifiedCommerceReview({
    required this.id,
    required this.targetKind,
    required this.targetId,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isReal,
    this.deviceUuid,
  });

  factory UnifiedCommerceReview.fromJson(Map<String, dynamic> json) =>
      UnifiedCommerceReview(
        id: json['id'] as String,
        targetKind: json['target_kind'] as String,
        targetId: (json['target_id'] as num).toInt(),
        displayName: (json['display_name'] as String?) ?? '',
        gender: (json['gender'] as String?) ?? '',
        avatarUrl: json['avatar_url'] as String?,
        rating: (json['rating'] as num).toInt(),
        comment: (json['comment'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        isReal: (json['is_real'] as bool?) ?? true,
        deviceUuid: json['device_uuid'] as String?,
      );
}

/// Aggregat (count + moyenne) pour une cible. Vient de la VIEW
/// `commerce_review_summary`.
@freezed
class CommerceReviewSummary with _$CommerceReviewSummary {
  const factory CommerceReviewSummary({
    @JsonKey(name: 'target_kind') required String targetKind,
    @JsonKey(name: 'target_id') required int targetId,
    @JsonKey(name: 'review_count') required int reviewCount,
    @JsonKey(name: 'avg_rating') required double avgRating,
  }) = _CommerceReviewSummary;

  factory CommerceReviewSummary.fromJson(Map<String, dynamic> json) =>
      _$CommerceReviewSummaryFromJson(json);
}
