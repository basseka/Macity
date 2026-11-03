import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';
import 'package:pulz_app/features/city/data/commune_geo_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Zone affichée par Food / Night / Culture : la commune où se trouve
/// l'utilisateur (GPS) ou celle qu'il a choisie, avec le centre des
/// recherches par rayon. [hub] reste la ville de référence du reste de
/// l'app (events, notifications) : c'est la valeur de `selectedCityProvider`.
class SearchArea {
  final String nom;
  final String hub;
  final double lat;
  final double lng;
  final bool fromGps;

  const SearchArea({
    required this.nom,
    required this.hub,
    required this.lat,
    required this.lng,
    required this.fromGps,
  });

  Map<String, dynamic> toJson() =>
      {'nom': nom, 'hub': hub, 'lat': lat, 'lng': lng, 'gps': fromGps};

  factory SearchArea.fromJson(Map<String, dynamic> j) => SearchArea(
        nom: j['nom'] as String,
        hub: j['hub'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        fromGps: j['gps'] as bool? ?? false,
      );
}

/// Suit la position de l'utilisateur quand l'app est ouverte et met la zone
/// à jour quand il change de commune ou s'éloigne de plus de [refreshKm].
/// Une ville choisie à la main reste fixe jusqu'à [useMyLocation].
/// Pas de suivi en arrière-plan : le flux GPS est coupé quand l'app passe en
/// pause et relancé au retour.
class SearchAreaNotifier extends StateNotifier<SearchArea?>
    with WidgetsBindingObserver {
  SearchAreaNotifier(this._ref) : super(null) {
    WidgetsBinding.instance.addObserver(this);
    _loaded = _load();
  }

  final Ref _ref;
  final _geo = CommuneGeoService();
  late final Future<void> _loaded;
  bool _forced = false;
  bool _started = false;
  bool _resolving = false;
  Position? _lastGeocoded;
  StreamSubscription<Position>? _sub;

  static const _prefArea = 'search_area';
  static const _prefForced = 'search_area_forced';
  static const _prefPrompted = 'location_prompted';

  /// Déplacement au-delà duquel la zone (et donc les listes) se met à jour,
  /// même sans changer de commune.
  static const refreshKm = 3.0;

  /// Déplacement minimum entre deux recherches de commune.
  static const _geocodeEveryKm = 1.0;

  bool get isForced => _forced;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _forced = prefs.getBool(_prefForced) ?? false;
    final raw = prefs.getString(_prefArea);
    if (raw == null) return;
    try {
      final area =
          SearchArea.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      CityCoordinates.registerArea(area.nom, area.lat, area.lng, area.hub);
      state = area;
    } catch (_) {}
  }

  /// Démarre le suivi. Appelé depuis l'accueil (jamais pendant
  /// l'onboarding) ; l'autorisation n'est demandée qu'une seule fois.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loaded;
    if (!_forced) await _startTracking(askIfNeeded: true);
  }

  /// Bouton « Utiliser ma position » : repasse en mode automatique.
  /// Renvoie false si la localisation est refusée ou désactivée.
  Future<bool> useMyLocation() async {
    _forced = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefForced, false);
    final ok = await _startTracking(askIfNeeded: true, alwaysAsk: true);
    if (!ok) return false;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _onPosition(pos, force: true);
    } catch (_) {}
    return true;
  }

  /// Ville hub choisie dans le sélecteur : zone fixe sur son centre.
  Future<void> forceHub(String hub) async {
    final c = CityCoordinates.of(hub);
    await _force(SearchArea(
        nom: hub, hub: hub, lat: c.lat, lng: c.lng, fromGps: false,),);
  }

  /// Commune choisie dans le sélecteur (Albi, Montauban…) : zone fixe sur
  /// son centre, rattachée au hub de son département.
  Future<void> forceCommune(CommuneGeo commune) async {
    await _force(SearchArea(
      nom: _canonicalName(commune.nom, commune.hub),
      hub: commune.hub,
      lat: commune.lat,
      lng: commune.lng,
      fromGps: false,
    ),);
  }

  Future<void> _force(SearchArea area) async {
    _forced = true;
    await _sub?.cancel();
    _sub = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefForced, true);
    await _apply(area);
  }

  Future<bool> _startTracking({
    required bool askIfNeeded,
    bool alwaysAsk = false,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && askIfNeeded) {
        final prefs = await SharedPreferences.getInstance();
        if (alwaysAsk || !(prefs.getBool(_prefPrompted) ?? false)) {
          await prefs.setBool(_prefPrompted, true);
          perm = await Geolocator.requestPermission();
        }
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return false;
      }
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) await _onPosition(last);
      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 500,
        ),
      ).listen((p) => _onPosition(p), onError: (_) {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPosition(Position p, {bool force = false}) async {
    if (_forced || _resolving) return;
    final last = _lastGeocoded;
    if (!force &&
        last != null &&
        _km(last.latitude, last.longitude, p.latitude, p.longitude) <
            _geocodeEveryKm) {
      return;
    }
    _resolving = true;
    try {
      _lastGeocoded = p;
      final next = await _areaAt(p.latitude, p.longitude);
      if (next == null || _forced) return;
      final cur = state;
      final unchanged = cur != null &&
          cur.fromGps &&
          cur.nom == next.nom &&
          _km(cur.lat, cur.lng, next.lat, next.lng) < refreshKm;
      if (!force && unchanged) return;
      await _apply(next);
    } finally {
      _resolving = false;
    }
  }

  /// Commune française qui contient le point ; hors de France, hub le plus
  /// proche à moins de 40 km (Barcelone, Genève) ; sinon null.
  Future<SearchArea?> _areaAt(double lat, double lng) async {
    final commune = await _geo.communeAt(lat, lng);
    if (commune != null) {
      final hub = commune.hub;
      return SearchArea(
        nom: _canonicalName(commune.nom, hub),
        hub: hub,
        lat: lat,
        lng: lng,
        fromGps: true,
      );
    }
    String? nearest;
    var best = 40.0;
    for (final hub in CityCoordinates.hubNames) {
      final c = CityCoordinates.of(hub);
      final d = _km(lat, lng, c.lat, c.lng);
      if (d < best) {
        best = d;
        nearest = hub;
      }
    }
    if (nearest == null) return null;
    return SearchArea(
        nom: nearest, hub: nearest, lat: lat, lng: lng, fromGps: true,);
  }

  Future<void> _apply(SearchArea area) async {
    CityCoordinates.registerArea(area.nom, area.lat, area.lng, area.hub);
    state = area;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefArea, jsonEncode(area.toJson()));
    if (_ref.read(selectedCityProvider) != area.hub) {
      await _ref
          .read(selectedCityProvider.notifier)
          .setCity(area.hub, updateProfile: !area.fromGps);
    }
  }

  /// « Besançon » détectée par le GPS doit s'appeler comme le hub
  /// (« Besancon ») : c'est ce nom qui est écrit sur les fiches en base.
  static String _canonicalName(String commune, String hub) =>
      _fold(commune) == _fold(hub) ? hub : commune;

  static String _fold(String s) {
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿ';
    const to = 'aaaaaceeeeiiiinooooouuuuy';
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static double _km(double lat1, double lng1, double lat2, double lng2) =>
      Haversine.distanceInMeters(lat1, lng1, lat2, lng2) / 1000;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sub?.cancel();
      _sub = null;
    } else if (state == AppLifecycleState.resumed && _started && !_forced) {
      _startTracking(askIfNeeded: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }
}

final searchAreaProvider =
    StateNotifierProvider<SearchAreaNotifier, SearchArea?>(
  (ref) => SearchAreaNotifier(ref),
);

/// Nom de la commune interrogée par Food / Night / Culture. Retombe sur la
/// ville choisie si la zone n'est pas encore connue ou si la ville a été
/// changée ailleurs (onboarding…) sans passer par la zone.
final areaVilleProvider = Provider<String>((ref) {
  final city = ref.watch(selectedCityProvider);
  final area = ref.watch(searchAreaProvider);
  return (area != null && area.hub == city) ? area.nom : city;
});

/// Commune interrogée + centre des recherches par rayon. Change aussi quand
/// l'utilisateur s'est déplacé de plus de [SearchAreaNotifier.refreshKm] sans
/// changer de commune : les listes Food / Night / Culture se rechargent.
final searchZoneProvider =
    Provider<({String ville, double? lat, double? lng})>((ref) {
  final ville = ref.watch(areaVilleProvider);
  ref.watch(searchAreaProvider);
  final c = CityCoordinates.maybeOf(ville);
  return (ville: ville, lat: c?.lat, lng: c?.lng);
});
