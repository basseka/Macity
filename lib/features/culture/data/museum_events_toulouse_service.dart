import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dedie aux evenements des musees de Toulouse et agglomeration.
///
/// Agrege les resultats de l'API OpenDataSoft Toulouse (filtrage par musee)
/// et des donnees curatees pour les musees mal couverts par l'API.
class MuseumEventsToulouseService {
  final EventApiService _api;

  MuseumEventsToulouseService({EventApiService? api})
      : _api = api ?? EventApiService();

  /// Noms normalises des musees cibles, utilises pour le filtrage API.
  static const venueNames = [
    'Augustins',
    'Abattoirs',
    'Bemberg',
    'Paul-Dupuy',
    'Saint-Raymond',
    'Vieux Toulouse',
    'Histoire de la Medecine',
    'Resistance',
    'Georges Labit',
    'Museum de Toulouse',
    'Jardins du Museum',
    'Cite de l\'Espace',
    'Aeroscopia',
    'Envol des Pionniers',
    'Halle de la Machine',
    'Espace Patrimoine',
    'Chateau d\'Eau',
  ];

  /// Construit la clause WHERE pour filtrer l'API par musees + types culturels.
  String _buildWhereClause() {
    final now = DateTime.now();
    final dateFrom =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final venueFilters =
        venueNames.map((v) => 'lieu_nom LIKE "%$v%"').join(' OR ');

    return '($venueFilters) '
        'AND (type_de_manifestation LIKE "%Exposition%" '
        'OR type_de_manifestation LIKE "%Visite%" '
        'OR type_de_manifestation LIKE "%Atelier%" '
        'OR type_de_manifestation LIKE "%Vernissage%" '
        'OR type_de_manifestation LIKE "%Animation%" '
        'OR categorie_de_la_manifestation LIKE "%Exposition%" '
        'OR categorie_de_la_manifestation LIKE "%Visite%" '
        'OR categorie_de_la_manifestation LIKE "%Atelier%" '
        'OR categorie_de_la_manifestation LIKE "%Vernissage%" '
        'OR categorie_de_la_manifestation LIKE "%Animation%") '
        'AND date_debut >= "$dateFrom"';
  }

  /// Recupere les evenements musees a venir depuis l'API + donnees curatees,
  /// dedupliques et tries par date croissante.
  Future<List<Event>> fetchUpcomingMuseumEvents() async {
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
    final curated = _getCuratedMuseumEvents();
    allEvents.addAll(curated);

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
  // Donnees curatees – evenements musees 2026
  // ─────────────────────────────────────────────

  static List<Event> _getCuratedMuseumEvents() => [
        // ── Musee des Augustins ──
        const Event(
          identifiant: 'musee_augustins_1',
          titre: 'Collections Permanentes - Peinture et Sculpture du Moyen Age au XXe siecle',
          dateDebut: '2026-01-01',
          dateFin: '2026-12-31',
          horaires: '10h00-18h00 (ferme mardi)',
          lieuNom: 'Musee des Augustins',
          lieuAdresse: '21 Rue de Metz, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '5€ (gratuit 1er dimanche)',
          reservationUrl: 'https://www.augustins.org/',
        ),

        // ── Les Abattoirs ──
        const Event(
          identifiant: 'musee_abattoirs_1',
          titre: 'Picasso et l\'Exil - Guernica en dialogue',
          dateDebut: '2026-02-15',
          dateFin: '2026-06-15',
          horaires: '12h00-18h00 (ferme lundi)',
          lieuNom: 'Les Abattoirs - Musee d\'Art Moderne et Contemporain',
          lieuAdresse: '76 Allees Charles de Fitte, 31300 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '8€',
          reservationUrl: 'https://www.lesabattoirs.org/',
        ),
        const Event(
          identifiant: 'musee_abattoirs_2',
          titre: 'Visite Guidee - Art Contemporain et Patrimoine Industriel',
          dateDebut: '2026-03-07',
          horaires: '15h00',
          lieuNom: 'Les Abattoirs - Musee d\'Art Moderne et Contemporain',
          lieuAdresse: '76 Allees Charles de Fitte, 31300 Toulouse',
          commune: 'Toulouse',
          categorie: 'Visite',
          type: 'Visite guidee',
          manifestationGratuite: 'non',
          tarifNormal: '3€ (en plus de l\'entree)',
          reservationUrl: 'https://www.lesabattoirs.org/',
        ),

        // ── Fondation Bemberg ──
        const Event(
          identifiant: 'musee_bemberg_1',
          titre: 'Bonnard, Vuillard et les Nabis - Collection Bemberg',
          dateDebut: '2026-01-01',
          dateFin: '2026-12-31',
          horaires: '10h00-18h00 (ferme lundi)',
          lieuNom: 'Fondation Bemberg - Hotel d\'Assezat',
          lieuAdresse: 'Place d\'Assezat, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '10€',
          reservationUrl: 'https://www.fondation-bemberg.fr/',
        ),

        // ── Musee Saint-Raymond ──
        const Event(
          identifiant: 'musee_straymond_1',
          titre: 'L\'Antiquite Romaine a Toulouse - Collections Permanentes',
          dateDebut: '2026-01-01',
          dateFin: '2026-12-31',
          horaires: '10h00-18h00',
          lieuNom: 'Musee Saint-Raymond',
          lieuAdresse: '1 ter Place Saint-Sernin, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '5€ (gratuit 1er dimanche)',
          reservationUrl: 'https://saintraymond.toulouse.fr/',
        ),

        // ── Cite de l'Espace ──
        const Event(
          identifiant: 'musee_cite_espace_1',
          titre: 'Lune : Episode II - Nouvelle Exposition Immersive',
          dateDebut: '2026-02-01',
          dateFin: '2026-11-30',
          horaires: '10h00-17h00',
          lieuNom: 'Cite de l\'Espace',
          lieuAdresse: 'Avenue Jean Gonord, 31500 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '25-27€',
          reservationUrl: 'https://www.cite-espace.com/',
        ),

        // ── Aeroscopia ──
        const Event(
          identifiant: 'musee_aeroscopia_1',
          titre: 'Concorde et l\'Aventure Aeronautique - Visite Guidee',
          dateDebut: '2026-03-14',
          horaires: '14h30',
          lieuNom: 'Aeroscopia - Musee Aeronautique',
          lieuAdresse: '1 Allee Andre Turcat, 31700 Blagnac',
          commune: 'Blagnac',
          categorie: 'Visite',
          type: 'Visite guidee',
          manifestationGratuite: 'non',
          tarifNormal: '15€',
          reservationUrl: 'https://www.musee-aeroscopia.fr/',
        ),

        // ── Museum de Toulouse ──
        const Event(
          identifiant: 'musee_museum_1',
          titre: 'Exposition Temporaire - Biodiversite, Tous Vivants !',
          dateDebut: '2026-02-20',
          dateFin: '2026-09-30',
          horaires: '10h00-18h00 (ferme lundi)',
          lieuNom: 'Museum de Toulouse',
          lieuAdresse: '35 Allees Jules Guesde, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '9€',
          reservationUrl: 'https://www.museum.toulouse.fr/',
        ),

        // ── Halle de la Machine ──
        const Event(
          identifiant: 'musee_halle_machine_1',
          titre: 'Le Minotaure et les Machines Geantes - Visite Animee',
          dateDebut: '2026-02-14',
          dateFin: '2026-12-31',
          horaires: '11h00-19h00',
          lieuNom: 'La Halle de la Machine',
          lieuAdresse: '3 Avenue de l\'Aerodrome de Montaudran, 31400 Toulouse',
          commune: 'Toulouse',
          categorie: 'Animation',
          type: 'Animations culturelles',
          manifestationGratuite: 'non',
          tarifNormal: '8-10€',
          reservationUrl: 'https://www.halledelamachine.fr/',
        ),

        // ── Galerie Le Chateau d'Eau ──
        const Event(
          identifiant: 'musee_chateau_eau_1',
          titre: 'Exposition Photographique - Regards Croises',
          dateDebut: '2026-03-01',
          dateFin: '2026-05-25',
          horaires: '13h00-19h00 (ferme lundi)',
          lieuNom: 'Galerie Le Chateau d\'Eau',
          lieuAdresse: '1 Place Laganne, 31300 Toulouse',
          commune: 'Toulouse',
          categorie: 'Exposition',
          type: 'Exposition',
          manifestationGratuite: 'non',
          tarifNormal: '4€',
          reservationUrl: 'https://www.galeriechateaudeau.org/',
        ),
      ];
}
