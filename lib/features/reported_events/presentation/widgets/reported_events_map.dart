import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/reported_event_detail_sheet.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

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
      ..setBackgroundColor(const Color(0xFFF8F0FA))
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
    final event = _lastEvents.where((e) => e.id == id).firstOrNull;
    if (event == null) return;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportedEventDetailSheet(event: event),
    );
  }

  Future<void> _injectMarkers(List<ReportedEvent> events) async {
    if (!_pageReady) return;
    final js = events.map((e) {
      final emoji = (e.generated?.emoji ?? '📍').replaceAll("'", "\\'");
      final title = (e.generated?.title ?? e.rawTitle).replaceAll("'", "\\'");
      final photoCount = e.photos.length;
      final reportCount = e.reportCount;
      return "{id:'${e.id}',lat:${e.lat},lng:${e.lng},emoji:'$emoji',title:'$title',photos:$photoCount,reports:$reportCount}";
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

    .orange-pulse {
      width: 16px; height: 16px;
      background: #F97316;
      border-radius: 50%;
      border: 2.5px solid white;
      box-shadow: 0 0 0 0 rgba(249,115,22,0.7), 0 2px 6px rgba(0,0,0,0.3);
      animation: orangepulse 1.8s ease-out infinite;
      cursor: pointer;
    }
    @keyframes orangepulse {
      0%   { box-shadow: 0 0 0 0 rgba(249,115,22,0.7), 0 2px 6px rgba(0,0,0,0.3); }
      70%  { box-shadow: 0 0 0 14px rgba(249,115,22,0), 0 2px 6px rgba(0,0,0,0.3); }
      100% { box-shadow: 0 0 0 0 rgba(249,115,22,0), 0 2px 6px rgba(0,0,0,0.3); }
    }

    .red-pulse {
      width: 18px; height: 18px;
      background: #DC2626;
      border-radius: 50%;
      border: 2.5px solid white;
      box-shadow: 0 0 0 0 rgba(220,38,38,0.6), 0 2px 6px rgba(0,0,0,0.3);
      animation: redpulse 1.5s ease-out infinite;
      cursor: pointer;
    }
    @keyframes redpulse {
      0%   { box-shadow: 0 0 0 0 rgba(220,38,38,0.6), 0 2px 6px rgba(0,0,0,0.3); }
      70%  { box-shadow: 0 0 0 12px rgba(220,38,38,0), 0 2px 6px rgba(0,0,0,0.3); }
      100% { box-shadow: 0 0 0 0 rgba(220,38,38,0), 0 2px 6px rgba(0,0,0,0.3); }
    }

    .hotspot-pulse {
      width: 22px; height: 22px;
      background: linear-gradient(135deg, #7B2D8E, #DC2626);
      border-radius: 50%;
      border: 3px solid white;
      box-shadow: 0 0 0 0 rgba(123, 45, 142, 0.8), 0 2px 8px rgba(0,0,0,0.4);
      animation: hotpulse 1.2s ease-out infinite;
      cursor: pointer;
    }
    @keyframes hotpulse {
      0%   { box-shadow: 0 0 0 0 rgba(123,45,142,0.8), 0 2px 8px rgba(0,0,0,0.4); transform: scale(1); }
      50%  { box-shadow: 0 0 0 18px rgba(220,38,38,0), 0 2px 8px rgba(0,0,0,0.4); transform: scale(1.15); }
      100% { box-shadow: 0 0 0 0 rgba(123,45,142,0), 0 2px 8px rgba(0,0,0,0.4); transform: scale(1); }
    }

    .user-dot {
      width: 14px; height: 14px;
      background: #4285F4;
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 0 0 2px rgba(66,133,244,0.3), 0 2px 6px rgba(0,0,0,0.25);
    }

    /* Override des clusters pour matcher le theme orange/rouge "signalement" */
    .marker-cluster-small {
      background-color: rgba(249, 115, 22, 0.25);
    }
    .marker-cluster-small div {
      background-color: #F97316;
    }
    .marker-cluster-medium,
    .marker-cluster-large {
      background-color: rgba(220, 38, 38, 0.25);
    }
    .marker-cluster-medium div,
    .marker-cluster-large div {
      background-color: #DC2626;
      color: white;
      font-weight: 700;
      font-size: 11px;
      border: 2px solid white;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
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

    function setReports(reports) {
      clusterGroup.clearLayers();
      // Score max pour identifier le #1
      let maxScore = 0;
      reports.forEach(r => {
        const s = (r.photos || 0) + (r.reports || 0);
        if (s > maxScore) maxScore = s;
      });

      reports.forEach(r => {
        const score = (r.photos || 0) + (r.reports || 0);
        // 3 tiers : hot (top score >= 4), warm (2+ reports ou 2+ photos), normal
        let cls, size, zOff;
        if (score >= 4 && score === maxScore) {
          cls = 'hotspot-pulse'; size = 22; zOff = 500;
        } else if ((r.reports || 0) >= 2 || (r.photos || 0) >= 2) {
          cls = 'red-pulse'; size = 18; zOff = 200;
        } else {
          cls = 'orange-pulse'; size = 16; zOff = 0;
        }
        const anchor = size / 2;
        const marker = L.marker([r.lat, r.lng], {
          icon: L.divIcon({
            className: '',
            html: '<div class="' + cls + '" title="' + r.title + '"></div>',
            iconSize: [size, size],
            iconAnchor: [anchor, anchor],
          }),
          zIndexOffset: zOff,
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
