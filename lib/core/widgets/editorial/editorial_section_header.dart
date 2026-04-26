import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Section header standard de l'app : ✦ magenta + prefixe Inter + 1 mot
/// italique dore (Playfair).
///
/// Ex : `EditorialSectionHeader(prefix: 'Toutes les', italicWord: 'rubriques')`
/// rendu : ✦ Toutes les *rubriques*
class EditorialSectionHeader extends StatelessWidget {
  final String prefix;
  final String italicWord;
  final Color italicColor;
  final EdgeInsets padding;

  const EditorialSectionHeader({
    super.key,
    required this.prefix,
    required this.italicWord,
    this.italicColor = EditorialColors.gold,
    this.padding = const EdgeInsets.fromLTRB(
      EditorialSpacing.screen,
      EditorialSpacing.lg,
      EditorialSpacing.screen,
      EditorialSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '✦',
            style: TextStyle(
              color: EditorialColors.magenta,
              fontSize: 18,
              height: 1.0,
            ),
          ),
          const SizedBox(width: EditorialSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$prefix ',
                    style: EditorialText.displayTitle().copyWith(fontSize: 24),
                  ),
                  TextSpan(
                    text: italicWord,
                    style:
                        EditorialText.sectionItalic(color: italicColor).copyWith(
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
