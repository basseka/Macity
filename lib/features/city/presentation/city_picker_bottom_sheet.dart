import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
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
      if (query.length >= 2) {
        ref.read(citySearchQueryProvider.notifier).state = query;
      } else {
        ref.read(citySearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);
    final searchResults = ref.watch(citySearchResultsProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choisir une ville',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: modeTheme.primaryDarkColor,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  color: modeTheme.primaryColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(citySearchQueryProvider.notifier).state =
                              '';
                        },
                        icon: const Icon(Icons.clear, size: 20),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: modeTheme.primaryColor,
                    width: 1.5,
                  ),
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
                      _searchController.text.length < 2
                          ? 'Tape au moins 2 caracteres...'
                          : 'Aucune ville trouvee',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: cities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: modeTheme.primaryColor,
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Erreur de recherche',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
