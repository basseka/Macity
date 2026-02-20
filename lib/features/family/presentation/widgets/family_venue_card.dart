import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class FamilyVenueCard extends ConsumerWidget {
  final CommerceModel commerce;

  const FamilyVenueCard({super.key, required this.commerce});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Card(
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
                // Emoji avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: modeTheme.chipBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    commerce.categoryEmoji,
                    style: const TextStyle(fontSize: 24),
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

                      // Horaires
                      if (commerce.horaires.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                commerce.horaires,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Maps button
                if (commerce.lienMaps.isNotEmpty)
                  _buildActionButton(
                    icon: Icons.map_outlined,
                    label: 'Maps',
                    color: modeTheme.primaryColor,
                    onTap: () => _openMaps(),
                  ),

                if (commerce.telephone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Appeler',
                    color: modeTheme.primaryColor,
                    onTap: () => _callPhone(),
                  ),
                ],

                const SizedBox(width: 8),
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

  Future<void> _openMaps() async {
    final uri = Uri.tryParse(commerce.lienMaps);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _callPhone() async {
    final uri = Uri(scheme: 'tel', path: commerce.telephone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
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
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
