import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';

/// Sous-categorie source (Spicy, Coquin ou Strip) vers laquelle revenir
/// quand l'utilisateur quitte la carte.
final nightSpicyMapSourceProvider = StateProvider<String>((_) => 'Spicy');

/// Carte plein ecran pour les etablissements Spicy (Coquin + Strip) avec
/// pins colores par type.
class NightSpicyFullscreenMap extends ConsumerWidget {
  const NightSpicyFullscreenMap({super.key});

  static const mapTag = 'Spicy carte';

  static bool isMapTag(String? tag) => tag == mapTag;

  static const _categoryColors = <String, String>{
    'Coquin': '#DC2626', // rouge
    'Strip': '#DB2777',  // magenta
  };

  static const _categoryIcons = <String, String>{
    'Coquin': '💋',
    'Strip': '💃',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(nightSpicyForMapProvider);

    return venuesAsync.when(
      data: (venues) => Stack(
        children: [
          VenuesMapView(
            venues: venues,
            title: 'Lieu le plus proche',
            accentColor: '#7C3AED',
            categoryColors: _categoryColors,
            showLabels: true,
            showClosestPanel: false,
            onVenueTap: (v) => CommerceRowCard.showDetailSheet(context, v),
          ),
          _buildListButton(ref, modeTheme),
        ],
      ),
      loading: () => Stack(
        children: [
          LoadingIndicator(color: modeTheme.primaryColor),
          _buildListButton(ref, modeTheme),
        ],
      ),
      error: (_, __) => Stack(
        children: [
          const Center(child: Text('Erreur de chargement')),
          _buildListButton(ref, modeTheme),
        ],
      ),
    );
  }

  Widget _buildListButton(WidgetRef ref, ModeTheme modeTheme) {
    final source = ref.watch(nightSpicyMapSourceProvider);
    return Positioned(
      top: 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref
              .read(modeSubcategoriesProvider.notifier)
              .select('night', source),
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Liste',
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
      ),
    );
  }
}
