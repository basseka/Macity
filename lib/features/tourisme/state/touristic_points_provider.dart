import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/touristic_points_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Provider qui charge les points touristiques depuis Supabase, filtré par ville.
final touristicPointsProvider =
    FutureProvider.family<List<CommerceModel>, String?>((ref, categorie) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = TouristicPointsSupabaseService();
    return await service.fetchPoints(ville: city, categorie: categorie);
  } catch (e) {
    debugPrint('[touristicPointsProvider] Supabase error: $e');
    return [];
  }
});

/// Tous les points touristiques (sans filtre de categorie), filtré par ville.
final allTouristicPointsProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = TouristicPointsSupabaseService();
    return await service.fetchPoints(ville: city);
  } catch (e) {
    debugPrint('[allTouristicPointsProvider] Supabase error: $e');
    return [];
  }
});
