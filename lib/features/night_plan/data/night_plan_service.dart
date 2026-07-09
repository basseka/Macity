import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/food/data/restaurant_supabase_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart'
    show RestaurantVenue;
import 'package:pulz_app/features/night_plan/domain/night_stop.dart';

/// Construit une « feuille de route » de soirée autour d'un événement :
/// un dîner, un bar et une boîte de nuit dans la même ville.
///
/// D'abord un parcours curé par l'admin (RPC get_parcours_for_event : ancre
/// proche par proximité GPS, sinon parcours ville) ; chaque slot vide retombe
/// sur la sélection auto « géo simple » : par distance quand on connaît les
/// coordonnées de l'événement, sinon par partenaire + priorité.
class NightPlanService {
  final VenuesSupabaseService _venues;
  final RestaurantSupabaseService _restaurants;
  final Dio _dio;

  NightPlanService({
    VenuesSupabaseService? venues,
    RestaurantSupabaseService? restaurants,
    Dio? dio,
  })  : _venues = venues ?? VenuesSupabaseService(),
        _restaurants = restaurants ?? RestaurantSupabaseService(),
        _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  // Classement des catégories night (matching par sous-chaîne, car les valeurs
  // réelles varient : « Bar de nuit », « Club Discotheque », « Club & Disco »…).
  // Une boîte est testée AVANT un bar (un « club » peut contenir « bar »).
  static bool _isClub(String c) {
    final s = c.toLowerCase();
    return s.contains('club') ||
        s.contains('disco') ||
        s.contains('boite') ||
        s.contains('boîte');
  }

  static bool _isBar(String c) {
    if (_isClub(c)) return false;
    final s = c.toLowerCase();
    // Exclut épicerie/tabac/hôtel/coquin/strip/soirée… (ne matchent rien).
    return s.contains('bar') ||
        s.contains('pub') ||
        s.contains('rooftop') ||
        s.contains('lounge');
  }

  // Étape dîner : on exclut les rubriques `food` non-restaurant (spa/bien-être,
  // épicerie, beauté…) tout en gardant restaurant/café/brunch/insolite/etc.
  static const _nonDiningKeywords = [
    'bien-etre',
    'bien-être',
    'lifestyle',
    'spa',
    'wellness',
    'epicerie',
    'épicerie',
    'boutique',
    'beaute',
    'beauté',
  ];

  static bool _isRestaurant(String c) {
    final s = c.toLowerCase();
    return !_nonDiningKeywords.any(s.contains);
  }

  Future<NightPlan> build({
    required String ville,
    double? anchorLat,
    double? anchorLng,
  }) async {
    // 1. Parcours curé par l'admin : d'abord un parcours ancré sur un lieu
    // proche de l'event (proximité GPS), sinon le parcours de la ville.
    final parcours = await _fetchParcours(ville, anchorLat, anchorLng);
    final curatedDinner = _stopFromJson(
      parcours?['dinner'],
      NightStopKind.dinner,
      anchorLat,
      anchorLng,
    );
    final curatedBar = _stopFromJson(
      parcours?['bar'],
      NightStopKind.bar,
      anchorLat,
      anchorLng,
    );
    final curatedClub = _stopFromJson(
      parcours?['club'],
      NightStopKind.club,
      anchorLat,
      anchorLng,
    );

    // 2. Fallback auto : uniquement pour les slots non curés.
    final needFallback =
        curatedDinner == null || curatedBar == null || curatedClub == null;
    var restos = const <CommerceModel>[];
    var nightVenues = const <CommerceModel>[];
    if (needFallback) {
      if (anchorLat != null && anchorLng != null) {
        // Mode DISTANCE : on prend les lieux les plus proches des coordonnées
        // de l'événement (bounding box ~40 km), toutes villes confondues.
        final results = await Future.wait([
          _fetchNearbyFood(anchorLat, anchorLng),
          _fetchNearbyNight(anchorLat, anchorLng),
        ]);
        restos = results[0];
        nightVenues = results[1];
      } else if (ville.isNotEmpty) {
        // Fallback sans coordonnées : par ville, partenaire + priorité.
        final results = await Future.wait([
          _restaurants.fetchRestaurants(ville: ville),
          _venues.fetchVenues(mode: 'night', ville: ville),
        ]);
        restos =
            (results[0] as List<RestaurantVenue>).map(_cmFromResto).toList();
        nightVenues = (results[1] as List<CommerceModel>);
      }
    }
    final bars = nightVenues.where((v) => _isBar(v.categorie)).toList();
    final clubs = nightVenues.where((v) => _isClub(v.categorie)).toList();
    final diners = restos.where((r) => _isRestaurant(r.categorie)).toList();

    return NightPlan(
      ville: ville,
      dinner: curatedDinner ??
          _pickVenue(diners, NightStopKind.dinner, anchorLat, anchorLng),
      bar: curatedBar ??
          _pickVenue(bars, NightStopKind.bar, anchorLat, anchorLng),
      club: curatedClub ??
          _pickVenue(clubs, NightStopKind.club, anchorLat, anchorLng),
    );
  }

  /// Parcours curé : ancre proche (coords) sinon ville. Null si aucun / RPC
  /// absente.
  Future<Map<String, dynamic>?> _fetchParcours(
    String ville,
    double? anchorLat,
    double? anchorLng,
  ) async {
    try {
      final res = await _dio.post(
        'rpc/get_parcours_for_event',
        data: {
          'p_lat': anchorLat,
          'p_lng': anchorLng,
          'p_ville': ville,
        },
      );
      final d = res.data;
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      // RPC pas encore déployée ou erreur réseau → fallback auto complet.
      return null;
    }
  }

  NightStop? _stopFromJson(
    dynamic j,
    NightStopKind kind,
    double? aLat,
    double? aLng,
  ) {
    if (j is! Map) return null;
    final lat = (j['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (j['longitude'] as num?)?.toDouble() ?? 0;
    return NightStop(
      kind: kind,
      name: j['name'] as String? ?? '',
      categorie: j['categorie'] as String? ?? '',
      adresse: j['adresse'] as String? ?? '',
      ville: j['ville'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      photo: j['photo'] as String? ?? '',
      lienMaps: j['lien_maps'] as String? ?? '',
      isPartner: j['is_partner'] as bool? ?? false,
      distanceMeters: _distance(lat, lng, aLat, aLng),
    );
  }

  int? _distance(double lat, double lng, double? aLat, double? aLng) {
    if (aLat == null || aLng == null) return null;
    if (lat == 0 && lng == 0) return null;
    return Haversine.distanceInMeters(lat, lng, aLat, aLng).round();
  }

  /// Classe la sélection AUTO : uniquement par distance quand on a un point
  /// d'ancrage. Sinon on garde l'ordre de la requête (priorité d'affichage).
  ///
  /// Volontairement NEUTRE vis-à-vis des partenaires : la mise en avant d'un
  /// partenaire se fait UNIQUEMENT via un parcours curé dans admin.html, jamais
  /// en biaisant l'auto.
  void _rank<T>(
    List<T> list,
    double? aLat,
    double? aLng,
    double Function(T) getLat,
    double Function(T) getLng,
  ) {
    if (aLat != null && aLng != null) {
      list.sort((a, b) {
        final da = _distance(getLat(a), getLng(a), aLat, aLng) ?? 1 << 30;
        final db = _distance(getLat(b), getLng(b), aLat, aLng) ?? 1 << 30;
        return da.compareTo(db);
      });
    }
    // Sans ancrage : ordre inchangé (déjà trié par display_priority côté requête).
  }

  // ── Conversion vers CommerceModel (type commun pour les 3 étapes) ──
  CommerceModel _cmFromResto(RestaurantVenue r) => CommerceModel(
        nom: r.name,
        categorie: r.group.isNotEmpty ? r.group : 'Restaurant',
        adresse: r.adresse,
        latitude: r.latitude,
        longitude: r.longitude,
        photo: r.photo,
        lienMaps: r.lienMaps,
        isPartner: r.isPartner,
      );

  CommerceModel _cmFromVenueJson(Map<String, dynamic> j) => CommerceModel(
        nom: j['name'] as String? ?? '',
        categorie: j['category'] as String? ?? '',
        adresse: j['adresse'] as String? ?? '',
        ville: j['ville'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        photo: j['photo'] as String? ?? '',
        lienMaps: j['lien_maps'] as String? ?? '',
        isPartner: j['is_partner'] as bool? ?? false,
      );

  CommerceModel _cmFromEtabJson(Map<String, dynamic> j) => CommerceModel(
        nom: j['nom'] as String? ?? '',
        categorie: j['categorie'] as String? ?? '',
        adresse: j['adresse'] as String? ?? '',
        ville: j['ville'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        photo: j['photo'] as String? ?? '',
        lienMaps: j['lien_maps'] as String? ?? '',
        isPartner: j['is_partner'] as bool? ?? false,
      );

  // ── Requêtes « bounding box » autour d'un point (mode distance) ──
  // Retourne [latMin, latMax, lngMin, lngMax] pour un rayon en km.
  List<double> _bbox(double lat, double lng, double km) {
    final dLat = km / 111.0;
    final cosLat = math.cos(lat * math.pi / 180).abs();
    final dLng = km / (111.0 * (cosLat < 0.01 ? 0.01 : cosLat));
    return [lat - dLat, lat + dLat, lng - dLng, lng + dLng];
  }

  String _bboxFilter(List<double> b) =>
      '(latitude.gte.${b[0]},latitude.lte.${b[1]},'
      'longitude.gte.${b[2]},longitude.lte.${b[3]})';

  Future<List<CommerceModel>> _fetchNearbyNight(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'venues',
        queryParameters: {
          'select':
              'name,category,adresse,ville,latitude,longitude,photo,lien_maps,is_partner',
          'mode': 'eq.night',
          'is_active': 'eq.true',
          'and': _bboxFilter(_bbox(lat, lng, 40)),
          'limit': '1000',
        },
      );
      return (res.data as List)
          .map((e) => _cmFromVenueJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CommerceModel>> _fetchNearbyFood(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'etablissements',
        queryParameters: {
          'select':
              'nom,categorie,adresse,ville,latitude,longitude,photo,lien_maps,is_partner',
          'rubrique': 'eq.food',
          'is_active': 'eq.true',
          'and': _bboxFilter(_bbox(lat, lng, 40)),
          'limit': '1000',
        },
      );
      return (res.data as List)
          .map((e) => _cmFromEtabJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  NightStop? _pickVenue(
    List<CommerceModel> list,
    NightStopKind kind,
    double? aLat,
    double? aLng,
  ) {
    if (list.isEmpty) return null;
    final sorted = [...list];
    _rank(
      sorted,
      aLat,
      aLng,
      (v) => v.latitude,
      (v) => v.longitude,
    );
    final v = sorted.first;
    return NightStop(
      kind: kind,
      name: v.nom,
      categorie: v.categorie,
      adresse: v.adresse,
      ville: v.ville,
      latitude: v.latitude,
      longitude: v.longitude,
      photo: v.photo,
      lienMaps: v.lienMaps,
      isPartner: v.isPartner,
      distanceMeters: _distance(v.latitude, v.longitude, aLat, aLng),
    );
  }
}
