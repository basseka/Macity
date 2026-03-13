import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/culture/presentation/widgets/dance_venue_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Liste des salles de danse groupees par style.
class DanceVenuesList extends ConsumerWidget {
  const DanceVenuesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final dancesAsync = ref.watch(danceVenuesProvider);

    return Column(
      children: [
        SportBackButton(
          title: 'Danse',
          label: 'Sport',
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', null),
          leading: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Danse carte'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: modeTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Carte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dancesAsync.when(
            data: (dances) {
              final groupOrder = <String>[];
              for (final d in dances) {
                if (d.group.isNotEmpty && !groupOrder.contains(d.group)) {
                  groupOrder.add(d.group);
                }
              }

              final items = <Widget>[];
              for (final group in groupOrder) {
                final groupVenues = dances.where((d) => d.group == group).toList();
                items.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(group, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: modeTheme.primaryDarkColor)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: modeTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                    '${groupVenues.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: modeTheme.primaryColor),
                  ),
                        ),
                      ],
                    ),
                  ),
                );
                for (final venue in groupVenues) {
                  items.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: DanceVenueCard(dance: venue),
                  ));
                }
              }

              return ListView(padding: const EdgeInsets.only(bottom: 16), children: items);
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => const AppErrorWidget(message: 'Erreur lors du chargement des salles de danse'),
          ),
        ),
      ],
    );
  }
}
