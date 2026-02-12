/// Normalizes text by removing diacritics and converting to lowercase.
class TextNormalizer {
  TextNormalizer._();

  static final _diacriticMap = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'è': 'e', 'ê': 'e', 'ë': 'e', 'é': 'e',
    'ì': 'i', 'î': 'i', 'ï': 'i', 'í': 'i',
    'ò': 'o', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ñ': 'n', 'ç': 'c', 'ÿ': 'y', 'ý': 'y',
    'À': 'A', 'Â': 'A', 'Ä': 'A', 'Á': 'A', 'Ã': 'A',
    'È': 'E', 'Ê': 'E', 'Ë': 'E', 'É': 'E',
    'Ì': 'I', 'Î': 'I', 'Ï': 'I', 'Í': 'I',
    'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Ó': 'O', 'Õ': 'O',
    'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ú': 'U',
    'Ñ': 'N', 'Ç': 'C', 'Ÿ': 'Y', 'Ý': 'Y',
  };

  /// Remove diacritics and convert to lowercase
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(_diacriticMap[char] ?? char);
    }
    return buffer.toString().toLowerCase().trim();
  }

  /// Check if [text] contains [query] after normalization
  static bool containsNormalized(String text, String query) {
    return normalize(text).contains(normalize(query));
  }
}
