import 'package:drift/drift.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/core/utils/query_helpers.dart';
import 'package:pulz_app/core/utils/text_normalizer.dart';
import 'package:pulz_app/features/commerce/data/backend_api_service.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

class CommerceRepository {
  final AppDatabase _db;
  final BackendApiService _backendApi;

  CommerceRepository({
    required AppDatabase db,
    BackendApiService? backendApi,
  })  : _db = db,
        _backendApi = backendApi ?? BackendApiService();

  // ── Sync from backend ──
  Future<bool> syncFromBackend() async {
    try {
      final lastUpdated = await _db.commerceDao.getMaxLastUpdated() ?? 0;
      final remoteCommerces = await _backendApi.fetchSync(since: lastUpdated);

      for (final remote in remoteCommerces) {
        final siret = remote['siret'] as String? ?? '';
        if (siret.isNotEmpty) {
          final existing = await _db.commerceDao.findBySiret(siret);
          final remoteUpdated = remote['lastUpdated'] as int? ?? 0;

          if (existing != null && remoteUpdated > existing.lastUpdated) {
            await _db.commerceDao.updateCommerce(
              existing.copyWith(
                nom: remote['nom'] ?? existing.nom,
                adresse: remote['adresse'] ?? existing.adresse,
                latitude: (remote['latitude'] as num?)?.toDouble() ?? existing.latitude,
                longitude: (remote['longitude'] as num?)?.toDouble() ?? existing.longitude,
                lastUpdated: remoteUpdated,
                synced: true,
              ),
            );
          } else if (existing == null) {
            await _db.commerceDao.insertCommerce(_remoteToCompanion(remote));
          }
        }
      }

      // Push unsynced
      final unsynced = await _db.commerceDao.findUnsynced();
      for (final commerce in unsynced) {
        try {
          await _backendApi.addCommerce(_commerceToMap(commerce));
          await _db.commerceDao.updateCommerce(commerce.copyWith(synced: true));
        } catch (_) {
          // Retry later
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Search by ville (backend-first + Drift fallback) ──
  Future<List<CommerceModel>> searchByVille({
    required String ville,
    String? query,
    double? userLat,
    double? userLon,
  }) async {
    try {
      final remoteData = await _backendApi.fetchByVille(ville: ville, query: query);
      return _processResults(remoteData, userLat, userLon, query);
    } catch (_) {
      // Fallback to local DB
      return _searchLocal(ville: ville, query: query, userLat: userLat, userLon: userLon);
    }
  }

  // ── Search nearby (backend-first + Drift fallback) ──
  Future<List<CommerceModel>> searchNearby({
    required double lat,
    required double lon,
    double radiusMeters = 5000,
    String? query,
  }) async {
    try {
      final remoteData = await _backendApi.fetchNearby(
        lat: lat,
        lon: lon,
        radius: radiusMeters,
        query: query,
      );
      return _processResults(remoteData, lat, lon, query);
    } catch (_) {
      // Fallback to local DB
      return _searchLocalNearby(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
        query: query,
      );
    }
  }

  // ── Add commerce (backend-first fallback) ──
  Future<bool> addCommerce(CommercesCompanion entry) async {
    try {
      await _backendApi.addCommerce({
        'nom': entry.nom.value,
        'adresse': entry.adresse.value,
        'ville': entry.ville.value,
        'codePostal': entry.codePostal.value,
        'categorie': entry.categorie.value,
        'latitude': entry.latitude.value,
        'longitude': entry.longitude.value,
        'horaires': entry.horaires.value,
        'telephone': entry.telephone.value,
      });
      await _db.commerceDao.insertCommerce(
        entry.copyWith(synced: const Value(true)),
      );
      return true;
    } catch (_) {
      // Save locally as unsynced
      await _db.commerceDao.insertCommerce(
        entry.copyWith(synced: const Value(false)),
      );
      return false;
    }
  }

  // ── Private helpers ──

  Future<List<CommerceModel>> _searchLocal({
    required String ville,
    String? query,
    double? userLat,
    double? userLon,
  }) async {
    List<Commerce> results;
    if (query != null && query.isNotEmpty) {
      results = await _db.commerceDao.searchInVille(ville, query);
    } else {
      results = await _db.commerceDao.findByVille(ville);
    }

    return _filterAndSort(results, query, userLat, userLon);
  }

  Future<List<CommerceModel>> _searchLocalNearby({
    required double lat,
    required double lon,
    required double radiusMeters,
    String? query,
  }) async {
    final delta = radiusMeters / 111000.0;
    final results = await _db.commerceDao.findNearby(
      lat - delta,
      lat + delta,
      lon - delta,
      lon + delta,
    );

    return _filterAndSort(results, query, lat, lon, radiusMeters: radiusMeters);
  }

  List<CommerceModel> _filterAndSort(
    List<Commerce> results,
    String? query,
    double? userLat,
    double? userLon, {
    double? radiusMeters,
  }) {
    var filtered = results;

    if (query != null && query.isNotEmpty) {
      final parsed = QueryHelpers.parseQuery(query);

      filtered = filtered.where((c) {
        // Query matching
        if (parsed.cleanQuery.isNotEmpty) {
          if (!QueryHelpers.matchesQuery(parsed.cleanQuery, c.nom, c.categorie)) {
            return false;
          }
        }

        // Filter modifiers
        if (parsed.filterOuvert && !c.ouvert) return false;
        if (parsed.filterIndependant && !c.independant) return false;
        if (parsed.filterBio && TextNormalizer.normalize(c.categorie) != 'bio') {
          return false;
        }

        return true;
      }).toList();
    }

    // Distance filter
    if (userLat != null && userLon != null && radiusMeters != null) {
      filtered = filtered.where((c) {
        final dist = Haversine.distanceInMeters(
          c.latitude,
          c.longitude,
          userLat,
          userLon,
        );
        return dist <= radiusMeters;
      }).toList();
    }

    // Convert and sort by distance
    final models = filtered.map((c) {
      final dist = userLat != null && userLon != null
          ? Haversine.distanceInMeters(c.latitude, c.longitude, userLat, userLon)
          : 0.0;
      return CommerceModel(
        nom: c.nom,
        adresse: c.adresse,
        ville: c.ville,
        categorie: c.categorie,
        latitude: c.latitude,
        longitude: c.longitude,
        horaires: c.horaires,
        ouvert: c.ouvert,
        independant: c.independant,
        telephone: c.telephone,
        siteWeb: c.siteWeb,
        lienMaps: c.lienMaps,
        avis: c.avis,
        photo: c.photo,
        distanceMetres: dist.round(),
        distance: Haversine.formatDistance(dist),
      );
    }).toList();

    models.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));
    return models;
  }

  List<CommerceModel> _processResults(
    List<Map<String, dynamic>> data,
    double? userLat,
    double? userLon,
    String? query,
  ) {
    final models = data.map((d) {
      final lat = (d['latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (d['longitude'] as num?)?.toDouble() ?? 0.0;
      final dist = userLat != null && userLon != null
          ? Haversine.distanceInMeters(lat, lon, userLat, userLon)
          : 0.0;

      return CommerceModel(
        nom: d['nom'] ?? '',
        adresse: d['adresse'] ?? '',
        ville: d['ville'] ?? '',
        categorie: d['categorie'] ?? '',
        latitude: lat,
        longitude: lon,
        horaires: d['horaires'] ?? '',
        ouvert: d['ouvert'] ?? true,
        independant: d['independant'] ?? false,
        telephone: d['telephone'] ?? '',
        siteWeb: d['siteWeb'] ?? '',
        lienMaps: d['lienMaps'] ?? '',
        distanceMetres: dist.round(),
        distance: Haversine.formatDistance(dist),
      );
    }).toList();

    models.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));
    return models;
  }

  CommercesCompanion _remoteToCompanion(Map<String, dynamic> data) {
    return CommercesCompanion(
      nom: Value(data['nom'] ?? ''),
      adresse: Value(data['adresse'] ?? ''),
      ville: Value(data['ville'] ?? ''),
      codePostal: Value(data['codePostal'] ?? ''),
      categorie: Value(data['categorie'] ?? ''),
      latitude: Value((data['latitude'] as num?)?.toDouble() ?? 0.0),
      longitude: Value((data['longitude'] as num?)?.toDouble() ?? 0.0),
      horaires: Value(data['horaires'] ?? ''),
      ouvert: Value(data['ouvert'] ?? true),
      independant: Value(data['independant'] ?? false),
      telephone: Value(data['telephone'] ?? ''),
      siteWeb: Value(data['siteWeb'] ?? ''),
      lienMaps: Value(data['lienMaps'] ?? ''),
      siret: Value(data['siret'] ?? ''),
      codeNaf: Value(data['codeNaf'] ?? ''),
      source: Value(data['source'] ?? 'backend'),
      lastUpdated: Value(data['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch),
      synced: const Value(true),
    );
  }

  Map<String, dynamic> _commerceToMap(Commerce c) {
    return {
      'nom': c.nom,
      'adresse': c.adresse,
      'ville': c.ville,
      'codePostal': c.codePostal,
      'categorie': c.categorie,
      'latitude': c.latitude,
      'longitude': c.longitude,
      'horaires': c.horaires,
      'ouvert': c.ouvert,
      'independant': c.independant,
      'telephone': c.telephone,
      'siteWeb': c.siteWeb,
      'lienMaps': c.lienMaps,
      'siret': c.siret,
      'codeNaf': c.codeNaf,
      'source': c.source,
      'lastUpdated': c.lastUpdated,
    };
  }
}
