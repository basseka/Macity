import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Banniere "A venir" editoriale, partagee par les 7 hubs (day, night, culture,
/// family, food, sport, gaming). Filet vertical accent + icone bolt + titre +
/// sous-titre + count tabular + chevron.
///
/// Reference : ancien `_AvenirBanner` de day_screen.dart. Factorise pour
/// garantir l'uniformite visuelle entre tous les modes (handoff 2026-05-03).
class EditorialAvenirBanner extends ConsumerWidget {
  final String mode;
  final Color accent;
  final String? subtitle;
  final FutureProvider<int>? countProvider;

  const EditorialAvenirBanner({
    super.key,
    required this.mode,
    required this.accent,
    this.subtitle,
    this.countProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = countProvider != null
        ? ref.watch(countProvider!).valueOrNull
        : null;

    // NB : le widget n'embarque pas de margin externe — chaque caller gere
    // l'inset (Day via Padding 20, DynamicHubGrid via la padding du ListView).
    return GestureDetector(
      onTap: () =>
          ref.read(modeSubcategoriesProvider.notifier).select(mode, 'A venir'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: EditorialColors.dividerSoft,
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A venir',
                    style: EditorialText.catCardTitle(),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: EditorialText.subtitleItalic(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (count != null && count > 0) ...[
              Text(
                count.toString(),
                style: EditorialText.meta().copyWith(
                  color: EditorialColors.paper,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right,
              size: 16,
              color: EditorialColors.paperMuted,
            ),
          ],
        ),
      ),
    );
  }
}
