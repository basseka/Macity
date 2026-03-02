import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VenuesMapView extends StatefulWidget {
  final List<CommerceModel> venues;
  final String title;
  final String accentColor;

  const VenuesMapView({
    super.key,
    required this.venues,
    this.title = 'Le plus proche',
    this.accentColor = '#228B22',
  });

  @override
  State<VenuesMapView> createState() => _VenuesMapViewState();
}

class _VenuesMapViewState extends State<VenuesMapView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _pageReady = false;
  Position? _pendingPosition;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterLocation',
        onMessageReceived: (_) => _handleLocationRequest(),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _pageReady = true;
            // Si la position a été obtenue avant que la page soit prête
            if (_pendingPosition != null) {
              _injectPosition(_pendingPosition!);
              _pendingPosition = null;
            }
          },
        ),
      );
    _loadHtml();
    // Lancer la géolocalisation immédiatement en parallèle
    _autoLocate();
  }

  /// Géolocalisation automatique dès l'ouverture
  Future<void> _autoLocate() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      // Position cache instantanée
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        if (_pageReady) {
          _injectPosition(lastKnown);
        } else {
          _pendingPosition = lastKnown;
        }
      }

      // Position précise en arrière-plan
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (_pageReady) {
        _injectPosition(position);
      } else {
        _pendingPosition = position;
      }
    } catch (_) {}
  }

  void _injectPosition(Position pos) {
    _controller.runJavaScript(
      'onLocationSuccess(${pos.latitude}, ${pos.longitude})',
    );
  }

  /// Géolocalisation manuelle (bouton)
  Future<void> _handleLocationRequest() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _controller.runJavaScript(
          "onLocationError('Active la localisation dans les parametres')",
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _controller.runJavaScript(
          "onLocationError('Autorise la localisation dans les parametres de l appli')",
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _controller.runJavaScript("onLocationError('Permission refusee')");
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _injectPosition(lastKnown);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _injectPosition(position);
    } catch (e) {
      _controller.runJavaScript(
        "onLocationError('Impossible d obtenir la position: ${e.toString().replaceAll("'", "")}')",
      );
    }
  }

  String _escapeJs(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n');

  Future<void> _loadHtml() async {
    final venuesJs = widget.venues.map((v) {
      return "{ nom: '${_escapeJs(v.nom)}', cat: '${_escapeJs(v.categorie)}', "
          "adresse: '${_escapeJs(v.adresse)}', "
          "lat: ${v.latitude}, lng: ${v.longitude}, "
          "site: '${_escapeJs(v.siteWeb)}' }";
    }).join(',\n      ');

    final cats = <String>{};
    for (final v in widget.venues) {
      cats.add(v.categorie);
    }
    final legendHtml = cats.map((c) {
      return '<div class="legend-item">'
          '<span class="legend-dot" style="background:${widget.accentColor}"></span>'
          '${_escapeHtml(c)}</div>';
    }).join('\n');

    final accent = widget.accentColor;
    final title = _escapeHtml(widget.title);

    final html = '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; height: 100vh; overflow: hidden; }
    #map { flex: 1; }
    .locate-btn { position: absolute; bottom: 90px; right: 12px; z-index: 1000; width: 44px; height: 44px; border-radius: 50%; border: none; background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.25); cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 22px; }
    .locate-btn:active { opacity: 0.7; }
    .locate-btn.locating { animation: pulse 1s infinite; }
    @keyframes pulse { 0%, 100% { box-shadow: 0 2px 8px rgba(0,0,0,0.25); } 50% { box-shadow: 0 2px 16px ${accent}80; } }
    .info-panel { position: absolute; bottom: 0; left: 0; right: 0; z-index: 1000; background: white; border-radius: 16px 16px 0 0; box-shadow: 0 -2px 12px rgba(0,0,0,0.15); padding: 12px 16px; transform: translateY(100%); transition: transform 0.3s ease; }
    .info-panel.visible { transform: translateY(0); }
    .info-panel-title { font-size: 0.7rem; color: $accent; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
    .info-panel-name { font-size: 1rem; font-weight: 700; color: #1f2937; }
    .info-panel-detail { font-size: 0.8rem; color: #6b7280; margin-top: 2px; }
    .info-panel-distance { font-size: 0.85rem; font-weight: 600; color: $accent; margin-top: 4px; }
    .info-panel-actions { display: flex; gap: 8px; margin-top: 8px; }
    .info-panel-btn { flex: 1; padding: 8px; border: none; border-radius: 10px; font-size: 0.8rem; font-weight: 600; cursor: pointer; text-align: center; text-decoration: none; display: block; }
    .info-panel-btn.primary { background: $accent; color: white; }
    .info-panel-btn.secondary { background: #f3f4f6; color: #374151; }
    .legend-wrapper { background: white; border-top: 1px solid #e5e7eb; flex-shrink: 0; padding: 6px 12px 8px; }
    .legend { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; }
    .legend-item { display: flex; align-items: center; gap: 4px; font-size: 0.7rem; color: #374151; }
    .legend-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
    .marker-icon { width: 28px; height: 28px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.35); display: flex; align-items: center; justify-content: center; font-size: 14px; line-height: 1; }
    .user-marker { width: 18px; height: 18px; border-radius: 50%; background: #4285F4; border: 3px solid white; box-shadow: 0 0 0 2px rgba(66,133,244,0.3), 0 2px 6px rgba(0,0,0,0.3); }
    .leaflet-popup-content { margin: 10px 14px; line-height: 1.5; }
    .popup-name { font-weight: 700; font-size: 0.95rem; margin-bottom: 2px; }
    .popup-cat { font-size: 0.8rem; color: $accent; font-weight: 500; }
    .popup-address { font-size: 0.8rem; color: #6b7280; margin-top: 2px; }
    .popup-link { display: inline-block; margin-top: 6px; font-size: 0.8rem; color: $accent; text-decoration: none; font-weight: 600; }
  </style>
</head>
<body>
  <div id="map"></div>
  <button class="locate-btn" id="locateBtn" onclick="locateMe()">&#128205;</button>
  <div class="info-panel" id="infoPanel">
    <div class="info-panel-title">$title</div>
    <div class="info-panel-name" id="closestName"></div>
    <div class="info-panel-detail" id="closestAddress"></div>
    <div class="info-panel-distance" id="closestDistance"></div>
    <div class="info-panel-actions">
      <a class="info-panel-btn primary" id="closestItinerary" href="#" target="_blank">Itineraire</a>
      <a class="info-panel-btn secondary" id="closestWebsite" href="#" target="_blank">Site web</a>
    </div>
  </div>
  <div class="legend-wrapper">
    <div class="legend">
      $legendHtml
      <div class="legend-item"><span class="legend-dot" style="background:#4285F4"></span>Ma position</div>
    </div>
  </div>
  <script>
    const VENUES = [$venuesJs];
    const ACCENT = '$accent';
    const map = L.map('map').setView([43.6047, 1.4442], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap', maxZoom: 19,
    }).addTo(map);

    const allMarkers = [];
    VENUES.forEach(v => {
      if (!v.lat || !v.lng) return;
      const marker = L.marker([v.lat, v.lng], {
        icon: L.divIcon({
          className: '',
          html: '<div class="marker-icon" style="background:' + ACCENT + '"></div>',
          iconSize: [28, 28], iconAnchor: [14, 14], popupAnchor: [0, -16],
        }),
      }).addTo(map);
      let popup = '<div class="popup-name">' + v.nom + '</div><div class="popup-cat">' + v.cat + '</div><div class="popup-address">' + v.adresse + '</div>';
      if (v.site) popup += '<a class="popup-link" href="' + v.site + '" target="_blank">Site web &rarr;</a>';
      marker.bindPopup(popup);
      allMarkers.push({ ...v, marker });
    });

    const validVenues = VENUES.filter(v => v.lat && v.lng);
    if (validVenues.length > 0) {
      map.fitBounds(L.latLngBounds(validVenues.map(v => [v.lat, v.lng])), { padding: [30, 30] });
    }

    let userMarker = null, userLat = null, userLng = null;

    // Demande la position a Flutter (bouton manuel)
    function locateMe() {
      document.getElementById('locateBtn').classList.add('locating');
      FlutterLocation.postMessage('getLocation');
    }

    // Callback succes depuis Flutter
    function onLocationSuccess(lat, lng) {
      document.getElementById('locateBtn').classList.remove('locating');
      userLat = lat; userLng = lng;
      if (userMarker) { userMarker.setLatLng([userLat, userLng]); }
      else {
        userMarker = L.marker([userLat, userLng], {
          icon: L.divIcon({ className: '', html: '<div class="user-marker"></div>', iconSize: [18, 18], iconAnchor: [9, 9] }),
          zIndexOffset: 1000,
        }).addTo(map);
        userMarker.bindPopup('<b>Ma position</b>');
      }
      findClosest();
      const c = getClosest();
      if (c) { map.fitBounds(L.latLngBounds([[userLat, userLng], [c.lat, c.lng]]), { padding: [60, 60] }); }
      else { map.setView([userLat, userLng], 12); }
    }

    // Callback erreur depuis Flutter
    function onLocationError(msg) {
      document.getElementById('locateBtn').classList.remove('locating');
      alert(msg);
    }

    function haversineKm(a1, o1, a2, o2) {
      const R = 6371, dA = (a2-a1)*Math.PI/180, dO = (o2-o1)*Math.PI/180;
      const a = Math.sin(dA/2)**2 + Math.cos(a1*Math.PI/180)*Math.cos(a2*Math.PI/180)*Math.sin(dO/2)**2;
      return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    }

    function getClosest() {
      if (!userLat) return null;
      let best = null, min = Infinity;
      validVenues.forEach(v => { const d = haversineKm(userLat, userLng, v.lat, v.lng); if (d < min) { min = d; best = { ...v, distance: d }; } });
      return best;
    }

    function findClosest() {
      const c = getClosest(); if (!c) return;
      document.getElementById('closestName').textContent = c.nom;
      document.getElementById('closestAddress').textContent = c.adresse;
      const dt = c.distance < 1 ? Math.round(c.distance*1000) + ' m' : c.distance.toFixed(1) + ' km';
      document.getElementById('closestDistance').textContent = 'a ' + dt + ' de vous';
      document.getElementById('closestItinerary').href = 'https://www.google.com/maps/dir/' + userLat + ',' + userLng + '/' + c.lat + ',' + c.lng;
      const sb = document.getElementById('closestWebsite');
      if (c.site) { sb.href = c.site; sb.style.display = 'block'; } else { sb.style.display = 'none'; }
      document.getElementById('infoPanel').classList.add('visible');
      allMarkers.forEach(m => { if (m.nom === c.nom) m.marker.openPopup(); });
      if (window._line) map.removeLayer(window._line);
      window._line = L.polyline([[userLat, userLng], [c.lat, c.lng]], { color: ACCENT, weight: 2, dashArray: '8, 8', opacity: 0.6 }).addTo(map);
    }
  </script>
</body>
</html>
''';
    await _controller.loadHtmlString(html);
  }

  String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
