import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Événements d'AUJOURD'HUI (journée + soirée, toutes rubriques/catégories) de
/// la ville sélectionnée. Alimente le carrousel « Quoi faire ce soir » ET la
/// pastille compteur du bouton du meme nom (meme liste, meme longueur, pour
/// que les deux affichent toujours le meme chiffre).
///
/// Limit volontairement large (500) : sur une seule ville et une seule
/// journee, on ne s'attend jamais a en approcher le compte, mais un plafond
/// bas (l'ancien 60) tronquait silencieusement la liste et faisait mentir le
/// compteur.
final tonightEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final now = DateTime.now();
  String pad(int v) => v.toString().padLeft(2, '0');
  final todayStr = '${now.year}-${pad(now.month)}-${pad(now.day)}';

  try {
    final (events, _) = await ScrapedEventsSupabaseService().fetchAllEvents(
      dateGte: todayStr,
      ville: city,
      limit: 500,
    );
    // Uniquement les events qui commencent aujourd'hui.
    return events.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return '${d.year}-${pad(d.month)}-${pad(d.day)}' == todayStr;
    }).toList();
  } catch (_) {
    return const <Event>[];
  }
});

/// Nombre d'evenements d'aujourd'hui — alimente la pastille compteur du
/// bouton "Quoi faire ce soir". Toujours egal a la longueur de la liste
/// affichee dans [TonightEventsSheet] (meme provider source).
final tonightEventsCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(tonightEventsProvider);
  return async.maybeWhen(
    data: (events) => events.length,
    orElse: () => 0,
  );
});
