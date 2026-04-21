import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';

/// Categorie vers laquelle revenir quand on quitte la carte (cat precedente).
/// Permet au bouton "Liste" de ramener l'utilisateur a la sous-categorie
/// depuis laquelle il a ouvert la carte.
final nightBarsMapSourceProvider = StateProvider<String>((_) => 'Bar de nuit');

/// Carte plein ecran affichant tous les bars de la ville courante, avec pins
/// colores par type (Bar de nuit / Pub / Bar a cocktails / Bar a chicha).
class NightBarsFullscreenMap extends ConsumerWidget {
  const NightBarsFullscreenMap({super.key});

  static const mapTag = 'Bars carte';

  static bool isMapTag(String? tag) => tag == mapTag;

  /// Couleurs pins (hex #RRGGBB) par type de bar.
  static const _categoryColors = <String, String>{
    'Bar de nuit': '#6366F1',     // indigo
    'Bar a cocktails': '#EC4899', // rose
    'Pub': '#F59E0B',             // amber
    'Bar a chicha': '#14B8A6',    // teal
  };

  /// Emojis pins par type (facultatif — joue bien avec _categoryColors).
  static const _categoryIcons = <String, String>{
    'Bar de nuit': '🌙',
    'Bar a cocktails': '🍸',
    'Pub': '🍺',
    'Bar a chicha': '💨',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(nightBarsForMapProvider);

    return venuesAsync.when(
      data: (venues) => Stack(
        children: [
          VenuesMapView(
            venues: venues,
            title: 'Bar le plus proche',
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
    final source = ref.watch(nightBarsMapSourceProvider);
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
