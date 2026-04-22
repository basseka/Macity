import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/reported_events/presentation/reported_event_detail_sheet.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_poster_card.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_view_tracker.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';

/// Tier de popularite d'un signalement.
enum _HeatTier { hot, warm, normal }

_HeatTier _tierFor(ReportedEvent e, int maxScore) {
  final score = e.photos.length + e.reportCount;
  // hot : top score et au moins 2 personnes differentes (reportCount >= 2)
  if (score >= 4 && score == maxScore) return _HeatTier.hot;
  // warm : confirme par au moins 2 personnes OU 2+ photos
  if (e.reportCount >= 2 || e.photos.length >= 2) return _HeatTier.warm;
  return _HeatTier.normal;
}

/// Carrousel horizontal des affiches de signalements communautaires.
/// Les affiches sont triees par activite et les plus populaires ressortent.
class ReportedEventsCarousel extends ConsumerStatefulWidget {
  const ReportedEventsCarousel({super.key});

  @override
  ConsumerState<ReportedEventsCarousel> createState() =>
      _ReportedEventsCarouselState();
}

class _ReportedEventsCarouselState extends ConsumerState<ReportedEventsCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(reportedEventsFeedProvider);

    return eventsAsync.when(
      data: (allEvents) {
        // Filtrer par ville selectionnee (bounding box ~25km)
        final city = ref.watch(selectedCityProvider);
        final bbox = CityCenters.boundingBox(city);
        final events = bbox != null
            ? allEvents.where((e) =>
                e.lat >= bbox.minLat && e.lat <= bbox.maxLat &&
                e.lng >= bbox.minLng && e.lng <= bbox.maxLng).toList()
            : allEvents;

        if (events.isEmpty) return const _EmptyHint();

        // Trier par score decroissant (photos + reports)
        final sorted = [...events]..sort((a, b) {
            final scoreA = a.photos.length + a.reportCount;
            final scoreB = b.photos.length + b.reportCount;
            return scoreB.compareTo(scoreA);
          });

        final maxScore = sorted.first.photos.length + sorted.first.reportCount;

        return SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final event = sorted[index];
              final tier = _tierFor(event, maxScore);
              final bubbleSize = tier == _HeatTier.hot
                  ? 64.0
                  : (tier == _HeatTier.warm ? 58.0 : 54.0);

              final card = ReportedEventViewTracker(
                eventId: event.id,
                child: ReportedEventPosterCard(
                  event: event,
                  width: bubbleSize,
                  height: bubbleSize,
                  circular: true,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _PagedDetailSheet(
                      events: sorted,
                      initialIndex: index,
                    ),
                  ),
                ),
              );

              if (tier == _HeatTier.normal) return Center(child: card);

              // Ring colore autour de la bulle (hot = anime, warm = fixe).
              if (tier == _HeatTier.hot) {
                return Center(
                  child: AnimatedBuilder(
                    animation: _blinkAnim,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                AppColors.violet,
                                AppColors.magenta,
                                _blinkAnim.value,
                              )!,
                              Color.lerp(
                                AppColors.magenta,
                                AppColors.violet,
                                _blinkAnim.value,
                              )!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.magenta.withValues(
                                alpha: 0.5 * _blinkAnim.value,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: card,
                  ),
                );
              }

              // Warm : ring magenta fixe
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.magenta, AppColors.violet],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.magenta.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: card,
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 58,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.magenta,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.magenta, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Personne n\'a encore signale par ici. Sois le premier !',
              style: GoogleFonts.geist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Detail sheet swipable (PageView entre affiches)
// ───────────────────────────────────────────

class _PagedDetailSheet extends StatefulWidget {
  final List<ReportedEvent> events;
  final int initialIndex;

  const _PagedDetailSheet({
    required this.events,
    required this.initialIndex,
  });

  @override
  State<_PagedDetailSheet> createState() => _PagedDetailSheetState();
}

class _PagedDetailSheetState extends State<_PagedDetailSheet> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dots indicateur
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.events.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  gradient: i == _current ? AppGradients.primary : null,
                  color: i == _current ? null : AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
        // PageView des detail sheets
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.events.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) => ReportedEventDetailSheet(
              event: widget.events[index],
            ),
          ),
        ),
      ],
    );
  }
}
