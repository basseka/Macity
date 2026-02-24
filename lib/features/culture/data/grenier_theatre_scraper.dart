import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Grenier Theatre depuis
/// greniertheatre.org/la-saison/.
///
/// Structure HTML :
/// <div class="pieceContainer CATEGORY">
///   <div class="pieceAffiche">
///     <a href="URL" title="TITLE"><img .../></a>
///   </div>
///   <div class="pieceInfo">
///     <div class="pieceDate"><span class="date">DATE</span></div>
///     <h2>TITRE</h2>
///     <div class="pieceActu">
///       <div class="piecePrix"><span class="price">PRIX</span></div>
///     </div>
///   </div>
///   <div class="pieceBtnContainer">
///     <a class="pieceBtn" href="DETAIL_URL">En savoir +</a>
///     <a class="pieceResa" href="RESA_URL">Réserver</a>
///   </div>
/// </div>
class GrenierTheatreScraper {
  GrenierTheatreScraper._();

  static const _saisonUrl = 'https://www.greniertheatre.org/la-saison/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Bloc piece : de pieceContainer jusqu'au pieceBtnContainer
  static final _pieceRegex = RegExp(
    r'<div class="pieceContainer[^"]*">(.*?)<div class="pieceBtnContainer',
    dotAll: true,
  );

  /// Date dans <span class="date">
  static final _dateRegex = RegExp(
    r'<span class="date">(.*?)</span>',
    dotAll: true,
  );

  /// Titre dans <h2>
  static final _titreRegex = RegExp(
    r'<h2>(.*?)</h2>',
    dotAll: true,
  );

  /// Prix dans <span class="price">
  static final _prixRegex = RegExp(
    r'<span class="price">(.*?)</span>',
    dotAll: true,
  );

  /// Lien detail
  static final _linkRegex = RegExp(
    r'<a href="(https://www\.greniertheatre\.org/pieces/[^"]*)"',
  );

  /// "19 Fév > 7 Mars 2026" (range cross-month, with HTML &gt;)
  static final _dateRangeCrossRegex = RegExp(
    r'(\d{1,2})\s+(\w+\.?)\s*(?:>|&gt;)\s*(\d{1,2})\s+(\w+\.?)\s+(\d{4})',
    caseSensitive: false,
  );

  /// "11 > 21 Mars 2026" (range same month)
  static final _dateRangeSameRegex = RegExp(
    r'(\d{1,2})\s*(?:>|&gt;)\s*(\d{1,2})\s+(\w+\.?)\s+(\d{4})',
    caseSensitive: false,
  );

  /// "26 27 28 Mars 2026" ou "2 3 4 Avril 2026" (multiple days)
  static final _dateMultiRegex = RegExp(
    r'((?:\d{1,2}\s+)+)(\w+\.?)\s+(\d{4})',
    caseSensitive: false,
  );

  /// "8 & 9 Avril 2026" ou "8 &amp; 9 Avril 2026"
  static final _datePairRegex = RegExp(
    r'(\d{1,2})\s*(?:&|&amp;)\s*(\d{1,2})\s+(\w+\.?)\s+(\d{4})',
    caseSensitive: false,
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_saisonUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _pieceRegex.allMatches(html)) {
        final blockHtml = match.group(1) ?? '';

        // Titre
        final titreMatch = _titreRegex.firstMatch(blockHtml);
        final titre = titreMatch != null
            ? _cleanHtml(titreMatch.group(1) ?? '')
            : '';
        if (titre.isEmpty) continue;

        // Date
        final dateMatch = _dateRegex.firstMatch(blockHtml);
        final dateText = dateMatch != null
            ? _cleanHtml(dateMatch.group(1) ?? '')
            : '';
        if (dateText.isEmpty) continue;

        // Skip non-date entries like "BONS CADEAUX"
        if (!RegExp(r'\d{4}').hasMatch(dateText)) continue;

        // Prix
        final prixMatch = _prixRegex.firstMatch(blockHtml);
        final prix = prixMatch != null
            ? _cleanHtml(prixMatch.group(1) ?? '')
            : '';

        // Lien
        final linkMatch = _linkRegex.firstMatch(blockHtml);
        final detailUrl = linkMatch?.group(1) ?? '';

        // Parse dates
        String? dateDebut;
        String? dateFin;

        // Cross-month range: "19 Fév > 7 Mars 2026"
        final crossMatch = _dateRangeCrossRegex.firstMatch(dateText);
        if (crossMatch != null) {
          dateDebut = _buildIsoDate(
            crossMatch.group(1)!,
            crossMatch.group(2)!,
            crossMatch.group(5)!,
          );
          dateFin = _buildIsoDate(
            crossMatch.group(3)!,
            crossMatch.group(4)!,
            crossMatch.group(5)!,
          );
        }

        // Same-month range: "11 > 21 Mars 2026"
        if (dateDebut == null) {
          final sameMatch = _dateRangeSameRegex.firstMatch(dateText);
          if (sameMatch != null) {
            dateDebut = _buildIsoDate(
              sameMatch.group(1)!,
              sameMatch.group(3)!,
              sameMatch.group(4)!,
            );
            dateFin = _buildIsoDate(
              sameMatch.group(2)!,
              sameMatch.group(3)!,
              sameMatch.group(4)!,
            );
          }
        }

        // Pair: "8 & 9 Avril 2026"
        if (dateDebut == null) {
          final pairMatch = _datePairRegex.firstMatch(dateText);
          if (pairMatch != null) {
            dateDebut = _buildIsoDate(
              pairMatch.group(1)!,
              pairMatch.group(3)!,
              pairMatch.group(4)!,
            );
            dateFin = _buildIsoDate(
              pairMatch.group(2)!,
              pairMatch.group(3)!,
              pairMatch.group(4)!,
            );
          }
        }

        // Multiple days: "26 27 28 Mars 2026"
        if (dateDebut == null) {
          final multiMatch = _dateMultiRegex.firstMatch(dateText);
          if (multiMatch != null) {
            final daysStr = multiMatch.group(1)!.trim();
            final days = daysStr.split(RegExp(r'\s+'));
            final monthStr = multiMatch.group(2)!;
            final yearStr = multiMatch.group(3)!;
            if (days.isNotEmpty) {
              dateDebut = _buildIsoDate(days.first, monthStr, yearStr);
              dateFin = _buildIsoDate(days.last, monthStr, yearStr);
            }
          }
        }

        if (dateDebut == null) continue;

        final slug = Uri.tryParse(detailUrl)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'grenier_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: prix.isNotEmpty ? prix : titre,
          descriptifLong: titre,
          dateDebut: dateDebut,
          dateFin: dateFin ?? dateDebut,
          datesAffichageHoraires: dateText,
          lieuNom: 'Grenier Theatre',
          lieuAdresse: '8 Rue Rivals',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Theatre',
          categorie: 'Theatre',
          tarifNormal: prix,
          reservationUrl: detailUrl,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = events.where((e) {
        final fin =
            DateTime.tryParse(e.dateFin) ?? DateTime.tryParse(e.dateDebut);
        if (fin == null) return false;
        return !fin.isBefore(today);
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
    final monthClean =
        month.toLowerCase().replaceAll('.', '').replaceAll('\u00e9', 'e');
    final m = _frenchMonths[monthClean];
    if (d == null || y == null || m == null) return null;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  static const _frenchMonths = {
    'janvier': 1, 'jan': 1, 'janv': 1,
    'fevrier': 2, 'février': 2, 'fev': 2, 'fevr': 2,
    'mars': 3, 'mar': 3,
    'avril': 4, 'avr': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7, 'juil': 7,
    'aout': 8, 'août': 8,
    'septembre': 9, 'sept': 9, 'sep': 9,
    'octobre': 10, 'oct': 10,
    'novembre': 11, 'nov': 11,
    'decembre': 12, 'décembre': 12, 'dec': 12, 'déc': 12,
  };

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
