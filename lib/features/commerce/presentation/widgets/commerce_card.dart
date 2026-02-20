import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class CommerceCard extends ConsumerWidget {
  final CommerceModel commerce;

  const CommerceCard({super.key, required this.commerce});

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
            // Top row: emoji + name + badges
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

                // Name + distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commerce.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (commerce.distance.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.near_me_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                commerce.distance,
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

                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Ouvert badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: commerce.ouvert
                            ? const Color(0xFF7B2D8E).withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        commerce.ouvert ? 'Ouvert' : 'Ferme',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: commerce.ouvert
                              ? const Color(0xFF059669)
                              : Colors.red.shade700,
                        ),
                      ),
                    ),

                    // Independant badge
                    if (commerce.independant) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: modeTheme.chipBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Independant',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: modeTheme.chipTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Divider(height: 1, color: Colors.grey.shade200),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Maps button
                if (commerce.lienMaps.isNotEmpty)
                  _buildActionButton(
                    icon: Icons.map_outlined,
                    label: 'Maps',
                    color: modeTheme.primaryColor,
                    onTap: () => _openMaps(),
                  ),

                // Phone button
                if (commerce.telephone.isNotEmpty)
                  _buildActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Appeler',
                    color: modeTheme.primaryColor,
                    onTap: () => _callPhone(),
                  ),

                // Share button
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
    final uri = Uri.parse(commerce.lienMaps);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final uri = Uri(scheme: 'tel', path: commerce.telephone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
    if (commerce.telephone.isNotEmpty) {
      buffer.writeln('Tel: ${commerce.telephone}');
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
