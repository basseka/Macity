import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre de la Violette depuis
/// theatredelaviolette.com.
///
/// Strategie en 2 etapes :
/// 1. Lister les spectacles depuis index.html
///    (<div class="spectacle"><a href="{slug}-{id}.html">)
/// 2. Pour chaque spectacle, fetch la page detail et parser les seances
///    depuis <select class="seances"><option value="{id}">{date}</option>
///
/// Format date dans les options : "jeu. 26 févr. à 20h00"
/// Peut contenir "- COMPLET" ou "/ N place(s) restante(s)".
class TheatreVioletteScraper {
  TheatreVioletteScraper._();

  static const _baseUrl = 'https://www.theatredelaviolette.com';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour le titre : <div class="titre">...</div>
  static final _showTitleRegex = RegExp(
    r'<div\s+class="titre">([^<]+)</div>',
  );

  /// Regex pour le public : <div class="public">...</div>
  static final _showPublicRegex = RegExp(
    r'<div\s+class="public">([^<]+)</div>',
  );

  /// Regex pour le titre sur la page detail : <p class="titre">...</p>
  static final _detailTitleRegex = RegExp(
    r'<p\s+class="titre">([^<]+)</p>',
  );

  /// Regex pour les options de seance.
  /// <option value="3286">jeu. 26 févr. à 20h00 / 10 places restantes</option>
  static final _seanceRegex = RegExp(
    r'<option\s+value="(\d+)">([^<]+)</option>',
  );

  /// Regex pour parser la date d'une seance.
  /// "jeu. 26 févr. à 20h00"
  static final _dateRegex = RegExp(
    r'(\w+)\.\s+(\d{1,2})\s+(\w+)\.?\s+[àa]\s+(\d{1,2})h(\d{2})',
  );

  /// Regex pour le genre/duree : <span class="duree">...NN mn</span>
  static final _dureeRegex = RegExp(
    r'(\d+)\s*mn',
  );

  static const _moisAbrev = <String, int>{
    'janv': 1,
    'jan': 1,
    'févr': 2,
    'fév': 2,
    'fevr': 2,
    'fev': 2,
    'mars': 3,
    'mar': 3,
    'avr': 4,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juil': 7,
    'jul': 7,
    'août': 8,
    'aout': 8,
    'sept': 9,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'déc': 12,
    'dec': 12,
  };

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      // --- Etape 1 : lister les spectacles ---
      final shows = await _fetchShowList();
      if (shows.isEmpty) return [];

      // --- Etape 2 : fetch chaque page detail ---
      final events = <Event>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch en parallele par lots de 6
      const batchSize = 6;
      for (var i = 0; i < shows.length; i += batchSize) {
        final batch = shows.skip(i).take(batchSize);
        final results = await Future.wait(
          batch.map((s) => _fetchShowSeances(s, today)),
        );
        for (final list in results) {
          events.addAll(list);
        }
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// Fetch index.html et extraire la liste des spectacles.
  static Future<List<_Show>> _fetchShowList() async {
    try {
      final response = await _dio.get<String>('$_baseUrl/index.html');
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final shows = <_Show>[];
      final seen = <String>{};

      // Trouver chaque bloc <div class="spectacle">
      // On parse le HTML lineairement pour associer href + titre + public
      final blocks = html.split('<div class="spectacle">');
      for (var i = 1; i < blocks.length; i++) {
        final block = blocks[i];

        // Extraire le href
        final hrefMatch = RegExp(r'<a\s+href="([^"]+\.html)"').firstMatch(block);
        if (hrefMatch == null) continue;
        final href = hrefMatch.group(1)!;
        if (!seen.add(href)) continue;

        // Extraire le titre
        final titleMatch = _showTitleRegex.firstMatch(block);
        final title = titleMatch != null
            ? _cleanHtml(titleMatch.group(1)!)
            : '';

        // Extraire le public
        final publicMatch = _showPublicRegex.firstMatch(block);
        final publicText = publicMatch != null
            ? _cleanHtml(publicMatch.group(1)!)
            : '';

        // Detecter la categorie (enfants/adultes) via la classe de l'image
        final isEnfants = block.contains('class="enfants"');

        shows.add(_Show(
          href: href,
          title: title,
          publicText: publicText,
          isEnfants: isEnfants,
        ),);
      }

      return shows;
    } catch (_) {
      return [];
    }
  }

  /// Fetch la page detail d'un spectacle et parser les seances.
  static Future<List<Event>> _fetchShowSeances(
    _Show show,
    DateTime today,
  ) async {
    try {
      final url = '$_baseUrl/${show.href}';
      final response = await _dio.get<String>(url);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      // Titre depuis la page detail (plus fiable)
      final titleMatch = _detailTitleRegex.firstMatch(html);
      final titre = titleMatch != null
          ? _cleanHtml(titleMatch.group(1)!)
          : show.title;
      if (titre.isEmpty) return [];

      // Duree
      final dureeMatch = _dureeRegex.firstMatch(html);
      final duree = dureeMatch != null ? '${dureeMatch.group(1)} mn' : '';

      // Parser les seances
      final events = <Event>[];
      for (final match in _seanceRegex.allMatches(html)) {
        final seanceText = match.group(2) ?? '';

        // Ignorer les seances completes
        if (seanceText.contains('COMPLET')) continue;

        final dateMatch = _dateRegex.firstMatch(seanceText);
        if (dateMatch == null) continue;

        final day = int.tryParse(dateMatch.group(2)!);
        final monthStr = dateMatch.group(3)!.toLowerCase().replaceAll('.', '');
        final hour = int.tryParse(dateMatch.group(4)!);
        final minute = dateMatch.group(5) ?? '00';

        if (day == null || hour == null) continue;

        int? month;
        for (final entry in _moisAbrev.entries) {
          if (monthStr.startsWith(entry.key)) {
            month = entry.value;
            break;
          }
        }
        if (month == null) continue;

        // Inferer l'annee
        var year = today.year;
        final candidate = DateTime(year, month, day);
        if (candidate.isBefore(today.subtract(const Duration(days: 60)))) {
          year++;
        }

        final dt = DateTime(year, month, day);
        if (dt.isBefore(today)) continue;

        final dateStr =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final horaires = '${hour.toString().padLeft(2, '0')}h$minute';

        final slug = show.href.replaceAll('.html', '');
        final id = 'violette_${slug}_${dateStr}_$horaires';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: show.publicText.isNotEmpty
              ? '${show.publicText} - $duree'
              : titre,
          descriptifLong: titre,
          dateDebut: dateStr,
          dateFin: dateStr,
          horaires: horaires,
          datesAffichageHoraires: '$dateStr $horaires',
          lieuNom: 'Theatre de la Violette',
          lieuAdresse: '2 impasse de la Violette',
          commune: 'Toulouse',
          codePostal: 31000,
          type: show.isEnfants ? 'Jeune Public' : 'Theatre',
          categorie: 'Theatre',
          reservationUrl: url,
        ),);
      }

      return events;
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
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#038;', '&')
        .replaceAll('&#8230;', '\u2026')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Show {
  final String href;
  final String title;
  final String publicText;
  final bool isEnfants;

  const _Show({
    required this.href,
    required this.title,
    required this.publicText,
    required this.isEnfants,
  });
}
