import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_tile.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/presentation/clubs_pager_view.dart';
import 'package:pulz_app/features/night/presentation/night_bars_fullscreen_map.dart';
import 'package:pulz_app/features/night/presentation/night_clubs_fullscreen_map.dart';
import 'package:pulz_app/features/night/presentation/night_hub_grid.dart';
import 'package:pulz_app/features/night/presentation/night_spicy_fullscreen_map.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/core/state/categories_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

class NightScreen extends ConsumerWidget {
  const NightScreen({super.key});

  /// Catégories qui sont des sub_grids (affichent leurs enfants au lieu de venues).
  static const _subGridTags = {'Spicy'};

  /// Categorie → map fullscreen associee. Les 4 types de bars partagent une
  /// carte combinee (Bars carte) ; les clubs ont leur propre carte dediee.
  static bool _categoryHasMap(String category) {
    if (category == 'Club Discotheque') return true;
    if (nightBarCategories.contains(category)) return true;
    if (category == 'Spicy' || nightSpicyCategories.contains(category)) return true;
    return false;
  }

  /// Libelle raccourci pour l'en-tete de la liste venues.
  static String _displayLabel(String category) {
    switch (category) {
      case 'Club Discotheque':
        return 'Club disco';
      case 'Bar a cocktails':
        return 'Cocktails';
      case 'Bar a chicha':
        return 'Chicha';
      default:
        return category;
    }
  }

  static void _openMapFor(WidgetRef ref, String category) {
    if (category == 'Club Discotheque') {
      ref
          .read(modeSubcategoriesProvider.notifier)
          .select('night', NightClubsFullscreenMap.mapTag);
      return;
    }
    if (nightBarCategories.contains(category)) {
      // Memorise la cat source pour que le bouton "Liste" de la carte y revienne.
      ref.read(nightBarsMapSourceProvider.notifier).state = category;
      ref
          .read(modeSubcategoriesProvider.notifier)
          .select('night', NightBarsFullscreenMap.mapTag);
      return;
    }
    if (category == 'Spicy' || nightSpicyCategories.contains(category)) {
      ref.read(nightSpicyMapSourceProvider.notifier).state = category;
      ref
          .read(modeSubcategoriesProvider.notifier)
          .select('night', NightSpicyFullscreenMap.mapTag);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(nightCategoryProvider);

    // Cartes plein ecran (sans chrome editorial)
    if (selectedCategory != null &&
        (NightClubsFullscreenMap.isMapTag(selectedCategory) ||
            NightBarsFullscreenMap.isMapTag(selectedCategory) ||
            NightSpicyFullscreenMap.isMapTag(selectedCategory))) {
      return _resolveContent(context, ref, selectedCategory);
    }

    return Container(
      color: EditorialColors.ink,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: EditorialMasthead(
              kicker: selectedCategory == null
                  ? 'Rubrique · After'
                  : 'Night · ${_displayLabel(selectedCategory)}',
              title: selectedCategory == null
                  ? 'Nuit'
                  : _displayLabel(selectedCategory),
              accent: RubricColors.night,
              blurb: selectedCategory == null
                  ? 'Clubs, bars, soirees — la nuit, la ville change de visage.'
                  : null,
              onBack: selectedCategory == null
                  ? () => context.go('/home')
                  : () => ref
                      .read(modeSubcategoriesProvider.notifier)
                      .select('night', null),
            ),
          ),
        ],
        body: _resolveContent(context, ref, selectedCategory),
      ),
    );
  }

  Widget _resolveContent(
    BuildContext context,
    WidgetRef ref,
    String? selectedCategory,
  ) {
    if (selectedCategory == null) return const NightHubGrid();
    if (NightClubsFullscreenMap.isMapTag(selectedCategory)) {
      return const NightClubsFullscreenMap();
    }
    if (NightBarsFullscreenMap.isMapTag(selectedCategory)) {
      return const NightBarsFullscreenMap();
    }
    if (NightSpicyFullscreenMap.isMapTag(selectedCategory)) {
      return const NightSpicyFullscreenMap();
    }
    if (_subGridTags.contains(selectedCategory)) {
      return _buildSubGrid(context, ref, selectedCategory);
    }
    return _buildVenueList(context, ref, selectedCategory);
  }

  Widget _buildSubGrid(BuildContext context, WidgetRef ref, String parentTag) {
    final modeTheme = ref.watch(modeThemeProvider);
    final childrenAsync = ref.watch(
      groupChildrenProvider((mode: 'night', groupe: parentTag)),
    );

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (_categoryHasMap(parentTag)) ...[
                InkWell(
                  onTap: () => _openMapFor(ref, parentTag),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: modeTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me, size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Carte',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _displayLabel(parentTag),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(modeSubcategoriesProvider.notifier).select('night', null);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Categories',
                        style: TextStyle(
                          color: modeTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: childrenAsync.when(
            data: (children) {
              if (children.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucune sous-categorie',
                  icon: Icons.nightlife,
                );
              }
              final gradient = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
              );
              return GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  for (final cat in children)
                    Builder(builder: (context) {
                      final count = ref.watch(nightCategoryCountProvider(cat.searchTag)).valueOrNull;
                      return DaySubcategoryCard(
                        emoji: '',
                        label: cat.label,
                        image: cat.imageUrl.isNotEmpty ? cat.imageUrl : null,
                        count: count,
                        gradient: gradient,
                        onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('night', cat.searchTag),
                      );
                    }),
                ],
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (_, __) => const AppErrorWidget(message: 'Erreur de chargement'),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueList(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(nightVenuesProvider);

    final isAvenir = category == 'A venir';

    return Column(
      children: [
        // Back button row (masquee sur A venir : la masthead a deja un back)
        if (!isAvenir) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_categoryHasMap(category)) ...[
                  InkWell(
                    onTap: () => _openMapFor(ref, category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: modeTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Carte',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _displayLabel(category),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: modeTheme.primaryDarkColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ref.read(modeSubcategoriesProvider.notifier).select('night', null);
                    ref.read(dateRangeFilterProvider.notifier).state =
                        const DateRangeFilter();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          size: 14,
                          color: modeTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Categories',
                          style: TextStyle(
                            color: modeTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],

        Expanded(
          child: isAvenir
              ? _buildUserEventsList(context, ref)
              : venuesAsync.when(
                  data: (venues) {
                    // Les soirees / events de cette categorie sont visibles
                    // uniquement dans l'onglet "A venir" — ici on liste juste
                    // les etablissements (clubs, bars, etc.).
                    if (venues.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun commerce trouve pour cette categorie',
                        icon: Icons.nightlife,
                      );
                    }
                    // Pour la categorie Club Discotheque : tap ouvre le pager
                    // qui permet de swiper de droite vers la gauche pour
                    // voir le club suivant. Autres categories (bars, pubs...)
                    // gardent le sheet detail isole.
                    final isClub = category == 'Club Discotheque';
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: venues.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CommerceRowCard(
                          commerce: venues[index],
                          onTap: isClub
                              ? () => ClubsPagerView.open(
                                    context,
                                    clubs: venues,
                                    initialIndex: index,
                                  )
                              : null,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      LoadingIndicator(color: modeTheme.primaryColor),
                  error: (error, _) => AppErrorWidget(
                    message: 'Erreur lors du chargement des commerces',
                    onRetry: () => ref.invalidate(nightVenuesProvider),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserEventsList(BuildContext context, WidgetRef ref) {
    final userEvents = ref.watch(nightUserEventsProvider);
    final scrapedAsync = ref.watch(nightScrapedEventsProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final filter = ref.watch(dateRangeFilterProvider);

    // Filtre : uniquement les events a venir (>= aujourd'hui) + filtre temporel.
    bool isInRange(Event e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && filter.isInRange(d);
    }

    final scrapedEvents = (scrapedAsync.valueOrNull ?? []).where(isInRange).toList();
    final allEvents = <Event>[
      ...userEvents.where(isInRange),
      ...scrapedEvents,
    ];
    // Trier par date.
    allEvents.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    // Afficher un loader seulement si pas encore d'events du tout.
    if (allEvents.isEmpty && scrapedAsync.isLoading) {
      return LoadingIndicator(color: modeTheme.primaryColor);
    }

    if (allEvents.isEmpty) {
      return const Column(
        children: [
          DateRangeChipBar(),
          Expanded(
            child: EmptyStateWidget(
              message: 'Aucun evenement pour le moment.\nAjoute un evenement avec le bouton +',
              icon: Icons.nightlife,
            ),
          ),
        ],
      );
    }
    return _buildDateGroupedEventsList(allEvents, modeTheme, context);
  }

  Widget _buildDateGroupedEventsList(List<Event> events, ModeTheme modeTheme, BuildContext context) {
    final grouped = <DateTime, List<Event>>{};
    for (final e in events) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: DateRangeChipBar(),
        ),
        const SizedBox(height: 4),
        for (final day in sortedDays) ...[
          editorialDateHeader(
            editorialDayLabel(day),
            RubricColors.night,
            count: grouped[day]!.length,
          ),
          for (final event in grouped[day]!)
            editorialEventTileFromEvent(
              context,
              event,
              RubricColors.night,
              fallbackImage: 'assets/images/pochette_default.jpg',
            ),
        ],
      ],
    );
  }

}
