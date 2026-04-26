import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_city_header.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_section_header.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_subcategory_card.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Ecran "Explorer" — handoff coherence v1.0 (Avril 2026).
///
/// Layout :
///  1. CityHeader (logo + Ta ville + ville + avatar)
///  2. SectionHeader "✦ Toutes les *rubriques*"
///  3. Grille 2 col de 8 cards rubriques
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: EditorialColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: EditorialCityHeader()),
            const SliverToBoxAdapter(
              child: EditorialSectionHeader(
                prefix: 'Toutes les',
                italicWord: 'rubriques',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                EditorialSpacing.screen,
                EditorialSpacing.sm,
                EditorialSpacing.screen,
                EditorialSpacing.xxl,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: EditorialSpacing.lg,
                  crossAxisSpacing: EditorialSpacing.md,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildModeCard(context, ref, AppMode.order[i]),
                  childCount: AppMode.order.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, WidgetRef ref, AppMode mode) {
    final meta = _modeMeta[mode]!;
    return EditorialSubcategoryCard(
      label: meta.title,
      kicker: meta.section,
      imageTag: meta.imageTag,
      imageUrl: _modeImage[mode],
      accent: meta.accent,
      onTap: () {
        ref.read(currentModeProvider.notifier).setMode(mode.name);
        context.push(mode.routePath);
      },
    );
  }

  // ─── Metadata par mode ────────────────────────────────────────────
  static const _modeMeta = <AppMode, _ModeMeta>{
    AppMode.day: _ModeMeta(
      section: 'Musique',
      title: 'Concerts',
      imageTag: 'CONCERT',
      accent: EditorialColors.gold,
    ),
    AppMode.night: _ModeMeta(
      section: 'After',
      title: 'Nuit',
      imageTag: 'NIGHT CLUB',
      accent: EditorialColors.cyan,
    ),
    AppMode.food: _ModeMeta(
      section: 'Plaisirs',
      title: 'Food',
      imageTag: 'FOOD',
      accent: EditorialColors.orange,
    ),
    AppMode.sport: _ModeMeta(
      section: 'Active',
      title: 'Sport',
      imageTag: 'SPORT',
      accent: EditorialColors.green,
    ),
    AppMode.culture: _ModeMeta(
      section: 'Culture',
      title: 'Culture',
      imageTag: 'MUSEUM',
      accent: EditorialColors.cyan,
    ),
    AppMode.family: _ModeMeta(
      section: 'Famille',
      title: 'Famille',
      imageTag: 'FAMILY',
      accent: EditorialColors.orange,
    ),
    AppMode.gaming: _ModeMeta(
      section: 'Joueurs',
      title: 'Gaming',
      imageTag: 'GAMING',
      accent: EditorialColors.green,
    ),
    AppMode.tourisme: _ModeMeta(
      section: 'Visite',
      title: 'Tourisme',
      imageTag: 'TOURISME',
      accent: EditorialColors.gold,
    ),
  };

  static const _modeImage = <AppMode, String>{
    AppMode.day: 'assets/images/pochette_concert.png',
    AppMode.sport: 'assets/images/home_bg_sport.jpg',
    AppMode.culture: 'assets/images/pochette_culture_art.png',
    AppMode.food: 'assets/images/pochette_food.png',
    AppMode.gaming: 'assets/images/pochette_gaming.jpg',
    AppMode.family: 'assets/images/pochette_enfamille.jpg',
    AppMode.night: 'assets/images/home_bg_night.jpg',
    AppMode.tourisme: 'assets/images/pochette_tourime.png',
  };
}

class _ModeMeta {
  final String section;
  final String title;
  final String imageTag;
  final Color accent;

  const _ModeMeta({
    required this.section,
    required this.title,
    required this.imageTag,
    required this.accent,
  });
}
