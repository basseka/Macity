import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.asset(dance.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
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
                      dance.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    if (dance.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        dance.horaires,
                        modeTheme.primaryColor,
                      ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (dance.websiteUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(dance.websiteUrl!),
                            child: Icon(
                              Icons.language,
                              color: modeTheme.primaryColor,
                              size: 16,
                            ),
                          ),
                        if (dance.websiteUrl != null)
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
        title: dance.name,
        emoji: '\uD83D\uDC83',
        imageAsset: dance.image,
        infos: [
          if (dance.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, dance.description),
          if (dance.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, dance.horaires),
          if (dance.city.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, dance.city),
        ],
        primaryAction: dance.websiteUrl != null
            ? DetailAction(icon: Icons.language, label: 'Site web', url: dance.websiteUrl!)
            : null,
        shareText: '${dance.name}\n${dance.description}\n${dance.city}\n${dance.websiteUrl ?? ''}\n\nDecouvre sur MaCity',
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
