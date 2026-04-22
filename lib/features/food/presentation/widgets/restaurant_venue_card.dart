import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';

class RestaurantVenueCard extends ConsumerWidget {
  final RestaurantVenue venue;

  const RestaurantVenueCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: modeTheme.primaryColor.withValues(alpha: 0.08),
                ),
                alignment: Alignment.center,
                child: const Text('\u{1F37D}\u{FE0F}', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: modeTheme.primaryDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (venue.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge.small(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (venue.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        venue.horaires,
                        modeTheme.primaryColor,
                      )
                    else if (venue.adresse.isNotEmpty)
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        venue.adresse,
                        modeTheme.primaryColor,
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _share(),
                child: Icon(
                  Icons.share_outlined,
                  color: AppColors.textFaint,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _defaultRestaurantPhotos = [
    'assets/images/plat-01.png',
    'assets/images/plat-02.png',
    'assets/images/plat-03.png',
    'assets/images/plat-04.png',
    'assets/images/plat-05.png',
    'assets/images/plat-06.png',
  ];

  void _openDetail(BuildContext context) {
    final photos = <String>[];
    if (venue.photo.isNotEmpty && venue.photo.startsWith('http')) {
      photos.add(venue.photo);
    }
    // Completer avec les photos generiques
    for (final p in _defaultRestaurantPhotos) {
      if (photos.length >= 6) break;
      if (!photos.contains(p)) photos.add(p);
    }

    final hasNetworkImage = venue.photo.isNotEmpty && venue.photo.startsWith('http');

    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: venue.name,
        emoji: '\u{1F37D}\u{FE0F}',
        imageAsset: hasNetworkImage ? null : 'assets/images/pochette_restaurant.jpg',
        imageUrl: hasNetworkImage ? venue.photo : null,
        photoGallery: photos,
        infos: [
          if (venue.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, venue.description),
          if (venue.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, venue.horaires),
          if (venue.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, venue.adresse),
          if (venue.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, venue.telephone),
        ],
        primaryAction: venue.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: venue.websiteUrl)
            : null,
        secondaryActions: [
          if (venue.lienMaps.isNotEmpty)
            DetailAction(icon: Icons.map_outlined, label: 'Maps', url: venue.lienMaps),
          if (venue.telephone.isNotEmpty)
            DetailAction(icon: Icons.phone_outlined, label: 'Appeler', url: 'tel:${venue.telephone.replaceAll(' ', '')}'),
        ],
        shareText: '${venue.name}\n${venue.adresse}\n${venue.telephone.isNotEmpty ? venue.telephone + '\n' : ''}${venue.websiteUrl}\n\nDecouvre sur MaCity',
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
            style: TextStyle(fontSize: 11, color: AppColors.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Impossible d\'ouvrir le lien: $e');
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(venue.name);
    buffer.writeln(venue.adresse);
    if (venue.telephone.isNotEmpty) buffer.writeln(venue.telephone);
    buffer.writeln(venue.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
