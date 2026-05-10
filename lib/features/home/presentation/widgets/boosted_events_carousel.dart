import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
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
        return _buildCarousel(context, events);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCarousel(BuildContext context, List<UserEvent> events) {
    // Full width hero : chaque card occupe la largeur ecran (- 32px de
    // padding L/R). PageView avec snap pour toujours centrer la card
    // visible quand l'utilisateur swipe.
    final cardWidth = MediaQuery.of(context).size.width;
    final cardHeight = cardWidth / 1.4375;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: _SectionTitle(
            prefix: 'A la',
            accent: 'une',
            icon: Icons.star,
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            itemCount: events.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.zero,
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
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
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

            // Badge EPINGLE (admin) / A LA UNE
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
                      event.priority == 'ADMIN' ? Icons.push_pin : Icons.star,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.priority == 'ADMIN' ? 'EPINGLE' : 'A LA UNE',
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
                      const Icon(Icons.calendar_today, size: 9, color: AppColors.textDim),
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
                        const Icon(Icons.access_time, size: 9, color: AppColors.textDim),
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
                        const Icon(Icons.location_on, size: 9, color: AppColors.textFaint),
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

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
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
        // Meme dimensions que "A la une" (ratio 1.4375) pour un swap visuel
        // cohérent quand l'utilisateur toggle entre les deux pills.
        final cardWidth = MediaQuery.of(context).size.width;
        final cardHeight = cardWidth / 1.4375;
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
                  padding: EdgeInsets.zero,
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
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
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
                      const Icon(Icons.calendar_today,
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
                        const Icon(Icons.access_time,
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
                        const Icon(Icons.location_on,
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
  const _SectionTitle({
    required this.prefix,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.magenta),
        const SizedBox(width: 7),
        Text(
          prefix,
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          accent,
          style: GoogleFonts.instrumentSerif(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
            foreground: Paint()
              ..shader = AppGradients.editorial.createShader(
                const Rect.fromLTWH(0, 0, 100, 28),
              ),
          ),
        ),
      ],
    );
  }
}
