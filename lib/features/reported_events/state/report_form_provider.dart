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
  final String? localPhotoPath;
  final bool isLocating;
  final bool isSubmitting;
  final String? error;

  const ReportFormState({
    this.lat,
    this.lng,
    this.category = '',
    this.rawTitle = '',
    this.localPhotoPath,
    this.isLocating = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get canSubmit =>
      lat != null && lng != null && category.isNotEmpty && !isSubmitting;

  ReportFormState copyWith({
    double? lat,
    double? lng,
    String? category,
    String? rawTitle,
    String? localPhotoPath,
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
      localPhotoPath: clearPhoto ? null : (localPhotoPath ?? this.localPhotoPath),
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

      // PRIORITE 1 : position haute precision (best accuracy possible).
      // On attend jusqu'a 20s pour avoir un fix GPS precis.
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 20),
          ),
        );
        debugPrint('[ReportForm] bestForNavigation: ${pos.latitude}, ${pos.longitude} (acc=${pos.accuracy}m)');
      } catch (e) {
        debugPrint('[ReportForm] bestForNavigation failed: $e');
      }

      // PRIORITE 2 : high accuracy (toujours bon, 5-10m d'erreur)
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          );
          debugPrint('[ReportForm] high: ${pos.latitude}, ${pos.longitude} (acc=${pos.accuracy}m)');
        } catch (e) {
          debugPrint('[ReportForm] high accuracy failed: $e');
        }
      }

      // PRIORITE 3 : lastKnown du cache OS (peut etre vieux de plusieurs heures
      // mais c'est mieux que rien). On indique a l'user que c'est imprecis.
      if (pos == null) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            debugPrint('[ReportForm] fallback lastKnown: ${lastKnown.latitude}, ${lastKnown.longitude}');
            state = state.copyWith(
              lat: lastKnown.latitude,
              lng: lastKnown.longitude,
              isLocating: false,
              error: 'Position approximative — dragge le pin pour ajuster',
            );
            return;
          }
        } catch (e) {
          debugPrint('[ReportForm] getLastKnownPosition failed: $e');
        }
      }

      if (pos != null) {
        state = state.copyWith(
          lat: pos.latitude,
          lng: pos.longitude,
          isLocating: false,
        );
        return;
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

  void setCategory(String c) => state = state.copyWith(category: c);
  void setTitle(String t) => state = state.copyWith(rawTitle: t);
  void setPin(double lat, double lng) =>
      state = state.copyWith(lat: lat, lng: lng);
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
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final id = await _svc.reportEvent(
        category: state.category,
        rawTitle: state.rawTitle.trim(),
        lat: state.lat!,
        lng: state.lng!,
        localPhotoPath: state.localPhotoPath,
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
