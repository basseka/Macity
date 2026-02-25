import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre du Chien Blanc depuis
/// theatreduchienblanc.fr/programme-en-cours/.
///
/// La page utilise un template Elementor avec des articles :
///   <article id="post-{ID}" class="...ecs-post-loop...">
///     <p class="elementor-heading-title ...">TITRE</p>
///     "du DD mois YYYY" ... "au DD mois YYYY"
///   </article>
///
/// Les horaires sont recuperes depuis les pages detail individuelles
/// (/spectacle/{slug}/) qui contiennent "Horaire : HHhMM".
class TheatreChienBlancScraper {
  TheatreChienBlancScraper._();

  static const _progUrl =
      'https://www.theatreduchienblanc.fr/programme-en-cours/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Titre du spectacle.
  static final _titleRegex = RegExp(
    r'<p\s+class="elementor-heading-title\s+elementor-size-medium">([^<]+)</p>',
  );

  /// Date debut : "du DD mois YYYY"
  static final _startDateRegex = RegExp(
    r'du\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Date fin : "au DD mois YYYY"
  static final _endDateRegex = RegExp(
    r'au\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Lien vers la page detail : /spectacle/slug/
  static final _detailLinkRegex = RegExp(
    r'href="(https://www\.theatreduchienblanc\.fr/spectacle/[^"]+)"',
  );

  /// Horaire sur la page detail : "Horaire : 20h30"
  static final _horaireRegex = RegExp(
    r'Horaire\s*:\s*(\d{1,2}h\d{0,2})',
    caseSensitive: false,
  );

  static const _moisFr = <String, int>{
    'janvier': 1,
    'fevrier': 2,
    'février': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'août': 8,
    'aout': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12,
    'décembre': 12,
  };

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_progUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Decouper en articles
      final articles = html.split('<article ');
      final shows = <_Show>[];

      for (var i = 1; i < articles.length; i++) {
        final article = articles[i];
        final articleEnd = article.indexOf('</article>');
        final block = articleEnd > 0 ? article.substring(0, articleEnd) : article;

        // Titre
        final titleMatch = _titleRegex.firstMatch(block);
        if (titleMatch == null) continue;
        final titre = _cleanHtml(titleMatch.group(1)!);
        if (titre.isEmpty) continue;

        // Date debut
        final startMatch = _startDateRegex.firstMatch(block);
        if (startMatch == null) continue;
        final startDay = int.tryParse(startMatch.group(1)!);
        final startMonth = _moisFr[startMatch.group(2)!.toLowerCase()];
        final startYear = int.tryParse(startMatch.group(3)!);
        if (startDay == null || startMonth == null || startYear == null) continue;

        // Date fin
        final endMatch = _endDateRegex.firstMatch(block);
        int endDay = startDay;
        int endMonth = startMonth;
        int endYear = startYear;
        if (endMatch != null) {
          endDay = int.tryParse(endMatch.group(1)!) ?? startDay;
          endMonth = _moisFr[endMatch.group(2)!.toLowerCase()] ?? startMonth;
          endYear = int.tryParse(endMatch.group(3)!) ?? startYear;
        }

        // Filtrer les evenements passes
        final endDate = DateTime(endYear, endMonth, endDay);
        if (endDate.isBefore(today)) continue;

        // Lien detail
        final detailMatch = _detailLinkRegex.firstMatch(block);
        final detailUrl = detailMatch?.group(1) ?? '';

        shows.add(_Show(
          titre: titre,
          dateDebut: _isoDate(startYear, startMonth, startDay),
          dateFin: _isoDate(endYear, endMonth, endDay),
          detailUrl: detailUrl,
        ),);
      }

      if (shows.isEmpty) return [];

      // Fetch les horaires depuis les pages detail (en parallele)
      final events = <Event>[];
      const batchSize = 6;
      for (var i = 0; i < shows.length; i += batchSize) {
        final batch = shows.skip(i).take(batchSize);
        final results = await Future.wait(
          batch.map((s) => _enrichWithHoraire(s)),
        );
        events.addAll(results);
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// Fetch la page detail pour recuperer l'horaire.
  static Future<Event> _enrichWithHoraire(_Show show) async {
    var horaires = '';

    if (show.detailUrl.isNotEmpty) {
      try {
        final response = await _dio.get<String>(show.detailUrl);
        final html = response.data ?? '';
        final horaireMatch = _horaireRegex.firstMatch(html);
        if (horaireMatch != null) {
          horaires = horaireMatch.group(1)!;
        }
      } catch (_) {
        // Pas grave, on continue sans horaire
      }
    }

    final slug = show.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final id = 'chienblanc_${slug}_${show.dateDebut}';

    return Event(
      identifiant: id,
      titre: show.titre,
      descriptifCourt: show.titre,
      descriptifLong: show.titre,
      dateDebut: show.dateDebut,
      dateFin: show.dateFin,
      horaires: horaires,
      datesAffichageHoraires:
          'Du ${show.dateDebut} au ${show.dateFin} $horaires'.trim(),
      lieuNom: 'Theatre du Chien Blanc',
      lieuAdresse: '17 rue Raymond IV',
      commune: 'Toulouse',
      codePostal: 31000,
      type: 'Theatre',
      categorie: 'Theatre',
      reservationUrl: show.detailUrl.isNotEmpty
          ? show.detailUrl
          : 'https://billetterie.festik.net/theatre-du-chien-blanc',
    );
  }

  static String _isoDate(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#038;', '&')
        .replaceAll('&#8230;', '\u2026')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Show {
  final String titre;
  final String dateDebut;
  final String dateFin;
  final String detailUrl;

  const _Show({
    required this.titre,
    required this.dateDebut,
    required this.dateFin,
    required this.detailUrl,
  });
}
