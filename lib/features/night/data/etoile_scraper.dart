import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation de L'Etoile Toulouse via l'iframe FourVenues.
///
/// Strategie (1 seule requete) :
/// 1. Fetch l'iframe FourVenues carrusel
/// 2. Extraire le JSON des events depuis le RSC data (self.__next_f.push)
/// 3. Convertir en [Event] et filtrer les dates passees
class EtoileScraper {
  EtoileScraper._();

  static const _iframeUrl =
      'https://custom-iframe.fourvenues.com/iframe/letoile-club-toulouse?type=carrusel';
  static const _lieu = "L'Etoile Club Toulouse";
  static const _adresse = '2 Avenue d\'Atlanta, 31200 Toulouse';
  static const _metro = 'Ligne 1 - Arenes';
  static const _site = 'https://etoile-toulouse.com/billetterie/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ));

  /// Regex pour trouver le debut du tableau events dans le RSC data.
  static final _eventsJsonRegex = RegExp(
    r'\\?"events\\?":\s*\[',
  );

  /// Point d'entree principal : retourne les events a venir de L'Etoile.
  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_iframeUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = _parseEventsFromHtml(html);

      // Filtrer : ne garder que les events a venir.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcoming = events.where((e) {
        final d = DateTime.tryParse(e.dateDebut);
        return d != null && !d.isBefore(today);
      }).toList();

      // Trier par date.
      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  /// Parse les events depuis le HTML de l'iframe FourVenues.
  static List<Event> _parseEventsFromHtml(String html) {
    // Strategie 1 : trouver le JSON events dans le RSC data.
    // Le format est : \"events\":[{\"_id\":\"...\", ...}, ...]
    // On cherche le debut du tableau et on extrait chaque objet event.
    final events = <Event>[];

    // Trouver la position du tableau events.
    final eventsMatch = _eventsJsonRegex.firstMatch(html);
    if (eventsMatch == null) return [];

    // Extraire le tableau JSON en comptant les crochets.
    final startIdx = eventsMatch.end - 1; // position du '['
    var depth = 0;
    var endIdx = startIdx;

    for (var i = startIdx; i < html.length; i++) {
      final c = html[i];
      // Gerer l'echappement : si on voit \[ ou \], ne pas compter.
      if (i > 0 && html[i - 1] == '\\') continue;
      if (c == '[') depth++;
      if (c == ']') {
        depth--;
        if (depth == 0) {
          endIdx = i + 1;
          break;
        }
      }
    }

    if (endIdx <= startIdx) return [];

    var jsonStr = html.substring(startIdx, endIdx);

    // Unescape le JSON : \" → ", \\\\ → \\, \\n → \n, \\/ → /
    jsonStr = jsonStr
        .replaceAll('\\"', '"')
        .replaceAll('\\\\n', '\n')
        .replaceAll('\\\\', '\\')
        .replaceAll('\\/', '/');

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final event = _parseEvent(item);
          if (event != null) events.add(event);
        }
      }
    } catch (_) {
      // Fallback : extraire les events individuellement via regex.
      return _parseEventsWithRegex(html);
    }

    return events;
  }

  /// Fallback : extraction individuelle par regex.
  static List<Event> _parseEventsWithRegex(String html) {
    final events = <Event>[];

    // Chercher chaque bloc qui ressemble a un event JSON.
    final pattern = RegExp(
      r'\\"_id\\":\\"([^\\]+)\\".*?\\"name\\":\\"([^\\]+)\\".*?\\"start_date\\":\\"([^\\]+)\\".*?\\"end_date\\":\\"([^\\]+)\\"',
    );

    for (final match in pattern.allMatches(html)) {
      final name = match.group(2) ?? '';
      final startDate = match.group(3) ?? '';
      final endDate = match.group(4) ?? '';
      if (name.isEmpty || startDate.isEmpty) continue;

      final dateDebut = _isoToDate(startDate);
      final dateFin = _isoToDate(endDate);
      if (dateDebut.isEmpty) continue;

      // Chercher l'image_url pres de ce match.
      final imagePattern = RegExp(
        r'\\"image_url\\":\\"([^\\]+)\\"',
      );
      final imageMatch = imagePattern.firstMatch(
        html.substring(match.start, (match.start + 2000).clamp(0, html.length)),
      );
      final imageUrl = imageMatch?.group(1)?.replaceAll('\\/', '/');

      final heureDebut = _isoToTime(startDate);
      final heureFin = _isoToTime(endDate);
      final horaires = heureDebut.isNotEmpty && heureFin.isNotEmpty
          ? '$heureDebut - $heureFin'
          : '00h00 - 06h00';

      final id = 'etoile_$dateDebut';

      events.add(Event(
        identifiant: id,
        titre: 'Etoile · $name',
        descriptifCourt: '$name a L\'Etoile Club Toulouse.',
        descriptifLong:
            '$name a L\'ETOILE CLUB TOULOUSE. '
            'Club & Rooftop au coeur de Toulouse.',
        dateDebut: dateDebut,
        dateFin: dateFin.isNotEmpty ? dateFin : dateDebut,
        horaires: horaires,
        lieuNom: _lieu,
        lieuAdresse: _adresse,
        commune: 'Toulouse',
        codePostal: 31200,
        type: 'Club Discotheque',
        categorie: 'musique',
        reservationUrl: _site,
        stationProximite: _metro,
        photoPath: imageUrl,
      ));
    }

    return events;
  }

  /// Convertit un objet JSON FourVenues en [Event].
  static Event? _parseEvent(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final startDate = json['start_date'] as String? ?? '';
    final endDate = json['end_date'] as String? ?? '';

    final dateDebut = _isoToDate(startDate);
    final dateFin = _isoToDate(endDate);
    if (dateDebut.isEmpty) return null;

    final heureDebut = _isoToTime(startDate);
    final heureFin = _isoToTime(endDate);
    final horaires = heureDebut.isNotEmpty && heureFin.isNotEmpty
        ? '$heureDebut - $heureFin'
        : '00h00 - 06h00';

    final imageUrl = json['image_url'] as String?;
    final description = json['description'] as String? ?? '';
    final slug = json['slug'] as String? ?? '';

    final id = 'etoile_$dateDebut';

    return Event(
      identifiant: id,
      titre: 'Etoile · $name',
      descriptifCourt: description.isNotEmpty
          ? (description.length > 100
              ? '${description.substring(0, 100)}...'
              : description)
          : '$name a L\'Etoile Club Toulouse.',
      descriptifLong: description.isNotEmpty
          ? description
          : '$name a L\'ETOILE CLUB TOULOUSE. '
              'Club & Rooftop au coeur de Toulouse.',
      dateDebut: dateDebut,
      dateFin: dateFin.isNotEmpty ? dateFin : dateDebut,
      horaires: horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      reservationUrl: slug.isNotEmpty
          ? 'https://custom-iframe.fourvenues.com/iframe/letoile-club-toulouse/$slug'
          : _site,
      stationProximite: _metro,
      photoPath: imageUrl,
    );
  }

  /// "2026-02-20T23:00:00.000Z" → "2026-02-20"
  static String _isoToDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// "2026-02-20T23:00:00.000Z" → "23h00"
  static String _isoToTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}
