import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mini-carte Leaflet (WebView) avec un seul pin draggable.
///
/// Utilisee dans la modal de signalement Waze-style. Le pin est positionne
/// initialement sur [initialLat]/[initialLng] (coordonnees GPS) et peut etre
/// drag par l'utilisateur. A chaque drag, [onPinMoved] est appele.
class DraggablePinMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onPinMoved;
  final double height;

  const DraggablePinMap({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onPinMoved,
    this.height = 180,
  });

  @override
  State<DraggablePinMap> createState() => _DraggablePinMapState();
}

class _DraggablePinMapState extends State<DraggablePinMap> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F0FA))
      ..setUserAgent('PulzApp/1.0 (https://pulzapp.fr)')
      ..addJavaScriptChannel(
        'FlutterPin',
        onMessageReceived: (msg) {
          // Format: "lat,lng"
          final parts = msg.message.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) widget.onPinMoved(lat, lng);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );
    _controller.loadHtmlString(_buildHtml());
  }

  @override
  void didUpdateWidget(covariant DraggablePinMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si les coords initiales changent (ex: la GPS finit par arriver),
    // on recentre le pin
    if ((oldWidget.initialLat - widget.initialLat).abs() > 0.0001 ||
        (oldWidget.initialLng - widget.initialLng).abs() > 0.0001) {
      _controller.runJavaScript(
        'setPin(${widget.initialLat}, ${widget.initialLng})',
      );
    }
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { height: 100%; overflow: hidden; background: #F8F0FA; }
    #map { width: 100vw; height: 100vh; }
    .leaflet-control-attribution { font-size: 8px; }

    .drag-pin {
      width: 32px; height: 32px;
      position: relative;
    }
    .drag-pin::after {
      content: '';
      position: absolute;
      left: 50%;
      top: 0;
      transform: translateX(-50%);
      width: 28px;
      height: 28px;
      background: #DC2626;
      border: 3px solid white;
      border-radius: 50% 50% 50% 0;
      transform: translateX(-50%) rotate(-45deg);
      transform-origin: center;
      box-shadow: 0 4px 10px rgba(0,0,0,0.35);
    }
    .drag-pin::before {
      content: '📍';
      position: absolute;
      left: 50%;
      top: -2px;
      transform: translateX(-50%);
      font-size: 26px;
      filter: drop-shadow(0 3px 6px rgba(0,0,0,0.5));
      z-index: 10;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    let initLat = ${widget.initialLat};
    let initLng = ${widget.initialLng};

    const map = L.map('map', {
      zoomControl: true,
      attributionControl: true,
    }).setView([initLat, initLng], 16);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OSM',
      referrerPolicy: 'origin',
    }).addTo(map);

    const pinIcon = L.divIcon({
      className: '',
      html: '<div class="drag-pin"></div>',
      iconSize: [32, 32],
      iconAnchor: [16, 32],
    });

    const pin = L.marker([initLat, initLng], {
      icon: pinIcon,
      draggable: true,
      autoPan: true,
    }).addTo(map);

    pin.on('dragend', function(e) {
      const ll = pin.getLatLng();
      FlutterPin.postMessage(ll.lat + ',' + ll.lng);
    });

    // Permet aussi de tap sur la carte pour deplacer le pin
    map.on('click', function(e) {
      pin.setLatLng(e.latlng);
      FlutterPin.postMessage(e.latlng.lat + ',' + e.latlng.lng);
    });

    function setPin(lat, lng) {
      pin.setLatLng([lat, lng]);
      map.setView([lat, lng], 16);
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
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
