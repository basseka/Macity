import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du TheatredelaCite depuis theatre-cite.com/programmation/.
///
/// Structure HTML :
/// <div class="programmation-grid__item programmation-grid__item--spectacles">
///   <a href="https://theatre-cite.com/programmation/2025-2026/spectacle/SLUG/" title="TITRE">
///     <div class="programmation-grid__item__date">27&nbsp;février&nbsp;2026 <span class="period-heure">19:00</span></div>
///     <span class="programmation-grid__item__title__inner">TITRE</span>
///     <div class="programmation-grid__item__subtitle">SOUS-TITRE</div>
///     <div class="spectacle__types__item">TYPE</div>
///   </a>
/// </div>
class TheatreCiteScraper {
  TheatreCiteScraper._();

  static const _url = 'https://theatre-cite.com/programmation/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Chaque bloc <a> qui pointe vers un spectacle ou evenement.
  /// Les <a> ne s'imbriquent pas, donc (.*?) est fiable.
  static final _itemRegex = RegExp(
    r'<a\s+href="(https://theatre-cite\.com/programmation/[^"]*)"[^>]*title="([^"]*)"[^>]*>(.*?)</a>',
    dotAll: true,
  );

  /// Titre inner.
  static final _titleRegex = RegExp(
    r'programmation-grid__item__title__inner">\s*(.*?)\s*</span>',
    dotAll: true,
  );

  /// Sous-titre.
  static final _subtitleRegex = RegExp(
    r'programmation-grid__item__subtitle">\s*(.*?)\s*</div>',
    dotAll: true,
  );

  /// Date brute.
  static final _dateRegex = RegExp(
    r'programmation-grid__item__date">\s*(.*?)\s*</div>',
    dotAll: true,
  );

  /// Types (spectacle__types__item).
  static final _typeRegex = RegExp(
    r'spectacle__types__item">(.*?)</div>',
    dotAll: true,
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_url);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _itemRegex.allMatches(html)) {
        final detailUrl = match.group(1) ?? '';
        final titleAttr = _cleanHtml(match.group(2) ?? '');
        final block = match.group(3) ?? '';

        // Titre : priorite au <span> inner, fallback sur l'attribut title
        final titleMatch = _titleRegex.firstMatch(block);
        final titre = titleMatch != null
            ? _cleanHtml(titleMatch.group(1) ?? '')
            : titleAttr;
        if (titre.isEmpty) continue;

        // Sous-titre
        final subtitleMatch = _subtitleRegex.firstMatch(block);
        final subtitle = subtitleMatch != null
            ? _cleanHtml(subtitleMatch.group(1) ?? '')
            : '';

        // Date brute
        final dateMatch = _dateRegex.firstMatch(block);
        final dateRaw = dateMatch != null
            ? _cleanHtml(dateMatch.group(1) ?? '')
            : '';

        // Types
        final types = <String>[];
        for (final tm in _typeRegex.allMatches(block)) {
          final t = _cleanHtml(tm.group(1) ?? '');
          if (t.isNotEmpty) types.add(t);
        }
        final typeStr = types.isNotEmpty ? types.first : 'Spectacle';

        // Parser les dates
        final dates = _parseDateRange(dateRaw);
        final dateDebut = dates.$1;
        final dateFin = dates.$2;

        final slug = Uri.tryParse(detailUrl)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        final id = 'cite_$slug${dateDebut.isNotEmpty ? '_$dateDebut' : ''}';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: [
            if (subtitle.isNotEmpty) subtitle,
            typeStr,
            if (dateRaw.isNotEmpty) dateRaw,
          ].join(' · '),
          descriptifLong: [
            titre,
            if (subtitle.isNotEmpty) subtitle,
            if (dateRaw.isNotEmpty) dateRaw,
          ].join('\n'),
          dateDebut: dateDebut,
          dateFin: dateFin.isNotEmpty ? dateFin : dateDebut,
          datesAffichageHoraires: dateRaw,
          lieuNom: 'Theatre de la Cite',
          lieuAdresse: '1 Rue Pierre Baudis',
          commune: 'Toulouse',
          codePostal: 31000,
          type: typeStr,
          categorie: 'Theatre',
          reservationUrl: detailUrl,
        ),);
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// Mois francais → numero.
  static const _moisFr = {
    'janvier': '01',
    'fevrier': '02',
    'février': '02',
    'mars': '03',
    'avril': '04',
    'mai': '05',
    'juin': '06',
    'juillet': '07',
    'août': '08',
    'aout': '08',
    'septembre': '09',
    'octobre': '10',
    'novembre': '11',
    'decembre': '12',
    'décembre': '12',
  };

  /// Parse les formats variés de date.
  /// "27 février 2026 19:00" → ("2026-02-27", "2026-02-27")
  /// "10 – 18 mars 2026" → ("2026-03-10", "2026-03-18")
  /// "31 mars – 3 avril 2026" → ("2026-03-31", "2026-04-03")
  /// "Février à avril 2026" → ("2026-02-01", "2026-04-30")
  /// "À partir du 10 janvier 2026" → ("2026-01-10", "2026-01-10")
  static (String, String) _parseDateRange(String raw) {
    if (raw.isEmpty) return ('', '');

    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('À partir du ', '')
        .replaceAll('A partir du ', '')
        .replaceAll(RegExp(r'\d{2}:\d{2}'), '')
        .trim();

    // Format "jour – jour mois annee" (ex: "10 – 18 mars 2026")
    final rangeShort = RegExp(
      r'(\d{1,2})\s*[–-]\s*(\d{1,2})\s+(\w+)\s+(\d{4})',
    ).firstMatch(cleaned);
    if (rangeShort != null) {
      final d1 = rangeShort.group(1)!.padLeft(2, '0');
      final d2 = rangeShort.group(2)!.padLeft(2, '0');
      final m = _moisFr[rangeShort.group(3)!.toLowerCase()];
      final y = rangeShort.group(4)!;
      if (m != null) {
        return ('$y-$m-$d1', '$y-$m-$d2');
      }
    }

    // Format "jour mois – jour mois annee" (ex: "31 mars – 3 avril 2026")
    final rangeLong = RegExp(
      r'(\d{1,2})\s+(\w+)\s*[–-]\s*(\d{1,2})\s+(\w+)\s+(\d{4})',
    ).firstMatch(cleaned);
    if (rangeLong != null) {
      final d1 = rangeLong.group(1)!.padLeft(2, '0');
      final m1 = _moisFr[rangeLong.group(2)!.toLowerCase()];
      final d2 = rangeLong.group(3)!.padLeft(2, '0');
      final m2 = _moisFr[rangeLong.group(4)!.toLowerCase()];
      final y = rangeLong.group(5)!;
      if (m1 != null && m2 != null) {
        return ('$y-$m1-$d1', '$y-$m2-$d2');
      }
    }

    // Format "Mois à mois annee" (ex: "Février à avril 2026")
    final monthRange = RegExp(
      r'(\w+)\s+[àa]\s+(\w+)\s+(\d{4})',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (monthRange != null) {
      final m1 = _moisFr[monthRange.group(1)!.toLowerCase()];
      final m2 = _moisFr[monthRange.group(2)!.toLowerCase()];
      final y = monthRange.group(3)!;
      if (m1 != null && m2 != null) {
        final lastDay = DateTime(int.parse(y), int.parse(m2) + 1, 0).day;
        return ('$y-$m1-01', '$y-$m2-${lastDay.toString().padLeft(2, '0')}');
      }
    }

    // Format simple "jour mois annee" (ex: "27 février 2026")
    final single = RegExp(
      r'(\d{1,2})\s+(\w+)\s+(\d{4})',
    ).firstMatch(cleaned);
    if (single != null) {
      final d = single.group(1)!.padLeft(2, '0');
      final m = _moisFr[single.group(2)!.toLowerCase()];
      final y = single.group(3)!;
      if (m != null) {
        return ('$y-$m-$d', '$y-$m-$d');
      }
    }

    return ('', '');
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
