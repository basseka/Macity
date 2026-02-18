import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';

class MuseumVenueCard extends ConsumerWidget {
  final MuseumVenue museum;

  const MuseumVenueCard({super.key, required this.museum});

  static const _categoryEmojis = {
    'art': '\uD83C\uDFA8',
    'histoire': '\uD83C\uDFF0',
    'science': '\uD83D\uDD2C',
    'culture': '\uD83C\uDFAD',
  };

  static const _categoryLabels = {
    'art': 'Art',
    'histoire': 'Histoire',
    'science': 'Science',
    'culture': 'Culture',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final emoji = _categoryEmojis[museum.category] ?? '\uD83C\uDFDB\uFE0F';
    final categoryLabel = _categoryLabels[museum.category] ?? museum.category;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pochette a gauche ──
            SizedBox(
              width: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(museum.image, fit: BoxFit.cover),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge billetterie en ligne
                  if (museum.hasOnlineTicket)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BILLETTERIE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Emoji badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      museum.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Horaires
                    if (museum.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        museum.horaires,
                        modeTheme.primaryColor,
                      ),

                    const Spacer(),

                    // Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(museum.websiteUrl),
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
        title: museum.name,
        emoji: _categoryEmojis[museum.category] ?? '\uD83C\uDFDB\uFE0F',
        imageAsset: museum.image,
        infos: [
          if (museum.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, museum.description),
          if (museum.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, museum.horaires),
          if (museum.city.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, museum.city),
        ],
        primaryAction: museum.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: museum.websiteUrl)
            : null,
        shareText: '${museum.name}\n${museum.description}\n${museum.city}\n${museum.websiteUrl}\n\nDecouvre sur MaCity',
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
    buffer.writeln(museum.name);
    if (museum.description.isNotEmpty) {
      buffer.writeln(museum.description);
    }
    buffer.writeln(museum.city);
    buffer.writeln(museum.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
