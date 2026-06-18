import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Une chaine de salles de fitness connue (Basic-Fit, Fitness Park, etc.).
///
/// Sur la page Sport, toutes les salles d'une meme chaine sont regroupees
/// dans une seule carte depliable (cf. [ChainFitnessCard]) au lieu d'une
/// carte par salle.
class FitnessChain {
  /// Jeton de detection normalise (minuscules, sans espace ni tiret ni accent).
  /// On matche si le nom normalise de la salle le contient.
  final String token;

  /// Nom d'affichage de la chaine.
  final String name;

  /// Logo de la chaine (asset local).
  final String logo;

  const FitnessChain(this.token, this.name, this.logo);
}

/// Les 5 chaines gerees. Les jetons sont volontairement courts pour absorber
/// les variantes d'orthographe en base ("Basic Fit" / "Basic-Fit",
/// "Interval" / "Intervalle", "Clark Powel" / "Clark Powell").
const List<FitnessChain> kFitnessChains = [
  FitnessChain('basicfit', 'Basic-Fit', 'assets/images/logo_salle_basicfit.png'),
  FitnessChain('fitnesspark', 'Fitness Park', 'assets/images/logo_salle_fitnesspark.png'),
  FitnessChain('interval', 'Interval', 'assets/images/logo_salle_interval.jpg'),
  FitnessChain('clarkpowel', 'Clark Powell', 'assets/images/logo_salle_calrkpowel.png'),
  FitnessChain('movida', 'Movida', 'assets/images/logo_salle_movida.png'),
  // Pas encore de logo : tombe sur l'icone fitness tant que le fichier
  // logo_salle_onair.png n'existe pas dans assets/images/.
  FitnessChain('onair', 'On Air', 'assets/images/logo_salle_onair.png'),
];

/// Normalise un nom : minuscules, sans accents, sans caractere non alphanum.
/// "Basic-Fit Toulouse" -> "basicfittoulouse".
String normalizeFitnessName(String s) {
  final lower = s.toLowerCase();
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Renvoie la chaine correspondant au nom de la salle, ou null si c'est une
/// salle independante.
FitnessChain? matchFitnessChain(String nom) {
  final n = normalizeFitnessName(nom);
  for (final c in kFitnessChains) {
    if (n.contains(c.token)) return c;
  }
  return null;
}

/// Element de la liste fitness : soit une salle independante, soit un groupe
/// de salles d'une meme chaine.
sealed class FitnessListEntry {
  const FitnessListEntry();
}

/// Une salle independante (carte classique).
class SingleVenueEntry extends FitnessListEntry {
  final CommerceModel venue;
  const SingleVenueEntry(this.venue);
}

/// Un groupe de salles d'une meme chaine (carte depliable).
class ChainGroupEntry extends FitnessListEntry {
  final FitnessChain chain;
  final List<CommerceModel> salles;
  const ChainGroupEntry(this.chain, this.salles);
}

/// Regroupe une liste de salles en entrees d'affichage : une entree par salle
/// independante, une entree par chaine (regroupant toutes ses salles).
///
/// L'ordre de la liste d'entree (deja triee par priorite par le provider) est
/// preserve : une chaine apparait a la position de sa premiere salle rencontree.
List<FitnessListEntry> groupFitnessVenues(List<CommerceModel> venues) {
  final entries = <FitnessListEntry>[];
  final chainIndex = <String, int>{}; // token -> index dans `entries`
  for (final v in venues) {
    final chain = matchFitnessChain(v.nom);
    if (chain == null) {
      entries.add(SingleVenueEntry(v));
      continue;
    }
    final existing = chainIndex[chain.token];
    if (existing == null) {
      chainIndex[chain.token] = entries.length;
      entries.add(ChainGroupEntry(chain, [v]));
    } else {
      (entries[existing] as ChainGroupEntry).salles.add(v);
    }
  }
  return entries;
}
