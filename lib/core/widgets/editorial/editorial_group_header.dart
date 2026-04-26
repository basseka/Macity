import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_kicker.dart';

/// Header d'un groupe d'events (ex. "À l'affiche", "Cette semaine").
/// Filet 1px haut + kicker couleur rubrique + Fraunces title + count tabular.
class EditorialGroupHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final int? count;
  final Color accent;

  const EditorialGroupHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: EditorialColors.dividerStrong),
          const SizedBox(height: 14),
          EditorialKicker(kicker, color: accent, size: 10),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EditorialText.groupHeaderTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null)
                Text(
                  count.toString(),
                  style: EditorialText.meta().copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
