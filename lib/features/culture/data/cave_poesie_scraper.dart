import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation de la Cave Poesie Rene Gouzenne
/// depuis cave-poesie.com/agenda/.
///
/// Structure HTML :
/// <div class="event all">
///   <h4 class="left">mardi 24 février 2026</h4>
///   <h5 class="left">20 h / 4 € sans réservation</h5>
///   <h2 class="left"><p>TITRE / <strong>ARTISTE</strong> / desc</p></h2>
///   <div class="event-links left">
///     <p class="btn-plus"><a href="URL">+ d'infos</a></p>
///     <p class="btn-resa"><a href="FESTIK_URL">réserver</a></p>
///   </div>
/// </div>
class CavePoesieScraper {
  CavePoesieScraper._();

  static const _agendaUrl = 'https://www.cave-poesie.com/agenda/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour chaque bloc <div class="event all">.
  static final _eventRegex = RegExp(
    r'<div\s+class="event\s+all">\s*(.*?)\s*<div\s+class="clear"></div>\s*</div>',
    dotAll: true,
  );

  /// Date dans <h4>
  static final _dateRegex = RegExp(
    r'<h4[^>]*>(.*?)</h4>',
    dotAll: true,
  );

  /// Horaire + tarif dans <h5>
  static final _h5Regex = RegExp(
    r'<h5[^>]*>(.*?)</h5>',
    dotAll: true,
  );

  /// Titre dans <h2><p>...</p></h2>
  static final _titreRegex = RegExp(
    r'<h2[^>]*>\s*<p>(.*?)</p>\s*</h2>',
    dotAll: true,
  );

  /// Lien "+ d'infos"
  static final _infosRegex = RegExp(
    r'class="btn-plus"><a\s+href="([^"]*)"',
  );

  /// Lien reservation Festik
  static final _resaRegex = RegExp(
    r'class="btn-resa"><a\s+href="([^"]*)"',
  );

  /// Date francaise complete : "mardi 24 février 2026"
  static final _fullDateRegex = RegExp(
    r'(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Horaire : "20 h", "21 h", "19 h 30"
  static final _horaireRegex = RegExp(
    r'(\d{1,2})\s*h\s*(\d{2})?',
  );

  /// Tarif : "4 €", "12 €"
  static final _tarifRegex = RegExp(
    r'(\d+)\s*€',
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_agendaUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _eventRegex.allMatches(html)) {
        final blockHtml = match.group(1) ?? '';

        // Date
        final dateMatch = _dateRegex.firstMatch(blockHtml);
        if (dateMatch == null) continue;
        final dateText = _cleanHtml(dateMatch.group(1) ?? '');
        final fullDateMatch = _fullDateRegex.firstMatch(dateText);
        if (fullDateMatch == null) continue;
        final dateIso = _buildIsoDate(
          fullDateMatch.group(1)!,
          fullDateMatch.group(2)!,
          fullDateMatch.group(3)!,
        );
        if (dateIso == null) continue;

        // Horaire + tarif
        String horaires = '';
        String tarif = '';
        final h5Match = _h5Regex.firstMatch(blockHtml);
        if (h5Match != null) {
          final h5Text = _cleanHtml(h5Match.group(1) ?? '');
          final horaireMatch = _horaireRegex.firstMatch(h5Text);
          if (horaireMatch != null) {
            final h = horaireMatch.group(1) ?? '';
            final m = horaireMatch.group(2) ?? '00';
            horaires = '${h}h$m';
          }
          final tarifMatch = _tarifRegex.firstMatch(h5Text);
          if (tarifMatch != null) {
            tarif = '${tarifMatch.group(1)} \u20AC';
          }
          // Informations supplementaires (reservation en ligne, etc.)
          if (h5Text.toLowerCase().contains('participation libre')) {
            tarif = 'Participation libre';
          }
          if (h5Text.toLowerCase().contains('sans r\u00E9servation')) {
            tarif += tarif.isEmpty
                ? 'Sans reservation'
                : ' (sans reservation)';
          }
        }

        // Titre
        final titreMatch = _titreRegex.firstMatch(blockHtml);
        if (titreMatch == null) continue;
        final titreHtml = titreMatch.group(1) ?? '';
        final titre = _cleanHtml(titreHtml);
        if (titre.isEmpty) continue;

        // Verifier si complet
        final isComplet = titre.toUpperCase().contains('COMPLET');

        // Lien infos
        String infoUrl = '';
        final infosMatch = _infosRegex.firstMatch(blockHtml);
        if (infosMatch != null) {
          infoUrl = infosMatch.group(1) ?? '';
        }

        // Lien reservation
        String resaUrl = '';
        final resaMatch = _resaRegex.firstMatch(blockHtml);
        if (resaMatch != null) {
          resaUrl = resaMatch.group(1) ?? '';
        }

        final slug = titre
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-|-$'), '');
        final id = 'cavepoesie_${slug.length > 30 ? slug.substring(0, 30) : slug}_$dateIso';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: [
            if (horaires.isNotEmpty) horaires,
            if (tarif.isNotEmpty) tarif,
            if (isComplet) 'COMPLET',
          ].join(' · '),
          descriptifLong: titre,
          dateDebut: dateIso,
          dateFin: dateIso,
          horaires: horaires,
          lieuNom: 'Cave Poesie Rene Gouzenne',
          lieuAdresse: '71 Rue du Taur',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Spectacle',
          categorie: 'Theatre',
          tarifNormal: tarif,
          reservationUrl:
              resaUrl.isNotEmpty ? resaUrl : infoUrl,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.add(const Duration(days: 30));

      final upcoming = events.where((e) {
        final d = DateTime.tryParse(e.dateDebut);
        if (d == null) return false;
        return !d.isBefore(today) && d.isBefore(cutoff);
      }).toList();

      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  static String? _buildIsoDate(String day, String month, String year) {
    final d = int.tryParse(day);
    final y = int.tryParse(year);
    final m = _frenchMonths[month.toLowerCase()];
    if (d == null || y == null || m == null) return null;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  static const _frenchMonths = {
    'janvier': 1, 'fevrier': 2, 'février': 2,
    'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
    'juillet': 7, 'aout': 8, 'août': 8,
    'septembre': 9, 'octobre': 10,
    'novembre': 11, 'decembre': 12, 'décembre': 12,
  };

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
