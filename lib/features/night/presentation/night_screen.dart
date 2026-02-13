import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';

import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/night/data/night_category_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';

class NightScreen extends ConsumerWidget {
  const NightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(nightCategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              modeTheme.subtitleString,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: selectedCategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildVenueList(context, ref, selectedCategory),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = NightCategoryData.allSubcategories;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        final countAsync =
            ref.watch(nightCategoryCountProvider(sub.searchTag));
        return DaySubcategoryCard(
          emoji: '',
          label: sub.label,
          image: sub.image,
          count: countAsync.valueOrNull,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
            ref.read(nightCategoryProvider.notifier).state = sub.searchTag;
          },
        );
      },
    );
  }

  Widget _buildVenueList(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(nightVenuesProvider);

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(nightCategoryProvider.notifier).state = null;
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
                          fontSize: 13,
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
          child: category == 'Cette Semaine'
              ? _buildUserEventsList(ref)
              : venuesAsync.when(
                  data: (venues) {
                    // Filter matching user events for this subcategory
                    final matchingEvents = ref.watch(nightUserEventsProvider).where((e) {
                      final cat = e.categorie.toLowerCase();
                      final tag = category.toLowerCase();
                      return cat.contains(tag) || tag.contains(cat);
                    }).toList();

                    if (venues.isEmpty && matchingEvents.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun commerce trouve pour cette categorie',
                        icon: Icons.nightlife,
                      );
                    }
                    final items = <Widget>[
                      ...matchingEvents.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EventRowCard(event: e),
                      )),
                      ...venues.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CommerceRowCard(commerce: v),
                      )),
                    ];
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: items,
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

  Widget _buildUserEventsList(WidgetRef ref) {
    final events = ref.watch(nightUserEventsProvider);
    if (events.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement pour le moment.\nAjoute un evenement avec le bouton +',
        icon: Icons.nightlife,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: EventRowCard(event: events[index]),
      ),
    );
  }
}
