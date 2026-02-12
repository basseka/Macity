import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/family/data/family_restaurant_venues_data.dart';

class FamilyRestaurantVenueCard extends ConsumerWidget {
  final FamilyRestaurantVenue venue;

  const FamilyRestaurantVenueCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

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
            SizedBox(
              width: 90,
              child: Container(
                color: modeTheme.primaryColor.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: const Text('\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}', style: TextStyle(fontSize: 30)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
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
                      venue.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.access_time,
                      venue.horaires,
                      modeTheme.primaryColor,
                    ),
                    const SizedBox(height: 3),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      venue.adresse,
                      modeTheme.primaryColor,
                    ),
                    if (venue.telephone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () async {
                          final cleaned = venue.telephone.replaceAll(' ', '');
                          final uri = Uri(scheme: 'tel', path: cleaned);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: modeTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              venue.telephone,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: modeTheme.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(venue.lienMaps),
                          child: Icon(
                            Icons.map_outlined,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openUrl(venue.websiteUrl),
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

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    buffer.writeln(venue.name);
    buffer.writeln(venue.adresse);
    buffer.writeln(venue.telephone);
    buffer.writeln(venue.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
