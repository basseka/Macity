import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/database/daos/category_dao.dart';
import 'package:pulz_app/core/database/daos/commerce_dao.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/core/utils/text_normalizer.dart';
import 'package:pulz_app/features/commerce/data/overpass_query_builder.dart';

/// Enriches the local commerce database with data from OpenStreetMap via the
/// Overpass API.
///
/// The enricher runs per-city and per-category. It maintains a 7-day cache
/// window: if a category was synced less than 7 days ago the sync is skipped.
class OsmEnricher {
  OsmEnricher({
    required CommerceDao commerceDao,
    required CategoryDao categoryDao,
    Dio? dio,
  })  : _commerceDao = commerceDao,
        _categoryDao = categoryDao,
        _dio = dio ?? DioClient.withBaseUrl(ApiConstants.overpassBaseUrl);

  final CommerceDao _commerceDao;
  final CategoryDao _categoryDao;
  final Dio _dio;

  /// Duration after which a category is re-synced from OSM.
  static const syncInterval = Duration(days: 7);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Enrich commerces for [ville] at ([cityLat], [cityLon]).
  ///
  /// Iterates over all categories that have `osmTags` defined, checks the
  /// 7-day cache, and queries Overpass for fresh data when needed.
  Future<void> enrichCity(
    String ville,
    double cityLat,
    double cityLon,
  ) async {
    final categories = await _categoryDao.getAll();

    for (final category in categories) {
      if (category.osmTags.isEmpty) continue;

      // Check 7-day cache: skip if last sync is recent enough.
      if (await _isCacheValid(ville, category.nom)) continue;

      try {
        await _syncCategory(
          ville: ville,
          categoryName: category.nom,
          osmTags: category.osmTags,
          cityLat: cityLat,
          cityLon: cityLon,
        );
      } catch (e) {
        // Silently skip individual category failures so we don't block
        // the rest. Logging can be added here.
        debugPrint('[OsmEnricher] Failed to sync ${category.nom} for $ville: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cache check
  // ---------------------------------------------------------------------------

  /// Returns `true` if the category for [ville] was synced within the last
  /// [syncInterval] (7 days).
  Future<bool> _isCacheValid(String ville, String categoryName) async {
    final commerces = await _commerceDao.findByVille(ville);
    final matching = commerces.where(
      (c) => c.categorie == categoryName && c.source == 'osm',
    );
    if (matching.isEmpty) return false;

    // Use the most recent lastUpdated timestamp among OSM-sourced entries.
    final latestSync = matching
        .map((c) => c.lastUpdated)
        .reduce((a, b) => a > b ? a : b);

    final lastSyncDate =
        DateTime.fromMillisecondsSinceEpoch(latestSync * 1000);
    return DateTime.now().difference(lastSyncDate) < syncInterval;
  }

  // ---------------------------------------------------------------------------
  // Sync logic
  // ---------------------------------------------------------------------------

  Future<void> _syncCategory({
    required String ville,
    required String categoryName,
    required String osmTags,
    required double cityLat,
    required double cityLon,
  }) async {
    // Build bbox: ~0.05 degrees around the city centre (approx 5 km).
    final latMin = cityLat - 0.05;
    final latMax = cityLat + 0.05;
    final lonMin = cityLon - 0.05;
    final lonMax = cityLon + 0.05;

    // Build the Overpass query from osmTags.
    final query = _buildBboxQuery(osmTags, latMin, latMax, lonMin, lonMax);

    // Execute the query.
    final elements = await _executeOverpassQuery(query);
    if (elements.isEmpty) return;

    // Fetch existing commerces for matching.
    final existingCommerces = await _commerceDao.findByVille(ville);
    final categoryCommerces = existingCommerces
        .where((c) => c.categorie == categoryName)
        .toList();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final element in elements) {
      final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
      final name = (tags['name'] as String?) ?? '';
      if (name.isEmpty) continue;

      // Resolve coordinates (nodes have lat/lon directly; ways use "center").
      final double? osmLat = _resolveCoord(element, 'lat');
      final double? osmLon = _resolveCoord(element, 'lon');
      if (osmLat == null || osmLon == null) continue;

      // --- Match priority ---
      final matched = _findMatch(
        name: name,
        lat: osmLat,
        lon: osmLon,
        candidates: categoryCommerces,
      );

      if (matched != null) {
        // Update existing commerce with fresh OSM data.
        await _updateExisting(matched, tags, osmLat, osmLon, now);
      } else {
        // Create new commerce from OSM.
        await _createNew(
          name: name,
          tags: tags,
          lat: osmLat,
          lon: osmLon,
          ville: ville,
          categorie: categoryName,
          now: now,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Overpass query helpers
  // ---------------------------------------------------------------------------

  /// Build an Overpass QL query using a bbox instead of `around`.
  ///
  /// [osmTags] is a comma-separated string like `"amenity=bar,shop=pub"`.
  String _buildBboxQuery(
    String osmTags,
    double latMin,
    double latMax,
    double lonMin,
    double lonMax,
  ) {
    final pairs =
        osmTags.split(',').map((t) => t.trim()).where((t) => t.contains('='));

    final buffer = StringBuffer();
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length != 2) continue;
      final key = parts[0].trim();
      final value = parts[1].trim();
      buffer.writeln('  node["$key"="$value"]($latMin,$lonMin,$latMax,$lonMax);');
      buffer.writeln('  way["$key"="$value"]($latMin,$lonMin,$latMax,$lonMax);');
    }

    return '''
[out:json][timeout:30];
(
${buffer.toString()}
);
out center tags;
''';
  }

  /// Execute an Overpass query and return the list of `elements`.
  Future<List<Map<String, dynamic>>> _executeOverpassQuery(String query) async {
    try {
      final response = await _dio.get(
        ApiConstants.overpassEndpoint,
        queryParameters: {'data': query},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>?;
        return elements?.cast<Map<String, dynamic>>() ?? [];
      }
    } on DioException catch (e) {
      // Try fallback Overpass server.
      if (e.response?.statusCode == 429 || e.type == DioExceptionType.connectionTimeout) {
        return _executeOverpassQueryFallback(query);
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _executeOverpassQueryFallback(
    String query,
  ) async {
    try {
      final fallbackDio =
          DioClient.withBaseUrl(ApiConstants.overpassFallbackBaseUrl);
      final response = await fallbackDio.get(
        ApiConstants.overpassEndpoint,
        queryParameters: {'data': query},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>?;
        return elements?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (_) {
      // Both servers failed; return empty.
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Matching
  // ---------------------------------------------------------------------------

  /// Find the best existing commerce that matches the OSM element.
  ///
  /// Match priority:
  /// 1. Category match + name substring match (normalized).
  /// 2. Category match + proximity < 50 m.
  /// 3. No match -- will create a new entry.
  Commerce? _findMatch({
    required String name,
    required double lat,
    required double lon,
    required List<Commerce> candidates,
  }) {
    final normalizedName = TextNormalizer.normalize(name);

    // Priority 1: category + name substring match
    for (final c in candidates) {
      final normalizedExisting = TextNormalizer.normalize(c.nom);
      if (normalizedExisting.contains(normalizedName) ||
          normalizedName.contains(normalizedExisting)) {
        return c;
      }
    }

    // Priority 2: category + proximity < 50 m
    Commerce? closest;
    double closestDist = double.infinity;
    for (final c in candidates) {
      final dist = Haversine.distanceInMeters(c.latitude, c.longitude, lat, lon);
      if (dist < 50 && dist < closestDist) {
        closestDist = dist;
        closest = c;
      }
    }

    return closest;
  }

  // ---------------------------------------------------------------------------
  // Update / Create
  // ---------------------------------------------------------------------------

  Future<void> _updateExisting(
    Commerce existing,
    Map<String, dynamic> tags,
    double lat,
    double lon,
    int now,
  ) async {
    final address = OverpassQueryBuilder.buildAddress(tags);
    final phone = (tags['phone'] as String?) ?? (tags['contact:phone'] as String?) ?? '';
    final website = (tags['website'] as String?) ?? (tags['contact:website'] as String?) ?? '';
    final hours = (tags['opening_hours'] as String?) ?? '';
    final photo = OverpassQueryBuilder.resolvePhotoUrl(tags);

    final updated = existing.copyWith(
      latitude: lat,
      longitude: lon,
      adresse: address.isNotEmpty ? address : existing.adresse,
      horaires: hours.isNotEmpty ? hours : existing.horaires,
      telephone: phone.isNotEmpty ? phone : existing.telephone,
      siteWeb: website.isNotEmpty ? website : existing.siteWeb,
      photo: photo.isNotEmpty ? photo : existing.photo,
      lastUpdated: now,
      synced: false,
    );

    await _commerceDao.updateCommerce(updated);
  }

  Future<void> _createNew({
    required String name,
    required Map<String, dynamic> tags,
    required double lat,
    required double lon,
    required String ville,
    required String categorie,
    required int now,
  }) async {
    final address = OverpassQueryBuilder.buildAddress(tags);
    final phone = (tags['phone'] as String?) ?? (tags['contact:phone'] as String?) ?? '';
    final website = (tags['website'] as String?) ?? (tags['contact:website'] as String?) ?? '';
    final hours = (tags['opening_hours'] as String?) ?? '';
    final photo = OverpassQueryBuilder.resolvePhotoUrl(tags);

    final entry = CommercesCompanion(
      nom: Value(name),
      adresse: Value(address),
      ville: Value(ville),
      categorie: Value(categorie),
      latitude: Value(lat),
      longitude: Value(lon),
      horaires: Value(hours),
      telephone: Value(phone),
      siteWeb: Value(website),
      photo: Value(photo),
      source: const Value('osm'),
      lastUpdated: Value(now),
      synced: const Value(false),
    );

    await _commerceDao.insertCommerce(entry);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Resolve latitude or longitude from an Overpass element.
  ///
  /// Nodes have `lat`/`lon` directly. Ways/relations use the `center` object
  /// when queried with `out center`.
  double? _resolveCoord(Map<String, dynamic> element, String key) {
    if (element.containsKey(key)) {
      return (element[key] as num?)?.toDouble();
    }
    final center = element['center'] as Map<String, dynamic>?;
    if (center != null && center.containsKey(key)) {
      return (center[key] as num?)?.toDouble();
    }
    return null;
  }
}
