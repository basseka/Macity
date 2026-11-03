import 'dart:async';
import 'package:pulz_app/core/l10n/locale_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/presentation/widgets/city_list_tile.dart';
import 'package:pulz_app/features/city/state/city_search_provider.dart';
import 'package:pulz_app/features/city/state/search_area_provider.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

class CityPickerBottomSheet extends ConsumerStatefulWidget {
  const CityPickerBottomSheet({super.key});

  @override
  ConsumerState<CityPickerBottomSheet> createState() =>
      _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState
    extends ConsumerState<CityPickerBottomSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(citySearchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(citySearchResultsProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title + current city
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(
                  context.l10n.cityPickerTitle,
                  style: GoogleFonts.geist(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    boxShadow: AppShadows.neon(AppColors.magenta, blur: 10, y: 3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        ref.watch(areaVilleProvider),
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: GoogleFonts.geist(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: context.l10n.cityPickerHint,
                hintStyle: GoogleFonts.geist(color: AppColors.textFaint),
                prefixIcon: const Icon(Icons.search, color: AppColors.magenta),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(citySearchQueryProvider.notifier).state = '';
                        },
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: AppColors.textFaint,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceHi,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.magenta, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Results list : position, villes hub, puis autres communes.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _useMyLocationTile(),
                Divider(height: 1, color: AppColors.line),
                ...searchResults.when(
                  data: (cities) => [
                    for (final ville in cities) ...[
                      CityListTile(
                        ville: ville,
                        onTap: () {
                          ref
                              .read(searchAreaProvider.notifier)
                              .forceHub(ville.nom);
                          Navigator.of(context).pop();
                        },
                      ),
                      Divider(height: 1, color: AppColors.line),
                    ],
                  ],
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.magenta,),
                      ),
                    ),
                  ],
                  error: (_, __) => [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          context.l10n.cityPickerError,
                          style: GoogleFonts.geist(color: AppColors.textFaint),
                        ),
                      ),
                    ),
                  ],
                ),
                ..._communeSection(
                  hubsEmpty: searchResults.valueOrNull?.isEmpty ?? false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Repasse en mode automatique : la zone suit la position de l'utilisateur.
  Widget _useMyLocationTile() {
    final area = ref.watch(searchAreaProvider);
    final following = area != null &&
        area.fromGps &&
        !ref.read(searchAreaProvider.notifier).isForced;
    return ListTile(
      onTap: () async {
        final ok =
            await ref.read(searchAreaProvider.notifier).useMyLocation();
        if (!mounted) return;
        if (ok) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.cityPickerLocationDenied)),
          );
        }
      },
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
      ),
      title: Text(
        context.l10n.cityPickerUseMyLocation,
        style: GoogleFonts.geist(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        following
            ? context.l10n.cityPickerFollowing(area.nom)
            : context.l10n.cityPickerUseMyLocationSub,
        style: GoogleFonts.geist(color: AppColors.textFaint, fontSize: 12),
      ),
    );
  }

  /// Communes hors villes hub (Albi, Montauban…) trouvées par la recherche.
  List<Widget> _communeSection({required bool hubsEmpty}) {
    final communes = ref.watch(communeSearchProvider).valueOrNull ?? const [];
    final query = ref.watch(citySearchQueryProvider).trim();
    if (communes.isEmpty) {
      if (hubsEmpty && query.length >= 2 &&
          !ref.watch(communeSearchProvider).isLoading) {
        return [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                context.l10n.cityPickerNone,
                style: GoogleFonts.geist(
                  color: AppColors.textFaint,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ];
      }
      return const [];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          context.l10n.cityPickerOtherCommunes.toUpperCase(),
          style: GoogleFonts.geist(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textFaint,
          ),
        ),
      ),
      for (final c in communes) ...[
        CityListTile(
          ville: VilleModel(
            nom: c.nom,
            codePostal: c.codePostal,
            departement: c.hub,
            population: c.population,
          ),
          onTap: () {
            ref.read(searchAreaProvider.notifier).forceCommune(c);
            Navigator.of(context).pop();
          },
        ),
        Divider(height: 1, color: AppColors.line),
      ],
    ];
  }

}
