/// Builds Overpass QL queries for different modes and categories.
///
/// Each category maps to one or more OSM tag combinations. The [buildQuery]
/// method returns a ready-to-send Overpass QL string that searches within a
/// given radius around a coordinate.
class OverpassQueryBuilder {
  OverpassQueryBuilder._();

  // ---------------------------------------------------------------------------
  // Night mode mappings
  // ---------------------------------------------------------------------------

  static const _nightQueries = <String, String>{
    'Bar': '''
      node["amenity"="bar"](around:{radius},{lat},{lon});
      way["amenity"="bar"](around:{radius},{lat},{lon});
    ''',
    'Bar de nuit': '''
      node["amenity"="bar"](around:{radius},{lat},{lon});
      way["amenity"="bar"](around:{radius},{lat},{lon});
    ''',
    'Discotheque': '''
      node["amenity"="nightclub"](around:{radius},{lat},{lon});
      way["amenity"="nightclub"](around:{radius},{lat},{lon});
    ''',
    'Bar a cocktails': '''
      node["amenity"="bar"]["cocktails"="yes"](around:{radius},{lat},{lon});
      way["amenity"="bar"]["cocktails"="yes"](around:{radius},{lat},{lon});
      node["amenity"="bar"]["drink:cocktails"="served"](around:{radius},{lat},{lon});
      way["amenity"="bar"]["drink:cocktails"="served"](around:{radius},{lat},{lon});
    ''',
    'Bar a chicha': '''
      node["amenity"="bar"]["cuisine"~"shisha|hookah"](around:{radius},{lat},{lon});
      way["amenity"="bar"]["cuisine"~"shisha|hookah"](around:{radius},{lat},{lon});
      node["amenity"="bar"]["smoking"="shisha"](around:{radius},{lat},{lon});
      way["amenity"="bar"]["smoking"="shisha"](around:{radius},{lat},{lon});
    ''',
    'Pub': '''
      node["amenity"="pub"](around:{radius},{lat},{lon});
      way["amenity"="pub"](around:{radius},{lat},{lon});
    ''',
    'Epicerie de nuit': '''
      node["shop"="convenience"](around:{radius},{lat},{lon});
      way["shop"="convenience"](around:{radius},{lat},{lon});
    ''',
    'Superette 24h': '''
      node["shop"~"supermarket|convenience"]["opening_hours"="24/7"](around:{radius},{lat},{lon});
      way["shop"~"supermarket|convenience"]["opening_hours"="24/7"](around:{radius},{lat},{lon});
    ''',
    'Station-service': '''
      node["amenity"="fuel"](around:{radius},{lat},{lon});
      way["amenity"="fuel"](around:{radius},{lat},{lon});
    ''',
    'Tabac de nuit': '''
      node["shop"="tobacco"](around:{radius},{lat},{lon});
      way["shop"="tobacco"](around:{radius},{lat},{lon});
    ''',
    'Hotel': '''
      node["tourism"="hotel"](around:{radius},{lat},{lon});
      way["tourism"="hotel"](around:{radius},{lat},{lon});
    ''',
  };

  // ---------------------------------------------------------------------------
  // Family mode mappings
  // ---------------------------------------------------------------------------

  static const _familyQueries = <String, String>{
    "Parc d'attractions": '''
      node["tourism"="theme_park"](around:{radius},{lat},{lon});
      way["tourism"="theme_park"](around:{radius},{lat},{lon});
      relation["tourism"="theme_park"](around:{radius},{lat},{lon});
      node["leisure"="amusement_arcade"](around:{radius},{lat},{lon});
      way["leisure"="amusement_arcade"](around:{radius},{lat},{lon});
    ''',
    'Aire de jeux': '''
      node["leisure"="playground"](around:{radius},{lat},{lon});
      way["leisure"="playground"](around:{radius},{lat},{lon});
    ''',
    'Parc animalier': '''
      node["tourism"="zoo"](around:{radius},{lat},{lon});
      way["tourism"="zoo"](around:{radius},{lat},{lon});
      relation["tourism"="zoo"](around:{radius},{lat},{lon});
    ''',
    'Cinema': '''
      node["amenity"="cinema"](around:{radius},{lat},{lon});
      way["amenity"="cinema"](around:{radius},{lat},{lon});
    ''',
    'Bowling': '''
      node["leisure"="bowling_alley"](around:{radius},{lat},{lon});
      way["leisure"="bowling_alley"](around:{radius},{lat},{lon});
    ''',
    'Laser game': '''
      node["leisure"="laser_tag"](around:{radius},{lat},{lon});
      way["leisure"="laser_tag"](around:{radius},{lat},{lon});
      node["leisure"="sports_centre"]["sport"="laser_tag"](around:{radius},{lat},{lon});
      way["leisure"="sports_centre"]["sport"="laser_tag"](around:{radius},{lat},{lon});
      node["leisure"="amusement_arcade"]["name"~"laser",i](around:{radius},{lat},{lon});
      way["leisure"="amusement_arcade"]["name"~"laser",i](around:{radius},{lat},{lon});
    ''',
    'Escape game': '''
      node["leisure"="escape_game"](around:{radius},{lat},{lon});
      way["leisure"="escape_game"](around:{radius},{lat},{lon});
      node["tourism"="attraction"]["name"~"escape",i](around:{radius},{lat},{lon});
      way["tourism"="attraction"]["name"~"escape",i](around:{radius},{lat},{lon});
    ''',
    'Musee': '''
      node["tourism"="museum"](around:{radius},{lat},{lon});
      way["tourism"="museum"](around:{radius},{lat},{lon});
      node["building"="museum"](around:{radius},{lat},{lon});
      way["building"="museum"](around:{radius},{lat},{lon});
    ''',
    'Bibliotheque': '''
      node["amenity"="library"](around:{radius},{lat},{lon});
      way["amenity"="library"](around:{radius},{lat},{lon});
    ''',
    'Aquarium': '''
      node["tourism"="aquarium"](around:{radius},{lat},{lon});
      way["tourism"="aquarium"](around:{radius},{lat},{lon});
    ''',
    'Restaurant familial': '''
      node["amenity"="restaurant"](around:{radius},{lat},{lon});
      way["amenity"="restaurant"](around:{radius},{lat},{lon});
    ''',
    'Fast-food': '''
      node["amenity"="fast_food"](around:{radius},{lat},{lon});
      way["amenity"="fast_food"](around:{radius},{lat},{lon});
    ''',
    'Glacier': '''
      node["cuisine"="ice_cream"](around:{radius},{lat},{lon});
      way["cuisine"="ice_cream"](around:{radius},{lat},{lon});
      node["amenity"="ice_cream"](around:{radius},{lat},{lon});
      way["amenity"="ice_cream"](around:{radius},{lat},{lon});
    ''',
  };

  // ---------------------------------------------------------------------------
  // Day mode mappings
  // ---------------------------------------------------------------------------

  static const _dayQueries = <String, String>{
    'Concert': '''
      node["amenity"="music_venue"](around:{radius},{lat},{lon});
      way["amenity"="music_venue"](around:{radius},{lat},{lon});
      node["amenity"="concert_hall"](around:{radius},{lat},{lon});
      way["amenity"="concert_hall"](around:{radius},{lat},{lon});
      node["leisure"="bandstand"](around:{radius},{lat},{lon});
      way["leisure"="bandstand"](around:{radius},{lat},{lon});
      node["amenity"="nightclub"]["name"~"concert|musique|music",i](around:{radius},{lat},{lon});
      way["amenity"="nightclub"]["name"~"concert|musique|music",i](around:{radius},{lat},{lon});
    ''',
    'Festival': '''
      node["amenity"="events_venue"](around:{radius},{lat},{lon});
      way["amenity"="events_venue"](around:{radius},{lat},{lon});
      node["amenity"="conference_centre"](around:{radius},{lat},{lon});
      way["amenity"="conference_centre"](around:{radius},{lat},{lon});
    ''',
    'Theatre': '''
      node["amenity"="theatre"](around:{radius},{lat},{lon});
      way["amenity"="theatre"](around:{radius},{lat},{lon});
    ''',
    'Opera': '''
      node["amenity"="theatre"]["name"~"opera|opéra",i](around:{radius},{lat},{lon});
      way["amenity"="theatre"]["name"~"opera|opéra",i](around:{radius},{lat},{lon});
      node["amenity"="theatre"]["theatre:type"="opera"](around:{radius},{lat},{lon});
      way["amenity"="theatre"]["theatre:type"="opera"](around:{radius},{lat},{lon});
    ''',
    'Visites guidees': '''
      node["tourism"="attraction"](around:{radius},{lat},{lon});
      way["tourism"="attraction"](around:{radius},{lat},{lon});
      node["historic"](around:{radius},{lat},{lon});
      way["historic"](around:{radius},{lat},{lon});
    ''',
    'Animations culturelles': '''
      node["amenity"="arts_centre"](around:{radius},{lat},{lon});
      way["amenity"="arts_centre"](around:{radius},{lat},{lon});
      node["amenity"="community_centre"](around:{radius},{lat},{lon});
      way["amenity"="community_centre"](around:{radius},{lat},{lon});
    ''',
  };

  // ---------------------------------------------------------------------------
  // Sport mode mappings
  // ---------------------------------------------------------------------------

  static const _sportQueries = <String, String>{
    'Rugby': '''
      node["sport"="rugby_union"](around:{radius},{lat},{lon});
      way["sport"="rugby_union"](around:{radius},{lat},{lon});
      node["sport"="rugby_league"](around:{radius},{lat},{lon});
      way["sport"="rugby_league"](around:{radius},{lat},{lon});
      node["leisure"="stadium"]["sport"~"rugby"](around:{radius},{lat},{lon});
      way["leisure"="stadium"]["sport"~"rugby"](around:{radius},{lat},{lon});
    ''',
    'Football': '''
      node["sport"="soccer"](around:{radius},{lat},{lon});
      way["sport"="soccer"](around:{radius},{lat},{lon});
      node["leisure"="stadium"]["sport"="soccer"](around:{radius},{lat},{lon});
      way["leisure"="stadium"]["sport"="soccer"](around:{radius},{lat},{lon});
    ''',
    'Basketball': '''
      node["sport"="basketball"](around:{radius},{lat},{lon});
      way["sport"="basketball"](around:{radius},{lat},{lon});
    ''',
    'Handball': '''
      node["sport"="handball"](around:{radius},{lat},{lon});
      way["sport"="handball"](around:{radius},{lat},{lon});
    ''',
    'Autres sports': '''
      node["leisure"="sports_centre"](around:{radius},{lat},{lon});
      way["leisure"="sports_centre"](around:{radius},{lat},{lon});
      node["leisure"="stadium"](around:{radius},{lat},{lon});
      way["leisure"="stadium"](around:{radius},{lat},{lon});
      node["leisure"="fitness_centre"](around:{radius},{lat},{lon});
      way["leisure"="fitness_centre"](around:{radius},{lat},{lon});
    ''',
  };

  // ---------------------------------------------------------------------------
  // Unified category lookup (merges all modes)
  // ---------------------------------------------------------------------------

  static final Map<String, String> _allQueries = {
    ..._nightQueries,
    ..._familyQueries,
    ..._dayQueries,
    ..._sportQueries,
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Build a complete Overpass QL query for [category] centred on
  /// ([lat], [lon]) with the given [radiusMeters].
  ///
  /// The returned query requests JSON output and includes standard metadata
  /// tags (name, address, phone, website, opening_hours, image, wikimedia).
  ///
  /// Returns `null` if the category is not mapped.
  static String? buildQuery(
    String category,
    double lat,
    double lon,
    int radiusMeters,
  ) {
    final template = _allQueries[category];
    if (template == null) return null;

    final body = template
        .replaceAll('{radius}', radiusMeters.toString())
        .replaceAll('{lat}', lat.toString())
        .replaceAll('{lon}', lon.toString());

    return '''
[out:json][timeout:25];
(
$body
);
out center tags;
''';
  }

  /// Build a query from raw OSM tags (comma-separated `key=value` pairs stored
  /// in the categories table).
  ///
  /// Example input: `"amenity=bar,shop=convenience"`
  static String buildQueryFromOsmTags(
    String osmTags,
    double lat,
    double lon,
    int radiusMeters,
  ) {
    final pairs = osmTags.split(',').map((t) => t.trim()).where((t) => t.contains('='));

    final buffer = StringBuffer();
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length != 2) continue;
      final key = parts[0].trim();
      final value = parts[1].trim();
      buffer.writeln('  node["$key"="$value"](around:$radiusMeters,$lat,$lon);');
      buffer.writeln('  way["$key"="$value"](around:$radiusMeters,$lat,$lon);');
    }

    return '''
[out:json][timeout:25];
(
${buffer.toString()}
);
out center tags;
''';
  }

  // ---------------------------------------------------------------------------
  // Address building from OSM tags
  // ---------------------------------------------------------------------------

  /// Build a human-readable address from an OSM element's tag map.
  ///
  /// Combines `addr:housenumber`, `addr:street`, `addr:postcode` and
  /// `addr:city` when available.
  static String buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    final housenumber = tags['addr:housenumber'] as String?;
    final street = tags['addr:street'] as String?;
    final postcode = tags['addr:postcode'] as String?;
    final city = tags['addr:city'] as String?;

    if (housenumber != null && housenumber.isNotEmpty) {
      if (street != null && street.isNotEmpty) {
        parts.add('$housenumber $street');
      } else {
        parts.add(housenumber);
      }
    } else if (street != null && street.isNotEmpty) {
      parts.add(street);
    }

    if (postcode != null && postcode.isNotEmpty) {
      parts.add(postcode);
    }

    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }

    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // Photo / image URL resolution
  // ---------------------------------------------------------------------------

  /// Resolve a photo URL from OSM tags.
  ///
  /// Priority:
  /// 1. Direct `image` tag (already a URL).
  /// 2. `wikimedia_commons` tag -- converted to a Wikimedia thumbnail URL.
  /// 3. `image:0`, `image:1`, ... variants.
  ///
  /// Returns an empty string if no image information is available.
  static String resolvePhotoUrl(Map<String, dynamic> tags) {
    // 1. Direct image tag
    final image = tags['image'] as String?;
    if (image != null && image.isNotEmpty && Uri.tryParse(image)?.hasScheme == true) {
      return image;
    }

    // 2. Wikimedia Commons
    final wikimedia = tags['wikimedia_commons'] as String?;
    if (wikimedia != null && wikimedia.isNotEmpty) {
      return _wikimediaToThumbUrl(wikimedia);
    }

    // 3. Numbered image variants
    for (var i = 0; i < 5; i++) {
      final variant = tags['image:$i'] as String?;
      if (variant != null && variant.isNotEmpty && Uri.tryParse(variant)?.hasScheme == true) {
        return variant;
      }
    }

    return '';
  }

  /// Convert a Wikimedia Commons file reference (e.g.
  /// `File:Example.jpg`) to a 400px thumbnail URL.
  static String _wikimediaToThumbUrl(String commonsRef) {
    // Strip the "File:" prefix if present.
    var filename = commonsRef;
    if (filename.startsWith('File:')) {
      filename = filename.substring(5);
    }
    filename = filename.replaceAll(' ', '_');

    // Wikimedia commons thumb URL pattern
    final encoded = Uri.encodeComponent(filename);
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encoded?width=400';
  }

  /// List of all supported category names.
  static List<String> get supportedCategories => _allQueries.keys.toList();
}
