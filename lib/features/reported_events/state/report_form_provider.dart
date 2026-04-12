import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Etat du formulaire de signalement (modal Waze-style).
@immutable
class ReportFormState {
  final double? lat;
  final double? lng;
  final String category;
  final String rawTitle;
  final String locationName;
  final String? localPhotoPath;
  final String? localVideoPath;
  final bool isLocating;
  final bool isSubmitting;
  final String? error;

  const ReportFormState({
    this.lat,
    this.lng,
    this.category = '',
    this.rawTitle = '',
    this.locationName = '',
    this.localPhotoPath,
    this.localVideoPath,
    this.isLocating = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get canSubmit =>
      category.isNotEmpty && !isSubmitting;

  ReportFormState copyWith({
    double? lat,
    double? lng,
    String? category,
    String? rawTitle,
    String? locationName,
    String? localPhotoPath,
    String? localVideoPath,
    bool? isLocating,
    bool? isSubmitting,
    String? error,
    bool clearPhoto = false,
    bool clearError = false,
  }) {
    return ReportFormState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      rawTitle: rawTitle ?? this.rawTitle,
      locationName: locationName ?? this.locationName,
      localPhotoPath: clearPhoto ? null : (localPhotoPath ?? this.localPhotoPath),
      localVideoPath: localVideoPath ?? this.localVideoPath,
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier(this._svc) : super(const ReportFormState());

  final ReportedEventsService _svc;

  /// Recupere la position GPS courante (auto-locate au open de la modal).
  ///
  /// Strategie : on prend ABSOLUMENT la position HAUTE precision avant de
  /// debloquer le bouton Signaler. C'est crucial pour un signalement Waze :
  /// si on accepte une position approximative (lastKnown du cache OS ou
  /// medium accuracy), le marqueur sur la carte sera a 100m-1km de la
  /// realite et l'experience est cassee.
  ///
  /// On utilise lastKnown UNIQUEMENT en fallback si la high precision
  /// echoue completement (ex: indoor sans signal).
  Future<void> initLocation() async {
    state = state.copyWith(isLocating: true, clearError: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLocating: false,
          error: 'Active la localisation dans les parametres systeme',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLocating: false,
          error: 'Autorise la localisation dans les parametres de l\'app',
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          isLocating: false,
          error: 'Permission de localisation refusee',
        );
        return;
      }

      // PRIORITE 1 : lastKnown instantane (cache OS, < 1s)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('[ReportForm] lastKnown instant: ${lastKnown.latitude}, ${lastKnown.longitude}');
          state = state.copyWith(
            lat: lastKnown.latitude,
            lng: lastKnown.longitude,
            isLocating: false,
          );
          _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
          // Affine en background sans bloquer
          _refinePosition();
          return;
        }
      } catch (e) {
        debugPrint('[ReportForm] lastKnown failed: $e');
      }

      // PRIORITE 2 : high accuracy (5-10m, timeout 8s)
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        debugPrint('[ReportForm] high: ${pos.latitude}, ${pos.longitude} (acc=${pos.accuracy}m)');
        state = state.copyWith(
          lat: pos.latitude,
          lng: pos.longitude,
          isLocating: false,
        );
        _reverseGeocode(pos.latitude, pos.longitude);
        return;
      } catch (e) {
        debugPrint('[ReportForm] high accuracy failed: $e');
      }

      state = state.copyWith(
        isLocating: false,
        error: 'GPS indisponible. Sors a l\'exterieur et reessaie.',
      );
    } catch (e) {
      debugPrint('[ReportForm] location error: $e');
      state = state.copyWith(
        isLocating: false,
        error: 'Impossible de te localiser',
      );
    }
  }

  /// Affine la position en background (non-bloquant).
  Future<void> _refinePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      state = state.copyWith(lat: pos.latitude, lng: pos.longitude);
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  void setCategory(String c) => state = state.copyWith(category: c);
  void setTitle(String t) => state = state.copyWith(rawTitle: t);
  void setLocationName(String n) => state = state.copyWith(locationName: n);
  void setVideo(String path) => state = state.copyWith(localVideoPath: path);
  void setPin(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);

  /// Reverse geocode via Nominatim (OSM, gratuit, sans cle API).
  /// Retourne le nom du lieu le plus proche (bar, rue, place, etc.).
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': '18',
          'addressdetails': '1',
        },
        options: Options(
          headers: {'User-Agent': 'PulzApp/1.0 (https://macity.app)'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = res.data as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return;

      // Cherche un nom de lieu pertinent dans l'ordre de preference
      final name = address['amenity'] ??
          address['shop'] ??
          address['leisure'] ??
          address['tourism'] ??
          address['building'] ??
          address['road'] ??
          address['pedestrian'] ??
          address['square'];

      if (name != null && name is String && name.isNotEmpty) {
        // Ajoute le quartier/commune si dispo
        final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
        final label = suburb.isNotEmpty ? '$name, $suburb' : name;
        state = state.copyWith(locationName: label);
        debugPrint('[ReportForm] reverse geocode: $label');
      }
    } catch (e) {
      debugPrint('[ReportForm] reverse geocode failed: $e');
    }
  }
  void setPhoto(String? path) {
    if (path == null) {
      state = state.copyWith(clearPhoto: true);
    } else {
      state = state.copyWith(localPhotoPath: path);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Soumet le signalement. Renvoie l'id de la row creee, ou null en cas d'erreur.
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    if (state.lat == null || state.lng == null) {
      state = state.copyWith(error: 'GPS pas encore pret, patiente...');
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final id = await _svc.reportEvent(
        category: state.category,
        rawTitle: state.rawTitle.trim(),
        lat: state.lat!,
        lng: state.lng!,
        localPhotoPath: state.localPhotoPath,
        localVideoPath: state.localVideoPath,
        locationName: state.locationName.trim(),
      );
      // On reset apres succes
      state = const ReportFormState();
      return id;
    } catch (e) {
      debugPrint('[ReportForm] submit error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Echec du signalement, reessaie',
      );
      return null;
    }
  }
}

final reportFormProvider =
    StateNotifierProvider.autoDispose<ReportFormNotifier, ReportFormState>(
  (ref) => ReportFormNotifier(ref.read(reportedEventsServiceProvider)),
);
