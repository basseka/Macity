import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Nombre max de photos par signalement. Au-dela, l'UX devient lourde et
/// les uploads mobiles prennent trop de temps.
const int kMaxReportPhotos = 4;

/// Etat du formulaire de signalement (modal Waze-style).
@immutable
class ReportFormState {
  final double? lat;
  final double? lng;
  final String category;
  final String rawTitle;
  final String locationName;
  /// Identifiant OSM du POI reverse-geocode (format "<osm_type>/<osm_id>").
  /// NULL pour les signalements faits hors POI nomme (rue, place generique).
  final String? osmId;
  /// Photos locales selectionnees (jusqu'a [kMaxReportPhotos]).
  /// Uploadees en serie a la soumission.
  final List<String> localPhotoPaths;
  final String? localVideoPath;
  final bool isLocating;
  final bool isSubmitting;
  final String? error;
  /// Story marquee privee : visible uniquement par moi (device UUID).
  /// Utilise pour valider le comportement sans polluer le feed des autres.
  final bool isPrivate;

  const ReportFormState({
    this.lat,
    this.lng,
    this.category = '',
    this.rawTitle = '',
    this.locationName = '',
    this.osmId,
    this.localPhotoPaths = const [],
    this.localVideoPath,
    this.isLocating = false,
    this.isSubmitting = false,
    this.error,
    this.isPrivate = false,
  });

  // Plus besoin de titre ni de catégorie pour publier une story Map Live :
  // il suffit d'avoir un media et de ne pas être déjà en cours d'envoi.
  bool get canSubmit => !isSubmitting;

  bool get canAddMorePhotos => localPhotoPaths.length < kMaxReportPhotos;

  ReportFormState copyWith({
    double? lat,
    double? lng,
    String? category,
    String? rawTitle,
    String? locationName,
    String? osmId,
    List<String>? localPhotoPaths,
    String? localVideoPath,
    bool? isLocating,
    bool? isSubmitting,
    String? error,
    bool? isPrivate,
    bool clearError = false,
    bool clearOsmId = false,
  }) {
    return ReportFormState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      rawTitle: rawTitle ?? this.rawTitle,
      locationName: locationName ?? this.locationName,
      osmId: clearOsmId ? null : (osmId ?? this.osmId),
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier(this._svc) : super(const ReportFormState());

  final ReportedEventsService _svc;

  /// Recupere la position GPS courante (auto-locate au open de la modal).
  ///
  /// Strategie en 3 temps pour eviter "rue de Dakar au lieu de Beaupuy" :
  /// 1) On ECARTE d'emblee tout lastKnown vieux de plus de 2 minutes
  ///    (cache OS qui peut dater de plusieurs heures et pointer une autre ville).
  /// 2) On ouvre un STREAM positionne sur best accuracy : on prend la
  ///    premiere fix sous 50m de precision (premier vrai fix satellite).
  /// 3) Si rien sous 50m en 15s, on garde la meilleure fix recue
  ///    (toujours mieux que le cache OS).
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

      // Strategie : on utilise le Fused Provider Android (rapide) mais on
      // FILTRE les fixes par precision pour eliminer la triangulation
      // wifi/cellulaire qui peut placer l'user a la derniere position wifi
      // connue de Google (ex: "rue de Dakar Toulouse" alors que l'user est
      // a Beaupuy). Une vraie fix GPS satellite est < 50m ; une fix
      // wifi/cell typique est 200-2000m.
      // `high` (pas `best`) : un fix arrive beaucoup plus vite, precision
      // largement suffisante pour situer un lieu (le user ajuste au besoin
      // avec le pin draggable).
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      // PRIORITE 1 : seed UI avec lastKnown s'il a moins de 5 min.
      // On accepte meme une fix imprecise (wifi/cell ~500m) car la
      // localisation grossiere est mieux que rien : le user peut
      // ajuster avec le pin draggable, et le stream/refine continuent
      // d'affiner en background. Refus uniquement si TROP vieux (>30min)
      // ou totalement aberrant (>10km de precision).
      Position? seed;
      try {
        final lk = await Geolocator.getLastKnownPosition();
        if (lk != null) {
          final ageSec = DateTime.now()
              .difference(lk.timestamp.toLocal())
              .inSeconds;
          if (ageSec < 1800 && lk.accuracy < 10000) {
            seed = lk;
            debugPrint('[ReportForm] seed lastKnown: ${lk.latitude},${lk.longitude} (age=${ageSec}s, acc=${lk.accuracy}m)');
            // On affiche immediatement la position seed pour que l'UI
            // ne reste pas bloquee sur "Localisation en cours..." pendant
            // que le stream cherche un fix plus precis.
            state = state.copyWith(
              lat: lk.latitude,
              lng: lk.longitude,
              isLocating: false,
            );
            _reverseGeocode(lk.latitude, lk.longitude);
          } else {
            debugPrint('[ReportForm] lastKnown rejete (age=${ageSec}s, acc=${lk.accuracy}m)');
          }
        }
      } catch (e) {
        debugPrint('[ReportForm] lastKnown failed: $e');
      }

      // PRIORITE 2 : stream, premiere fix < 120m gagne (assez precis pour un
      // lieu, et atteignable en interieur — un fix < 50m n'arrive quasi
      // jamais en intra muros et faisait timeout a chaque fois).
      Position? bestFix = seed;
      final completer = Completer<Position>();
      late StreamSubscription<Position> sub;
      sub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
        debugPrint('[ReportForm] stream fix: ${pos.latitude},${pos.longitude} (acc=${pos.accuracy}m)');
        if (bestFix == null || pos.accuracy < bestFix!.accuracy) {
          bestFix = pos;
        }
        if (pos.accuracy < 120 && !completer.isCompleted) {
          completer.complete(pos);
        }
      }, onError: (e) {
        debugPrint('[ReportForm] stream error: $e');
      },);

      try {
        final fix = await completer.future
            .timeout(const Duration(seconds: 6));
        await sub.cancel();
        debugPrint('[ReportForm] fix accepte: ${fix.latitude},${fix.longitude} (acc=${fix.accuracy}m)');
        state = state.copyWith(
          lat: fix.latitude,
          lng: fix.longitude,
          isLocating: false,
        );
        _reverseGeocode(fix.latitude, fix.longitude);
        return;
      } on TimeoutException {
        await sub.cancel();
        // Pas de fix < 120m en 6s. On garde la meilleure recue MEME si
        // imprecise (mieux que "GPS indisponible"). User peut bouger le
        // pin manuellement dans le draggable map.
        if (bestFix != null) {
          debugPrint('[ReportForm] timeout, best fix gardee: acc=${bestFix!.accuracy}m');
          state = state.copyWith(
            lat: bestFix!.latitude,
            lng: bestFix!.longitude,
            isLocating: false,
          );
          _reverseGeocode(bestFix!.latitude, bestFix!.longitude);
          _refinePosition();
          return;
        }
      }

      // PRIORITE 3 (ultime fallback) : getCurrentPosition direct.
      // Si meme le stream n'a rien delivre, on tente un dernier appel
      // synchrone avec accuracy reduite. Mieux que "GPS indisponible".
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        debugPrint('[ReportForm] fallback getCurrent: ${pos.latitude},${pos.longitude} (acc=${pos.accuracy}m)');
        state = state.copyWith(
          lat: pos.latitude,
          lng: pos.longitude,
          isLocating: false,
        );
        _reverseGeocode(pos.latitude, pos.longitude);
        return;
      } catch (e) {
        debugPrint('[ReportForm] fallback getCurrent failed: $e');
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
  void setIsPrivate(bool v) => state = state.copyWith(isPrivate: v);
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

      // Capture l'osm_id SI Nominatim a matche un POI nomme (pas une rue
      // ni une zone generique). Sert de cle de dedup pour les grands lieux
      // ou le rayon GPS ~80m ne suffit pas (African Safari, stades, malls).
      final osmType = data['osm_type'] as String?;
      final osmIdRaw = data['osm_id'];
      final osmClass = data['class'] as String?;
      const poiClasses = {
        'leisure', 'tourism', 'amenity', 'shop', 'building', 'sport',
        'historic', 'office',
      };
      String? osmKey;
      if (osmType != null &&
          osmIdRaw != null &&
          osmClass != null &&
          poiClasses.contains(osmClass)) {
        osmKey = '$osmType/$osmIdRaw';
      }

      if (name != null && name is String && name.isNotEmpty) {
        // Ajoute le quartier/commune si dispo
        final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
        final label = suburb.isNotEmpty ? '$name, $suburb' : name;
        state = state.copyWith(locationName: label, osmId: osmKey);
        debugPrint('[ReportForm] reverse geocode: $label (osm=$osmKey, class=$osmClass)');
      } else if (osmKey != null) {
        state = state.copyWith(osmId: osmKey);
      }
    } catch (e) {
      debugPrint('[ReportForm] reverse geocode failed: $e');
    }
  }
  /// Remplace la liste de photos par une seule (ou la vide si null).
  /// Utilise par le flow single-photo (camera preview, legacy).
  void setPhoto(String? path) {
    if (path == null || path.isEmpty) {
      state = state.copyWith(localPhotoPaths: const []);
    } else {
      state = state.copyWith(localPhotoPaths: [path]);
    }
  }

  /// Ajoute des photos a la liste existante, en tronquant a [kMaxReportPhotos].
  void addPhotos(Iterable<String> paths) {
    final current = state.localPhotoPaths;
    final merged = [...current, ...paths];
    final capped = merged.length > kMaxReportPhotos
        ? merged.sublist(0, kMaxReportPhotos)
        : merged;
    state = state.copyWith(localPhotoPaths: capped);
  }

  void removePhotoAt(int index) {
    final current = state.localPhotoPaths;
    if (index < 0 || index >= current.length) return;
    final next = [...current]..removeAt(index);
    state = state.copyWith(localPhotoPaths: next);
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Soumet le signalement.
  /// Renvoie un [ReportSubmitResult] (id + nombre de photos en echec),
  /// ou null en cas d'erreur globale.
  Future<ReportSubmitResult?> submit() async {
    if (!state.canSubmit) return null;
    if (state.lat == null || state.lng == null) {
      state = state.copyWith(error: 'GPS pas encore pret, patiente...');
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    // Defaults : l'UI Story Map Live n'expose plus titre ni categorie, mais
    // l'edge function `generate-event-poster` les attend non vides
    // (sinon elle rejette → status='rejected' → disparait du feed).
    // On force des valeurs minimales et l'IA enrichira a posteriori.
    final category = state.category.trim().isNotEmpty
        ? state.category.trim()
        : 'live';
    final rawTitle = state.rawTitle.trim().isNotEmpty
        ? state.rawTitle.trim()
        : (state.locationName.trim().isNotEmpty
            ? state.locationName.trim()
            : 'Story Map Live');
    debugPrint('[ReportForm] submit start lat=${state.lat} lng=${state.lng} '
        'category="$category" title="$rawTitle" '
        'photos=${state.localPhotoPaths.length} '
        'video=${state.localVideoPath != null}');
    try {
      final result = await _svc.reportEvent(
        category: category,
        rawTitle: rawTitle,
        lat: state.lat!,
        lng: state.lng!,
        localPhotoPaths: state.localPhotoPaths,
        localVideoPath: state.localVideoPath,
        locationName: state.locationName.trim(),
        osmId: state.osmId,
        isPrivate: state.isPrivate,
      );
      debugPrint('[ReportForm] submit success id=${result.id} '
          'photoFailures=${result.photoFailures}');
      // On reset apres succes
      state = const ReportFormState();
      return result;
    } catch (e) {
      debugPrint('[ReportForm] submit error: $e');
      final isMediaFail = e is NoMediaUploadedException;
      state = state.copyWith(
        isSubmitting: false,
        error: isMediaFail
            ? "Echec de l'envoi du media, verifie ta connexion et reessaie"
            : 'Echec du signalement, reessaie',
      );
      return null;
    }
  }
}

final reportFormProvider =
    StateNotifierProvider.autoDispose<ReportFormNotifier, ReportFormState>(
  (ref) => ReportFormNotifier(ref.read(reportedEventsServiceProvider)),
);
