import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/widgets/star_rating.dart';
import 'package:pulz_app/features/engagement/presentation/widgets/engagement_avatar.dart';
import 'package:pulz_app/features/reviews/data/commerce_review_service.dart';
import 'package:pulz_app/features/reviews/domain/models/commerce_review.dart';
import 'package:pulz_app/features/reviews/presentation/review_compose_sheet.dart';
import 'package:pulz_app/features/reviews/state/commerce_summaries_provider.dart';

/// Cible d'un commerce notable. Passe a `ItemDetailSheet` via `reviewsTarget`
/// pour afficher la section avis + bouton "Donner mon avis".
class ReviewsTarget {
  final String kind; // 'venue' | 'etablissement'
  final int id;
  final String name;

  const ReviewsTarget({
    required this.kind,
    required this.id,
    required this.name,
  });
}

class _ReviewsState {
  final List<UnifiedCommerceReview> reviews;
  final CommerceReview? mine;
  final CommerceReviewSummary? summary;

  const _ReviewsState({
    required this.reviews,
    required this.mine,
    required this.summary,
  });
}

/// Provider qui charge en bloc reviews + my review + summary pour une cible.
/// Tag de cache : "<kind>:<id>".
final _reviewsLoaderProvider = FutureProvider.autoDispose
    .family<_ReviewsState, String>((ref, key) async {
  final parts = key.split(':');
  final kind = parts[0];
  final id = int.parse(parts[1]);
  final svc = CommerceReviewService();
  final deviceUuid = await UserIdentityService.getUserId();

  final results = await Future.wait<dynamic>([
    svc.listForTarget(targetKind: kind, targetId: id),
    svc.summaryForTarget(targetKind: kind, targetId: id),
    svc.getMyReview(targetKind: kind, targetId: id, deviceUuid: deviceUuid),
  ]);
  return _ReviewsState(
    reviews: results[0] as List<UnifiedCommerceReview>,
    summary: results[1] as CommerceReviewSummary?,
    mine: results[2] as CommerceReview?,
  );
});

/// Section "Avis" pour un commerce, embarquee dans le bottom sheet de detail.
/// Affiche la moyenne + count, la liste des avis, et un bouton pour
/// donner / modifier son propre avis.
class ReviewsSection extends ConsumerWidget {
  final ReviewsTarget target;

  const ReviewsSection({super.key, required this.target});

  String get _key => '${target.kind}:${target.id}';

  void _openCompose(
    BuildContext context,
    WidgetRef ref,
    CommerceReview? existing,
  ) {
    ReviewComposeSheet.show(
      context,
      targetKind: target.kind,
      targetId: target.id,
      commerceName: target.name,
      existing: existing,
      onSubmitted: () {
        ref.invalidate(_reviewsLoaderProvider(_key));
        // Refresh la pastille des cartes de liste pour ce commerce.
        ref
            .read(commerceSummariesProvider.notifier)
            .refresh(target.kind, target.id);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_reviewsLoaderProvider(_key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section : titre + summary
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Avis',
              style: GoogleFonts.geist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 10),
            dataAsync.when(
              data: (s) => _SummaryPill(summary: s.summary),
              loading: () => const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white54,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // CTA donner / modifier
        dataAsync.when(
          data: (s) => SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openCompose(context, ref, s.mine),
              icon: Icon(
                s.mine == null
                    ? Icons.rate_review_outlined
                    : Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                s.mine == null ? 'Donner mon avis' : 'Modifier mon avis',
                style: GoogleFonts.geist(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Liste des avis
        dataAsync.when(
          data: (s) {
            if (s.reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Aucun avis pour le moment. Sois le premier !',
                  style: GoogleFonts.geist(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: s.reviews
                    .take(8) // limite affichage MVP
                    .map(
                      (r) => _ReviewTile(
                        review: r,
                        isMine: s.mine?.id == r.id,
                      ),
                    )
                    .toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Impossible de charger les avis',
              style: GoogleFonts.geist(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final CommerceReviewSummary? summary;

  const _SummaryPill({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null || summary!.reviewCount == 0) {
      return Text(
        'Pas encore note',
        style: GoogleFonts.geist(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final s = summary!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(value: s.avgRating, size: 13),
        const SizedBox(width: 6),
        Text(
          s.avgRating.toStringAsFixed(1),
          style: GoogleFonts.geist(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${s.reviewCount})',
          style: GoogleFonts.geist(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final UnifiedCommerceReview review;
  final bool isMine;

  const _ReviewTile({required this.review, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMM yyyy', 'fr_FR').format(review.createdAt);
    final hasAuthor = review.displayName.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isMine ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: isMine
            ? Border.all(color: Colors.white.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasAuthor) ...[
                EngagementAvatar(
                  displayName: review.displayName,
                  gender: review.gender.isEmpty ? 'F' : review.gender,
                  avatarUrl: review.avatarUrl,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  review.displayName,
                  style: GoogleFonts.geist(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              StarRating(value: review.rating.toDouble(), size: 12),
              const SizedBox(width: 8),
              Text(
                formatted,
                style: GoogleFonts.geist(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Toi',
                    style: GoogleFonts.geist(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: GoogleFonts.geist(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
