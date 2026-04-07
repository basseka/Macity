import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeteMusiqueMapView extends StatefulWidget {
  final String ville;

  const FeteMusiqueMapView({super.key, this.ville = 'Toulouse'});

  @override
  State<FeteMusiqueMapView> createState() => _FeteMusiqueMapViewState();

  /// Coordonnees par ville pour centrer la carte.
  static const cityCoords = <String, List<double>>{
    'toulouse': [43.6047, 1.4442],
    'paris': [48.8566, 2.3522],
    'lyon': [45.7640, 4.8357],
    'marseille': [43.2965, 5.3698],
    'bordeaux': [44.8378, -0.5792],
    'nice': [43.7102, 7.2620],
    'nantes': [47.2184, -1.5536],
    'montpellier': [43.6108, 3.8767],
    'strasbourg': [48.5734, 7.7521],
    'lille': [50.6292, 3.0573],
    'rennes': [48.1173, -1.6778],
    'grenoble': [45.1885, 5.7245],
    'carcassonne': [43.2130, 2.3491],
    'avignon': [43.9493, 4.8055],
    'annecy': [45.8992, 6.1294],
    'colmar': [48.0794, 7.3558],
    'bayonne': [43.4929, -1.4748],
    'reims': [49.2583, 3.7500],
    'dijon': [47.3220, 5.0415],
    'rouen': [49.4432, 1.0999],
    'metz': [49.1193, 6.1757],
    'nancy': [48.6921, 6.1844],
    'amiens': [49.8941, 2.2958],
    'besancon': [47.2378, 6.0241],
    'toulon': [43.1242, 5.9280],
    'nimes': [43.8367, 4.3601],
    'clermont-ferrand': [45.7772, 3.0870],
    'saint-etienne': [45.4397, 4.3872],
    'aix-en-provence': [43.5297, 5.4474],
    'angers': [47.4712, -0.5518],
    'le havre': [49.4944, 0.1079],
    'le mans': [48.0061, 0.1996],
    'brest': [48.3904, -4.4861],
    'blois': [47.5861, 1.3359],
    'chartres': [48.4439, 1.4894],
  };
}

class _FeteMusiqueMapViewState extends State<FeteMusiqueMapView> {
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
            if (_pendingPosition != null) {
              _injectPosition(_pendingPosition!);
              _pendingPosition = null;
            }
          },
        ),
      );
    _loadHtml();
  }

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

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        if (_pageReady) {
          _injectPosition(lastKnown);
        } else {
          _pendingPosition = lastKnown;
        }
      }

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

  Future<void> _handleLocationRequest() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _controller.runJavaScript("onLocationError('GPS desactive')");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _controller.runJavaScript("onLocationError('Permission refusee')");
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) _injectPosition(lastKnown);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _injectPosition(position);
    } catch (e) {
      _controller.runJavaScript("onLocationError('Erreur')");
    }
  }

  Future<void> _loadHtml() async {
    var html = await rootBundle.loadString('web/fete-musique/index.html');
    // Remplacer le centre de la carte et le titre par la ville selectionnee
    final ville = widget.ville;
    final coords = FeteMusiqueMapView.cityCoords[ville.toLowerCase()] ?? [43.6047, 1.4442];
    html = html.replaceAll('[43.6047, 1.4442]', '[${coords[0]}, ${coords[1]}]');
    html = html.replaceAll('Toulouse', ville);
    await _controller.loadHtmlString(html);
  }

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
