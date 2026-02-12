import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';

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
              width: 110,
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
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      museum.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Categorie
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: modeTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Ville
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      museum.city,
                      modeTheme.primaryColor,
                    ),

                    // Description
                    if (museum.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildInfoRow(
                        Icons.info_outline,
                        museum.description,
                        modeTheme.primaryColor,
                      ),
                    ],

                    const Spacer(),

                    // Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Billetterie
                        if (museum.hasOnlineTicket && museum.ticketUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(museum.ticketUrl!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: modeTheme.primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 12,
                                    color: modeTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Billetterie',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: modeTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Site web
                        GestureDetector(
                          onTap: () => _openUrl(museum.websiteUrl),
                          child: Icon(
                            Icons.language,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Share
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
