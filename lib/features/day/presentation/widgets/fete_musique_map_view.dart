import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeteMusiqueMapView extends StatefulWidget {
  const FeteMusiqueMapView({super.key});

  @override
  State<FeteMusiqueMapView> createState() => _FeteMusiqueMapViewState();
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
    final html = await rootBundle.loadString('web/fete-musique/index.html');
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
