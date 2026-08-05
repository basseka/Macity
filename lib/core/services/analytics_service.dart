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
  /// Getter paresseux : `FirebaseAnalytics.instance` n'est résolu qu'à l'appel
  /// (jamais avant Firebase.initializeApp, sinon crash → écran blanc).
  static FirebaseAnalytics get instance => FirebaseAnalytics.instance;

  /// Passe à true une fois Firebase initialisé. Tant qu'il est false, tout
  /// appel au SDK lèverait « No Firebase App [DEFAULT] » : `runApp()` précède
  /// `Firebase.initializeApp()` dans main.dart, donc les premiers écrans sont
  /// affichés avant que le SDK existe.
  static bool _pret = false;

  /// Dernier écran vu avant que Firebase soit prêt. Sans ce tampon, le premier
  /// écran de la session (splash → home, ou l'écran ouvert par un deep link)
  /// serait systématiquement perdu — précisément celui qui dit par où les gens
  /// entrent dans l'app.
  static String? _ecranEnAttente;

  /// Dernier écran loggé, pour ne pas compter deux fois le même : plusieurs
  /// sources appellent `logScreenView` pour une même destination (le routeur
  /// ET la sélection de sous-rubrique émettent `/mode/food` sur un retour).
  static String? _dernierEcran;

  /// À appeler une fois après Firebase.initializeApp().
  static Future<void> init() async {
    try {
      await instance.setAnalyticsCollectionEnabled(true);
      _pret = true;
      final enAttente = _ecranEnAttente;
      _ecranEnAttente = null;
      if (enAttente != null) await _envoyerEcran(enAttente);
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

  // ── Écrans ────────────────────────────────────────────────────────────────

  /// Déclare l'écran courant à GA4.
  ///
  /// Indispensable : sans appel explicite, la seule dimension remontée est la
  /// *classe d'écran* native, et une app Flutter n'en a qu'une par plateforme
  /// (`MainActivity` sur Android, `FlutterViewController` sur iOS). Le rapport
  /// « Pages et écrans » ne distinguait donc aucune rubrique.
  ///
  /// [nom] est un chemin stable, aligné sur les routes : `/home`, `/explorer`,
  /// `/mode/food`, `/mode/food/Guinguette`. Cet alignement est ce qui permet la
  /// déduplication quand deux sources signalent la même destination.
  static Future<void> logScreenView(String nom) async {
    if (nom.isEmpty || nom == _dernierEcran) return;
    _dernierEcran = nom;
    if (!_pret) {
      _ecranEnAttente = nom;
      return;
    }
    await _envoyerEcran(nom);
  }

  static Future<void> _envoyerEcran(String nom) async {
    try {
      // screenClass explicite : laissé à null, le SDK le remplit avec la classe
      // native (MainActivity / FlutterViewController) et le rapport « Pages et
      // écrans » retombe sur le problème que cette méthode existe pour régler.
      await instance.logScreenView(screenName: nom, screenClass: 'MaCity');
    } catch (e) {
      debugPrint('[Analytics] screen_view "$nom" failed: $e');
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
