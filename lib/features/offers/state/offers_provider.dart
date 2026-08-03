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

/// Offre active par commerce, indexee sur `sourceTable#sourceId`. Sert a la
/// fois a badger la pochette et a afficher l'offre dans la fiche detail, sans
/// requete supplementaire : on reutilise la liste deja chargee par
/// [activeOffersProvider], qui applique deja les filtres ville / actif / non
/// expiree. Vide tant que les offres chargent, donc l'affichage apparait quand
/// la donnee arrive plutot que de faire clignoter un etat faux.
///
/// Si plusieurs offres visent le meme commerce, la premiere gagne :
/// `fetchActiveOffers` trie par `created_at desc`, c'est donc la plus recente.
final offerByVenueProvider = Provider<Map<String, Offer>>((ref) {
  final offers = ref.watch(activeOffersProvider);
  return offers.maybeWhen(
    data: (list) {
      final map = <String, Offer>{};
      for (final o in list) {
        final key = o.venueKey;
        if (key != null) map.putIfAbsent(key, () => o);
      }
      return map;
    },
    orElse: () => const <String, Offer>{},
  );
});

/// Cles des commerces qui portent une offre active. Derive de
/// [offerByVenueProvider] pour qu'il n'existe qu'une seule definition de ce
/// qu'est « un commerce avec une offre ».
final offerVenueKeysProvider = Provider<Set<String>>((ref) {
  return ref.watch(offerByVenueProvider).keys.toSet();
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
