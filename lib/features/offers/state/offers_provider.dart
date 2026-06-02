import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

final activeOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    return await OfferSupabaseService().fetchActiveOffers(city: city);
  } catch (e) {
    debugPrint('[Offers] fetchActiveOffers error: $e');
    return [];
  }
});

/// Toutes les offres du pro connecte (actives + expirees + inactives).
/// Vide si pas de pro connecte. Utilise par l'ecran "Mes offres".
final myOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final proState = ref.watch(proAuthProvider);
  final proId = proState.profile?.id;
  if (proId == null || proId.isEmpty) return const [];
  try {
    return await OfferSupabaseService().fetchOffersByPro(proId);
  } catch (e) {
    debugPrint('[Offers] fetchOffersByPro error: $e');
    return [];
  }
});
