/// Filtre simple de mots vulgaires/insultes pour le chat communautaire.
/// Detection insensible a la casse et aux substitutions courantes (a/@, e/3, etc.).
class BadWordsFilter {
  static const _words = <String>[
    // Insultes courantes FR
    'connard', 'connasse', 'salope', 'pute', 'putain', 'enculer', 'enculé',
    'enfoiré', 'fdp', 'fils de pute', 'ntm', 'nique ta mere', 'nique', 'ta gueule',
    'tg', 'batard', 'bâtard', 'pd', 'pédé', 'tapette', 'tarlouze',
    'bougnoule', 'negre', 'nègre', 'youpin', 'feuj', 'sale arabe', 'sale juif',
    'sale noir', 'sale blanc',
    // EN
    'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'nigger', 'faggot',
  ];

  static final _normalized = _words.map(_normalize).toList();

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('\$', 's')
        .replaceAll(RegExp(r'[^a-z\s]'), '');
  }

  /// Retourne true si le texte contient au moins un mot interdit.
  static bool contains(String text) {
    final normalized = _normalize(text);
    for (final w in _normalized) {
      // Match mot entier OU presence de la sequence (pour les substitutions)
      if (RegExp('\\b$w\\b').hasMatch(normalized)) return true;
      if (w.length >= 5 && normalized.contains(w)) return true;
    }
    return false;
  }
}
