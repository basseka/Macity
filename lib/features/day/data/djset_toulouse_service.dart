import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dédié aux DJ sets des clubs et salles de Toulouse et agglomération.
///
/// Agrège les résultats de l'API OpenDataSoft Toulouse (filtrage par lieux
/// de nuit + mots-clés DJ/électro) et des données curatées pour les clubs
/// mal couverts par l'API.
class DjSetToulouseService {
  final EventApiService _api;

  DjSetToulouseService({EventApiService? api})
      : _api = api ?? EventApiService();

  /// Lieux de nuit / clubs ciblés pour les DJ sets à Toulouse.
  static const venueNames = [
    'Bikini',
    'Rex',
    'Connexion Live',
    'Ramier',
    'Warehouse',
    'Petit London',
    'Zig Zag',
    'Purple',
    'Mouette',
    'Usine',
    'Metronum',
  ];

  /// Construit la clause WHERE pour filtrer l'API par lieux de nuit
  /// + types DJ/électro.
  String _buildWhereClause() {
    final now = DateTime.now();
    final dateFrom =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final venueFilters =
        venueNames.map((v) => 'lieu_nom LIKE "%$v%"').join(' OR ');

    return '($venueFilters) '
        'AND (type_de_manifestation LIKE "%DJ%" '
        'OR type_de_manifestation LIKE "%electro%" '
        'OR type_de_manifestation LIKE "%techno%" '
        'OR type_de_manifestation LIKE "%house%" '
        'OR categorie_de_la_manifestation LIKE "%DJ%" '
        'OR categorie_de_la_manifestation LIKE "%electro%") '
        'AND date_debut >= "$dateFrom"';
  }

  /// Récupère les DJ sets à venir depuis l'API + données curatées,
  /// dédupliqués et triés par date croissante.
  Future<List<Event>> fetchUpcomingDjSets() async {
    final List<Event> allEvents = [];

    // 1. API OpenDataSoft Toulouse
    try {
      final apiEvents = await _api.fetchEvents(
        where: _buildWhereClause(),
        limit: 100,
      );
      allEvents.addAll(apiEvents);
    } catch (_) {
      // API indisponible : on continue avec les données curatées
    }

    // 2. Données curatées
    allEvents.addAll(_getCuratedDjSets());

    // 3. Dédoublonnage par titre normalisé + date
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key = '${_normalize(e.titre)}|${e.dateDebut}';
      if (seen.add(key)) {
        deduped.add(e);
      }
    }

    // 4. Filtrer les événements passés
    final now = DateTime.now();
    final upcoming = deduped.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    // 5. Tri chronologique
    upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return upcoming;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // ─────────────────────────────────────────────
  // Données curatées – DJ sets à venir 2026
  // ─────────────────────────────────────────────

  /// DJ sets curates accessibles publiquement (pour le resolver des likes).
  static List<Event> get curatedDjSets => _getCuratedDjSets();

  static List<Event> _getCuratedDjSets() => [];
}
