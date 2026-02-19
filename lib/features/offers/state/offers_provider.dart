import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';

final activeOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    return await OfferSupabaseService().fetchActiveOffers(city: city);
  } catch (e) {
    debugPrint('[Offers] fetchActiveOffers error: $e');
    return [];
  }
});
