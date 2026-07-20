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
