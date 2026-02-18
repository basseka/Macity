import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class FitnessVenueCard extends ConsumerWidget {
  final CommerceModel commerce;

  const FitnessVenueCard({super.key, required this.commerce});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue image or fallback emoji
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: modeTheme.chipBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: commerce.photo.isNotEmpty
                        ? Image.asset(
                            commerce.photo,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : const Text(
                            '\uD83D\uDCAA',
                            style: TextStyle(fontSize: 24),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          commerce.nom,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Category
                        Text(
                          commerce.categorie,
                          style: TextStyle(
                            fontSize: 12,
                            color: modeTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Address
                        if (commerce.adresse.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  commerce.adresse,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
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

              const SizedBox(height: 12),

              // Actions row
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Site web button
                  if (commerce.siteWeb.isNotEmpty)
                    _buildActionButton(
                      icon: Icons.language,
                      label: 'Site web',
                      color: modeTheme.primaryColor,
                      onTap: () => _openWebsite(),
                    ),

                  // Maps button
                  if (commerce.lienMaps.isNotEmpty)
                    _buildActionButton(
                      icon: Icons.map_outlined,
                      label: 'Maps',
                      color: modeTheme.primaryColor,
                      onTap: () => _openMaps(),
                    ),

                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    color: Colors.grey.shade600,
                    onTap: () => _share(),
                  ),
                ],
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
        title: commerce.nom,
        emoji: '\uD83D\uDCAA',
        infos: [
          if (commerce.categorie.isNotEmpty)
            DetailInfoItem(Icons.category_outlined, commerce.categorie),
          if (commerce.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, commerce.horaires),
          if (commerce.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, commerce.adresse),
          if (commerce.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, commerce.telephone),
        ],
        primaryAction: commerce.siteWeb.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: commerce.siteWeb)
            : null,
        secondaryActions: [
          if (commerce.lienMaps.isNotEmpty)
            DetailAction(icon: Icons.map_outlined, label: 'Maps', url: commerce.lienMaps),
        ],
        shareText: '${commerce.nom}\n${commerce.categorie}\n${commerce.adresse}\n${commerce.siteWeb}\n\nDecouvre sur MaCity',
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(commerce.siteWeb);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(commerce.lienMaps);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(commerce.nom);
    if (commerce.categorie.isNotEmpty) {
      buffer.writeln(commerce.categorie);
    }
    if (commerce.adresse.isNotEmpty) {
      buffer.writeln(commerce.adresse);
    }
    if (commerce.siteWeb.isNotEmpty) {
      buffer.writeln(commerce.siteWeb);
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
