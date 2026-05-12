import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/toulouse_peripherique.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_paged_sheet.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_realtime_provider.dart';

/// Mini-carte Leaflet (WebView) qui affiche les signalements actifs sous forme
/// de points rouges pulsants. Pattern adapte de `VenuesMapView`.
///
/// Tap sur un point -> ouvre le bottom sheet detail du signalement.
class ReportedEventsMap extends ConsumerStatefulWidget {
  final double height;

  /// Si true, n'écoute pas le provider real-time et injecte des markers
  /// fictifs autour du centre ville pour la presentation home.
  final bool usePresentationMarkers;

  const ReportedEventsMap({
    super.key,
    this.height = 180,
    this.usePresentationMarkers = false,
  });

  @override
  ConsumerState<ReportedEventsMap> createState() => _ReportedEventsMapState();
}

/// Cache global du WebView de la map. La premiere instance cree + charge le
/// controller ; les suivantes (re-mount apres push/pop) reutilisent le meme
/// controller deja "page ready" -> plus de spinner pendant le re-chargement
/// Leaflet/tiles.
class _MapWebViewCache {
  static WebViewController? controller;
  static bool pageReady = false;
  // Notifier qui re-route les taps marker vers l'instance actuelle.
  static void Function(String id)? onMarkerTap;
}

class _ReportedEventsMapState extends ConsumerState<ReportedEventsMap> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _pageReady = false;
  List<ReportedEvent> _lastEvents = const [];
  String? _lastCity;

  @override
  void initState() {
    super.initState();
    // Bind le callback de tap marker a CETTE instance (re-route via cache).
    _MapWebViewCache.onMarkerTap = _handleMarkerTap;

    if (_MapWebViewCache.controller != null) {
      // Reuse : on a deja un controller charge en memoire.
      _controller = _MapWebViewCache.controller!;
      _pageReady = _MapWebViewCache.pageReady;
      _isLoading = !_pageReady;
      // Re-injecter les markers/centre avec les donnees fraiches.
      if (_pageReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastCity != null) _centerOnCity(_lastCity!);
          _autoLocateUserPin();
          if (widget.usePresentationMarkers) {
            _injectPresentationMarkersForCurrentCity();
          } else if (_lastEvents.isNotEmpty) {
            _injectMarkers(_lastEvents);
          }
        });
      }
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setUserAgent('PulzApp/1.0 (https://pulzapp.fr)')
      ..addJavaScriptChannel(
        'FlutterReportTap',
        // Channel statique : route vers l'instance courante via le cache.
        // Empeche le callback de capturer un `this` mort apres pop/push.
        onMessageReceived: (msg) {
          _MapWebViewCache.onMarkerTap?.call(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _MapWebViewCache.pageReady = true;
            if (mounted) setState(() => _isLoading = false);
            _pageReady = true;
            if (_lastCity != null) _centerOnCity(_lastCity!);
            _autoLocateUserPin();
            if (widget.usePresentationMarkers) {
              _injectPresentationMarkersForCurrentCity();
            } else if (_lastEvents.isNotEmpty) {
              _injectMarkers(_lastEvents);
            }
          },
        ),
      );
    _MapWebViewCache.controller = _controller;
    _loadHtml();
  }

  @override
  void dispose() {
    // Important : on ne dispose PAS le controller, il reste vivant dans le
    // cache pour le prochain mount. On detache juste le callback de tap.
    if (_MapWebViewCache.onMarkerTap == _handleMarkerTap) {
      _MapWebViewCache.onMarkerTap = null;
    }
    super.dispose();
  }

  /// Recentre la map sur le centre de la ville donnee.
  Future<void> _centerOnCity(String city) async {
    if (!_pageReady) return;
    final center = CityCenters.center(city);
    if (center == null) return;
    debugPrint('[ReportedEventsMap] center on city $city: ${center.lat}, ${center.lng}');
    await _controller.runJavaScript(
      'centerOnCity(${center.lat}, ${center.lng})',
    );
  }

  /// Affiche un pin "Ma position". Tente d'abord lastKnownPosition (rapide),
  /// puis getCurrentPosition (fix GPS frais) en fallback. Centre la map sur
  /// l'utilisateur quand on est sur la page dynamique (MapLive).
  Future<void> _autoLocateUserPin() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Map] location service disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Map] location permission denied: $permission');
        return;
      }

      // Fix GPS frais uniquement (high accuracy ~10m). On évite
      // getLastKnownPosition qui retourne souvent un cache stale (km off).
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (e) {
        debugPrint('[Map] getCurrentPosition failed: $e');
        // Fallback last-known SEULEMENT s'il est récent (<5 min)
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final age = DateTime.now().difference(last.timestamp);
          if (age.inMinutes < 5) {
            pos = last;
            debugPrint('[Map] using last known (age=${age.inSeconds}s)');
          } else {
            debugPrint('[Map] last known too old (age=${age.inMinutes}min)');
          }
        }
      }

      if (pos != null && _pageReady) {
        debugPrint('[Map] user pos: ${pos.latitude}, ${pos.longitude}');
        await _controller.runJavaScript(
          'showUserPin(${pos.latitude}, ${pos.longitude})',
        );
        // Sur la page MapLive (mode dynamique), recentre sur le user à
        // zoom rapproché. Sur la home (presentation), garde le centre ville.
        if (!widget.usePresentationMarkers) {
          await _controller.runJavaScript(
            'map.setView([${pos.latitude}, ${pos.longitude}], 14)',
          );
        }
      } else {
        debugPrint('[Map] no GPS position available');
      }
    } catch (e) {
      debugPrint('[Map] _autoLocateUserPin error: $e');
    }
  }

  /// Injecte 14 markers fictifs autour du centre de la ville courante.
  /// Utilise pour la presentation home (la map dynamique reelle est sur
  /// la page MapLive avec usePresentationMarkers=false).
  Future<void> _injectPresentationMarkersForCurrentCity() async {
    if (!_pageReady) {
      debugPrint('[PresentationMap] not ready yet');
      return;
    }
    final city = _lastCity ?? ref.read(selectedCityProvider);
    if (city == null) {
      debugPrint('[PresentationMap] no city');
      return;
    }
    final center = CityCenters.center(city);
    if (center == null) {
      debugPrint('[PresentationMap] no center for $city — fallback Toulouse');
    }
    final fallback = (lat: 43.6047, lng: 1.4442);
    final cc = center ?? fallback;
    // Mix : fakes (presentation) + reals (signalements actifs si disponibles)
    final realEvents = ref.read(reportedEventsFeedProvider).valueOrNull ?? const [];
    const categories = ['nightlife', 'food', 'culture', 'sport', 'general'];
    const titles = [
      'Bar à cocktails',
      'Resto branché',
      "Galerie d'art",
      'Cours de fitness',
      'Concert acoustique',
      'Food truck',
      'Expo photo',
      'Yoga matinal',
      'DJ set',
      'Marché bio',
      'Atelier peinture',
      'Match local',
      'Soirée latino',
      'Brunch dominical',
    ];
    final rand = Random(cc.lat.hashCode ^ cc.lng.hashCode);
    final fakes = <Map<String, dynamic>>[];
    for (var i = 0; i < 14; i++) {
      final dLat = (rand.nextDouble() - 0.5) * 0.05;
      final dLng = (rand.nextDouble() - 0.5) * 0.05;
      fakes.add({
        'id': 'fake_$i',
        'lat': cc.lat + dLat,
        'lng': cc.lng + dLng,
        'title': titles[i % titles.length],
        'category': categories[i % categories.length],
      });
    }
    // Ajoute les vrais signalements pour qu'ils apparaissent en + des fakes.
    // is_real=true pour les distinguer côté CSS si besoin futur.
    final all = <Map<String, dynamic>>[
      ...fakes,
      for (final e in realEvents)
        {
          'id': e.id,
          'lat': e.lat,
          'lng': e.lng,
          'title': e.rawTitle,
          'category': e.category,
          'is_real': true,
        },
    ];
    final json = jsonEncode(all);
    // Petit delai pour s'assurer que la couche L.layerGroup est prête côté JS.
    await Future.delayed(const Duration(milliseconds: 250));
    debugPrint(
        '[PresentationMap] injecting ${fakes.length} fake + ${realEvents.length} real markers around $city');
    await _controller.runJavaScript('setPresentationReports($json)');
  }

  void _handleMarkerTap(String id) {
    final idx = _lastEvents.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    ReportedEventsPagedSheet.open(
      context,
      events: _lastEvents,
      initialIndex: idx,
    );
  }

  Future<void> _injectMarkers(List<ReportedEvent> events) async {
    if (!_pageReady) return;
    final js = events.map((e) {
      final emoji = (e.generated?.emoji ?? '📍').replaceAll("'", "\\'");
      final title = (e.generated?.title ?? e.rawTitle).replaceAll("'", "\\'");
      final photoCount = e.photos.length;
      final reportCount = e.reportCount;
      final category = e.category.replaceAll("'", "\\'");
      return "{id:'${e.id}',lat:${e.lat},lng:${e.lng},emoji:'$emoji',title:'$title',photos:$photoCount,reports:$reportCount,category:'$category'}";
    }).join(',');
    await _controller.runJavaScript('setReports([$js])');
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script src="https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { height: 100%; overflow: hidden; background: #04020A; }
    #map { width: 100vw; height: 100vh; background: #04020A; }
    .leaflet-control-attribution {
      font-size: 8px;
      background: rgba(10, 4, 20, 0.5) !important;
      color: rgba(245, 240, 255, 0.4) !important;
    }
    .leaflet-control-attribution a { color: rgba(168, 85, 247, 0.6) !important; }

    /* Tint violet sur les tuiles dark CartoDB pour matcher la spec neon */
    .leaflet-tile-pane {
      filter: hue-rotate(245deg) saturate(1.4) brightness(0.85);
    }

    /* Pins style "goutte SVG" 24x26 + halo radial pulsant 40px (spec neon).
       Optim 2026-05-12 :
        - halo "pulse" actif UNIQUEMENT sur les pins .real (signalements
          actifs). Sur les fakes le halo reste statique = pas de repaint
          continu de N gradients radiaux.
        - drop-shadow CSS retire (couteux non-GPU). On garde un box-shadow
          discret sur le halo lui-meme = GPU compose. */
    .neon-pin {
      position: relative;
      width: 24px; height: 26px;
      cursor: pointer;
    }
    .neon-pin .halo {
      position: absolute;
      left: -8px; top: -7px;
      width: 40px; height: 40px;
      border-radius: 50%;
      pointer-events: none;
      background: radial-gradient(
        circle,
        var(--pin-color, rgba(168,85,247,0.75)) 0%,
        transparent 70%
      );
      opacity: 0.55;
      will-change: transform, opacity;
    }
    @keyframes halopulse {
      0%   { transform: scale(0.8); opacity: 0.75; }
      70%  { transform: scale(1.15); opacity: 0; }
      100% { transform: scale(0.8); opacity: 0.75; }
    }
    .neon-pin svg {
      position: relative;
      display: block;
      z-index: 1;
    }
    /* Pin "réel" (signalement actif) : seul lui pulse + ring blanc statique */
    .neon-pin.real svg {
      filter: drop-shadow(0 0 1px #fff);
    }
    .neon-pin.real .halo {
      animation: halopulse 1.6s ease-out infinite;
      opacity: 1;
    }

    .user-dot {
      width: 14px; height: 14px;
      background: #C77DFF;
      border: 3px solid #F5F0FF;
      border-radius: 50%;
      box-shadow:
        0 0 0 2px rgba(168,85,247,0.4),
        0 0 12px rgba(199,125,255,0.8);
    }

    /* Clusters : neon halo rose */
    .marker-cluster-small {
      background-color: rgba(244, 114, 182, 0.22);
    }
    .marker-cluster-small div {
      background-color: #F472B6;
      color: #0A0414;
      font-weight: 700;
      border: 2px solid #F5F0FF;
      box-shadow: 0 0 12px rgba(244,114,182,0.7);
    }
    .marker-cluster-medium,
    .marker-cluster-large {
      background-color: rgba(168, 85, 247, 0.22);
    }
    .marker-cluster-medium div,
    .marker-cluster-large div {
      background-color: #A855F7;
      color: #F5F0FF;
      font-weight: 700;
      font-size: 11px;
      border: 2px solid #F5F0FF;
      box-shadow: 0 0 14px rgba(168,85,247,0.85);
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    // Defaut : centre France (sera ajuste par centerOnUser ou setReports)
    const map = L.map('map', {
      zoomControl: false,
      attributionControl: true,
    }).setView([46.6, 2.4], 6);

    // Tile layer dark (CartoDB DarkMatter NoLabels) — couplé au filter CSS
    // hue-rotate pour donner la teinte violet/neon de la spec.
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png', {
      maxZoom: 19,
      attribution: '&copy; CartoDB &copy; OSM',
      subdomains: 'abcd',
      referrerPolicy: 'origin',
    }).addTo(map);

    // Trace REEL du Peripherique Exterieur de Toulouse (A 620) — geometrie
    // extraite d'OpenStreetMap via Overpass API, 205 ways / ~1450 points.
    // Pane dedie zIndex 425 pour rendre AU-DESSUS du tile-pane.
    map.createPane('peripherique');
    map.getPane('peripherique').style.zIndex = 425;
    map.getPane('peripherique').style.pointerEvents = 'none';
    const TOULOUSE_PERIPH_WAYS = $kToulousePeripheriqueWaysJson;
    TOULOUSE_PERIPH_WAYS.forEach(way => {
      // Halo tres discret
      L.polyline(way, {
        pane: 'peripherique',
        color: '#CA8A04',
        weight: 7,
        opacity: 0.08,
        lineCap: 'round',
        lineJoin: 'round',
      }).addTo(map);
      // Ligne fine ambree sombre par-dessus
      L.polyline(way, {
        pane: 'peripherique',
        color: '#CA8A04',
        weight: 1.6,
        opacity: 0.5,
        lineCap: 'round',
        lineJoin: 'round',
      }).addTo(map);
    });

    // Cluster group : groupe les pins proches en cercles avec compteur.
    // maxClusterRadius=40 = pins a < 40px sont groupes.
    // spiderfyOnMaxZoom=true = au max zoom, eclate les pins en spirale.
    const clusterGroup = L.markerClusterGroup({
      maxClusterRadius: 40,
      spiderfyOnMaxZoom: true,
      showCoverageOnHover: false,
      zoomToBoundsOnClick: true,
    });
    map.addLayer(clusterGroup);

    let userMarker = null;

    let centeredOnCity = false;

    // Mapping categorie -> famille visuelle. 5 familles max pour rester lisible.
    const FAMILY_BY_CATEGORY = {
      concert: 'nightlife', soiree: 'nightlife', festival: 'nightlife',
      food: 'food', marche: 'food',
      salon: 'culture', exposition: 'culture',
      sport: 'sport',
      fete: 'general',
    };

    // Layer dédié aux markers fictifs de la home (pas de clustering).
    let presentationLayer = L.layerGroup().addTo(map);

    function setPresentationReports(reports) {
      console.log('[map] setPresentationReports', reports.length);
      presentationLayer.clearLayers();
      reports.forEach(r => {
        const family = FAMILY_BY_CATEGORY[r.category] || 'general';
        const fill = FAMILY_COLOR_PRES[family] || '#A855F7';
        const realCls = r.is_real ? ' real' : '';
        const html = '<div class="neon-pin' + realCls + '" title="' + r.title + '" style="--pin-color:' + fill + '99">'
          + '<div class="halo"></div>'
          + '<svg width="24" height="26" viewBox="0 0 24 26" xmlns="http://www.w3.org/2000/svg">'
          + '<path d="M12 0 C18.6 0 24 5.4 24 12 C24 18.6 12 26 12 26 C12 26 0 18.6 0 12 C0 5.4 5.4 0 12 0 Z" fill="' + fill + '"/>'
          + '<circle cx="12" cy="10" r="3" fill="#0A0414"/>'
          + '</svg>'
          + '</div>';
        const marker = L.marker([r.lat, r.lng], {
          icon: L.divIcon({
            className: '',
            html: html,
            iconSize: [24, 26],
            iconAnchor: [12, 26],
          }),
        });
        marker.addTo(presentationLayer);
      });
    }

    const FAMILY_COLOR_PRES = {
      nightlife: '#F472B6',
      food:      '#FBBF24',
      culture:   '#C77DFF',
      sport:     '#22D3EE',
      general:   '#A855F7',
    };

    function setReports(reports) {
      clusterGroup.clearLayers();
      const FAMILY_COLOR = {
        nightlife: '#F472B6',
        food:      '#FBBF24',
        culture:   '#C77DFF',
        sport:     '#22D3EE',
        general:   '#A855F7',
      };
      reports.forEach(r => {
        const family = FAMILY_BY_CATEGORY[r.category] || 'general';
        const fill = FAMILY_COLOR[family] || '#A855F7';
        // Goutte SVG 24x26 + cœur sombre + halo radial pulsant.
        const html = '<div class="neon-pin" title="' + r.title + '" style="--pin-color:' + fill + '99">'
          + '<div class="halo"></div>'
          + '<svg width="24" height="26" viewBox="0 0 24 26" xmlns="http://www.w3.org/2000/svg">'
          + '<path d="M12 0 C18.6 0 24 5.4 24 12 C24 18.6 12 26 12 26 C12 26 0 18.6 0 12 C0 5.4 5.4 0 12 0 Z" fill="' + fill + '"/>'
          + '<circle cx="12" cy="10" r="3" fill="#0A0414"/>'
          + '</svg>'
          + '</div>';
        const marker = L.marker([r.lat, r.lng], {
          icon: L.divIcon({
            className: '',
            html: html,
            iconSize: [24, 26],
            iconAnchor: [12, 26],
          }),
        });
        marker.on('click', function() {
          FlutterReportTap.postMessage(r.id);
        });
        clusterGroup.addLayer(marker);
      });
    }

    /// Recentre la map sur le centre d'une ville.
    /// Appelle au load et a chaque changement de ville selectionnee.
    function centerOnCity(lat, lng) {
      centeredOnCity = true;
      // Zoom 12 = ~niveau metropole, ideal pour voir Toulouse + banlieue
      map.setView([lat, lng], 12);
    }

    /// Affiche le pin "Ma position" sans recentrer la map.
    function showUserPin(lat, lng) {
      if (userMarker) {
        userMarker.setLatLng([lat, lng]);
      } else {
        userMarker = L.marker([lat, lng], {
          icon: L.divIcon({
            className: '',
            html: '<div class="user-dot"></div>',
            iconSize: [14, 14],
            iconAnchor: [7, 7],
          }),
          zIndexOffset: 1000,
        }).addTo(map);
      }
      // Si la map n'a pas encore ete recentree par une ville (cas edge),
      // on centre sur le user
      if (!centeredOnCity) {
        map.setView([lat, lng], 12);
      }
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _loadHtml() async {
    await _controller.loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);

    // Recentre la map a chaque changement de ville
    if (_lastCity != city) {
      _lastCity = city;
      if (_pageReady) {
        _centerOnCity(city);
        if (widget.usePresentationMarkers) {
          _injectPresentationMarkersForCurrentCity();
        }
      }
    }

    // Abonnement realtime : actif aussi en mode présentation pour que les
    // vrais signalements apparaissent dynamiquement par-dessus les fakes.
    ref.watch(reportedEventsRealtimeProvider);
    final eventsAsync = ref.watch(reportedEventsFeedProvider);
    eventsAsync.whenData((events) {
      if (!listEquals(
        _lastEvents.map((e) => e.id).toList(),
        events.map((e) => e.id).toList(),
      )) {
        _lastEvents = events;
        if (widget.usePresentationMarkers) {
          _injectPresentationMarkersForCurrentCity();
        } else {
          _injectMarkers(events);
        }
      }
    });

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF04020A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x33A855F7),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33A855F7),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
            // Vignette radiale (assombrit les bords pour cohérence neon)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Color(0xCC04020A),
                    ],
                    stops: [0.65, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC77DFF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
