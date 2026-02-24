import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape les evenements de la ville de Balma depuis mairie-balma.fr.
///
/// Strategie :
/// 1. Fetch la page agenda HTML (15 premiers resultats)
/// 2. Parser les cards : titre, dates, categorie, description, lien detail
/// 3. Pour chaque event, fetch la page detail pour horaires, lieu, tarif
/// 4. Convertir en [Event], filtrer J+14, trier par date
class BalmaEventsScraper {
  BalmaEventsScraper._();

  static const _agendaUrl = 'https://www.mairie-balma.fr/systeme/agenda/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour extraire les cards evenements de la page liste.
  /// Chaque card est un <a href="...agenda/slug/"> contenant h3, dates, etc.
  static final _cardRegex = RegExp(
    r'<a\s[^>]*href="(https?://www\.mairie-balma\.fr/agenda/[^"]+)"[^>]*>(.*?)</a>',
    dotAll: true,
  );

  /// Regex pour extraire le titre h3.
  static final _titleRegex = RegExp(r'<h3[^>]*>(.*?)</h3>', dotAll: true);

  /// Regex pour extraire les paragraphes (description).
  static final _descRegex = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true);

  /// Regex pour extraire les dates francaises dans la carte (ex: "23 février").
  static final _cardDateRegex = RegExp(
    r'(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)',
    caseSensitive: false,
  );

  /// Regex pour la categorie (Sport, Culture, etc.) dans la page liste.
  static final _categoryRegex = RegExp(
    r'(?:Sport|Culture|Environnement|Divers|Solidarit[eé]|Economie|Loisirs|Jeunesse|Sant[eé])',
    caseSensitive: false,
  );

  /// Regex pour la date complete sur la page detail.
  /// Ex: "Du mardi 24 février 2026 au samedi 07 mars 2026"
  /// ou: "Le mardi 27 février 2026"
  static final _detailDateRegex = RegExp(
    r'(?:Du\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+au\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4}))|(?:Le\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4}))',
    caseSensitive: false,
  );

  /// Regex pour les horaires.
  static final _horaireRegex = RegExp(
    r'(\d{1,2}h\d{2})\s*[àa]\s*(\d{1,2}h\d{2})',
    caseSensitive: false,
  );

  /// Regex pour extraire la localisation/adresse.
  static final _lieuRegex = RegExp(
    r'Localisation.*?<strong>(.*?)</strong>(.*?)(?:31\d{3})',
    dotAll: true,
  );

  /// Regex pour le tarif.
  static final _tarifRegex = RegExp(
    r'Tarif.*?</.*?>(.*?)(?:<|$)',
    dotAll: true,
  );

  /// Point d'entree principal : retourne les events a venir de Balma.
  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_agendaUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      // Parser les cards de la page liste.
      final cards = _parseListPage(html);
      if (cards.isEmpty) return [];

      // Fetch les details en parallele (max 15).
      final events = await Future.wait(
        cards.take(15).map(_fetchDetailAndBuild),
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.add(const Duration(days: 14));

      final upcoming = events.whereType<Event>().where((e) {
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

  /// Parse la page liste et retourne une liste de donnees brutes par card.
  static List<_CardData> _parseListPage(String html) {
    final results = <_CardData>[];

    for (final match in _cardRegex.allMatches(html)) {
      final url = match.group(1) ?? '';
      final cardHtml = match.group(2) ?? '';
      if (url.isEmpty || cardHtml.isEmpty) continue;

      // Titre
      final titleMatch = _titleRegex.firstMatch(cardHtml);
      final titre = titleMatch != null ? _cleanHtml(titleMatch.group(1) ?? '') : '';
      if (titre.isEmpty) continue;

      // Description
      final descMatch = _descRegex.firstMatch(cardHtml);
      final description = descMatch != null ? _cleanHtml(descMatch.group(1) ?? '') : '';

      // Dates (peut y en avoir 2 : debut et fin)
      final dateMatches = _cardDateRegex.allMatches(cardHtml).toList();
      String? dateDebutStr;
      String? dateFinStr;
      if (dateMatches.isNotEmpty) {
        final d = dateMatches.first;
        dateDebutStr = '${d.group(1)} ${d.group(2)}';
      }
      if (dateMatches.length > 1) {
        final d = dateMatches[1];
        dateFinStr = '${d.group(1)} ${d.group(2)}';
      }

      // Categorie
      final catMatch = _categoryRegex.firstMatch(cardHtml);
      final categorie = catMatch?.group(0) ?? '';

      results.add(_CardData(
        url: url,
        titre: titre,
        description: description,
        dateDebutStr: dateDebutStr,
        dateFinStr: dateFinStr,
        categorie: categorie,
      ),);
    }
    return results;
  }

  /// Fetch la page detail d'un event et construire l'objet Event.
  static Future<Event?> _fetchDetailAndBuild(_CardData card) async {
    String horaires = '';
    String lieuNom = '';
    String lieuAdresse = '';
    String tarif = '';
    String? dateDebut;
    String? dateFin;

    try {
      final response = await _dio.get<String>(card.url);
      final html = response.data ?? '';

      // Dates completes depuis la page detail.
      final dateMatch = _detailDateRegex.firstMatch(html);
      if (dateMatch != null) {
        if (dateMatch.group(1) != null) {
          // Format "Du ... au ..."
          dateDebut = _buildIsoDate(
            dateMatch.group(1)!,
            dateMatch.group(2)!,
            dateMatch.group(3)!,
          );
          dateFin = _buildIsoDate(
            dateMatch.group(4)!,
            dateMatch.group(5)!,
            dateMatch.group(6)!,
          );
        } else if (dateMatch.group(7) != null) {
          // Format "Le ..."
          dateDebut = _buildIsoDate(
            dateMatch.group(7)!,
            dateMatch.group(8)!,
            dateMatch.group(9)!,
          );
          dateFin = dateDebut;
        }
      }

      // Horaires
      final horaireMatch = _horaireRegex.firstMatch(html);
      if (horaireMatch != null) {
        horaires = '${horaireMatch.group(1)} - ${horaireMatch.group(2)}';
      }

      // Lieu
      final lieuMatch = _lieuRegex.firstMatch(html);
      if (lieuMatch != null) {
        lieuNom = _cleanHtml(lieuMatch.group(1) ?? '');
        lieuAdresse = _cleanHtml(lieuMatch.group(2) ?? '').trim();
        if (lieuAdresse.startsWith(',')) {
          lieuAdresse = lieuAdresse.substring(1).trim();
        }
      }

      // Tarif
      final tarifMatch = _tarifRegex.firstMatch(html);
      if (tarifMatch != null) {
        tarif = _cleanHtml(tarifMatch.group(1) ?? '').trim();
      }
    } catch (_) {
      // On continue avec les donnees de la carte.
    }

    // Fallback sur les dates de la carte si la page detail n'a rien donne.
    dateDebut ??= _frenchDateToIso(card.dateDebutStr);
    dateFin ??= _frenchDateToIso(card.dateFinStr) ?? dateDebut;

    if (dateDebut == null || dateDebut.isEmpty) return null;

    final slug = Uri.tryParse(card.url)?.pathSegments
        .where((s) => s.isNotEmpty)
        .lastOrNull ?? '';
    final id = 'balma_${slug}_$dateDebut';

    return Event(
      identifiant: id,
      titre: 'Balma · ${card.titre}',
      descriptifCourt: card.description.isNotEmpty
          ? (card.description.length > 120
              ? '${card.description.substring(0, 120)}...'
              : card.description)
          : card.titre,
      descriptifLong: card.description.isNotEmpty
          ? card.description
          : card.titre,
      dateDebut: dateDebut,
      dateFin: dateFin ?? dateDebut,
      horaires: horaires,
      lieuNom: lieuNom.isNotEmpty ? lieuNom : 'Balma',
      lieuAdresse: lieuAdresse,
      commune: 'Balma',
      codePostal: 31130,
      type: card.categorie.isNotEmpty ? card.categorie : 'Evenement municipal',
      categorie: card.categorie.isNotEmpty ? card.categorie : 'famille',
      tarifNormal: tarif,
      reservationUrl: card.url,
    );
  }

  /// Construit une date ISO "YYYY-MM-DD" a partir de jour, mois (francais), annee.
  static String? _buildIsoDate(String day, String month, String year) {
    final d = int.tryParse(day);
    final y = int.tryParse(year);
    final m = _frenchMonths[month.toLowerCase()];
    if (d == null || y == null || m == null) return null;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  /// Convertit "23 février" → "2026-02-23" (annee courante ou suivante).
  static String? _frenchDateToIso(String? dateText) {
    if (dateText == null || dateText.isEmpty) return null;

    final regex = RegExp(r'(\d{1,2})\s+(\w+)');
    final match = regex.firstMatch(dateText);
    if (match == null) return null;

    final dayStr = match.group(1);
    final monthRaw = match.group(2);
    if (dayStr == null || monthRaw == null) return null;
    final day = int.tryParse(dayStr);
    final monthStr = monthRaw.toLowerCase();
    if (day == null) return null;

    final month = _frenchMonths[monthStr];
    if (month == null) return null;

    final now = DateTime.now();
    var year = now.year;
    final candidate = DateTime(year, month, day);
    if (candidate.isBefore(now.subtract(const Duration(days: 30)))) {
      year++;
    }

    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  static const _frenchMonths = {
    'janvier': 1,
    'fevrier': 2,
    'février': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'aout': 8,
    'août': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12,
    'décembre': 12,
  };

  /// Nettoie les tags HTML d'une chaine.
  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#039;'), "'")
        .replaceAll(RegExp(r'&rsquo;'), "'")
        .replaceAll(RegExp(r'&lsquo;'), "'")
        .replaceAll(RegExp(r'&rdquo;'), '"')
        .replaceAll(RegExp(r'&ldquo;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Donnees brutes extraites d'une card de la page liste.
class _CardData {
  final String url;
  final String titre;
  final String description;
  final String? dateDebutStr;
  final String? dateFinStr;
  final String categorie;

  const _CardData({
    required this.url,
    required this.titre,
    required this.description,
    this.dateDebutStr,
    this.dateFinStr,
    required this.categorie,
  });
}
