import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/presentation/widgets/fitness_venue_card.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Liste de venues sport (fitness, boxe, piscine, etc.)
class SportVenuesList extends ConsumerWidget {
  final String sportType;
  final String displayTitle;
  final String? mapTag;
  final String backLabel;
  final String backTarget;

  const SportVenuesList({
    super.key,
    required this.sportType,
    required this.displayTitle,
    this.mapTag,
    this.backLabel = 'Sport',
    this.backTarget = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(sportVenuesProvider(sportType));

    return Column(
      children: [
        SportBackButton(
          title: displayTitle,
          label: backLabel,
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', backTarget.isEmpty ? null : backTarget),
          leading: mapTag != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', mapTag!),
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
                )
              : null,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: venuesAsync.when(
            data: (venues) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: venues.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FitnessVenueCard(commerce: venues[index]),
              ),
            ),
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => AppErrorWidget(
              message: 'Erreur lors du chargement des venues',
              onRetry: () => ref.invalidate(sportVenuesProvider(sportType)),
            ),
          ),
        ),
      ],
    );
  }
}
