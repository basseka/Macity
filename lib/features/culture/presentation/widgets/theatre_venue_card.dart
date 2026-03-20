import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';

class TheatreVenueCard extends ConsumerWidget {
  final TheatreVenue theatre;

  const TheatreVenueCard({super.key, required this.theatre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(theatreVenueEventsProvider(theatre.id));
    final eventCount = eventsAsync.whenOrNull(data: (e) => e.length) ?? 0;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Pochette arrondie à gauche ──
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VenueImage(imageUrl: theatre.image, defaultAsset: 'assets/images/pochette_theatre.png'),
                    ),
                    if (theatre.hasOnlineTicket)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BILLETTERIE',
                            style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    // ── Badge compteur events ──
                    if (eventCount > 0)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: modeTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$eventCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theatre.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // ── Nombre de spectacles ──
                    eventsAsync.when(
                      data: (events) => Text(
                        events.isEmpty
                            ? 'Aucun spectacle a venir'
                            : '${events.length} spectacle${events.length > 1 ? 's' : ''} a venir',
                        style: TextStyle(
                          fontSize: 10,
                          color: events.isEmpty ? Colors.grey.shade400 : modeTheme.primaryColor,
                          fontWeight: events.isEmpty ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      loading: () => Text(
                        'Chargement...',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (theatre.websiteUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(theatre.websiteUrl!),
                            child: Icon(
                              Icons.language,
                              color: modeTheme.primaryColor,
                              size: 16,
                            ),
                          ),
                        if (theatre.websiteUrl != null)
                          const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _share(),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _openDetail(BuildContext context) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: theatre.name,
        imageAsset: theatre.image.isNotEmpty ? theatre.image : 'assets/images/pochette_theatre.png',
        infos: [
          if (theatre.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, theatre.description),
          if (theatre.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, theatre.horaires),
          if (theatre.city.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, theatre.city),
        ],
        primaryAction: theatre.websiteUrl != null
            ? DetailAction(icon: Icons.language, label: 'Site web', url: theatre.websiteUrl!)
            : null,
        shareText: '${theatre.name}\n${theatre.description}\n${theatre.city}\n${theatre.websiteUrl ?? ''}\n\nDecouvre sur MaCity',
        imageHeightFraction: 0.15,
        extraContent: Consumer(
          builder: (_, ref, __) {
            final asyncEvents = ref.watch(theatreVenueEventsProvider(theatre.id));
            return asyncEvents.when(
              data: (events) => events.isNotEmpty
                  ? _buildProgrammation(events)
                  : const SizedBox.shrink(),
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgrammation(List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programmation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 8),
        ...events.map((e) => _buildEventTile(e)),
      ],
    );
  }

  Widget _buildEventTile(Event event) {
    final hasUrl = event.reservationUrl.isNotEmpty;
    final hasPhoto = event.photoPath != null && event.photoPath!.startsWith('http');
    return GestureDetector(
      onTap: hasUrl ? () => _openUrl(event.reservationUrl) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPhoto)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: event.photoPath!,
                    width: 45,
                    height: 63,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 45,
                      height: 63,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.theater_comedy,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 45,
                      height: 63,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.theater_comedy,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              Icon(
                Icons.theater_comedy,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titre,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                      decoration: hasUrl ? TextDecoration.underline : null,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.datesAffichageHoraires.isNotEmpty ||
                      event.type.isNotEmpty)
                    Text(
                      [
                        if (event.datesAffichageHoraires.isNotEmpty)
                          event.datesAffichageHoraires,
                        if (event.type.isNotEmpty) event.type,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasUrl)
              Icon(
                Icons.open_in_new,
                size: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(theatre.name);
    if (theatre.description.isNotEmpty) {
      buffer.writeln(theatre.description);
    }
    buffer.writeln(theatre.city);
    if (theatre.websiteUrl != null) {
      buffer.writeln(theatre.websiteUrl);
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
