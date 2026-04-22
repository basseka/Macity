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
          padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: _SectionTitle(
            prefix: 'A la',
            accent: 'une',
            icon: Icons.star,
          ),
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
        width: 230,
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
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // Photo (avec badge pin si admin)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: event.resolvedPhoto!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surfaceHi),
                            errorWidget: (_, __, ___) => Container(color: AppColors.surfaceHi),
                          )
                        : Container(
                            color: AppColors.surfaceHi,
                            child: const Icon(Icons.event, color: AppColors.textFaint, size: 28),
                          ),
                  ),
                ),
                if (event.priority == 'ADMIN')
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: AppGradients.editorial,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: AppShadows.neon(
                          const Color(0xFFFBBF24),
                          blur: 8,
                          y: 2,
                        ),
                      ),
                      child: const Icon(Icons.push_pin, size: 10, color: Colors.white),
                    ),
                  ),
              ],
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
                    style: GoogleFonts.geist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      height: 1.2,
                      letterSpacing: -0.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 9, color: AppColors.textFaint),
                      const SizedBox(width: 3),
                      Text(
                        dateLabel.toUpperCase(),
                        style: GoogleFonts.geistMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                  if (event.lieuNom.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 9, color: AppColors.textFaint),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            event.lieuNom,
                            style: GoogleFonts.geist(
                              fontSize: 9.5,
                              color: AppColors.textFaint,
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
            fontSize: 19,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          accent,
          style: GoogleFonts.instrumentSerif(
            fontSize: 22,
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
