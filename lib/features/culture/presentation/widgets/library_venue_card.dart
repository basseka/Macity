import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';

class LibraryVenueCard extends ConsumerWidget {
  final LibraryVenue library;

  const LibraryVenueCard({super.key, required this.library});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

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
            // ── Bulle image a gauche ──
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: modeTheme.primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(library.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
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
                      library.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (library.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        library.horaires,
                        modeTheme.primaryColor,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(library.websiteUrl),
                          child: Icon(
                            Icons.language,
                            color: modeTheme.primaryColor,
                            size: 16,
                          ),
                        ),
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
        title: library.name,
        emoji: '\uD83D\uDCDA',
        imageAsset: library.image,
        infos: [
          if (library.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, library.horaires),
          if (library.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, library.adresse),
        ],
        primaryAction: library.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: library.websiteUrl)
            : null,
        shareText: '${library.name}\n${library.adresse}\n${library.horaires}\n${library.websiteUrl}\n\nDecouvre sur MaCity',
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    buffer.writeln(library.name);
    buffer.writeln(library.adresse);
    buffer.writeln(library.horaires);
    buffer.writeln(library.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
