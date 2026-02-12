import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';

class TheatreVenueCard extends ConsumerWidget {
  final TheatreVenue theatre;

  const TheatreVenueCard({super.key, required this.theatre});

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
            // ── Pochette a gauche ──
            SizedBox(
              width: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(theatre.image, fit: BoxFit.cover),
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
                  if (theatre.hasOnlineTicket)
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
                        '\uD83C\uDFAD',
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
                      theatre.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    _buildInfoRow(
                      Icons.location_on_outlined,
                      theatre.city,
                      modeTheme.primaryColor,
                    ),

                    if (theatre.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildInfoRow(
                        Icons.info_outline,
                        theatre.description,
                        modeTheme.primaryColor,
                      ),
                    ],

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (theatre.hasOnlineTicket && theatre.ticketUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(theatre.ticketUrl!),
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
                        if (theatre.websiteUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(theatre.websiteUrl!),
                            child: Icon(
                              Icons.language,
                              color: modeTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                        if (theatre.websiteUrl != null)
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
    buffer.writeln(theatre.name);
    if (theatre.description.isNotEmpty) {
      buffer.writeln(theatre.description);
    }
    buffer.writeln(theatre.city);
    if (theatre.websiteUrl != null) {
      buffer.writeln(theatre.websiteUrl);
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
