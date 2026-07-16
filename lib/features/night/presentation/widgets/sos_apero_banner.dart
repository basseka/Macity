import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';

/// Bandeau « SOS Apéro » du hub Night, placé sous la carte.
///
/// Raccourci vers un service à part : quand tout est fermé, ces enseignes
/// livrent encore. Au tap, on sélectionne la catégorie `SOS Apero`, ce qui
/// affiche la liste existante (le même écran que la tuile du hub) — pas de vue
/// dupliquée. Masqué s'il n'y a aucune enseigne dans la ville.
class SosAperoBanner extends ConsumerWidget {
  const SosAperoBanner({super.key});

  /// Valeur exacte de `venues.category` (cf. night_category_data.dart).
  static const _tag = 'SOS Apero';

  /// Orange apéro : se démarque du bleu nuit de la rubrique, c'est le but.
  static const _accent = Color(0xFFF2A20C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(nightAllVenuesProvider).valueOrNull ?? const [];
    final count = venues.where((v) => v.categorie == _tag).length;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: GestureDetector(
        onTap: () =>
            ref.read(modeSubcategoriesProvider.notifier).select('night', _tag),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: RubriqueTheme.surface,
            borderRadius: BorderRadius.circular(RubriqueTheme.rCard),
            border: Border.all(color: RubriqueTheme.hairline, width: 1),
            boxShadow: RubriqueTheme.banner,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🍾', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SOS Apéro',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RubriqueTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count > 1
                          ? '$count enseignes livrent quand tout est fermé'
                          : 'Une enseigne livre quand tout est fermé',
                      style: RubriqueTheme.meta(color: RubriqueTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(RubriqueTheme.rPill),
                ),
                child: Text(
                  'Voir',
                  style: RubriqueTheme.chip(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
