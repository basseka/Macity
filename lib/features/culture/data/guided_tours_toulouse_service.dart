import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dedie aux visites guidees de Toulouse et agglomeration.
///
/// Requete l'API OpenDataSoft Toulouse (agenda des manifestations)
/// filtree sur les types "Visite" + donnees curatees en fallback.
class GuidedToursToulouseService {
  final EventApiService _api;

  GuidedToursToulouseService({EventApiService? api})
      : _api = api ?? EventApiService();

  /// Construit la clause WHERE pour filtrer l'API sur les visites guidees.
  String _buildWhereClause() {
    final now = DateTime.now();
    final dateFrom =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return '(type_de_manifestation LIKE "%Visite%" '
        'OR type_de_manifestation LIKE "%visite guidee%" '
        'OR type_de_manifestation LIKE "%Balade%" '
        'OR type_de_manifestation LIKE "%Parcours%" '
        'OR categorie_de_la_manifestation LIKE "%Visite%" '
        'OR categorie_de_la_manifestation LIKE "%visite guidee%" '
        'OR categorie_de_la_manifestation LIKE "%Balade%" '
        'OR categorie_de_la_manifestation LIKE "%Parcours%") '
        'AND date_debut >= "$dateFrom"';
  }

  /// Recupere les visites guidees a venir depuis l'API + donnees curatees,
  /// dedupliquees et triees par date croissante.
  Future<List<Event>> fetchUpcomingGuidedTours() async {
    final List<Event> allEvents = [];

    // 1. API OpenDataSoft Toulouse
    try {
      final apiEvents = await _api.fetchEvents(
        where: _buildWhereClause(),
        limit: 100,
      );
      allEvents.addAll(apiEvents);
    } catch (_) {
      // API indisponible : on continue avec les donnees curatees
    }

    // 2. Donnees curatees
    allEvents.addAll(_curatedGuidedTours);

    // 3. Dedoublonnage par titre normalise + date
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key = '${_normalize(e.titre)}|${e.dateDebut}';
      if (seen.add(key)) {
        deduped.add(e);
      }
    }

    // 4. Filtrer les evenements passes
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
  // Donnees curatees – visites guidees 2026
  // ─────────────────────────────────────────────

  static const _curatedGuidedTours = <Event>[
    Event(
      identifiant: 'visite_capitole',
      titre: 'Visite Guidee du Capitole de Toulouse',
      descriptifCourt: 'Decouverte de l\'hotel de ville et de ses salles historiques.',
      dateDebut: '2026-03-01',
      dateFin: '2026-12-31',
      horaires: 'Sam-Dim 10h30 et 14h30',
      lieuNom: 'Capitole de Toulouse',
      lieuAdresse: 'Place du Capitole, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'oui',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
    Event(
      identifiant: 'visite_basilique_sernin',
      titre: 'Visite Guidee de la Basilique Saint-Sernin',
      descriptifCourt: 'Plus grande eglise romane d\'Europe, patrimoine mondial UNESCO.',
      dateDebut: '2026-03-01',
      dateFin: '2026-12-31',
      horaires: 'Mar-Sam 14h30',
      lieuNom: 'Basilique Saint-Sernin',
      lieuAdresse: 'Place Saint-Sernin, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '6€',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
    Event(
      identifiant: 'visite_jacobins',
      titre: 'Visite du Couvent des Jacobins',
      descriptifCourt: 'Chef-d\'oeuvre du gothique meridional, celebre palmier des Jacobins.',
      dateDebut: '2026-03-01',
      dateFin: '2026-12-31',
      horaires: 'Mar-Dim 10h-18h',
      lieuNom: 'Couvent des Jacobins',
      lieuAdresse: 'Place des Jacobins, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '5€',
      reservationUrl: 'https://www.jacobins.toulouse.fr/',
    ),
    Event(
      identifiant: 'visite_canal_midi',
      titre: 'Balade Guidee le long du Canal du Midi',
      descriptifCourt: 'Promenade commentee sur les berges du Canal du Midi, patrimoine UNESCO.',
      dateDebut: '2026-04-01',
      dateFin: '2026-10-31',
      horaires: 'Sam 10h',
      lieuNom: 'Canal du Midi - Port Saint-Sauveur',
      lieuAdresse: 'Port Saint-Sauveur, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'oui',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
    Event(
      identifiant: 'visite_hotel_assezat',
      titre: 'Visite de l\'Hotel d\'Assezat et Fondation Bemberg',
      descriptifCourt: 'Hotel particulier Renaissance et collection d\'art europeen.',
      dateDebut: '2026-03-01',
      dateFin: '2026-12-31',
      horaires: 'Mar-Dim 10h-18h',
      lieuNom: 'Hotel d\'Assezat - Fondation Bemberg',
      lieuAdresse: 'Place d\'Assezat, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '10€',
      reservationUrl: 'https://www.fondation-bemberg.fr/',
    ),
    Event(
      identifiant: 'visite_cite_espace',
      titre: 'Visite Guidee de la Cite de l\'Espace',
      descriptifCourt: 'Parcours guide a travers les expositions spatiales.',
      dateDebut: '2026-02-01',
      dateFin: '2026-12-31',
      horaires: 'Tous les jours 10h et 14h',
      lieuNom: 'Cite de l\'Espace',
      lieuAdresse: 'Avenue Jean Gonord, 31500 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '25-27€',
      reservationUrl: 'https://www.cite-espace.com/',
    ),
    Event(
      identifiant: 'visite_aeroscopia',
      titre: 'Visite Guidee Aeroscopia - Concorde et A380',
      descriptifCourt: 'Decouverte des avions mythiques avec guide specialise.',
      dateDebut: '2026-02-01',
      dateFin: '2026-12-31',
      horaires: 'Sam-Dim 14h30',
      lieuNom: 'Musee Aeroscopia',
      lieuAdresse: '1 Allee Andre Turcat, 31700 Blagnac',
      commune: 'Blagnac',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '15€',
      reservationUrl: 'https://www.musee-aeroscopia.fr/',
    ),
    Event(
      identifiant: 'visite_toulouse_nocturne',
      titre: 'Visite Nocturne de Toulouse - La Ville Rose au clair de lune',
      descriptifCourt: 'Parcours nocturne dans le centre historique illumine.',
      dateDebut: '2026-05-01',
      dateFin: '2026-09-30',
      horaires: 'Ven 21h30',
      lieuNom: 'Office de Tourisme - Depart',
      lieuAdresse: 'Square Charles de Gaulle, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '12€',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
    Event(
      identifiant: 'visite_quartier_saint_etienne',
      titre: 'Balade dans le Quartier Saint-Etienne',
      descriptifCourt: 'Decouverte des hotels particuliers et de la cathedrale.',
      dateDebut: '2026-03-15',
      dateFin: '2026-12-31',
      horaires: 'Mer 15h',
      lieuNom: 'Cathedrale Saint-Etienne - Depart',
      lieuAdresse: 'Place Saint-Etienne, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Visite guidee',
      manifestationGratuite: 'non',
      tarifNormal: '8€',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
    Event(
      identifiant: 'visite_garonne_peniche',
      titre: 'Croisiere Commentee sur la Garonne',
      descriptifCourt: 'Decouverte de Toulouse vue depuis la Garonne en peniche.',
      dateDebut: '2026-04-01',
      dateFin: '2026-10-31',
      horaires: 'Sam-Dim 11h et 15h',
      lieuNom: 'Embarcadere des Daurades',
      lieuAdresse: 'Quai de la Daurade, 31000 Toulouse',
      commune: 'Toulouse',
      categorie: 'Visite',
      type: 'Balade',
      manifestationGratuite: 'non',
      tarifNormal: '14€',
      reservationUrl: 'https://www.toulouse-tourisme.com/',
    ),
  ];
}
