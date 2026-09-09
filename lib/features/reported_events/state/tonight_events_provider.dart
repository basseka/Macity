import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Événements d'AUJOURD'HUI (journée + soirée, toutes rubriques/catégories) de
/// la ville sélectionnée. Alimente le carrousel « Quoi faire ce soir ».
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
      limit: 60,
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

/// Parse "14h30, 17h00, 20h30" et retourne `true` si au moins une seance est
/// a 17h ou plus tard. Comme ailleurs dans le code (voir
/// `today_events_provider.dart`), un horaire absent/non parsable ne filtre
/// pas l'event : on l'inclut plutot que de le masquer a tort.
bool _hasEveningShowing(String raw) {
  if (raw.isEmpty) return true;
  final matches = RegExp(r'(\d{1,2})h(\d{0,2})').allMatches(raw).toList();
  if (matches.isEmpty) return true;
  return matches.any((m) => (int.tryParse(m.group(1)!) ?? 0) >= 17);
}

/// Nombre d'evenements de CE SOIR (aujourd'hui, au moins une seance a partir
/// de 17h) — alimente la pastille compteur du bouton "Quoi faire ce soir".
/// Distinct de [tonightEventsProvider] qui, lui, inclut toute la journee
/// (carrousel derriere le bouton, volontairement plus large).
final tonightAfter17hCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(tonightEventsProvider);
  return async.maybeWhen(
    data: (events) =>
        events.where((e) => _hasEveningShowing(e.horaires)).length,
    orElse: () => 0,
  );
});
