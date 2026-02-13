import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dédié aux showcases (artistes émergents, sessions live)
/// des salles et bars musicaux de Toulouse.
///
/// Agrège les résultats de l'API OpenDataSoft Toulouse (filtrage par lieux
/// + mots-clés showcase/live) et des données curatées.
class ShowcaseToulouseService {
  final EventApiService _api;

  ShowcaseToulouseService({EventApiService? api})
      : _api = api ?? EventApiService();

  /// Salles et bars musicaux ciblés pour les showcases à Toulouse.
  static const venueNames = [
    'Metronum',
    'Connexion Live',
    'Taquin',
    'Petit London',
    'Bikini',
    'Rex',
    'Nougaro',
    'Interference',
  ];

  /// Construit la clause WHERE pour filtrer l'API par lieux
  /// + types showcase/live.
  String _buildWhereClause() {
    final now = DateTime.now();
    final dateFrom =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final venueFilters =
        venueNames.map((v) => 'lieu_nom LIKE "%$v%"').join(' OR ');

    return '($venueFilters) '
        'AND (type_de_manifestation LIKE "%Showcase%" '
        'OR type_de_manifestation LIKE "%live%" '
        'OR type_de_manifestation LIKE "%acoustique%" '
        'OR categorie_de_la_manifestation LIKE "%Showcase%") '
        'AND date_debut >= "$dateFrom"';
  }

  /// Récupère les showcases à venir depuis l'API + données curatées,
  /// dédupliqués et triés par date croissante.
  Future<List<Event>> fetchUpcomingShowcases() async {
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
    allEvents.addAll(_getCuratedShowcases());

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
  // Données curatées – showcases à venir 2026
  // ─────────────────────────────────────────────

  /// Showcases curates accessibles publiquement (pour le resolver des likes).
  static List<Event> get curatedShowcases => _getCuratedShowcases();

  static List<Event> _getCuratedShowcases() => [];
}
