import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/data/festik_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dédié aux festivals de Toulouse et agglomération.
///
/// Pipeline multi-source :
/// 1. API OpenDataSoft Toulouse (agenda culturel)
/// 2. Festik (billetterie festivals)
/// 3. Données curatées (fallback)
class FestivalToulouseService {
  final EventApiService _api;
  final FestikApiService _festik;

  FestivalToulouseService({
    EventApiService? api,
    FestikApiService? festik,
  })  : _api = api ?? EventApiService(),
        _festik = festik ?? FestikApiService();

  Future<List<Event>> fetchUpcomingFestivals() async {
    final List<Event> allEvents = [];

    // 1. API OpenDataSoft Toulouse
    try {
      final now = DateTime.now();
      final dateFrom =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final apiEvents = await _api.fetchEvents(
        where:
            '(type_de_manifestation LIKE "%Festival%" OR categorie_de_la_manifestation LIKE "%Festival%") '
            'AND date_debut >= "$dateFrom"',
        limit: 100,
      );
      allEvents.addAll(apiEvents);
    } catch (_) {}

    // 2. Festik (billetterie festivals)
    try {
      final festikEvents = await _festik.fetchToulouseEvents();
      allEvents.addAll(festikEvents);
    } catch (_) {}

    // 3. Données curatées
    allEvents.addAll(_getCuratedFestivals());

    // 4. Dédoublonnage
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key =
          '${e.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${e.dateDebut}';
      if (seen.add(key)) deduped.add(e);
    }

    // 5. Filtrer passés
    final now = DateTime.now();
    final upcoming = deduped.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    // 6. Tri chronologique
    upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return upcoming;
  }

  static List<Event> _getCuratedFestivals() => [
        // ── Le Printemps du Rire 2026 (source: festik.net) ──
        const Event(
          identifiant: 'fest_printemps_du_rire_2026',
          titre: 'Le Printemps du Rire 2026',
          dateDebut: '2026-03-15',
          dateFin: '2026-04-11',
          horaires: '20h30',
          lieuNom: 'Divers lieux - Toulouse & agglomeration',
          commune: 'Toulouse',
          categorie: 'Festival',
          type: 'Festival',
          manifestationGratuite: 'non',
          tarifNormal: '3-53€',
          reservationUrl: 'https://billetterie.festik.net/leprintempsdurire/',
        ),

        // ── Pink Tolosa 2026 - 10e edition (source: billetweb.fr) ──
        const Event(
          identifiant: 'fest_pink_tolosa_2026',
          titre: 'Pink Tolosa 2026 - 10e Edition',
          dateDebut: '2026-03-06',
          dateFin: '2026-03-09',
          horaires: '16h00',
          lieuNom: 'Le Sing Sing',
          lieuAdresse: '90 Chemin de la Flambere, 31300 Toulouse',
          commune: 'Toulouse',
          categorie: 'Festival',
          type: 'Festival',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.billetweb.fr/pink-tolosa-2026',
        ),
      ];
}
