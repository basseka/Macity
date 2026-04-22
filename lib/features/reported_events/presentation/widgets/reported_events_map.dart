import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
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

  const ReportedEventsMap({super.key, this.height = 180});

  @override
  ConsumerState<ReportedEventsMap> createState() => _ReportedEventsMapState();
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setUserAgent('PulzApp/1.0 (https://pulzapp.fr)')
      ..addJavaScriptChannel(
        'FlutterReportTap',
        onMessageReceived: (msg) => _handleMarkerTap(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _pageReady = true;
            // Centre sur la ville selectionnee (priorite #1)
            if (_lastCity != null) _centerOnCity(_lastCity!);
            // Affiche le pin user en parallele si GPS dispo
            _autoLocateUserPin();
            // Re-injecter les markers maintenant que la page est prete
            if (_lastEvents.isNotEmpty) _injectMarkers(_lastEvents);
          },
        ),
      );
    _loadHtml();
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

  /// Affiche un pin "Ma position" si la GPS est dispo, sans recentrer.
  Future<void> _autoLocateUserPin() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _pageReady) {
        await _controller.runJavaScript(
          'showUserPin(${last.latitude}, ${last.longitude})',
        );
      }
    } catch (_) {}
  }

  void _handleMarkerTap(String id) {
    final idx = _lastEvents.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportedEventsPagedSheet(
        events: _lastEvents,
        initialIndex: idx,
      ),
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
    html, body { height: 100%; overflow: hidden; background: #F8F0FA; }
    #map { width: 100vw; height: 100vh; }
    .leaflet-control-attribution { font-size: 8px; }

    /* Pins par famille. Meme base visuelle (18px, bordure blanche, pulse 1.6s).
       Une couleur par famille, 5 familles max pour rester lisible. */
    .fam-pulse {
      width: 18px; height: 18px;
      border-radius: 50%;
      border: 2.5px solid white;
      cursor: pointer;
      animation: fampulse 1.6s ease-out infinite;
    }
    @keyframes fampulse {
      0%   { box-shadow: 0 0 0 0 var(--pulse-color), 0 2px 6px rgba(0,0,0,0.3); }
      70%  { box-shadow: 0 0 0 14px transparent, 0 2px 6px rgba(0,0,0,0.3); }
      100% { box-shadow: 0 0 0 0 transparent, 0 2px 6px rgba(0,0,0,0.3); }
    }
    /* Violet - Vie nocturne (concert, soiree, festival) */
    .fam-nightlife { background: #A855F7; --pulse-color: rgba(168,85,247,0.7); }
    /* Orange - Food (food, marche) */
    .fam-food      { background: #FB923C; --pulse-color: rgba(251,146,60,0.7); }
    /* Cyan - Culture (salon, exposition) */
    .fam-culture   { background: #22D3EE; --pulse-color: rgba(34,211,238,0.7); }
    /* Vert - Sport */
    .fam-sport     { background: #22C55E; --pulse-color: rgba(34,197,94,0.7); }
    /* Rouge - General (fete + fallback) */
    .fam-general   { background: #EF4444; --pulse-color: rgba(239,68,68,0.7); }

    .user-dot {
      width: 14px; height: 14px;
      background: #22D3EE;
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 0 0 2px rgba(34,211,238,0.35), 0 2px 6px rgba(0,0,0,0.3);
    }

    /* Clusters : magenta pour petit, violet pour grand (theme brand) */
    .marker-cluster-small {
      background-color: rgba(255, 61, 139, 0.22);
    }
    .marker-cluster-small div {
      background-color: #FF3D8B;
    }
    .marker-cluster-medium,
    .marker-cluster-large {
      background-color: rgba(168, 85, 247, 0.22);
    }
    .marker-cluster-medium div,
    .marker-cluster-large div {
      background-color: #A855F7;
      color: white;
      font-weight: 700;
      font-size: 11px;
      border: 2px solid white;
      box-shadow: 0 2px 6px rgba(0,0,0,0.4);
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

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OSM',
      referrerPolicy: 'origin',
    }).addTo(map);

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

    function setReports(reports) {
      clusterGroup.clearLayers();
      reports.forEach(r => {
        const family = FAMILY_BY_CATEGORY[r.category] || 'general';
        const cls = 'fam-pulse fam-' + family;
        const size = 18;
        const anchor = size / 2;
        const marker = L.marker([r.lat, r.lng], {
          icon: L.divIcon({
            className: '',
            html: '<div class="' + cls + '" title="' + r.title + '"></div>',
            iconSize: [size, size],
            iconAnchor: [anchor, anchor],
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
    // Active l'abonnement Realtime tant que la carte est montee.
    // Chaque INSERT/UPDATE invalide automatiquement le feed provider.
    ref.watch(reportedEventsRealtimeProvider);

    final eventsAsync = ref.watch(reportedEventsFeedProvider);
    final city = ref.watch(selectedCityProvider);

    // Recentre la map a chaque changement de ville
    if (_lastCity != city) {
      _lastCity = city;
      if (_pageReady) _centerOnCity(city);
    }

    // Re-injecter les markers quand les donnees changent
    eventsAsync.whenData((events) {
      if (!listEquals(
        _lastEvents.map((e) => e.id).toList(),
        events.map((e) => e.id).toList(),
      )) {
        _lastEvents = events;
        _injectMarkers(events);
      }
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          border: Border.all(color: AppColors.line),
        ),
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
            if (_isLoading)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.magenta,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
