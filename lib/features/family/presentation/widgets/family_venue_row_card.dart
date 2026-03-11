import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

/// Carte venue famille unifiee — remplace toutes les cartes specifiques
/// (CinemaVenueCard, BowlingVenueCard, etc.)
class FamilyVenueRowCard extends ConsumerWidget {
  final FamilyVenue venue;

  const FamilyVenueRowCard({super.key, required this.venue});

  static const _categoryEmojis = <String, String>{
    "Parc d'attractions": '\uD83C\uDFA2',
    'Aire de jeux': '\uD83E\uDDD2',
    'Parc animalier': '\uD83E\uDD81',
    'Ferme pedagogique': '\uD83D\uDC04',
    'Cinema': '\uD83C\uDFAC',
    'Bowling': '\uD83C\uDFB3',
    'Laser game': '\uD83D\uDD2B',
    'Escape game': '\uD83D\uDD10',
    'Patinoire': '\u26F8\uFE0F',
    'Restaurant familial': '\uD83C\uDF54',
    'Aquarium': '\uD83D\uDC20',
  };

  String get _emoji => _categoryEmojis[venue.category] ?? '\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67';

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
              // Pochette
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: modeTheme.primaryColor.withValues(alpha: 0.08),
                        ),
                        alignment: Alignment.center,
                        child: Text(_emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      if (venue.ticketUrl.isNotEmpty)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BILLETS',
                              style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Infos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: modeTheme.primaryDarkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (venue.horaires.isNotEmpty)
                        _buildInfoRow(Icons.access_time, venue.horaires, modeTheme.primaryColor),
                      if (venue.tarif.isNotEmpty)
                        _buildInfoRow(Icons.euro, venue.tarif, modeTheme.primaryColor),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (venue.websiteUrl.isNotEmpty)
                            GestureDetector(
                              onTap: () => _openUrl(venue.websiteUrl),
                              child: Icon(Icons.language, color: modeTheme.primaryColor, size: 16),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _share(),
                            child: Icon(Icons.share_outlined, color: Colors.grey.shade400, size: 16),
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
        title: venue.name,
        emoji: _emoji,
        infos: [
          if (venue.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, venue.horaires),
          if (venue.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, venue.adresse),
          if (venue.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, venue.telephone),
          if (venue.tarif.isNotEmpty)
            DetailInfoItem(Icons.euro, venue.tarif),
          if (venue.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, venue.description),
        ],
        primaryAction: venue.ticketUrl.isNotEmpty
            ? DetailAction(icon: Icons.confirmation_number_outlined, label: 'Billets', url: venue.ticketUrl)
            : venue.websiteUrl.isNotEmpty
                ? DetailAction(icon: Icons.language, label: 'Site web', url: venue.websiteUrl)
                : null,
        secondaryActions: [
          if (venue.ticketUrl.isNotEmpty && venue.websiteUrl.isNotEmpty)
            DetailAction(icon: Icons.language, label: 'Site web', url: venue.websiteUrl),
          if (venue.telephone.isNotEmpty)
            DetailAction(icon: Icons.phone_outlined, label: 'Appeler', url: 'tel:${venue.telephone.replaceAll(' ', '')}'),
          if (venue.lienMaps.isNotEmpty)
            DetailAction(icon: Icons.map_outlined, label: 'Maps', url: venue.lienMaps),
        ],
        shareText: '${venue.name}\n${venue.adresse}\n${venue.telephone}\n${venue.websiteUrl}\n\nDecouvre sur MaCity',
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
