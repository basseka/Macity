import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class FitnessVenueCard extends ConsumerWidget {
  final CommerceModel commerce;
  final List<CommerceModel>? pagerSiblings;
  final int? pagerIndex;

  const FitnessVenueCard({
    super.key,
    required this.commerce,
    this.pagerSiblings,
    this.pagerIndex,
  });

  static const _logoMap = <String, String>{
    'basic-fit': 'assets/images/logo_salle_basicfit.png',
    'fitness park': 'assets/images/logo_salle_fitnesspark.png',
    'interval': 'assets/images/logo_salle_interval.jpg',
    'clark powell': 'assets/images/logo_salle_calrkpowel.png',
    'movida': 'assets/images/logo_salle_movida.png',
  };

  String _resolvePhoto() {
    // 1. Vraie photo uploadee (URL reseau) ou galerie : prioritaire sur le logo
    //    de chaine code en dur — permet de personnaliser la pochette via
    //    admin.html, y compris pour les 5 enseignes connues.
    if (commerce.photo.startsWith('http')) return commerce.photo;
    if (commerce.photos.isNotEmpty) return commerce.photos.first;
    // 2. Sinon, logo de l'enseigne si c'est une chaine connue.
    final nom = commerce.nom.toLowerCase();
    for (final entry in _logoMap.entries) {
      if (nom.contains(entry.key)) return entry.value;
    }
    // 3. Repli : valeur DB (placeholder asset ou chaine vide).
    return commerce.photo;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final photo = _resolvePhoto();

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
                    child: photo.isNotEmpty
                        ? photo.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: photo,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                memCacheWidth: 96,
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.fitness_center,
                                  color: modeTheme.primaryColor,
                                  size: 22,
                                ),
                              )
                            : Image.asset(
                                photo,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                cacheWidth: 96,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.fitness_center,
                                  color: modeTheme.primaryColor,
                                  size: 22,
                                ),
                              )
                        : Icon(
                            Icons.fitness_center,
                            color: modeTheme.primaryColor,
                            size: 22,
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
                            fontSize: 10,
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
                                color: AppColors.textDim,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  commerce.adresse,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textDim,
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
                    color: AppColors.textDim,
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
    // M\u00EAme fiche d\u00E9tail que les bo\u00EEtes de nuit : vid\u00E9o + galerie (jusqu'\u00E0
    // 6 photos), avis, badge v\u00E9rifi\u00E9, partage\u2026 via CommerceRowCard.
    // On passe le logo de cha\u00EEne en image d'en-t\u00EAte s'il n'y a pas de
    // vraie photo (commerce.photo http).
    final resolved = _resolvePhoto();
    final headerAsset =
        (resolved.isEmpty || resolved.startsWith('http')) ? null : resolved;
    CommerceRowCard.openDetail(context, commerce,
        imageAsset: headerAsset,
        siblings: pagerSiblings,
        index: pagerIndex);
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
                fontSize: 10,
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
    final uri = Uri.tryParse(commerce.siteWeb);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Impossible d\'ouvrir le lien: $e');
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.tryParse(commerce.lienMaps);
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
