/// Maps NAF (Nomenclature d'Activites Francaise) codes to commerce categories.
///
/// NAF codes are used by INSEE (French national statistics institute) to
/// classify business activities. This mapper translates them to the category
/// names used in the local commerce database.
class NafCategoryMapper {
  NafCategoryMapper._();

  // ---------------------------------------------------------------------------
  // Exact NAF code -> category name mappings
  // ---------------------------------------------------------------------------

  static const Map<String, String> _exactMappings = {
    // Boulangerie
    '10.71C': 'Boulangerie',
    '10.71D': 'Boulangerie',

    // Pharmacie
    '47.73Z': 'Pharmacie',

    // Restaurant
    '56.10A': 'Restaurant',

    // Cafe
    '56.30Z': 'Cafe',

    // Coiffeur
    '96.02A': 'Coiffeur',
    '96.02B': 'Coiffeur',

    // Fleuriste
    '47.76Z': 'Fleuriste',

    // Epicerie
    '47.11F': 'Epicerie',
    '47.29Z': 'Epicerie',

    // Supermarche
    '47.11A': 'Supermarche',
    '47.11B': 'Supermarche',
    '47.11C': 'Supermarche',
    '47.11D': 'Supermarche',

    // Librairie
    '47.61Z': 'Librairie',

    // Boucherie
    '47.22Z': 'Boucherie',

    // Poissonnerie
    '47.23Z': 'Poissonnerie',

    // Banque
    '64.19Z': 'Banque',

    // Pressing
    '96.01A': 'Pressing',
    '96.01B': 'Pressing',

    // Opticien
    '47.78A': 'Opticien',

    // Veterinaire
    '75.00Z': 'Veterinaire',
  };

  // ---------------------------------------------------------------------------
  // Prefix mappings (first 5 characters of the NAF code)
  // ---------------------------------------------------------------------------

  static const Map<String, String> _prefixMappings = {
    '10.71': 'Boulangerie',
    '47.73': 'Pharmacie',
    '56.10': 'Restaurant',
    '56.30': 'Cafe',
    '96.02': 'Coiffeur',
    '47.76': 'Fleuriste',
    '47.11': 'Epicerie',
    '47.29': 'Epicerie',
    '47.61': 'Librairie',
    '47.22': 'Boucherie',
    '47.23': 'Poissonnerie',
    '64.19': 'Banque',
    '96.01': 'Pressing',
    '47.78': 'Opticien',
    '75.00': 'Veterinaire',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Look up the commerce category for a given NAF [code].
  ///
  /// Resolution order:
  /// 1. Exact match against the full code (e.g. `"10.71C"`).
  /// 2. Prefix match using the first 5 characters (e.g. `"10.71"`).
  ///
  /// Returns `null` if the code is not recognized.
  static String? lookup(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    // 1. Exact match
    final exact = _exactMappings[trimmed];
    if (exact != null) return exact;

    // 2. Prefix match (first 5 characters)
    if (trimmed.length >= 5) {
      final prefix = trimmed.substring(0, 5);
      final prefixMatch = _prefixMappings[prefix];
      if (prefixMatch != null) return prefixMatch;
    }

    return null;
  }

  /// Returns `true` if the given NAF [code] can be resolved to a category.
  static bool isKnown(String code) => lookup(code) != null;

  /// Returns a list of all NAF codes that map to the given [category].
  static List<String> codesForCategory(String category) {
    return _exactMappings.entries
        .where((e) => e.value == category)
        .map((e) => e.key)
        .toList();
  }

  /// Returns all known category names (deduplicated).
  static List<String> get allCategories {
    return _exactMappings.values.toSet().toList()..sort();
  }

  /// Returns all exact NAF code mappings.
  static Map<String, String> get allMappings =>
      Map.unmodifiable(_exactMappings);
}
