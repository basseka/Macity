import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/data/permanent_fake_stories.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/map_live_page.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_paged_sheet.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// "En direct autour de vous" : carrousel horizontal des stories Map Live
/// formattees en cards rectangulaires (photo + nom + temps relatif).
/// Affiche en home sous les nav tabs.
class ReportedEventsLiveStripe extends ConsumerWidget {
  const ReportedEventsLiveStripe({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(reportedEventsFeedProvider);
    return eventsAsync.when(
      data: (allEvents) {
        // Filtre par ville selectionnee (bounding box ~25km)
        final city = ref.watch(selectedCityProvider);
        final bbox = CityCenters.boundingBox(city);
        final events = bbox != null
            ? allEvents
                .where((e) =>
                    e.lat >= bbox.minLat &&
                    e.lat <= bbox.maxLat &&
                    e.lng >= bbox.minLng &&
                    e.lng <= bbox.maxLng)
                .toList()
            : allEvents;

        debugPrint('[LiveStripe] city=$city allEvents=${allEvents.length} '
            'afterBbox=${events.length}');
        if (allEvents.isNotEmpty) {
          final latest = allEvents.first;
          debugPrint('[LiveStripe] latest in DB: id=${latest.id} '
              'lat=${latest.lat} lng=${latest.lng} '
              'status=${latest.status} created=${latest.createdAt}');
        }

        // Tri chronologique inverse : les plus recents en tete.
        final realSorted = [...events]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Ordre final : stories reelles AVANT les fakes permanentes.
        // Une nouvelle publication user pousse en position 0 (gauche), les
        // 3 fakes restent en queue comme contenu de fond toujours visible.
        final sorted = [
          ...realSorted,
          ...permanentFakeStories(),
        ];

        if (sorted.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapLivePage()),
              ),
            ),
            SizedBox(
              height: 146,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Padding horizontal centre quand le contenu rentre dans
                  // la largeur ecran ; sinon padding minimal et la liste
                  // scrolle horizontalement.
                  const cardW = _LiveCard._cardWidth;
                  const sep = 10.0;
                  final contentW =
                      sorted.length * cardW + (sorted.length - 1) * sep;
                  final available = constraints.maxWidth;
                  final extra = available - contentW;
                  final pad = extra > 32 ? extra / 2 : 16.0;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: extra > 0
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(width: sep),
                    itemBuilder: (_, index) => _LiveCard(
                      event: sorted[index],
                      allEvents: sorted,
                      index: index,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'En direct ',
            style: GoogleFonts.geist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              color: AppColors.text,
            ),
          ),
          Text(
            'autour de vous',
            style: GoogleFonts.instrumentSerif(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              foreground: Paint()
                ..shader = AppGradients.editorial.createShader(
                  const Rect.fromLTWH(0, 0, 140, 20),
                ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Voir tout',
              style: GoogleFonts.geist(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC77DFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final ReportedEvent event;
  final List<ReportedEvent> allEvents;
  final int index;

  const _LiveCard({
    required this.event,
    required this.allEvents,
    required this.index,
  });

  static const _cardWidth = 100.0;
  static const _photoSize = 100.0;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photos.isNotEmpty;
    final title = event.generated?.title.isNotEmpty == true
        ? event.generated!.title
        : (event.rawTitle.isNotEmpty
            ? event.rawTitle
            : (event.locationName.isNotEmpty
                ? event.locationName
                : 'Story Map Live'));
    return GestureDetector(
      onTap: () {
        debugPrint('[LiveStripe] tap card index=$index id=${event.id}');
        ReportedEventsPagedSheet.open(
          context,
          events: allEvents,
          initialIndex: index,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo carree avec coins arrondis, badge "LIVE" en haut a gauche
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: _photoSize,
                    height: _photoSize,
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: event.firstPhoto!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.surfaceHi),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.surfaceHi),
                          )
                        : Container(
                            color: AppColors.surfaceHi,
                            alignment: Alignment.center,
                            child: Text(
                              event.generated?.emoji ?? '📍',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: AppShadows.neon(
                        const Color(0xFFEF4444),
                        blur: 6,
                        y: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'LIVE',
                          style: GoogleFonts.geistMono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _relativeTime(event.createdAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textFaint,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
