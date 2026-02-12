import 'package:pulz_app/core/utils/text_normalizer.dart';

class QueryHelpers {
  QueryHelpers._();

  /// Synonyms mapping for search queries
  static const _synonyms = <String, String>{
    'pain': 'Boulangerie',
    'croissant': 'Boulangerie',
    'patisserie': 'Boulangerie',
    'medicament': 'Pharmacie',
    'sante': 'Pharmacie',
    'manger': 'Restaurant',
    'dejeuner': 'Restaurant',
    'diner': 'Restaurant',
    'repas': 'Restaurant',
    'fleur': 'Fleuriste',
    'bouquet': 'Fleuriste',
    'rose': 'Fleuriste',
    'coupe': 'Coiffeur',
    'cheveux': 'Coiffeur',
    'coiffure': 'Coiffeur',
    'cafe': 'Cafe',
    'coffee': 'Cafe',
    'boire': 'Cafe',
    'courses': 'Epicerie',
    'alimentation': 'Epicerie',
    'supermarche': 'Epicerie',
    'viande': 'Boucherie',
    'steak': 'Boucherie',
    'poisson': 'Poissonnerie',
    'fruits de mer': 'Poissonnerie',
    'livre': 'Librairie',
    'lire': 'Librairie',
    'lecture': 'Librairie',
    'vetement': 'Pressing',
    'nettoyage': 'Pressing',
    'lunette': 'Opticien',
    'vue': 'Opticien',
    'optique': 'Opticien',
    'animal': 'Veterinaire',
    'chien': 'Veterinaire',
    'chat': 'Veterinaire',
    'argent': 'Banque',
    'compte': 'Banque',
    'retrait': 'Banque',
  };

  /// Expand a search query using synonyms
  static String? expandSynonym(String query) {
    final normalized = TextNormalizer.normalize(query);
    return _synonyms[normalized];
  }

  /// Extract filter flags from query
  static ({String cleanQuery, bool filterOuvert, bool filterIndependant, bool filterBio}) parseQuery(String query) {
    final normalized = TextNormalizer.normalize(query);
    final words = normalized.split(' ');

    var filterOuvert = false;
    var filterIndependant = false;
    var filterBio = false;
    final cleanWords = <String>[];

    for (final word in words) {
      if (word == 'ouvert') {
        filterOuvert = true;
      } else if (word == 'independant' || word == 'local') {
        filterIndependant = true;
      } else if (word == 'bio') {
        filterBio = true;
      } else {
        cleanWords.add(word);
      }
    }

    return (
      cleanQuery: cleanWords.join(' '),
      filterOuvert: filterOuvert,
      filterIndependant: filterIndependant,
      filterBio: filterBio,
    );
  }

  /// Check if a commerce matches a query
  static bool matchesQuery(
    String query,
    String commerceName,
    String commerceCategorie,
  ) {
    final normalizedQuery = TextNormalizer.normalize(query);
    final normalizedName = TextNormalizer.normalize(commerceName);
    final normalizedCat = TextNormalizer.normalize(commerceCategorie);

    // Direct category match
    if (normalizedCat.contains(normalizedQuery)) return true;

    // Synonym match
    final synonym = expandSynonym(query);
    if (synonym != null &&
        TextNormalizer.normalize(synonym) == normalizedCat) {
      return true;
    }

    // Name match
    if (normalizedName.contains(normalizedQuery)) return true;

    return false;
  }
}
