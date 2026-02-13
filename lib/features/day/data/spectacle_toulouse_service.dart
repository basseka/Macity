import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/data/festik_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dedie aux spectacles vivants (humour, theatre, cirque, danse, magie)
/// de Toulouse et agglomeration.
///
/// Pipeline multi-source :
/// 1. API OpenDataSoft Toulouse (agenda culturel)
/// 2. Festik (billetterie spectacles)
/// 3. Donnees curatees (fallback)
class SpectacleToulouseService {
  final EventApiService _api;
  final FestikApiService _festik;

  SpectacleToulouseService({
    EventApiService? api,
    FestikApiService? festik,
  })  : _api = api ?? EventApiService(),
        _festik = festik ?? FestikApiService();

  Future<List<Event>> fetchUpcomingSpectacles() async {
    final List<Event> allEvents = [];

    // 1. API OpenDataSoft Toulouse
    try {
      final now = DateTime.now();
      final dateFrom =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final apiEvents = await _api.fetchEvents(
        where:
            '(type_de_manifestation LIKE "%Spectacle%" '
            'OR type_de_manifestation LIKE "%Humour%" '
            'OR type_de_manifestation LIKE "%Cirque%" '
            'OR type_de_manifestation LIKE "%Danse%" '
            'OR type_de_manifestation LIKE "%Magie%" '
            'OR categorie_de_la_manifestation LIKE "%Spectacle%" '
            'OR categorie_de_la_manifestation LIKE "%Humour%") '
            'AND date_debut >= "$dateFrom"',
        limit: 100,
      );
      // Exclure les résultats de théâtre
      allEvents.addAll(apiEvents.where((e) => !_isTheatre(e)));
    } catch (_) {}

    // 2. Festik (billetterie spectacles)
    try {
      final festikEvents =
          await _festik.fetchToulouseEvents(categorie: 'Spectacle');
      allEvents.addAll(festikEvents.where((e) => !_isTheatre(e)));
    } catch (_) {}

    // 3. Donnees curatees
    allEvents.addAll(_getCuratedSpectacles());

    // 4. Dedoublonnage
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key =
          '${e.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${e.dateDebut}';
      if (seen.add(key)) deduped.add(e);
    }

    // 5. Filtrer passes
    final now = DateTime.now();
    final upcoming = deduped.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    // 6. Tri chronologique
    upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return upcoming;
  }

  /// Retourne true si l'événement est du théâtre.
  static bool _isTheatre(Event e) {
    final t = e.titre.toLowerCase();
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    final lieu = e.lieuNom.toLowerCase();
    return cat.contains('theatre') ||
        type.contains('theatre') ||
        lieu.contains('theatre') ||
        t.contains('theatre');
  }

  // ─────────────────────────────────────────────
  // Donnees curatees – Casino Barriere Toulouse
  // (source: casinosbarriere.com/toulouse/spectacles
  //  + infoconcert.com)
  // ─────────────────────────────────────────────

  /// Spectacles curates accessibles publiquement (pour le resolver des likes).
  static List<Event> get curatedSpectacles => _getCuratedSpectacles();

  static List<Event> _getCuratedSpectacles() => [
        const Event(
          identifiant: 'cb_constance',
          titre: 'Constance - Inconstance',
          dateDebut: '2026-02-11',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '34-37€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_time_for_love_0213',
          titre: 'Time for Love - Diner Spectacle',
          dateDebut: '2026-02-13',
          horaires: '21h00',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '41€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_florian_lex',
          titre: 'Florian Lex - Imparfaits',
          dateDebut: '2026-02-18',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '35-42€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_podkassos',
          titre: 'Podkassos',
          dateDebut: '2026-02-25',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '23-28€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_haroun',
          titre: 'Haroun - Bonjour Quand Meme',
          dateDebut: '2026-02-28',
          horaires: '17h00 / 20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_caroline_estremo',
          titre: 'Caroline Estremo - Normalement',
          dateDebut: '2026-03-03',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_bougheraba',
          titre: 'Redouane Bougheraba - Mon Premier Spectacle',
          dateDebut: '2026-03-04',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_jimmy_sax',
          titre: 'Jimmy Sax - Toi & Moi',
          dateDebut: '2026-03-05',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '39-68€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_harjane',
          titre: 'Redouanne Harjane - Je Me Souviens du Futur',
          dateDebut: '2026-03-06',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '34-37€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_ladesou',
          titre: 'Chantal Ladesou - Le Retour',
          dateDebut: '2026-03-07',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '43-56€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_legende_balavoine',
          titre: 'Legende Balavoine',
          dateDebut: '2026-03-10',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '39-59€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_messmer',
          titre: 'Messmer - 13Hz',
          dateDebut: '2026-03-17',
          dateFin: '2026-03-19',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '42-67€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_irish_celtic',
          titre: 'Irish Celtic - Spirit of Ireland',
          dateDebut: '2026-03-21',
          horaires: '15h00 / 20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '35-70€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_le_prenom',
          titre: 'Le Prenom',
          dateDebut: '2026-03-25',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '38-53€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_ahmed_sparrow',
          titre: 'Ahmed Sparrow',
          dateDebut: '2026-03-26',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '29-39€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_benureau',
          titre: 'Didier Benureau - Entier',
          dateDebut: '2026-03-28',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '31-42€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_ici_chocolatine',
          titre: 'Ici, c\'est Chocolatine',
          dateDebut: '2026-04-01',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '24-34€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_le_rossignol',
          titre: 'Alexis Le Rossignol - Le Sens de la Vie',
          dateDebut: '2026-04-02',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '35-39€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_issa_doumbia',
          titre: 'Issa Doumbia - Monsieur Doumbia',
          dateDebut: '2026-04-07',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '36-42€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_viktor_vincent',
          titre: 'Viktor Vincent - Fantastik',
          dateDebut: '2026-04-09',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '36-39€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_simon_garfunkel',
          titre: 'The Simon & Garfunkel Story',
          dateDebut: '2026-04-15',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '54-74€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_noelle_perna',
          titre: 'Noelle Perna - Mado Fait Son Cabaret',
          dateDebut: '2026-04-22',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '37-40€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_gus_illusionniste',
          titre: 'Gus l\'Illusionniste - Givre',
          dateDebut: '2026-04-23',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '36-42€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_lac_des_cygnes',
          titre: 'Le Lac des Cygnes',
          dateDebut: '2026-04-26',
          horaires: '14h30 / 18h00',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          tarifNormal: '25-78€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
      ];
}
