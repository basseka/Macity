import 'package:dio/dio.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Scrape les prochains galas de boxe depuis galadeboxetoulouse.com.
///
/// Strategie :
/// 1. Fetch la page /services/ (Prochain Gala) + la page d'accueil
/// 2. Extraire le nom, la date, l'heure, le lieu et le lien billetterie
/// 3. Convertir en [SupabaseMatch]
class GalaBoxeScraper {
  GalaBoxeScraper._();

  static const _baseUrl = 'https://galadeboxetoulouse.com';
  static const _prochainGalaUrl = '$_baseUrl/services/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Point d'entree : retourne les galas de boxe a venir.
  static Future<List<SupabaseMatch>> fetchUpcomingEvents() async {
    try {
      final results = <SupabaseMatch>[];

      // Scraper la page "Prochain Gala"
      final prochainGala = await _scrapeProchainGala();
      if (prochainGala != null) {
        results.add(prochainGala);
      }

      // Filtrer : ne garder que les events a venir
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return results.where((m) {
        final d = DateTime.tryParse(m.date);
        return d != null && !d.isBefore(today);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Scrape la page /services/ pour le prochain gala.
  static Future<SupabaseMatch?> _scrapeProchainGala() async {
    try {
      final response = await _dio.get<String>(_prochainGalaUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return null;

      // Extraire le titre (premier <h2> significatif)
      final title = _extractFirst(html, RegExp(r'<h2[^>]*>(.*?)</h2>', dotAll: true));

      // Extraire la date (format "20 juin", "15 mars", etc.)
      final dateText = _extractDate(html);
      final dateFormatted = _frenchDateToIso(dateText);

      // Extraire l'heure (format "19h30", "20h00", etc.)
      final heure = _extractFirst(html, RegExp(r'(\d{1,2}h\d{2})'));

      // Extraire le lieu
      final lieu = _extractVenue(html);

      // Extraire l'adresse
      final adresse = _extractFirst(
        html,
        RegExp(r'(\d+[^<]*\d{5}[^<]*)'),
      );

      // Extraire le lien billetterie
      final billetterie = _extractFirst(
        html,
        RegExp(r'href="(https?://[^"]*)"[^>]*>[^<]*[Bb]illetterie'),
      );

      // Extraire le tarif
      final tarif = _extractFirst(html, RegExp(r'(\d+\s*€)'));

      if (title == null || title.isEmpty) return null;

      final description = StringBuffer();
      description.write('Gala de boxe professionnelle');
      if (adresse != null && adresse.isNotEmpty) {
        description.write(' - $adresse');
      }
      if (tarif != null) {
        description.write(' - A partir de $tarif');
      }

      return SupabaseMatch(
        sport: 'Boxe',
        competition: _cleanHtml(title),
        equipe1: '',
        equipe2: '',
        date: dateFormatted ?? '',
        heure: heure ?? '',
        lieu: lieu ?? '',
        ville: 'Toulouse',
        description: description.toString(),
        billetterie: billetterie ?? '',
        source: 'galadeboxetoulouse.com',
      );
    } catch (_) {
      return null;
    }
  }

  /// Extrait la premiere correspondance d'un regex, groupe 1.
  static String? _extractFirst(String html, RegExp regex) {
    final match = regex.firstMatch(html);
    return match?.group(1)?.trim();
  }

  /// Cherche une date au format "20 juin", "3 mai", etc.
  static String? _extractDate(String html) {
    final regex = RegExp(
      r'(\d{1,2})\s+(janvier|f[eé]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[eé]cembre)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    if (match == null) return null;
    final day = match.group(1);
    final month = match.group(2);
    if (day == null || month == null) return null;
    return '$day $month';
  }

  /// Cherche le nom du lieu (texte apres le titre, souvent "Chateau de ...", "Salle ...", etc.)
  static String? _extractVenue(String html) {
    // Chercher des noms de lieux courants
    final venuePatterns = [
      RegExp(r'(Ch[aâ]teau\s+[^<,]{3,40})', caseSensitive: false),
      RegExp(r'(Salle\s+[^<,]{3,40})', caseSensitive: false),
      RegExp(r'(Palais\s+des\s+Sports[^<,]{0,40})', caseSensitive: false),
      RegExp(r'(Z[eé]nith[^<,]{0,40})', caseSensitive: false),
      RegExp(r'(Gymnase\s+[^<,]{3,40})', caseSensitive: false),
      RegExp(r'(Halle\s+[^<,]{3,40})', caseSensitive: false),
    ];
    for (final pattern in venuePatterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        return _cleanHtml(match.group(1)!.trim());
      }
    }
    return null;
  }

  /// Convertit "20 juin" → "2026-06-20" (utilise l'annee courante ou prochaine).
  static String? _frenchDateToIso(String? dateText) {
    if (dateText == null) return null;

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
    // Si la date est passee, prendre l'annee suivante
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
