import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/etablissements_supabase_service.dart';
import 'package:pulz_app/core/helpers/lieu_suggestions.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Provider qui charge les etablissements depuis Supabase par rubrique,
/// avec fallback sur les donnees statiques en cas d'erreur.
final etablissementsProvider =
    FutureProvider.family<List<CommerceModel>, String>((ref, rubrique) async {
  final city = ref.watch(selectedCityProvider);
  if (city.toLowerCase() != 'toulouse') return [];

  try {
    final service = EtablissementsSupabaseService();
    final venues = await service.fetchByRubrique(rubrique);
    if (venues.isNotEmpty) return venues;
    return _staticFallback(rubrique);
  } catch (e) {
    debugPrint('[etablissementsProvider] Supabase error for $rubrique: $e');
    return _staticFallback(rubrique);
  }
});

/// Map Supabase rubrique key → display name for static fallback.
const _keyToDisplay = <String, String>{
  'nuit': 'Nuit',
  'famille': 'En Famille',
  'culture': 'Culture & Arts',
  'food': 'Food & lifestyle',
};

/// Convertit les donnees statiques en CommerceModel pour le fallback.
List<CommerceModel> _staticFallback(String rubrique) {
  final displayName = _keyToDisplay[rubrique] ?? rubrique;
  final lieux = getLieuxForRubriqueStatic(displayName);
  return lieux
      .map((l) => CommerceModel(nom: l.nom, adresse: l.adresse))
      .toList();
}
