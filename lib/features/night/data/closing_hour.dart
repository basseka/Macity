/// Heure de fermeture d'un lieu de nuit, lue depuis le champ texte `horaires`.
///
/// La saisie admin suit un format regulier ("18h00 - 02h00", "23h00 - 06h00"),
/// donc on parse la 2e heure de la plage. Les hotels affichent
/// "Reception 24h/24" : traites comme ouverts en permanence.
library;

final _rangeRe = RegExp(r'(\d{1,2})\s*h\s*(\d{2})?\s*[-–—]\s*(\d{1,2})\s*h');
final _h24Re = RegExp(r'24\s*h\s*/?\s*24', caseSensitive: false);

/// Heure de fermeture en heures (0-23), ou null si non renseigne/illisible.
///
/// Un lieu ouvert 24h/24 renvoie 24 : il ferme "apres" toutes les autres
/// valeurs, ce qui le fait ressortir dans chaque filtre "ouvert apres X".
/// Attention : la valeur est une heure d'horloge, pas une duree — 2 (fermeture
/// a 2h du matin) est plus TARD que 23. D'ou [closesAfter] qui remet les
/// heures de fin de nuit (0h-7h) apres celles de la soiree.
int? closingHour(String horaires) {
  final h = horaires.trim();
  if (h.isEmpty) return null;
  if (_h24Re.hasMatch(h)) return 24;
  final m = _rangeRe.firstMatch(h);
  if (m == null) return null;
  final close = int.tryParse(m.group(3) ?? '');
  if (close == null || close > 24) return null;
  return close;
}

/// Vrai si le lieu ferme a [hour] ou plus tard, sur une echelle nocturne :
/// minuit-7h comptent comme la suite de la soiree (24h-31h), pas comme le
/// matin. Ex : un bar qui ferme a 5h "est ouvert apres 2h".
bool closesAfter(String horaires, int hour) {
  final close = closingHour(horaires);
  if (close == null) return false; // horaires inconnus : jamais dans un filtre
  return _nightScale(close) >= _nightScale(hour);
}

/// Vrai si le lieu ferme a [hour] ou plus TOT, sur la meme echelle nocturne.
/// Ex : "jusqu'a 2h" garde un bar qui ferme a 2h ou a 23h, mais pas celui qui
/// ferme a 5h. Un lieu ouvert 24h/24 n'y est jamais.
bool closesUpTo(String horaires, int hour) {
  final close = closingHour(horaires);
  if (close == null || close == 24) return false;
  return _nightScale(close) <= _nightScale(hour);
}

/// 0h-7h -> 24h-31h (fin de nuit), 8h-23h inchange. 24 (= 24h/24) reste au
/// sommet.
int _nightScale(int hour) {
  if (hour == 24) return 99;
  return hour <= 7 ? hour + 24 : hour;
}
