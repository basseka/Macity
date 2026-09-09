import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/event_list_item.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/reported_events/state/tonight_events_provider.dart';

/// Page plein écran "Les bons plans" : liste petites annonces (FEED_LISTE.md)
/// des events du jour, groupes par rubrique.
class TonightBonsPlansPage extends ConsumerWidget {
  const TonightBonsPlansPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TonightBonsPlansPage(),
      ),
    );
  }

  static const _rubriqueOrder = [
    AppMode.day,
    AppMode.food,
    AppMode.night,
    AppMode.culture,
    AppMode.family,
  ];

  static EventListCategory _categoryFor(String rubrique) {
    switch (rubrique) {
      case 'food':
        return EventListCategory.food;
      case 'night':
        return EventListCategory.night;
      case 'culture':
        return EventListCategory.culture;
      case 'family':
        return EventListCategory.family;
      default:
        return EventListCategory.evasion;
    }
  }

  static String _shortLabelFor(String rubrique) {
    final mode = AppMode.values.firstWhere(
      (m) => m.name == rubrique,
      orElse: () => AppMode.day,
    );
    return mode.shortLabel;
  }

  /// "14h30, 17h00, 20h30" -> "14h30" (premiere seance).
  static String _firstShowTime(String horaires) {
    if (horaires.isEmpty) return '';
    return horaires.split(',').first.trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tonightEventsProvider);
    final liked = ref.watch(likesProvider);

    return Scaffold(
      backgroundColor: AppColors.feedBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.feedText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Les bons plans',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.025 * 19,
                      color: AppColors.feedText,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.feedDivider,
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.magenta),
                ),
                error: (_, __) =>
                    _empty("Impossible de charger les bons plans."),
                data: (events) {
                  if (events.isEmpty) {
                    return _empty(
                      "Aucun bon plan aujourd'hui dans cette ville.",
                    );
                  }
                  final byRubrique = <String, List<Event>>{};
                  for (final e in events) {
                    byRubrique.putIfAbsent(e.rubrique, () => []).add(e);
                  }
                  final rubriques = [
                    ..._rubriqueOrder
                        .map((m) => m.name)
                        .where(byRubrique.containsKey),
                    ...byRubrique.keys.where(
                      (r) => !_rubriqueOrder.any((m) => m.name == r),
                    ),
                  ];

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: rubriques.length,
                    itemBuilder: (_, i) {
                      final rubrique = rubriques[i];
                      final mode = AppMode.values.firstWhere(
                        (m) => m.name == rubrique,
                        orElse: () => AppMode.day,
                      );
                      final items = byRubrique[rubrique]!.map((event) {
                        final isFavorite = liked.contains(event.identifiant);
                        return EventListItem(
                          imageUrl: event.photoPath ?? '',
                          categoryLabel: _shortLabelFor(rubrique),
                          category: _categoryFor(rubrique),
                          price: event.isFree
                              ? 'Gratuit'
                              : (event.tarifNormal.isNotEmpty
                                  ? event.tarifNormal
                                  : 'Tarif non communiqué'),
                          priceNote: event.isFree ? 'entrée libre' : null,
                          isFree: event.isFree,
                          name: event.titre,
                          time: _firstShowTime(event.horaires),
                          venue: event.lieuNom,
                          city: event.commune,
                          postalCode: event.codePostal > 0
                              ? '${event.codePostal}'
                              : null,
                          timestamp:
                              "Aujourd'hui à ${_firstShowTime(event.horaires)}",
                          isFavorite: isFavorite,
                          onTap: () => EventFullscreenPopup.show(
                            context,
                            event,
                            'assets/images/pochette_concert.webp',
                          ),
                          onFavoriteTap: () =>
                              ref.read(likesProvider.notifier).toggle(
                                    event.identifiant,
                                    meta: LikeMetadata(
                                      title: event.titre,
                                      imageUrl: event.photoPath,
                                      category: event.categorie,
                                    ),
                                  ),
                        );
                      }).toList();

                      return EventListSection(title: mode.label, items: items);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.feedTextSecondary,
            ),
          ),
        ),
      );
}
