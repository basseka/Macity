import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape les expositions / salons a venir depuis meett.fr.
class MeettExhibitorService {
  static const _url = 'https://meett.fr/en/exhibitor/';

  final Dio _dio;

  MeettExhibitorService({Dio? dio}) : _dio = dio ?? Dio();

  /// Mois abreges anglais utilises sur le site MEETT.
  static const _months = {
    'JAN': '01', 'FEB': '02', 'FEV': '02', 'MAR': '03',
    'APR': '04', 'AVR': '04', 'MAY': '05', 'MAI': '05',
    'JUN': '06', 'JUL': '07', 'AUG': '08', 'AOU': '08',
    'SEP': '09', 'OCT': '10', 'NOV': '11', 'DEC': '12',
  };

  /// Recupere les evenements depuis le site MEETT, avec fallback curate.
  Future<List<Event>> fetchExhibitions() async {
    try {
      final scraped = await _scrape();
      if (scraped.isNotEmpty) return scraped;
    } catch (_) {
      // Fallback silencieux
    }
    return _curatedEvents;
  }

  Future<List<Event>> _scrape() async {
    final response = await _dio.get(
      _url,
      options: Options(
        headers: {'User-Agent': 'MaCityApp/1.0'},
        responseType: ResponseType.plain,
      ),
    );
    final html = response.data as String;
    return _parseEvents(html);
  }

  /// Parse le HTML du site MEETT pour extraire les evenements.
  List<Event> _parseEvents(String html) {
    final events = <Event>[];

    // Chaque evenement est dans un bloc avec la classe elementor-post
    // Titre dans un <h3> avec lien, dates dans un <span> specifique
    // Pattern pour titres : <h3 ...><a ...>TITRE</a></h3>
    final titlePattern = RegExp(
      r'<h3[^>]*class="[^"]*elementor-post__title[^"]*"[^>]*>\s*<a[^>]*>(.*?)</a>\s*</h3>',
      dotAll: true,
    );

    // Pattern pour dates : "DD-DD MMM YYYY" ou "DD MMM - DD MMM YYYY"
    final dateBlockPattern = RegExp(
      r'(\d{1,2})\s*[-–]\s*(\d{1,2})\s+([A-ZÉ]{3,4})\s+(\d{4})',
      caseSensitive: false,
    );

    // Pattern pour type : "Public" ou "Professional"
    final typePattern = RegExp(
      r'(Public|Professional|Professionnel)\s*Event',
      caseSensitive: false,
    );

    // Pattern pour organisateur
    final organizerPattern = RegExp(
      r'Organis[ée]e?\s+(?:par|by)\s*:?\s*([^<\n]+)',
      caseSensitive: false,
    );

    // Pattern pour image
    final imagePattern = RegExp(
      r'<img[^>]*src="(https://meett\.fr/wp-content/uploads/[^"]+)"',
    );

    // Decouper par blocs d'evenements
    final blocks = html.split(RegExp(r'elementor-post\b'));

    for (final block in blocks.skip(1)) {
      final titleMatch = titlePattern.firstMatch(block);
      if (titleMatch == null) continue;

      final titre = _cleanHtml(titleMatch.group(1) ?? '');
      if (titre.isEmpty) continue;

      // Dates
      String dateDebut = '';
      String dateFin = '';
      String horaires = '';
      final dateMatch = dateBlockPattern.firstMatch(block);
      if (dateMatch != null) {
        final dayStart = dateMatch.group(1)!.padLeft(2, '0');
        final dayEnd = dateMatch.group(2)!.padLeft(2, '0');
        final monthStr = dateMatch.group(3)!.toUpperCase();
        final year = dateMatch.group(4)!;
        final month = _months[monthStr] ?? '01';
        dateDebut = '$year-$month-$dayStart';
        dateFin = '$year-$month-$dayEnd';
        horaires = '$dayStart-$dayEnd ${dateMatch.group(3)} $year';
      }

      // Type
      final typeMatch = typePattern.firstMatch(block);
      final isPublic = typeMatch != null &&
          typeMatch.group(1)!.toLowerCase().startsWith('public');

      // Organisateur
      final orgMatch = organizerPattern.firstMatch(block);
      final organizer = orgMatch != null ? _cleanHtml(orgMatch.group(1)!) : '';

      // Image
      final imgMatch = imagePattern.firstMatch(block);
      final imageUrl = imgMatch?.group(1);

      final id = 'meett_${titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

      events.add(Event(
        identifiant: id,
        titre: titre,
        descriptifCourt: isPublic ? 'Salon grand public' : 'Salon professionnel',
        descriptifLong: organizer.isNotEmpty ? 'Organise par $organizer' : '',
        dateDebut: dateDebut,
        dateFin: dateFin,
        horaires: horaires,
        lieuNom: 'MEETT - Parc des Expositions',
        lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
        commune: 'Toulouse',
        categorie: 'Exposition',
        type: isPublic ? 'Salon grand public' : 'Salon professionnel',
        reservationUrl: 'https://meett.fr/en/exhibitor/',
        photoPath: imageUrl,
      ),);
    }

    // Filtrer les evenements passes
    final now = DateTime.now();
    events.removeWhere((e) {
      if (e.dateFin.isEmpty) return false;
      final fin = DateTime.tryParse(e.dateFin);
      return fin != null && fin.isBefore(now);
    });

    // Tri chrono
    events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return events;
  }

  String _cleanHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&#8217;'), "'")
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Donnees curatees en cas d'echec du scraping.
  static final _curatedEvents = [
    const Event(
      identifiant: 'meett_art3f_2026',
      titre: 'art3f - Salon international d\'art contemporain',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par art3f',
      dateDebut: '2026-02-12',
      dateFin: '2026-02-15',
      horaires: '12-15 FEV 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_vins_terroirs_2026',
      titre: 'Salon Vins & Terroirs Printemps',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Toulouse events',
      dateDebut: '2026-03-13',
      dateFin: '2026-03-15',
      horaires: '13-15 MARS 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_immobilier_2026',
      titre: 'Salon de l\'Immobilier',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Toulouse events',
      dateDebut: '2026-03-13',
      dateFin: '2026-03-15',
      horaires: '13-15 MARS 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_occygene_2026',
      titre: 'Salon OCC\'YGENE',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Toulouse events',
      dateDebut: '2026-03-27',
      dateFin: '2026-03-29',
      horaires: '27-29 MARS 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_vivre_nature_2026',
      titre: 'VIVRE NATURE',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Sarl BIO ETC',
      dateDebut: '2026-03-27',
      dateFin: '2026-03-29',
      horaires: '27-29 MARS 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_foire_internationale_2026',
      titre: 'Foire Internationale de Toulouse',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Toulouse events',
      dateDebut: '2026-04-10',
      dateFin: '2026-04-19',
      horaires: '10-19 AVR 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_camping_car_2026',
      titre: 'Salon du Camping-Car',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par Libertium',
      dateDebut: '2026-05-14',
      dateFin: '2026-05-17',
      horaires: '14-17 MAI 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
    const Event(
      identifiant: 'meett_alchimie_jeu_2026',
      titre: 'Festival Alchimie du Jeu',
      descriptifCourt: 'Salon grand public',
      descriptifLong: 'Organise par ALCHIMIE DU JEU',
      dateDebut: '2026-05-08',
      dateFin: '2026-05-10',
      horaires: '08-10 MAI 2026',
      lieuNom: 'MEETT - Parc des Expositions',
      lieuAdresse: 'Concorde Avenue, 31840 Aussonne',
      commune: 'Toulouse',
      categorie: 'Exposition',
      type: 'Salon grand public',
      reservationUrl: 'https://meett.fr/en/exhibitor/',
    ),
  ];
}
