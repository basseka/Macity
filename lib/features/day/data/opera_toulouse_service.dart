import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dédié aux opéras et spectacles lyriques de Toulouse.
class OperaToulouseService {
  final EventApiService _api;

  OperaToulouseService({EventApiService? api})
      : _api = api ?? EventApiService();

  Future<List<Event>> fetchUpcomingOperas() async {
    final List<Event> allEvents = [];

    // 1. API OpenDataSoft Toulouse
    try {
      final now = DateTime.now();
      final dateFrom =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final apiEvents = await _api.fetchEvents(
        where:
            '(type_de_manifestation LIKE "%Opera%" OR type_de_manifestation LIKE "%Lyrique%" '
            'OR categorie_de_la_manifestation LIKE "%Opera%") '
            'AND date_debut >= "$dateFrom"',
        limit: 100,
      );
      allEvents.addAll(apiEvents);
    } catch (_) {}

    // 2. Données curatées
    allEvents.addAll(_getCuratedOperas());

    // 3. Dédoublonnage
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key =
          '${e.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${e.dateDebut}';
      if (seen.add(key)) deduped.add(e);
    }

    // 4. Filtrer passés
    final now = DateTime.now();
    final upcoming = deduped.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    // 5. Tri chronologique
    upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return upcoming;
  }

  /// Operas curates accessibles publiquement (pour le resolver des likes).
  static List<Event> get curatedOperas => _getCuratedOperas();

  static List<Event> _getCuratedOperas() => [];
}
