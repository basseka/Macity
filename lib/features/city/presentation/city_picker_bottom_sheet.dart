import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/presentation/widgets/city_list_tile.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/city/state/city_search_provider.dart';

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
      decoration: const BoxDecoration(
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
                  'Choisir une ville',
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
                        ref.watch(selectedCityProvider),
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
                hintText: 'Rechercher une ville...',
                hintStyle: GoogleFonts.geist(color: AppColors.textFaint),
                prefixIcon: const Icon(Icons.search, color: AppColors.magenta),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(citySearchQueryProvider.notifier).state = '';
                        },
                        icon: const Icon(
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
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.line),
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

          // Results list
          Expanded(
            child: searchResults.when(
              data: (cities) {
                if (cities.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune ville trouvee',
                      style: GoogleFonts.geist(
                        color: AppColors.textFaint,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: cities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (context, index) {
                    final ville = cities[index];
                    return CityListTile(
                      ville: ville,
                      onTap: () {
                        ref
                            .read(selectedCityProvider.notifier)
                            .setCity(ville.nom);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.magenta),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Erreur de recherche',
                  style: GoogleFonts.geist(color: AppColors.textFaint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
