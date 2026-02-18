import 'package:pulz_app/features/day/domain/models/event.dart';

/// Programmation curatee du Nine Club Toulouse.
/// Source : https://www.lenineclub.com/
class NineClubEventsData {
  NineClubEventsData._();

  static const _lieu = 'Le Nine Club';
  static const _adresse = '26 Allee des Foulques, 31200 Toulouse';
  static const _site = 'https://www.lenineclub.com/';
  static const _horaires = '23h00 - 06h00';
  static const _tarif = '12\u20AC (avec une consommation)';
  static const _metro = 'Compans-Caffarelli (navette gratuite)';

  static const List<Event> events = [
    // ── Vendredi 21 fevrier 2026 ──
    Event(
      identifiant: 'nine_club_2026_02_21',
      titre: 'Soiree Nine Club - Vendredi',
      descriptifCourt: 'Soiree Hip-Hop, House & Urban au Nine Club.',
      descriptifLong:
          'Le NINE CLUB, l\'une des plus grandes discotheques du sud de la France, '
          'vous accueille chaque vendredi pour une soiree Hip-Hop, House & Urban Music. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-02-21',
      dateFin: '2026-02-21',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      theme: 'Hip-Hop / House / Urban',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),

    // ── Samedi 22 fevrier 2026 ──
    Event(
      identifiant: 'nine_club_2026_02_22',
      titre: 'Soiree Nine Club - Samedi',
      descriptifCourt: 'Soiree Shatta, Afro & Urban au Nine Club.',
      descriptifLong:
          'Le NINE CLUB vous accueille chaque samedi pour une soiree Shatta, Afro & Urban Music. '
          'Parc lumineux XXL et ecrans geants. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-02-22',
      dateFin: '2026-02-22',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      theme: 'Shatta / Afro / Urban',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),

    // ── Vendredi 27 fevrier 2026 ── WEEK-END GOUYAD
    Event(
      identifiant: 'nine_club_2026_02_27',
      titre: 'Week-End Gouyad - Oswald Band',
      descriptifCourt: 'Le Week-End Gouyad Toulouse avec Oswald Band au Nine Club.',
      descriptifLong:
          'Le NINE CLUB presente le WEEK-END GOUYAD TOULOUSE avec OSWALD BAND en live ! '
          'Une soiree speciale Gouyad, Kompa & Afro. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-02-27',
      dateFin: '2026-02-27',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'concert live',
      theme: 'Gouyad / Kompa / Afro',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),

    // ── Samedi 28 fevrier 2026 ──
    Event(
      identifiant: 'nine_club_2026_02_28',
      titre: 'Soiree Nine Club - Samedi',
      descriptifCourt: 'Soiree Shatta, Afro & Urban au Nine Club.',
      descriptifLong:
          'Le NINE CLUB vous accueille chaque samedi pour une soiree Shatta, Afro & Urban Music. '
          'Parc lumineux XXL et ecrans geants. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-02-28',
      dateFin: '2026-02-28',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      theme: 'Shatta / Afro / Urban',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),

    // ── Vendredi 6 mars 2026 ──
    Event(
      identifiant: 'nine_club_2026_03_06',
      titre: 'Soiree Nine Club - Vendredi',
      descriptifCourt: 'Soiree Hip-Hop, House & Urban au Nine Club.',
      descriptifLong:
          'Le NINE CLUB vous accueille chaque vendredi pour une soiree Hip-Hop, House & Urban Music. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-03-06',
      dateFin: '2026-03-06',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      theme: 'Hip-Hop / House / Urban',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),

    // ── Samedi 7 mars 2026 ──
    Event(
      identifiant: 'nine_club_2026_03_07',
      titre: 'Soiree Nine Club - Samedi',
      descriptifCourt: 'Soiree Shatta, Afro & Urban au Nine Club.',
      descriptifLong:
          'Le NINE CLUB vous accueille chaque samedi pour une soiree Shatta, Afro & Urban Music. '
          'Parc lumineux XXL et ecrans geants. '
          'Navette gratuite depuis le metro Compans-Caffarelli.',
      dateDebut: '2026-03-07',
      dateFin: '2026-03-07',
      horaires: _horaires,
      lieuNom: _lieu,
      lieuAdresse: _adresse,
      commune: 'Toulouse',
      codePostal: 31200,
      type: 'Club Discotheque',
      categorie: 'musique',
      theme: 'Shatta / Afro / Urban',
      tarifNormal: _tarif,
      reservationUrl: _site,
      stationProximite: _metro,
    ),
  ];
}
