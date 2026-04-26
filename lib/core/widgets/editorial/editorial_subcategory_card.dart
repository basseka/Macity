import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Carte de rubrique / sous-rubrique — handoff coherence v1.0.
///
/// Image radius 12 en haut + tag mono uppercase en overlay coin haut-gauche
/// sur l'image, eyebrow accent thematique sous l'image, titre Inter 18/700.
/// La carte elle-meme a un radius 16, fond surfaceHi, bordure stroke.
class EditorialSubcategoryCard extends StatelessWidget {
  /// Titre principal (ex "Concerts").
  final String label;

  /// Eyebrow accent thematique sous l'image (ex "MUSIQUE", "PLAISIRS").
  final String kicker;

  /// Tag dans le coin haut-gauche de l'image (ex "CONCERT", "FOOD"). Optionnel.
  final String? imageTag;

  /// Compteur de sortie / venues (affiche a droite du titre si non null).
  final int? count;

  /// URL ou path asset de l'image.
  final String? imageUrl;

  /// Couleur d'accent thematique : eyebrow + soulignement subtil.
  final Color accent;

  final VoidCallback onTap;

  /// Hauteur image. Default 110 (handoff card standard).
  final double imageHeight;

  /// Override taille du titre. Defaut 18.
  final double? titleSize;

  const EditorialSubcategoryCard({
    super.key,
    required this.label,
    required this.kicker,
    this.imageTag,
    this.count,
    this.imageUrl,
    required this.accent,
    required this.onTap,
    this.imageHeight = 110,
    this.titleSize,
  });

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.6),
              accent.withValues(alpha: 0.3),
            ],
          ),
        ),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: EditorialColors.surface),
        errorWidget: (_, __, ___) => Container(color: EditorialColors.surface),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      cacheWidth: 400,
      errorBuilder: (_, __, ___) => Container(color: EditorialColors.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EditorialColors.surfaceHi,
      borderRadius: BorderRadius.circular(EditorialRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.18),
        highlightColor: accent.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(EditorialSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EditorialRadius.card),
            border: Border.all(color: EditorialColors.stroke, width: 1),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image avec tag overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(EditorialRadius.search),
              child: SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(imageUrl),
                    // Tag mono coin haut-gauche
                    if (imageTag != null && imageTag!.isNotEmpty)
                      Positioned(
                        top: EditorialSpacing.sm,
                        left: EditorialSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius:
                                BorderRadius.circular(EditorialRadius.sm),
                          ),
                          child: Text(
                            imageTag!.toUpperCase(),
                            style: EditorialText.eyebrow(
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: EditorialSpacing.md),
            // Eyebrow accent thematique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                kicker.toUpperCase(),
                style: EditorialText.eyebrow(color: accent, size: 10),
              ),
            ),
            const SizedBox(height: 4),
            // Titre Inter 18 + count optionnel
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: EditorialText.cardTitle().copyWith(
                        fontSize: titleSize ?? 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      count.toString(),
                      style: EditorialText.meta().copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
