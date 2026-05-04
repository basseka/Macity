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
