import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';

class DanceVenueCard extends ConsumerWidget {
  final DanceVenue dance;

  const DanceVenueCard({super.key, required this.dance});

  static const _categoryLabels = {
    'Ecole generale': 'Ecole generale',
    'Specialisation': 'Specialisation & style',
    'Formation pro': 'Formation professionnelle',
    'Autre': 'Ecole de danse',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final categoryLabel = _categoryLabels[dance.category] ?? dance.category;

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
                  Image.asset(dance.image, fit: BoxFit.cover),
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
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '\uD83D\uDC83',
                        style: TextStyle(fontSize: 14),
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
                    Text(
                      dance.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

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

                    _buildInfoRow(
                      Icons.location_on_outlined,
                      dance.city,
                      modeTheme.primaryColor,
                    ),

                    if (dance.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildInfoRow(
                        Icons.info_outline,
                        dance.description,
                        modeTheme.primaryColor,
                      ),
                    ],

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        if (dance.websiteUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(dance.websiteUrl!),
                            child: Icon(
                              Icons.language,
                              color: modeTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                        if (dance.websiteUrl != null)
                          const SizedBox(width: 10),
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
    buffer.writeln(dance.name);
    if (dance.description.isNotEmpty) {
      buffer.writeln(dance.description);
    }
    buffer.writeln(dance.city);
    if (dance.websiteUrl != null) {
      buffer.writeln(dance.websiteUrl);
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
