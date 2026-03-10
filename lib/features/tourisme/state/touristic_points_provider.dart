import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/touristic_points_supabase_service.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Provider qui charge les points touristiques depuis Supabase.
final touristicPointsProvider =
    FutureProvider.family<List<CommerceModel>, String?>((ref, categorie) async {
  try {
    final service = TouristicPointsSupabaseService();
    return await service.fetchPoints(categorie: categorie);
  } catch (e) {
    debugPrint('[touristicPointsProvider] Supabase error: $e');
    return [];
  }
});

/// Tous les points touristiques (sans filtre de categorie).
final allTouristicPointsProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  try {
    final service = TouristicPointsSupabaseService();
    return await service.fetchPoints();
  } catch (e) {
    debugPrint('[allTouristicPointsProvider] Supabase error: $e');
    return [];
  }
});
