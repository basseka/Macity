import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

/// Carte venue famille unifiee — remplace toutes les cartes specifiques
/// (CinemaVenueCard, BowlingVenueCard, etc.)
class FamilyVenueRowCard extends ConsumerWidget {
  final FamilyVenue venue;
  final List<CommerceModel>? pagerSiblings;
  final int? pagerIndex;

  const FamilyVenueRowCard({
    super.key,
    required this.venue,
    this.pagerSiblings,
    this.pagerIndex,
  });

  /// Convertit un [FamilyVenue] en [CommerceModel] — utilisable par les
  /// parents pour construire la liste de `pagerSiblings`.
  static CommerceModel toCommerce(FamilyVenue venue) {
    final hasPhoto = venue.photo.isNotEmpty;
    final description = [
      if (venue.description.isNotEmpty) venue.description,
      if (venue.tarif.isNotEmpty) 'Tarif : ${venue.tarif}',
    ].join('\n\n');
    return CommerceModel(
      nom: venue.name,
      categorie: venue.category,
      adresse: venue.adresse,
      ville: venue.ville,
      horaires: venue.horaires,
      telephone: venue.telephone,
      siteWeb: venue.ticketUrl.isNotEmpty ? venue.ticketUrl : venue.websiteUrl,
      lienMaps: venue.lienMaps,
      latitude: venue.latitude,
      longitude: venue.longitude,
      photo: hasPhoto ? venue.photo : '',
      description: description,
      isVerified: venue.isVerified,
    );
  }

  static const _categoryImages = <String, String>{
    "Parc d'attractions": 'assets/images/pochette_parc_attraction.webp',
    'Aire de jeux': 'assets/images/pochette_aire_de_jeu.webp',
    'Parc animalier': 'assets/images/sc_parc_animalier.jpg',
    'Ferme pedagogique': 'assets/images/pochette_ferme.webp',
    'Cinema': 'assets/images/pochette_spectacle.webp',
    'Bowling': 'assets/images/pochette_bowling.webp',
    'Laser game': 'assets/images/pochette_laser_game.webp',
    'Escape game': 'assets/images/pochette_escapegame.jpg',
    'Patinoire': 'assets/images/pochette_patinoire.webp',
    'Restaurant familial': 'assets/images/pochette_restaurant.jpg',
    'Aquarium': 'assets/images/pochette_enfamille.jpg',
  };

  String? get _fallbackImage => _categoryImages[venue.category];

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: IntrinsicHeight(
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: venue.photo.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: venue.photo,
                                fit: BoxFit.cover,
                                memCacheWidth: 400,
                                placeholder: (_, __) => _imageFallback(modeTheme),
                                errorWidget: (_, __, ___) => _imageFallback(modeTheme),
                              )
                            : _imageFallback(modeTheme),
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
                      const SizedBox(height: 4),
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
                            child: Icon(Icons.share_outlined, color: AppColors.textFaint, size: 16),
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
      ),
    );
  }

  Widget _imageFallback(ModeTheme modeTheme) {
    final asset = _fallbackImage;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: modeTheme.primaryColor.withValues(alpha: 0.08),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: modeTheme.primaryColor.withValues(alpha: 0.08),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final hasPhoto = venue.photo.isNotEmpty;
    final imageAsset = hasPhoto ? null : _fallbackImage;
    final commerce = toCommerce(venue);
    CommerceRowCard.openDetail(context, commerce,
        imageAsset: imageAsset,
        siblings: pagerSiblings,
        index: pagerIndex);
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
