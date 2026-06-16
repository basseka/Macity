import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/sport/data/sport_repository.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Sports affichés dans le bloc "Matchs à domicile" de la page Sport, et leur
/// ordre d'affichage + libellé/emoji. On ne garde que ces 4 disciplines.
const kHomeMatchSports = <({String key, String label, String emoji})>[
  (key: 'Rugby', label: 'Rugby', emoji: '🏉'),
  (key: 'Football', label: 'Foot', emoji: '⚽'),
  (key: 'Basketball', label: 'Basket', emoji: '🏀'),
  (key: 'Handball', label: 'Hand', emoji: '🤾'),
];

/// Normalise le champ `sport` (texte libre en base) vers une des 4 clés
/// canoniques, ou null si la discipline n'entre pas dans ce bloc (boxe, etc.).
String? canonicalHomeMatchSport(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('rugby')) return 'Rugby';
  if (s.contains('foot')) return 'Football';
  if (s.contains('basket')) return 'Basketball';
  if (s.contains('hand')) return 'Handball';
  return null;
}

/// Vrai si [m] est un match à domicile de la ville sélectionnée. Même logique
/// que `sportMatchesProvider`, mais on exige 2 équipes (vrais matchs, pas les
/// "events" sport solo type natation).
bool _isHomeMatch(SupabaseMatch m, String cityLower) {
  final dom = m.equipe1.toLowerCase();
  if (m.equipe2.isEmpty) return false;
  if (dom.contains(cityLower)) return true;
  if (cityLower == 'toulouse') {
    return dom.contains('stade toulousain') ||
        dom.contains('tfc') ||
        dom.contains('toulouse fc') ||
        dom.contains('fenix') ||
        dom.contains('tbc') ||
        dom.contains('tmb') ||
        dom.contains('toulouse');
  }
  if (cityLower == 'carcassonne') {
    return dom.contains('carcassonne') || dom.contains('usc');
  }
  if (cityLower == 'colomiers') return dom.contains('colomiers');
  return dom.contains(cityLower);
}

int _compareByDateTime(SupabaseMatch a, SupabaseMatch b) {
  final da = DateTime.tryParse(a.date) ?? DateTime(2099);
  final db = DateTime.tryParse(b.date) ?? DateTime(2099);
  final cmp = da.compareTo(db);
  return cmp != 0 ? cmp : a.heure.compareTo(b.heure);
}

/// Prochains matchs À DOMICILE, groupés par sport (Rugby/Foot/Basket/Hand),
/// pour la ville sélectionnée. Chaque liste est triée par date/heure
/// croissante. Alimente le bloc "Matchs à domicile" de la page Sport.
final homeMatchesBySportProvider =
    FutureProvider<Map<String, List<SupabaseMatch>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final cityLower = city.toLowerCase();

  final all = await SportRepository().fetchSupabaseMatches(ville: city);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final bySport = <String, List<SupabaseMatch>>{};
  for (final m in all) {
    if (!_isHomeMatch(m, cityLower)) continue;
    final canon = canonicalHomeMatchSport(m.sport);
    if (canon == null) continue;
    final d = DateTime.tryParse(m.date);
    if (d == null || d.isBefore(today)) continue;
    (bySport[canon] ??= <SupabaseMatch>[]).add(m);
  }
  for (final list in bySport.values) {
    list.sort(_compareByDateTime);
  }
  return bySport;
});
