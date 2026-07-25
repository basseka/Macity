import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Wrapper Firebase Analytics.
///
/// La simple présence + initialisation du SDK Analytics suffit à remonter les
/// MAU / DAU / sessions dans la console Firebase (auto-collecte). Les events
/// custom ci-dessous enrichissent les stats (utile pour piloter et pour les
/// annonceurs). Tous les appels sont best-effort : ils n'interrompent jamais
/// l'app en cas d'erreur.
class AnalyticsService {
  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;

  /// Observer de navigation à brancher sur le routeur → events `screen_view`
  /// automatiques (engagement, écrans les plus vus).
  static FirebaseAnalyticsObserver observer() =>
      FirebaseAnalyticsObserver(analytics: instance);

  /// À appeler une fois après Firebase.initializeApp().
  static Future<void> init() async {
    try {
      await instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('[Analytics] init failed: $e');
    }
  }

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await instance.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[Analytics] event "$name" failed: $e');
    }
  }

  // ── Events métier clés ────────────────────────────────────────────────────

  /// Inscription complétée (profil créé).
  static Future<void> signupCompleted() => _log('signup_completed');

  /// Entrée « Explorer sans compte » (anonyme).
  static Future<void> exploreNoAccount() => _log('explore_no_account');

  /// Une Story Map Live a été publiée.
  static Future<void> storyPublished({String? category}) => _log(
        'story_published',
        category != null && category.isNotEmpty ? {'category': category} : null,
      );

  /// Un événement a été consulté (ouverture fiche/affiche).
  static Future<void> eventViewed(String eventId, {String? source}) => _log(
        'event_viewed',
        {
          if (eventId.isNotEmpty) 'event_id': eventId,
          if (source != null && source.isNotEmpty) 'source': source,
        },
      );
}
