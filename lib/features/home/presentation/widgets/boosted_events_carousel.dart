import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';
import 'package:pulz_app/features/admin/presentation/widgets/admin_pin_gesture.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/engagement/domain/event_source_detector.dart';
import 'package:pulz_app/features/engagement/presentation/widgets/engagement_stats_row.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';

String _eventSourceFor(UserEvent e) => detectEventSource(e.id);

/// Carrousel horizontal des events boostés P1 — visibilité maximale.
class BoostedEventsCarousel extends ConsumerWidget {
  const BoostedEventsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(boostedEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return _buildCarousel(
          context,
          events,
          () => ref.read(navBarIndexProvider.notifier).state = 1,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    List<UserEvent> events,
    VoidCallback onSeeAll,
  ) {
    // Hero : chaque card occupe la largeur ecran - 32px de marge L/R.
    // PageView avec snap pour toujours centrer la card visible.
    final cardWidth = MediaQuery.of(context).size.width - 32;
    final cardHeight = cardWidth / 1.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: _SectionTitle(
            prefix: 'À la',
            accent: 'une',
            icon: Icons.star,
            onSeeAll: onSeeAll,
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            itemCount: events.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BoostedCard(
                event: events[index],
                allEvents: events,
                index: index,
                width: cardWidth,
              ),
            ),
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
  final double width;
  const _BoostedCard({
    required this.event,
    required this.allEvents,
    required this.index,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.resolvedPhoto != null && event.resolvedPhoto!.isNotEmpty;
    final parsed = DateTime.tryParse(event.date);
    final dateLabel = parsed != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(parsed)
        : event.date;

    return AdminPinGesture(
      source: AdminPinSource.userEvents,
      identifiant: event.id,
      eventName: event.titre,
      dateFin: event.dateFin,
      dateDebutFallback: event.date,
      child: GestureDetector(
      onTap: () => EventFullscreenPopup.showPaged(
        context,
        events: allEvents.map((e) => e.toEvent()).toList(),
        initialIndex: index,
        fallbackAssetBuilder: (_) => 'assets/images/pochette_default.jpg',
        badge: 'A la une',
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 8),
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
                placeholder: (_, __) => _gradientBg(),
                errorWidget: (_, __, ___) => _gradientBg(),
              )
            else
              _gradientBg(),

            // Bottom shade (AppColors.bg transparent -> opaque)
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.cardShade),
            ),

            // Badge categorie / EPINGLE (admin) — pill arrondi
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  gradient: event.priority == 'ADMIN'
                      ? AppGradients.editorial
                      : const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFF3D8B), Color(0xFFFB923C)],
                        ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      event.priority == 'ADMIN'
                          ? Icons.push_pin
                          : Icons.local_fire_department,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (event.priority == 'ADMIN'
                              ? 'ÉPINGLÉ'
                              : (event.categorie.isNotEmpty
                                  ? event.categorie
                                  : 'À LA UNE'))
                          .toUpperCase(),
                      style: GoogleFonts.geistMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Coeur outline haut-droite
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.28),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    style: GoogleFonts.geist(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '$dateLabel${event.heure.isNotEmpty ? ' · ${event.heure}' : ''}',
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (event.lieuNom.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: EngagementStatsRow(
                          eventSource: _eventSourceFor(event),
                          eventIdentifiant: event.id,
                          eventTitle: event.titre,
                          iconColor: Colors.white,
                          textColor: Colors.white,
                          iconSize: 14,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'En savoir plus',
                              style: GoogleFonts.geist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward,
                                size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceHi],
        ),
      ),
    );
  }
}

/// Carrousel horizontal des events boostés P2 — "Au top".
class BoostedP2Carousel extends ConsumerWidget {
  const BoostedP2Carousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(boostedP2EventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        // Meme dimensions que "A la une" (ratio 1.2) pour un swap visuel
        // cohérent quand l'utilisateur toggle entre les deux pills.
        final cardWidth = MediaQuery.of(context).size.width - 32;
        final cardHeight = cardWidth / 1.2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _SectionTitle(
                prefix: 'Au',
                accent: 'top',
                icon: Icons.trending_up,
              ),
            ),
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                itemCount: events.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _P2Card(
                    event: events[index],
                    allEvents: events,
                    index: index,
                    width: cardWidth,
                  ),
                ),
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
  final double width;
  const _P2Card({
    required this.event,
    required this.allEvents,
    required this.index,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.resolvedPhoto != null &&
        event.resolvedPhoto!.isNotEmpty &&
        event.resolvedPhoto!.startsWith('http');
    final parsed = DateTime.tryParse(event.date);
    final dateLabel = parsed != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(parsed)
        : event.date;

    return AdminPinGesture(
      source: AdminPinSource.userEvents,
      identifiant: event.id,
      eventName: event.titre,
      dateFin: event.dateFin,
      dateDebutFallback: event.date,
      child: GestureDetector(
      onTap: () => EventFullscreenPopup.showPaged(
        context,
        events: allEvents.map((e) => e.toEvent()).toList(),
        initialIndex: index,
        fallbackAssetBuilder: (_) => 'assets/images/pochette_default.jpg',
        badge: 'Au top',
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image full-bleed
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: event.resolvedPhoto!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _gradientBgP2(),
                errorWidget: (_, __, ___) => _gradientBgP2(),
              )
            else
              _gradientBgP2(),

            // Shade bas pour lisibilite du texte overlay
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.cardShade),
            ),

            // Badge AU TOP / EPINGLE
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: event.priority == 'ADMIN'
                      ? AppGradients.editorial
                      : AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  boxShadow: AppShadows.neon(
                    event.priority == 'ADMIN'
                        ? const Color(0xFFFBBF24)
                        : AppColors.magenta,
                    blur: 10,
                    y: 4,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      event.priority == 'ADMIN'
                          ? Icons.push_pin
                          : Icons.trending_up,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.priority == 'ADMIN' ? 'EPINGLE' : 'AU TOP',
                      style: GoogleFonts.geistMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Texte overlay en bas (titre + date/heure + lieu + engagement)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    style: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 9, color: AppColors.textDim),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel.toUpperCase(),
                        style: GoogleFonts.geistMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: AppColors.textDim,
                        ),
                      ),
                      if (event.heure.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time,
                            size: 9, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text(
                          event.heure,
                          style: GoogleFonts.geistMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (event.lieuNom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 9, color: AppColors.textFaint),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.geist(
                              fontSize: 10,
                              color: AppColors.textFaint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  EngagementStatsRow(
                    eventSource: _eventSourceFor(event),
                    eventIdentifiant: event.id,
                    eventTitle: event.titre,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    iconSize: 11,
                    fontSize: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _gradientBgP2() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFFF1A6E)],
        ),
      ),
    );
  }
}

/// Titre de section : "{prefix} {accent}" ou l'accent est en Instrument
/// Serif italique + gradient editorial (magenta -> amber).
class _SectionTitle extends StatelessWidget {
  final String prefix;
  final String accent;
  final IconData icon;
  final VoidCallback? onSeeAll;
  const _SectionTitle({
    required this.prefix,
    required this.accent,
    required this.icon,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.magenta),
        const SizedBox(width: 6),
        Text(
          prefix,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          accent,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: const Color(0xFFFB923C),
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voir tout',
                  style: GoogleFonts.geist(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: const Color(0xFFA855F7),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: Color(0xFFA855F7),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
