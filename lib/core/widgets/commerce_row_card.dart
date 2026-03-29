import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Carte commerce en ligne : image a gauche, infos a droite.
class CommerceRowCard extends ConsumerWidget {
  final CommerceModel commerce;
  final String? imageAsset;

  const CommerceRowCard({
    super.key,
    required this.commerce,
    this.imageAsset,
  });

  /// Retourne la photo DB ou null.
  String? _resolveImage() {
    if (imageAsset != null) return imageAsset;
    if (commerce.photo.isNotEmpty && commerce.photo.startsWith('http')) {
      return commerce.photo;
    }
    return null;
  }

  Widget _buildImage(String? image, ModeTheme modeTheme) {
    // Pas de photo DB → placeholder générique
    if (image == null) {
      return Container(
        color: modeTheme.chipBgColor,
        child: Center(
          child: Icon(
            _categoryIcon(commerce.categorie),
            size: 28,
            color: modeTheme.primaryColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final src = image;
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: src,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        placeholder: (_, __) => Container(color: modeTheme.chipBgColor),
        errorWidget: (_, __, ___) => Container(color: modeTheme.chipBgColor),
      );
    }

    return Image.asset(
      src,
      fit: BoxFit.cover,
      cacheWidth: 300,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Container(color: modeTheme.chipBgColor),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final image = _resolveImage();

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Pochette image a gauche ──
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: modeTheme.primaryColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: _buildImage(image, modeTheme),
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
                      commerce.nom,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (commerce.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        commerce.horaires,
                        modeTheme.primaryColor,
                      ),
                    if (commerce.displayCount > 0)
                      _buildInfoRow(
                        Icons.people_outline,
                        '${commerce.displayCount} personnes',
                        modeTheme.primaryColor.withValues(alpha: 0.7),
                      ),

                    const SizedBox(height: 4),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildLikeIcon(ref),
                        const SizedBox(width: 8),
                        _buildActionIcon(
                          Icons.share_outlined,
                          Colors.grey.shade400,
                          () {
                            final buffer = StringBuffer();
                            buffer.writeln(commerce.nom);
                            if (commerce.adresse.isNotEmpty) {
                              buffer.writeln(commerce.adresse);
                            }
                            buffer.writeln('\nDecouvre sur MaCity');
                            Share.share(buffer.toString());
                          },
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
    final image = _resolveImage();
    final isNetwork = image != null && image.startsWith('http');
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: commerce.nom,
        emoji: '',
        imageAsset: isNetwork ? null : image,
        imageUrl: isNetwork ? image : null,
        videoUrl: commerce.videoUrl.isNotEmpty ? commerce.videoUrl : null,
        likeId: 'night_${commerce.nom}',
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
            ? DetailAction(
                icon: commerce.siteWeb.contains('instagram') ? Icons.camera_alt : Icons.language,
                label: commerce.siteWeb.contains('instagram') ? 'Instagram' : 'Site web',
                url: commerce.siteWeb,
              )
            : null,
        secondaryActions: [
          if (commerce.lienMaps.isNotEmpty)
            DetailAction(
              icon: Icons.map_outlined,
              label: 'Maps',
              url: commerce.lienMaps,
            ),
          if (commerce.telephone.isNotEmpty)
            DetailAction(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              url: 'tel:${commerce.telephone.replaceAll(' ', '')}',
            ),
        ],
        shareText: _buildShareText(),
      ),
    );
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln(commerce.nom);
    if (commerce.adresse.isNotEmpty) buffer.writeln(commerce.adresse);
    if (commerce.horaires.isNotEmpty) {
      buffer.writeln('Horaires: ${commerce.horaires}');
    }
    buffer.writeln('\nDecouvre sur MaCity');
    return buffer.toString();
  }

  static IconData _categoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurant') || cat.contains('food')) return Icons.restaurant;
    if (cat.contains('bar') || cat.contains('pub') || cat.contains('nuit')) return Icons.local_bar;
    if (cat.contains('club') || cat.contains('discotheque')) return Icons.nightlife;
    if (cat.contains('hotel')) return Icons.hotel;
    if (cat.contains('cinema')) return Icons.movie;
    if (cat.contains('theatre')) return Icons.theater_comedy;
    if (cat.contains('musee') || cat.contains('galerie')) return Icons.museum;
    if (cat.contains('fitness') || cat.contains('sport')) return Icons.fitness_center;
    if (cat.contains('piscine') || cat.contains('natation')) return Icons.pool;
    if (cat.contains('bowling')) return Icons.sports;
    if (cat.contains('gaming') || cat.contains('arcade') || cat.contains('jeux')) return Icons.sports_esports;
    if (cat.contains('manga') || cat.contains('comics') || cat.contains('boutique')) return Icons.store;
    if (cat.contains('escape')) return Icons.lock;
    if (cat.contains('laser')) return Icons.flash_on;
    if (cat.contains('parc')) return Icons.park;
    if (cat.contains('ferme')) return Icons.nature;
    if (cat.contains('patinoire')) return Icons.ice_skating;
    if (cat.contains('bibliotheque')) return Icons.menu_book;
    if (cat.contains('chicha')) return Icons.smoking_rooms;
    if (cat.contains('epicerie') || cat.contains('tabac')) return Icons.store;
    if (cat.contains('apero')) return Icons.liquor;
    if (cat.contains('vr') || cat.contains('virtuelle')) return Icons.vrpano;
    if (cat.contains('cosplay') || cat.contains('figurine')) return Icons.emoji_objects;
    return Icons.place;
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

  Widget _buildLikeIcon(WidgetRef ref) {
    final likeId = 'night_${commerce.nom}';
    final isLiked = ref.watch(likesProvider).contains(likeId);
    return GestureDetector(
      onTap: () => ref.read(likesProvider.notifier).toggle(
        likeId,
        meta: LikeMetadata(
          title: commerce.nom,
          imageUrl: commerce.photo.isNotEmpty ? commerce.photo : null,
          category: commerce.categorie,
        ),
      ),
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        size: 16,
        color: isLiked ? Colors.red : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 16, color: color),
    );
  }
}
