import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';

class MonumentVenueCard extends ConsumerWidget {
  final MonumentVenue monument;

  const MonumentVenueCard({super.key, required this.monument});

  static const _typeEmojis = {
    'Hotel particulier': '\uD83C\uDFDB\uFE0F',
    'Vestige': '\uD83C\uDFF0',
    'Edifice religieux': '\u26EA',
    'Pont': '\uD83C\uDF09',
    'Ouvrage hydraulique': '\u2699\uFE0F',
    'Immeuble': '\uD83C\uDFE0',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final emoji = _typeEmojis[monument.type] ?? '\uD83C\uDFF0';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pochette a gauche ──
            SizedBox(
              width: 90,
              child: Container(
                color: modeTheme.primaryColor.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: modeTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        monument.type,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: modeTheme.primaryDarkColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monument.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monument.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: modeTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            monument.adresse,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(monument.lienMaps),
                          child: Icon(
                            Icons.map_outlined,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openUrl(monument.websiteUrl),
                          child: Icon(
                            Icons.language,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _share(),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
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
    buffer.writeln(monument.name);
    buffer.writeln(monument.description);
    buffer.writeln(monument.adresse);
    buffer.writeln(monument.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
