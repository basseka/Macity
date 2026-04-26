import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/core/state/categories_provider.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_row_card.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_group_header.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_subcategory_card.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/fete_musique_map_view.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Screen pilote de la refonte editoriale (handoff design 2026-04-25).
/// Architecture inchangee : on garde les hubs (subcategories -> venues ->
/// events). Seul le chrome visuel passe en dark editorial B3.
class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  static const Color _accent = RubricColors.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(selectedDaySubcategoryProvider);
    final selectedVenue = ref.watch(selectedConcertVenueProvider);

    // Cas special : Fete musique = map plein ecran sans chrome editorial
    if (selectedSubcategory == 'Fete musique') {
      return _buildFeteMusiqueMap(context, ref);
    }

    return Container(
      color: EditorialColors.ink,
      child: _buildContent(context, ref, selectedSubcategory, selectedVenue),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String? selectedSubcategory,
    String? selectedVenue,
  ) {
    if (selectedSubcategory == null) {
      return _buildSubcategoryGrid(context, ref);
    }
    if (selectedVenue != null) {
      return _buildVenueEventsList(context, ref, selectedVenue, selectedSubcategory);
    }
    final childrenAsync = ref.watch(
      groupChildrenProvider((mode: 'day', groupe: selectedSubcategory)),
    );
    return childrenAsync.when(
      data: (children) {
        if (children.isNotEmpty) {
          return _buildVenueGrid(context, ref, selectedSubcategory, children);
        }
        return _buildEventsList(context, ref, selectedSubcategory);
      },
      loading: () => const Center(child: LoadingIndicator(color: _accent)),
      error: (_, __) => _buildEventsList(context, ref, selectedSubcategory),
    );
  }

  // ─── Etat 1 : grille des sous-rubriques (root) ────────────────────────

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(modeRootCategoriesProvider('day'));

    return catsAsync.when(
      data: (subcategories) {
        final others = subcategories.where((c) => c.searchTag != 'A venir').toList();
        final hasAvenir = subcategories.any((c) => c.searchTag == 'A venir');

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: EditorialMasthead(
                kicker: 'Rubrique · Sortir',
                title: 'Sortir',
                accent: _accent,
                blurb:
                    'Concerts, spectacles, festivals — la programmation du jour et a venir.',
                onBack: () => context.go('/explorer'),
              ),
            ),
            if (hasAvenir)
              SliverToBoxAdapter(
                child: _AvenirBanner(ref: ref, accent: _accent),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sub = others[index];
                    final countAsync =
                        ref.watch(daySubcategoryCountProvider(sub.searchTag));
                    return EditorialSubcategoryCard(
                      label: sub.label,
                      kicker: sub.label,
                      imageUrl: sub.imageUrl.isNotEmpty ? sub.imageUrl : null,
                      count: countAsync.valueOrNull,
                      accent: _accent,
                      onTap: () {
                        ref.read(selectedConcertVenueProvider.notifier).state = null;
                        ref.read(modeSubcategoriesProvider.notifier).select('day', sub.searchTag);
                      },
                    );
                  },
                  childCount: others.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingIndicator(color: _accent)),
      error: (_, __) => AppErrorWidget(
        message: 'Erreur lors du chargement des categories',
        onRetry: () => ref.invalidate(modeRootCategoriesProvider('day')),
      ),
    );
  }

  // ─── Etat 2 : grille des venues d'une sous-rubrique ───────────────────

  Widget _buildVenueGrid(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
    List<AppCategory> venues,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EditorialMasthead(
            kicker: 'Day · $subcategory',
            title: subcategory,
            accent: _accent,
            onBack: () =>
                ref.read(modeSubcategoriesProvider.notifier).select('day', null),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final venue = venues[index];
                final keyword = venue.meta('venue_keyword') ?? venue.searchTag;
                final countAsync = ref.watch(concertVenueCountProvider(keyword));
                return EditorialSubcategoryCard(
                  label: venue.label,
                  kicker: subcategory,
                  imageUrl: venue.imageUrl.isNotEmpty ? venue.imageUrl : null,
                  count: countAsync.valueOrNull,
                  accent: _accent,
                  imageHeight: 90,
                  onTap: () =>
                      ref.read(selectedConcertVenueProvider.notifier).state = keyword,
                );
              },
              childCount: venues.length,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Etat 3 : liste events d'une venue ────────────────────────────────

  Widget _buildVenueEventsList(
    BuildContext context,
    WidgetRef ref,
    String venueKeyword,
    String subcategory,
  ) {
    final eventsAsync = ref.watch(dayVenueEventsProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EditorialMasthead(
            kicker: '$subcategory · Salle',
            title: venueKeyword,
            accent: _accent,
            onBack: () =>
                ref.read(selectedConcertVenueProvider.notifier).state = null,
          ),
        ),
        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette salle',
                  icon: Icons.event_busy,
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _editorialRowFromEvent(context, events[i]),
                childCount: events.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: LoadingIndicator(color: _accent)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: AppErrorWidget(
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(dayVenueEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Etat 4 : liste events d'une sous-rubrique sans venues ────────────

  Widget _buildEventsList(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
  ) {
    final eventsAsync = ref.watch(dayEventsProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EditorialMasthead(
            kicker: 'Day · $subcategory',
            title: subcategory,
            accent: _accent,
            onBack: () {
              ref.read(modeSubcategoriesProvider.notifier).select('day', null);
              ref.read(dateRangeFilterProvider.notifier).state =
                  const DateRangeFilter();
            },
          ),
        ),
        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette categorie',
                  icon: Icons.event_busy,
                ),
              );
            }
            if (subcategory == 'A venir') {
              return _buildGroupedEventsSliver(context, events, ref);
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _editorialRowFromEvent(context, events[i]),
                childCount: events.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: LoadingIndicator(color: _accent)),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: AppErrorWidget(
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(dayEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedEventsSliver(
    BuildContext context,
    List<Event> events,
    WidgetRef ref,
  ) {
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final filtered = events.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return filter.isInRange(DateTime(d.year, d.month, d.day));
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          message: 'Aucun evenement trouve',
          icon: Icons.event_busy,
        ),
      );
    }

    final grouped = <DateTime, List<Event>>{};
    for (final e in filtered) {
      final d = DateTime.tryParse(e.dateDebut)!;
      final dateOnly = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }
    final sortedDays = grouped.keys.toList()..sort();

    final children = <Widget>[
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: DateRangeChipBar(),
      ),
      const SizedBox(height: 4),
    ];

    for (final day in sortedDays) {
      final dayLabel = day == today
          ? "Aujourd'hui"
          : day == tomorrow
              ? 'Demain'
              : _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(day));
      children
        ..add(EditorialGroupHeader(
          kicker: dayLabel,
          title: dayLabel,
          count: grouped[day]!.length,
          accent: _accent,
        ))
        ..addAll(grouped[day]!.map((e) => _editorialRowFromEvent(context, e)));
    }

    return SliverList(
      delegate: SliverChildListDelegate(children),
    );
  }

  Widget _buildFeteMusiqueMap(BuildContext context, WidgetRef ref) {
    // Pas de PopScope ici : `ModeShell` enveloppe deja l'ecran avec un PopScope
    // generique qui clear la sous-categorie au back. Ajouter un PopScope local
    // declenchait les deux callbacks dans le meme back → l'outer voyait la
    // sous-cat deja clearee et redirigeait vers /explorer.
    return FeteMusiqueMapView(
      ville: ref.watch(selectedCityProvider),
      onBack: () =>
          ref.read(modeSubcategoriesProvider.notifier).select('day', null),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  Widget _editorialRowFromEvent(BuildContext context, Event event) {
    final parsed = DateTime.tryParse(event.dateDebut);
    final monthAbbr = parsed != null
        ? DateFormat('MMM', 'fr_FR').format(parsed).replaceAll('.', '').toUpperCase()
        : null;
    final dayNum = parsed?.day.toString();
    final weekDay = parsed != null
        ? DateFormat('EEE', 'fr_FR').format(parsed).toLowerCase()
        : null;
    final price = event.isFree
        ? 'Gratuit'
        : (event.tarifNormal.isNotEmpty ? event.tarifNormal : null);

    return EditorialEventRowCard(
      dateMonth: monthAbbr,
      dateDay: dayNum,
      weekDay: weekDay,
      time: event.horaires,
      title: event.titre,
      subtitle: event.descriptifCourt.isNotEmpty ? event.descriptifCourt : null,
      venue: event.lieuNom.isNotEmpty ? event.lieuNom : null,
      price: price,
      imageUrl: event.photoPath,
      accent: _accent,
      onTap: () => EventFullscreenPopup.show(
        context, event, 'assets/images/pochette_concert.png',
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Bandeau "A venir" en haut de la grille, version editoriale.
/// Garde le tap -> ouvre la sous-rubrique "A venir".
class _AvenirBanner extends StatelessWidget {
  final WidgetRef ref;
  final Color accent;

  const _AvenirBanner({required this.ref, required this.accent});

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(daySubcategoryCountProvider('A venir')).valueOrNull;
    return GestureDetector(
      onTap: () =>
          ref.read(modeSubcategoriesProvider.notifier).select('day', 'A venir'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: EditorialColors.dividerSoft,
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A venir',
                    style: EditorialText.catCardTitle(),
                  ),
                  Text(
                    'Selection editorialisee — concerts, spectacles, festivals.',
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
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: EditorialColors.paperMuted,
            ),
          ],
        ),
      ),
    );
  }
}
