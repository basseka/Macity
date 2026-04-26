/// Resout une commune (ou un couple commune+CP) vers le "hub ville" de
/// l'app. Les hubs correspondent aux villes principales supportees (Toulouse,
/// Paris, Lyon, etc.) — les communes de banlieue sont rattachees au hub de
/// leur agglomeration.
///
/// Usage :
///   - Cote scan flyer : on a `ville` ET `code_postal` extraits par l'IA.
///     -> `resolveHub(ville, codePostal)` retourne le hub canonique a
///        sauvegarder dans `user_events.ville`.
///   - Cote feed (lecture) : pour les rows legacy qui ont un nom de commune,
///     on essaie un lookup par nom (sans CP) ; fallback = ville telle quelle.
///
/// Le mapping CP -> hub est calque sur l'edge function `send-daily-digest`
/// pour rester coherent.
class CityHubResolver {
  CityHubResolver._();

  /// Mapping numero de departement (2 ou 3 chiffres) -> hub ville.
  static const Map<String, String> _deptToHub = {
    '01': 'Lyon', '02': 'Amiens', '03': 'Clermont-Ferrand',
    '04': 'Aix-en-Provence', '05': 'Grenoble', '06': 'Nice',
    '07': 'Lyon', '08': 'Reims', '09': 'Toulouse',
    '10': 'Reims', '11': 'Carcassonne', '12': 'Toulouse',
    '13': 'Marseille', '14': 'Rouen', '15': 'Clermont-Ferrand',
    '16': 'Bordeaux', '17': 'Bordeaux', '18': 'Blois',
    '19': 'Clermont-Ferrand', '21': 'Dijon', '22': 'Rennes',
    '23': 'Clermont-Ferrand', '24': 'Bordeaux', '25': 'Besancon',
    '26': 'Lyon', '27': 'Rouen', '28': 'Chartres',
    '29': 'Brest', '2a': 'Marseille', '2b': 'Marseille',
    '30': 'Nimes', '31': 'Toulouse', '32': 'Toulouse',
    '33': 'Bordeaux', '34': 'Montpellier', '35': 'Rennes',
    '36': 'Blois', '37': 'Blois', '38': 'Grenoble',
    '39': 'Besancon', '40': 'Bayonne', '41': 'Blois',
    '42': 'Saint-Etienne', '43': 'Clermont-Ferrand', '44': 'Nantes',
    '45': 'Chartres', '46': 'Toulouse', '47': 'Bordeaux',
    '48': 'Nimes', '49': 'Angers', '50': 'Le Havre',
    '51': 'Reims', '52': 'Reims', '53': 'Le Mans',
    '54': 'Nancy', '55': 'Nancy', '56': 'Rennes',
    '57': 'Metz', '58': 'Dijon', '59': 'Lille',
    '60': 'Amiens', '61': 'Le Mans', '62': 'Lille',
    '63': 'Clermont-Ferrand', '64': 'Bayonne', '65': 'Toulouse',
    '66': 'Montpellier', '67': 'Strasbourg', '68': 'Colmar',
    '69': 'Lyon', '70': 'Besancon', '71': 'Dijon',
    '72': 'Le Mans', '73': 'Annecy', '74': 'Annecy',
    '75': 'Paris', '76': 'Rouen', '77': 'Paris',
    '78': 'Paris', '79': 'Nantes', '80': 'Amiens',
    '81': 'Toulouse', '82': 'Toulouse', '83': 'Toulon',
    '84': 'Avignon', '85': 'Nantes', '86': 'Bordeaux',
    '87': 'Clermont-Ferrand', '88': 'Nancy', '89': 'Dijon',
    '90': 'Besancon', '91': 'Paris', '92': 'Paris',
    '93': 'Paris', '94': 'Paris', '95': 'Paris',
    // DOM-TOM
    '971': 'Pointe-a-Pitre', '972': 'Fort-de-France',
    '973': 'Cayenne', '974': 'Saint-Denis', '976': 'Mamoudzou',
  };

  /// Communes courantes -> hub. Pour le cas "lecture" ou on n'a que le nom
  /// (rows legacy de `user_events` sans `code_postal`).
  /// Liste a etendre au fil de l'eau quand on rencontre des cas qui ratent.
  static const Map<String, String> _communeToHub = {
    // Toulouse agglo (31)
    'toulouse': 'Toulouse',
    'blagnac': 'Toulouse', 'colomiers': 'Toulouse',
    'tournefeuille': 'Toulouse', 'cugnaux': 'Toulouse',
    'muret': 'Toulouse', 'saint-jean': 'Toulouse',
    'l\'union': 'Toulouse', 'balma': 'Toulouse',
    'ramonville-saint-agne': 'Toulouse', 'plaisance-du-touch': 'Toulouse',
    'pibrac': 'Toulouse', 'saint-orens': 'Toulouse',
    'castanet-tolosan': 'Toulouse', 'quint-fonsegrives': 'Toulouse',
    'aucamville': 'Toulouse', 'leguevin': 'Toulouse',
    'castelginest': 'Toulouse', 'beauzelle': 'Toulouse',
    'fonsorbes': 'Toulouse', 'frouzins': 'Toulouse',
    'saint-lys': 'Toulouse', 'seysses': 'Toulouse',
    'auzeville-tolosane': 'Toulouse', 'roques': 'Toulouse',
    'rouffiac-tolosan': 'Toulouse', 'saint-alban': 'Toulouse',
    'aussonne': 'Toulouse', 'cornebarrieu': 'Toulouse',
    'pinsaguel': 'Toulouse', 'portet-sur-garonne': 'Toulouse',
    'eaunes': 'Toulouse', 'carbonne': 'Toulouse',
    'launaguet': 'Toulouse', 'fenouillet': 'Toulouse',
    'gratentour': 'Toulouse', 'lespinasse': 'Toulouse',
    'mondonville': 'Toulouse', 'saint-jory': 'Toulouse',

    // Paris agglo (75/77/78/91/92/93/94/95) — quelques majeurs
    'paris': 'Paris',
    'boulogne-billancourt': 'Paris', 'saint-denis': 'Paris',
    'argenteuil': 'Paris', 'montreuil': 'Paris',
    'nanterre': 'Paris', 'courbevoie': 'Paris',
    'vitry-sur-seine': 'Paris', 'creteil': 'Paris',
    'asnieres-sur-seine': 'Paris', 'colombes': 'Paris',
    'aulnay-sous-bois': 'Paris', 'rueil-malmaison': 'Paris',
    'champigny-sur-marne': 'Paris', 'saint-maur-des-fosses': 'Paris',
    'aubervilliers': 'Paris', 'levallois-perret': 'Paris',
    'noisy-le-grand': 'Paris', 'neuilly-sur-seine': 'Paris',
    'cergy': 'Paris', 'antony': 'Paris',
    'issy-les-moulineaux': 'Paris', 'pantin': 'Paris',
    'ivry-sur-seine': 'Paris',

    // Lyon agglo (69/01) — quelques majeurs
    'lyon': 'Lyon', 'villeurbanne': 'Lyon',
    'venissieux': 'Lyon', 'saint-priest': 'Lyon',
    'caluire-et-cuire': 'Lyon', 'bron': 'Lyon',
    'vaulx-en-velin': 'Lyon', 'rillieux-la-pape': 'Lyon',
    'meyzieu': 'Lyon', 'oullins': 'Lyon',
    'tassin-la-demi-lune': 'Lyon', 'ecully': 'Lyon',

    // Marseille (13)
    'marseille': 'Marseille', 'aubagne': 'Marseille',
    'la ciotat': 'Marseille', 'martigues': 'Marseille',

    // Bordeaux (33)
    'bordeaux': 'Bordeaux', 'merignac': 'Bordeaux',
    'pessac': 'Bordeaux', 'talence': 'Bordeaux',
    'le bouscat': 'Bordeaux', 'gradignan': 'Bordeaux',
    'villenave-d\'ornon': 'Bordeaux', 'begles': 'Bordeaux',

    // Lille (59)
    'lille': 'Lille', 'roubaix': 'Lille', 'tourcoing': 'Lille',
    'villeneuve-d\'ascq': 'Lille',

    // Nice (06)
    'nice': 'Nice', 'cannes': 'Nice', 'antibes': 'Nice',
    'grasse': 'Nice', 'cagnes-sur-mer': 'Nice',
    'le cannet': 'Nice', 'menton': 'Nice',

    // Nantes (44)
    'nantes': 'Nantes', 'saint-herblain': 'Nantes',
    'reze': 'Nantes', 'orvault': 'Nantes',

    // Strasbourg (67)
    'strasbourg': 'Strasbourg', 'schiltigheim': 'Strasbourg',

    // Montpellier (34)
    'montpellier': 'Montpellier', 'beziers': 'Montpellier',
    'sete': 'Montpellier',

    // Rennes (35)
    'rennes': 'Rennes',
  };

  /// Resout `(ville, codePostal)` vers un hub canonique.
  /// Si rien ne correspond, retourne `ville` tel quel (mieux que vide).
  ///
  /// L'algo essaie dans l'ordre :
  ///  1. Si `ville` est deja un hub connu -> retourne tel quel (casse normalisee).
  ///  2. Si `codePostal` est fourni -> mappe via dept (2 premiers chiffres).
  ///  3. Si `ville` est dans la liste des communes connues -> retourne le hub.
  ///  4. Sinon -> retourne `ville` brut.
  static String resolveHub(String? ville, [String? codePostal]) {
    if (ville == null || ville.trim().isEmpty) {
      return ville ?? '';
    }
    final villeNorm = ville.trim().toLowerCase();

    // 1. Si la ville est elle-meme un hub (lookup direct)
    final asHub = _communeToHub[villeNorm];
    if (asHub != null) return asHub;

    // 2. CP -> dept -> hub
    if (codePostal != null && codePostal.trim().length >= 2) {
      final cp = codePostal.trim();
      // DOM-TOM = 3 premiers chiffres (97x)
      final dept3 = cp.startsWith('97') ? cp.substring(0, 3) : null;
      final hub = (dept3 != null ? _deptToHub[dept3] : null) ??
          _deptToHub[cp.substring(0, 2)];
      if (hub != null) return hub;
    }

    // 3. Aucune resolution : retourne tel quel
    return ville;
  }
}
