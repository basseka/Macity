import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre Garonne depuis theatregaronne.com/saison.
///
/// Structure HTML (Drupal) :
/// <article class="carte carte--spectacle">
///   <figure><img src="IMAGE" /></figure>
///   <div class="carte__tags"><span>Théâtre</span></div>
///   <div class="carte--spectacle__title">
///     <a href="/spectacle/2025-2026/SLUG">
///       <h2><span class="artiste__title">ARTISTE</span></h2>
///       <h3>TITRE</h3>
///     </a>
///   </div>
///   <div class="carte--spectacle__dates">
///     <time datetime="2026-03-11T13:00:00+01:00">11</time>
///     → <time datetime="2026-03-13T13:00:00+01:00">13 Mar</time>
///   </div>
///   <div class="carte--spectacle__booking">
///     <a href="BOOKING_URL">Réserver</a>
///   </div>
/// </article>
class TheatreGaronneScraper {
  TheatreGaronneScraper._();

  static const _saisonUrl = 'https://www.theatregaronne.com/saison';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour chaque <article class="carte carte--spectacle">.
  static final _articleRegex = RegExp(
    r'<article\s+class="carte carte--spectacle">(.*?)</article>',
    dotAll: true,
  );

  /// Categorie (tag)
  static final _tagRegex = RegExp(
    r'<div\s+class="carte__tags">\s*(?:<span>([^<]*)</span>\s*)+',
    dotAll: true,
  );
  static final _singleTagRegex = RegExp(r'<span>([^<]*)</span>');

  /// Titre <h3>
  static final _titreRegex = RegExp(
    r'<h3>(.*?)</h3>',
    dotAll: true,
  );

  /// Artiste <span class="artiste__title">
  static final _artisteRegex = RegExp(
    r'<span\s+class="artiste__title">\s*(.*?)\s*</span>',
    dotAll: true,
  );

  /// Lien detail
  static final _linkRegex = RegExp(
    r'<a\s+href="(/spectacle/[^"]*)"',
  );

  /// Dates via <time datetime="...">
  static final _timeRegex = RegExp(
    r'<time\s+datetime="(\d{4}-\d{2}-\d{2})T',
  );

  /// Lien billetterie
  static final _bookingRegex = RegExp(
    r'carte--spectacle__booking">\s*(?:<a\s+href="([^"]*)"[^>]*>)?',
    dotAll: true,
  );

  /// Lieu (hors Garonne)
  static final _placeRegex = RegExp(
    r'<div\s+class="place">(.*?)</div>',
    dotAll: true,
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_saisonUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _articleRegex.allMatches(html)) {
        final articleHtml = match.group(1) ?? '';

        // Titre
        final titreMatch = _titreRegex.firstMatch(articleHtml);
        final titre = titreMatch != null
            ? _cleanHtml(titreMatch.group(1) ?? '')
            : '';
        if (titre.isEmpty) continue;

        // Artiste(s)
        final artistes = <String>[];
        for (final am in _artisteRegex.allMatches(articleHtml)) {
          final name = _cleanHtml(am.group(1) ?? '');
          if (name.isNotEmpty) artistes.add(name);
        }
        final artisteStr = artistes.join(', ');

        // Categorie (premier tag)
        String categorie = 'Spectacle';
        final tagMatch = _tagRegex.firstMatch(articleHtml);
        if (tagMatch != null) {
          final tagContent = tagMatch.group(0) ?? '';
          final singleTag = _singleTagRegex.firstMatch(tagContent);
          if (singleTag != null) {
            categorie = _cleanHtml(singleTag.group(1) ?? 'Spectacle');
          }
        }

        // Lien detail
        final linkMatch = _linkRegex.firstMatch(articleHtml);
        final detailPath = linkMatch?.group(1) ?? '';
        final detailUrl = detailPath.isNotEmpty
            ? 'https://www.theatregaronne.com$detailPath'
            : '';

        // Dates
        final timeMatches = _timeRegex.allMatches(articleHtml).toList();
        if (timeMatches.isEmpty) continue;
        final dateDebut = timeMatches.first.group(1)!;
        final dateFin = timeMatches.length > 1
            ? timeMatches.last.group(1)!
            : dateDebut;

        // Lien billetterie
        String bookingUrl = '';
        final bookingMatch = _bookingRegex.firstMatch(articleHtml);
        if (bookingMatch != null) {
          bookingUrl = (bookingMatch.group(1) ?? '').trim();
        }

        // Lieu
        String place = '';
        final placeMatch = _placeRegex.firstMatch(articleHtml);
        if (placeMatch != null) {
          place = _cleanHtml(placeMatch.group(1) ?? '');
        }

        final slug = Uri.tryParse(detailUrl)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        final id = 'garonne_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: [
            if (artisteStr.isNotEmpty) artisteStr,
            categorie,
            if (place.isNotEmpty) place,
          ].join(' · '),
          descriptifLong: [
            titre,
            if (artisteStr.isNotEmpty) artisteStr,
            categorie,
          ].join('\n'),
          dateDebut: dateDebut,
          dateFin: dateFin,
          lieuNom: place.isNotEmpty ? place : 'Theatre Garonne',
          lieuAdresse: '1 Avenue du Chateau d\'Eau',
          commune: 'Toulouse',
          codePostal: 31300,
          type: categorie,
          categorie: 'Theatre',
          reservationUrl: bookingUrl.isNotEmpty
              ? bookingUrl
              : detailUrl,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = events.where((e) {
        final fin = DateTime.tryParse(e.dateFin) ?? DateTime.tryParse(e.dateDebut);
        if (fin == null) return false;
        return !fin.isBefore(today);
      }).toList();

      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
