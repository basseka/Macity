/// Heuristique pour deviner la source DB d'un event à partir de son id.
///
/// - `user_events.id` → timestamp numerique (ex: "1778227221082") OU UUID v4
/// - `scraped_events.identifiant` → texte avec underscores/lettres (ex:
///   "zenith_queenhouse_2026-05-08", "manual_soiree-latino_2026-05-08")
///
/// Test : si l'identifiant est purement numérique OU UUID v4 → user_events.
/// Sinon → scraped_events.
///
/// Note : depuis le fix du service `getTotals*`, la requête ne filtre plus
/// par event_source — donc même si la détection se trompe, les compteurs
/// sont retrouvés. Cette détection sert juste à choisir la clé de cache
/// `<source>:<id>` côté state Riverpod (cohérence read/write).
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _digitsOnlyRegex = RegExp(r'^[0-9]+$');

String detectEventSource(String identifiant) {
  if (_digitsOnlyRegex.hasMatch(identifiant)) return 'user_events';
  if (_uuidRegex.hasMatch(identifiant)) return 'user_events';
  return 'scraped_events';
}
