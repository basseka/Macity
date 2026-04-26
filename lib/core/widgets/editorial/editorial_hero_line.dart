import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Phrase signature italique en gros sous le header. Ex: "Toutes les
/// rubriques." ou "185 sorties autour de toi.". Optionnellement une chip mono
/// a droite (ex "NO. 04").
class EditorialHeroLine extends StatelessWidget {
  /// Texte avant l'italique. Peut etre vide.
  final String prefix;

  /// Mot mis en italique (Playfair, accent dore par defaut).
  final String italicWord;

  /// Texte apres l'italique (typiquement le point ".").
  final String suffix;

  /// Couleur du mot italique.
  final Color italicColor;

  /// Couleur du prefixe + suffixe.
  final Color textColor;

  /// Chip mono optionnelle a droite (ex "NO. 04").
  final String? chipLabel;

  /// Eyebrow optionnel au-dessus (ex "GUIDE DES SORTIES · AVRIL '26").
  final String? eyebrow;
  final Color eyebrowColor;

  const EditorialHeroLine({
    super.key,
    this.prefix = '',
    required this.italicWord,
    this.suffix = '.',
    this.italicColor = EditorialColors.gold,
    this.textColor = EditorialColors.text,
    this.chipLabel,
    this.eyebrow,
    this.eyebrowColor = EditorialColors.magenta,
  });

  @override
  Widget build(BuildContext context) {
    final lineStyle = GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.5,
      color: textColor,
    );
    final italicStyle = GoogleFonts.playfairDisplay(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.1,
      letterSpacing: -0.5,
      color: italicColor,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EditorialSpacing.screen,
        EditorialSpacing.sm,
        EditorialSpacing.screen,
        EditorialSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null && eyebrow!.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '◆',
                  style: TextStyle(color: eyebrowColor, fontSize: 8),
                ),
                const SizedBox(width: 6),
                Text(
                  eyebrow!,
                  style: EditorialText.eyebrow(color: eyebrowColor),
                ),
              ],
            ),
            const SizedBox(height: EditorialSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      if (prefix.isNotEmpty)
                        TextSpan(text: '$prefix ', style: lineStyle),
                      TextSpan(text: italicWord, style: italicStyle),
                      if (suffix.isNotEmpty)
                        TextSpan(text: suffix, style: lineStyle),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chipLabel != null && chipLabel!.isNotEmpty) ...[
                const SizedBox(width: EditorialSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: EditorialColors.stroke,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(EditorialRadius.sm),
                  ),
                  child: Text(
                    chipLabel!,
                    style: EditorialText.eyebrow(
                      color: EditorialColors.textDim,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
