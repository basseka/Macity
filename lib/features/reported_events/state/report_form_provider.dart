import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulz_app/core/network/network_info.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';
import 'package:pulz_app/features/reported_events/state/story_outbox_provider.dart';

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
  /// Precision (rayon en metres) de la derniere fix GPS retenue. null tant
  /// qu'aucune position. Sert a afficher un cercle/indicateur de precision.
  final double? accuracy;
  /// true tant que le GPS continue d'affiner la position en arriere-plan
  /// (le pin peut encore bouger vers un fix plus precis).
  final bool isRefining;
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
    this.accuracy,
    this.isRefining = false,
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
    double? accuracy,
    bool? isRefining,
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
      accuracy: accuracy ?? this.accuracy,
      isRefining: isRefining ?? this.isRefining,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier(this._svc, this._ref) : super(const ReportFormState());

  final ReportedEventsService _svc;
  final Ref _ref;

  /// Flux GPS d'affinage en cours (converge vers le fix satellite le plus
  /// precis, puis se coupe tout seul). Conserve pour annulation propre.
  StreamSubscription<Position>? _locSub;
  Timer? _refineTimer;
  Timer? _noFixTimer;
  double _bestAccuracy = double.infinity;

  /// Precision cible (m) : en dessous, on considere le fix satellite atteint
  /// et on coupe le GPS pour economiser la batterie.
  static const double _targetAccuracy = 20;

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

      // Strategie « affiche vite, affine ensuite » : on montre immediatement
      // une position approximative (lastKnown / 1er fix) pour ne pas bloquer
      // l'UI, MAIS on garde le flux GPS ouvert et on met le pin a jour a
      // chaque fix PLUS PRECIS, jusqu'a atteindre le fix satellite (<20m) ou
      // 22s max. C'est la cle de la precision : avant, on coupait au 1er fix
      // <120m (souvent un fix wifi/cell a 60-120m) et on ne voyait jamais le
      // vrai fix satellite qui arrive 3-8s plus tard.
      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );

      _bestAccuracy = double.infinity;

      // Seed UI avec lastKnown (age <30min, acc <10km) : localisation grossiere
      // immediate, mieux que "Localisation en cours...". Le flux l'affinera.
      try {
        final lk = await Geolocator.getLastKnownPosition();
        if (lk != null) {
          final ageSec =
              DateTime.now().difference(lk.timestamp.toLocal()).inSeconds;
          if (ageSec < 1800 && lk.accuracy < 10000) {
            _bestAccuracy = lk.accuracy;
            debugPrint('[ReportForm] seed lastKnown acc=${lk.accuracy}m age=${ageSec}s');
            state = state.copyWith(
              lat: lk.latitude,
              lng: lk.longitude,
              accuracy: lk.accuracy,
              isLocating: false,
              isRefining: true,
            );
            _reverseGeocode(lk.latitude, lk.longitude);
          }
        }
      } catch (e) {
        debugPrint('[ReportForm] lastKnown failed: $e');
      }

      // Flux convergent : chaque fix strictement plus precis remplace le pin.
      await _locSub?.cancel();
      _locSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) {
          if (pos.accuracy >= _bestAccuracy) return; // fix moins bon : ignore
          _bestAccuracy = pos.accuracy;
          _noFixTimer?.cancel();
          debugPrint('[ReportForm] fix affine acc=${pos.accuracy}m');
          state = state.copyWith(
            lat: pos.latitude,
            lng: pos.longitude,
            accuracy: pos.accuracy,
            isLocating: false,
            isRefining: true,
          );
          // Fix satellite atteint : inutile de continuer a drainer le GPS.
          if (pos.accuracy <= _targetAccuracy) {
            _stopRefine(geocode: true);
          }
        },
        onError: (e) => debugPrint('[ReportForm] stream error: $e'),
      );

      // Garde-fou batterie : on coupe l'affinage apres 22s quoi qu'il arrive
      // (on garde alors la meilleure fix recue).
      _refineTimer?.cancel();
      _refineTimer = Timer(const Duration(seconds: 22), () {
        debugPrint('[ReportForm] refine timeout, best acc=${_bestAccuracy}m');
        _stopRefine(geocode: true);
      });

      // Si AUCUNE fix n'arrive en 12s ET pas de seed : message d'erreur.
      _noFixTimer?.cancel();
      _noFixTimer = Timer(const Duration(seconds: 12), () {
        if (state.lat == null) {
          _stopRefine(geocode: false);
          state = state.copyWith(
            isLocating: false,
            error: 'GPS indisponible. Sors a l\'exterieur et reessaie.',
          );
        }
      });
    } catch (e) {
      debugPrint('[ReportForm] location error: $e');
      state = state.copyWith(
        isLocating: false,
        error: 'Impossible de te localiser',
      );
    }
  }

  /// Coupe le flux d'affinage GPS (fix satellite atteint, timeout, submit,
  /// pin deplace manuellement ou dispose). Idempotent.
  void _stopRefine({bool geocode = false}) {
    _refineTimer?.cancel();
    _refineTimer = null;
    _noFixTimer?.cancel();
    _noFixTimer = null;
    _locSub?.cancel();
    _locSub = null;
    if (state.isRefining) {
      state = state.copyWith(isRefining: false);
      if (geocode && state.lat != null && state.lng != null) {
        _reverseGeocode(state.lat!, state.lng!);
      }
    }
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _refineTimer?.cancel();
    _noFixTimer?.cancel();
    super.dispose();
  }

  void setCategory(String c) => state = state.copyWith(category: c);
  void setTitle(String t) => state = state.copyWith(rawTitle: t);
  void setLocationName(String n) => state = state.copyWith(locationName: n);
  void setVideo(String path) => state = state.copyWith(localVideoPath: path);
  void setIsPrivate(bool v) => state = state.copyWith(isPrivate: v);
  void setPin(double lat, double lng) {
    // L'user positionne le pin a la main : il prend le controle, on arrete
    // l'affinage auto pour ne pas ecraser son choix avec une fix suivante.
    _stopRefine();
    state = state.copyWith(lat: lat, lng: lng, accuracy: 0, isRefining: false);
  }

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
    // Fige la position soumise : on coupe l'affinage pour ne pas publier une
    // coordonnee differente de celle que l'user voit a l'ecran.
    _stopRefine();
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

    // Hors-ligne : on met directement en file d'attente (pas d'upload voue a
    // l'echec). La story partira automatiquement au retour du reseau.
    final online = await NetworkInfo().isConnected;
    if (!online) {
      return _enqueueOffline(category, rawTitle);
    }

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
    } on NoMediaUploadedException {
      // Reseau redevenu KO en plein upload : plutot que d'echouer, on bascule
      // en file d'attente pour un envoi automatique plus tard.
      debugPrint('[ReportForm] upload KO -> mise en file d\'attente');
      return _enqueueOffline(category, rawTitle);
    } catch (e) {
      debugPrint('[ReportForm] submit error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Echec du signalement, reessaie',
      );
      return null;
    }
  }

  /// Met la story courante en file d'attente offline et reset le formulaire.
  /// Renvoie un [ReportSubmitResult] avec `queued: true`.
  Future<ReportSubmitResult?> _enqueueOffline(
      String category, String rawTitle) async {
    try {
      final pending = await _ref.read(storyOutboxProvider.notifier).enqueue(
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
      state = const ReportFormState();
      return ReportSubmitResult(id: pending.id, queued: true);
    } catch (e) {
      debugPrint('[ReportForm] enqueue offline failed: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Impossible de mettre la story en attente, reessaie',
      );
      return null;
    }
  }
}

final reportFormProvider =
    StateNotifierProvider.autoDispose<ReportFormNotifier, ReportFormState>(
  (ref) => ReportFormNotifier(ref.read(reportedEventsServiceProvider), ref),
);
