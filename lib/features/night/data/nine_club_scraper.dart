import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Nine Club depuis lenineclub.com.
///
/// Strategie :
/// 1. Fetch le sitemap events XML → liste d'URLs
/// 2. Fetch chaque page HTML en parallele (max 5)
/// 3. Extraire le JSON-LD (Schema.org Event) de chaque page
/// 4. Convertir en [Event] et filtrer les dates passees
class NineClubScraper {
  NineClubScraper._();

  static const _sitemapUrl =
      'https://www.lenineclub.com/event-pages-sitemap.xml';
  static const _lieu = 'Le Nine Club';
  static const _adresse = '26 Allee des Foulques, 31200 Toulouse';
  static const _metro = 'Compans-Caffarelli (navette gratuite)';
  static const _tarif = '12\u20AC (avec une consommation)';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ));

  /// Regex pour extraire les <loc> du sitemap XML.
  static final _locRegex = RegExp(r'<loc>(.*?)</loc>');

  /// Regex pour extraire les <lastmod> du sitemap XML.
  static final _lastmodRegex = RegExp(r'<lastmod>(.*?)</lastmod>');

  /// Regex pour extraire le bloc JSON-LD d'une page HTML.
  static final _jsonLdRegex = RegExp(
    r'<script\s+type="application/ld\+json">(.*?)</script>',
    dotAll: true,
  );

  /// Point d'entree principal : retourne les events a venir du Nine Club.
  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final urls = await _fetchEventUrls();
      if (urls.isEmpty) return [];

      final events = await _fetchEventsFromUrls(urls);

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

  /// Etape 1 : fetch le sitemap et extraire les URLs d'events recents.
  /// Trie par lastmod decroissant et limite a 20 URLs max.
  static Future<List<String>> _fetchEventUrls() async {
    final response = await _dio.get<String>(_sitemapUrl);
    final xml = response.data;
    if (xml == null || xml.isEmpty) return [];

    final locs = _locRegex
        .allMatches(xml)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final lastmods = _lastmodRegex
        .allMatches(xml)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    // Collecter les URLs avec leur lastmod pour trier.
    final entries = <({String url, DateTime? mod})>[];
    for (var i = 0; i < locs.length; i++) {
      DateTime? mod;
      if (i < lastmods.length) {
        mod = DateTime.tryParse(lastmods[i]);
        if (mod != null && mod.isBefore(cutoff)) continue;
      }
      entries.add((url: locs[i], mod: mod));
    }

    // Trier par lastmod decroissant (les plus recents d'abord).
    entries.sort((a, b) {
      final ma = a.mod ?? DateTime(2000);
      final mb = b.mod ?? DateTime(2000);
      return mb.compareTo(ma);
    });

    // Limiter a 10 URLs max.
    return entries.take(10).map((e) => e.url).toList();
  }

  /// Etape 2 : fetch toutes les pages en parallele (1 seul round).
  static Future<List<Event>> _fetchEventsFromUrls(List<String> urls) async {
    final results = await Future.wait(urls.map(_fetchEventFromPage));
    return results.whereType<Event>().toList();
  }

  /// Fetch une page event et extraire le JSON-LD.
  static Future<Event?> _fetchEventFromPage(String url) async {
    try {
      final response = await _dio.get<String>(url);
      final html = response.data;
      if (html == null) return null;

      final match = _jsonLdRegex.firstMatch(html);
      if (match == null) return null;

      final jsonStr = match.group(1)?.trim() ?? '';
      if (jsonStr.isEmpty) return null;
      final dynamic decoded = json.decode(jsonStr);

      // Le JSON-LD peut etre un objet ou un tableau.
      final Map<String, dynamic> jsonLd;
      if (decoded is List) {
        jsonLd = decoded.firstWhere(
          (e) => e is Map && e['@type'] == 'Event',
          orElse: () => null,
        ) as Map<String, dynamic>? ?? {};
      } else if (decoded is Map<String, dynamic>) {
        jsonLd = decoded;
      } else {
        return null;
      }

      if (jsonLd['@type'] != 'Event') return null;

      return _parseJsonLdEvent(jsonLd, url);
    } catch (_) {
      return null;
    }
  }

  /// Convertit un JSON-LD Event en [Event] du modele app.
  static Event? _parseJsonLdEvent(Map<String, dynamic> jsonLd, String url) {
    final name = jsonLd['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final startDate = jsonLd['startDate'] as String? ?? '';
    final endDate = jsonLd['endDate'] as String? ?? '';

    // Extraire la date au format YYYY-MM-DD.
    final dateDebut = _isoToDate(startDate);
    final dateFin = _isoToDate(endDate);
    if (dateDebut.isEmpty) return null;

    // Extraire les horaires au format HHhMM.
    final heureDebut = _isoToTime(startDate);
    final heureFin = _isoToTime(endDate);
    final horaires =
        heureDebut.isNotEmpty && heureFin.isNotEmpty
            ? '$heureDebut - $heureFin'
            : '23h00 - 06h00';

    // Image.
    final imageData = jsonLd['image'];
    String? imageUrl;
    if (imageData is Map) {
      imageUrl = imageData['url'] as String?;
    } else if (imageData is String) {
      imageUrl = imageData;
    }

    // Identifiant unique base sur la date.
    final id = 'nine_club_$dateDebut';

    return Event(
      identifiant: id,
      titre: 'Nine · $name',
      descriptifCourt: '$name au Nine Club.',
      descriptifLong:
          '$name au NINE CLUB, l\'une des plus grandes discotheques du sud de la France. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: dateDebut,
      dateFin: dateFin.isNotEmpty ? dateFin : dateDebut,
      horaires: horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      tarifNormal: _tarif,
      reservationUrl: url,
      stationProximite: _metro,
      photoPath: imageUrl,
    );
  }

  /// "2026-02-21T23:00:00+01:00" → "2026-02-21"
  static String _isoToDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// "2026-02-21T23:00:00+01:00" → "23h00"
  static String _isoToTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}
