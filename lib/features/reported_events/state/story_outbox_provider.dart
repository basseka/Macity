import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulz_app/features/reported_events/data/story_outbox_service.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

final storyOutboxServiceProvider = Provider<StoryOutboxService>(
  (ref) => StoryOutboxService(ref.read(reportedEventsServiceProvider)),
);

/// Controleur de la file d'attente offline des stories. Expose la liste des
/// stories en attente et declenche l'envoi automatiquement :
///  - au retour du reseau (connectivity_plus),
///  - a la reprise de l'app (lifecycle resumed),
///  - au demarrage (construction du provider).
class StoryOutboxController extends StateNotifier<List<PendingStory>>
    with WidgetsBindingObserver {
  StoryOutboxController(this._ref) : super(const []) {
    WidgetsBinding.instance.addObserver(this);
    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) flushNow();
    });
    // Chargement initial + tentative d'envoi au demarrage.
    refresh();
    flushNow();
  }

  final Ref _ref;
  StreamSubscription<ConnectivityResult>? _connSub;

  StoryOutboxService get _svc => _ref.read(storyOutboxServiceProvider);

  /// Recharge la liste persistee dans l'etat (pour l'UI).
  Future<void> refresh() async {
    state = await _svc.list();
  }

  /// Met une story en file d'attente (appelee quand l'envoi direct est
  /// impossible faute de reseau).
  Future<PendingStory> enqueue({
    required String category,
    required String rawTitle,
    required double lat,
    required double lng,
    required List<String> localPhotoPaths,
    required String? localVideoPath,
    required String locationName,
    required String? osmId,
    required bool isPrivate,
  }) async {
    final pending = await _svc.enqueue(
      category: category,
      rawTitle: rawTitle,
      lat: lat,
      lng: lng,
      localPhotoPaths: localPhotoPaths,
      localVideoPath: localVideoPath,
      locationName: locationName,
      osmId: osmId,
      isPrivate: isPrivate,
    );
    await refresh();
    return pending;
  }

  /// Tente d'envoyer toute la file. Rafraichit l'etat et le feed si au moins
  /// une story est partie.
  Future<void> flushNow() async {
    final sent = await _svc.flush();
    await refresh();
    if (sent > 0) {
      _ref.invalidate(reportedEventsFeedProvider);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) flushNow();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Provider NON autoDispose : la file doit vivre toute la session pour ecouter
/// la connexion et le lifecycle.
final storyOutboxProvider =
    StateNotifierProvider<StoryOutboxController, List<PendingStory>>(
  (ref) => StoryOutboxController(ref),
);
