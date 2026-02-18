import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
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

  static const _defaultImages = <String, String>{
    // SOS Apero (avant les cles generiques)
    'apero toulousain': 'assets/images/sos_aperotoulousain.png',
    'speed apero': 'assets/images/sos_speedapero.png',
    'apero eclair': 'assets/images/sos_aperoeclair.png',
    'apero speed': 'assets/images/sos_aperospeed.png',
    'allo apero': 'assets/images/sos_alloapero.png',
    'bar': 'assets/images/sc_pub.png',
    'pub': 'assets/images/sc_pub.png',
    'club': 'assets/images/sc_discotheque.png',
    'discotheque': 'assets/images/sc_discotheque.png',
    'restaurant': 'assets/images/pochette_food.png',
    'cafe': 'assets/images/pochette_food.png',
    'brasserie': 'assets/images/pochette_food.png',
    'pizzeria': 'assets/images/pochette_food.png',
    'boulangerie': 'assets/images/pochette_food.png',
    'hotel': 'assets/images/sc_hotel.png',
    'musee': 'assets/images/sc_expo.png',
    'theatre': 'assets/images/sc_theatre.png',
    'cinema': 'assets/images/pochette_spectacle.png',
    'bowling': 'assets/images/pochette_enfamille.png',
    'parc': 'assets/images/pochette_parc_attraction.png',
    'bibliotheque': 'assets/images/sc_expo.png',
    'librairie': 'assets/images/sc_expo.png',
    'piscine': 'assets/images/sc_natation.png',
    'fitness': 'assets/images/sc_autres_sport.png',
    'tennis': 'assets/images/sc_autres_sport.png',
    'football': 'assets/images/sc_football.png',
    'rugby': 'assets/images/sc_rugby.png',
    'basket': 'assets/images/sc_basketball.png',
    'chicha': 'assets/images/sc_chicha.png',
    'epicerie': 'assets/images/sc_tabac_nuit.png',
    'tabac': 'assets/images/sc_tabac_nuit.png',
    'station': 'assets/images/sc_tabac_nuit.png',
    'gaming': 'assets/images/pochette_gaming.png',
    'jeux': 'assets/images/pochette_gaming.png',
    'esport': 'assets/images/pochette_gaming.png',
  };

  String? _resolveImage() {
    if (imageAsset != null) return imageAsset;
    final cat = commerce.categorie.toLowerCase();
    final nom = commerce.nom.toLowerCase();
    for (final entry in _defaultImages.entries) {
      if (cat.contains(entry.key) || nom.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
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
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image a gauche ──
            SizedBox(
              width: 90,
              child: image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          image,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.08),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Emoji badge
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              commerce.categoryEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        // Status badge
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: commerce.ouvert
                                  ? const Color(0xFF059669)
                                  : Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              commerce.ouvert ? 'Ouvert' : 'Ferme',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: modeTheme.chipBgColor,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            commerce.categoryEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: commerce.ouvert
                                  ? const Color(0xFF059669)
                                  : Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              commerce.ouvert ? 'Ouvert' : 'Ferme',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

                    const Spacer(),

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
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: commerce.nom,
        emoji: commerce.categoryEmoji,
        imageAsset: image,
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
                icon: Icons.language,
                label: 'Site web',
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
      onTap: () => ref.read(likesProvider.notifier).toggle(likeId),
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
