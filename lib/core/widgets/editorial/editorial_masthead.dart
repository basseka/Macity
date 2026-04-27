import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Masthead d'un ecran de rubrique — handoff coherence v1.0.
///
/// Layout : bouton retour + actions + eyebrow magenta + titre Playfair italic
/// (couleur accent rubrique) + blurb italic optionnel.
///
/// Ex: "Day · Concert" / "Concerts" italic violet / "271 dates ce mois-ci"
class EditorialMasthead extends StatelessWidget {
  /// Eyebrow uppercase au-dessus du titre, ex "DAY · CONCERT".
  final String kicker;

  /// Titre en gros — rendu en italique Playfair couleur accent.
  final String title;

  /// Couleur accent rubrique (italique du titre + chevron retour).
  final Color accent;

  /// Phrase italique sous le titre. Optionnel.
  final String? blurb;

  /// Bouton retour optionnel a gauche.
  final VoidCallback? onBack;

  /// Actions a droite (search, menu...).
  final List<Widget>? actions;

  /// Widget aligne a droite du titre, sur la meme ligne. Utile pour un
  /// bouton de filtre / action contextuelle.
  final Widget? titleTrailing;

  const EditorialMasthead({
    super.key,
    required this.kicker,
    required this.title,
    required this.accent,
    this.blurb,
    this.onBack,
    this.actions,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EditorialSpacing.lg,
        EditorialSpacing.sm,
        EditorialSpacing.lg,
        EditorialSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top nav row
          if (onBack != null || (actions != null && actions!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: EditorialSpacing.sm),
              child: Row(
                children: [
                  if (onBack != null)
                    GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: EditorialColors.surfaceHi,
                          borderRadius:
                              BorderRadius.circular(EditorialRadius.search),
                          border: Border.all(
                            color: EditorialColors.stroke,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_left,
                          color: accent,
                          size: 22,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          // Eyebrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '◆',
                  style: TextStyle(
                    color: EditorialColors.magenta,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    kicker.toUpperCase(),
                    style: EditorialText.eyebrow(
                      color: EditorialColors.magenta,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EditorialSpacing.sm),
          // Titre — Playfair italic accent rubrique + point sans accent.
          // Optionnellement un widget trailing aligne a droite (ex: bouton
          // de filtre).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            height: 1.05,
                            letterSpacing: -0.6,
                            color: accent,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: EditorialColors.text,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (titleTrailing != null) ...[
                  const SizedBox(width: EditorialSpacing.md),
                  titleTrailing!,
                ],
              ],
            ),
          ),
          if (blurb != null && blurb!.isNotEmpty) ...[
            const SizedBox(height: EditorialSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(blurb!, style: EditorialText.blurbItalic()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
