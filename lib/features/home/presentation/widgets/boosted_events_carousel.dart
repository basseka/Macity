import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';

/// Carrousel horizontal des events boostés P1 — visibilité maximale.
class BoostedEventsCarousel extends ConsumerWidget {
  const BoostedEventsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(boostedEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return _buildCarousel(context, events);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCarousel(BuildContext context, List<UserEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: _ShimmerTitle(),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _BoostedCard(event: events[index], allEvents: events, index: index),
          ),
        ),
      ],
    );
  }
}

class _BoostedCard extends StatelessWidget {
  final UserEvent event;
  final List<UserEvent> allEvents;
  final int index;
  const _BoostedCard({required this.event, required this.allEvents, required this.index});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.resolvedPhoto != null && event.resolvedPhoto!.isNotEmpty;
    final parsed = DateTime.tryParse(event.date);
    final dateLabel = parsed != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(parsed)
        : event.date;

    return GestureDetector(
      onTap: () => EventFullscreenPopup.showPaged(
        context,
        events: allEvents.map((e) => e.toEvent()).toList(),
        initialIndex: index,
        fallbackAssetBuilder: (_) => 'assets/images/pochette_default.jpg',
        badge: 'A la une',
      ),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (hasPhoto && event.resolvedPhoto!.startsWith('http'))
              CachedNetworkImage(
                imageUrl: event.resolvedPhoto!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _gradientBg(),
              )
            else
              _gradientBg(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Badge BOOST
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFE91E8C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'SPONSORISE',
                      style: GoogleFonts.poppins(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 10, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      if (event.heure.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 10, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          event.heure,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (event.lieuNom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF4A1259)],
        ),
      ),
    );
  }
}

/// Carrousel horizontal des events boostés P2 — "Au top".
class BoostedP2Carousel extends ConsumerWidget {
  const BoostedP2Carousel({super.key});

  static const _accentColor = Color(0xFFE91E8C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(boostedP2EventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: _ShimmerTitleAuTop(),
            ),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _P2Card(event: events[index], allEvents: events, index: index),
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

class _P2Card extends StatelessWidget {
  final UserEvent event;
  final List<UserEvent> allEvents;
  final int index;
  const _P2Card({required this.event, required this.allEvents, required this.index});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.resolvedPhoto != null &&
        event.resolvedPhoto!.isNotEmpty &&
        event.resolvedPhoto!.startsWith('http');
    final parsed = DateTime.tryParse(event.date);
    final dateLabel = parsed != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(parsed)
        : event.date;

    return GestureDetector(
      onTap: () => EventFullscreenPopup.showPaged(
        context,
        events: allEvents.map((e) => e.toEvent()).toList(),
        initialIndex: index,
        fallbackAssetBuilder: (_) => 'assets/images/pochette_default.jpg',
        badge: 'Au top',
      ),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE91E8C).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: event.resolvedPhoto!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFF2D1B4E)),
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF2D1B4E)),
                      )
                    : Container(
                        color: const Color(0xFF2D1B4E),
                        child: const Icon(Icons.event, color: Colors.white24, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.titre,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 9, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (event.lieuNom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 9, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre "A la une" avec effet shimmer/scintillement dore.
class _ShimmerTitle extends StatefulWidget {
  const _ShimmerTitle();

  @override
  State<_ShimmerTitle> createState() => _ShimmerTitleState();
}

class _ShimmerTitleState extends State<_ShimmerTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 3.0 * _ctrl.value, 0),
              end: Alignment(-0.5 + 3.0 * _ctrl.value, 0),
              colors: const [
                Colors.white,
                Color(0xFFFFD700),
                Colors.white,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child!,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rocket_launch, size: 18),
          const SizedBox(width: 8),
          Text(
            'A la une',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre "Au top" avec effet shimmer rose/blanc.
class _ShimmerTitleAuTop extends StatefulWidget {
  const _ShimmerTitleAuTop();

  @override
  State<_ShimmerTitleAuTop> createState() => _ShimmerTitleAuTopState();
}

class _ShimmerTitleAuTopState extends State<_ShimmerTitleAuTop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 3.0 * _ctrl.value, 0),
              end: Alignment(-0.5 + 3.0 * _ctrl.value, 0),
              colors: const [
                Colors.white,
                Color(0xFFE91E8C),
                Colors.white,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child!,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 18),
          const SizedBox(width: 8),
          Text(
            'Au top',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
