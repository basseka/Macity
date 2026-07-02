import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/core/services/deep_link_service.dart';
import 'package:pulz_app/features/explorer/presentation/explorer_screen.dart';
import 'package:pulz_app/features/home/presentation/feed_screen.dart';
import 'package:pulz_app/features/mode/presentation/mode_shell.dart';
import 'package:pulz_app/features/day/presentation/day_screen.dart';
import 'package:pulz_app/features/sport/presentation/sport_screen.dart';
import 'package:pulz_app/features/night/presentation/night_screen.dart';
import 'package:pulz_app/features/culture/presentation/culture_screen.dart';
import 'package:pulz_app/features/family/presentation/family_screen.dart';
import 'package:pulz_app/features/food/presentation/food_screen.dart';
import 'package:pulz_app/features/gaming/presentation/gaming_screen.dart';
import 'package:pulz_app/features/tourisme/presentation/tourisme_screen.dart';
import 'package:pulz_app/features/auth/presentation/instagram_callback_handler.dart';
import 'package:pulz_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pulz_app/features/test/presentation/test_screen.dart';
import 'package:pulz_app/features/splash/presentation/toto_splash_screen.dart';
import 'package:pulz_app/features/day/presentation/event_deeplink_screen.dart';
import 'package:pulz_app/core/widgets/lieu_deeplink_screen.dart';
import 'package:pulz_app/features/private_events/presentation/open_secret_box_screen.dart';

final rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Verrou d'accès (cache mémoire, lu une seule fois depuis SharedPreferences) :
/// true seulement après inscription/connexion (email + téléphone). Tant que
/// false, tout chemin hors splash/onboarding/deep-links est redirigé vers
/// /onboarding.
bool? _userRegistered;

Future<void> initOnboardingState() async {
  // Partager la clé root navigator avec le deep link service
  deepLinkNavigatorKey = rootNavigatorKey;
  final prefs = await SharedPreferences.getInstance();
  _userRegistered = prefs.getBool('user_registered') ?? false;
}

/// Met à jour le cache mémoire du verrou après une inscription/connexion.
void markRegisteredComplete() {
  _userRegistered = true;
}

late final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // Deep link custom-scheme (pulzapp://coffre/{token}, pulzapp://event/{id})
    // delivre par la plateforme au demarrage a froid : go_router ne sait pas
    // matcher l'URI brute (-> "no routes for location: pulzapp://...").
    // On la convertit ici en route interne valide.
    if (state.uri.scheme == 'pulzapp') {
      if (state.uri.host == 'coffre' && state.uri.pathSegments.isNotEmpty) {
        return '/coffre/${state.uri.pathSegments.first}';
      }
      return '/home';
    }
    // Allow deep links to /event/, /coffre/ et /lieu/ even if onboarding not done
    if (state.matchedLocation.startsWith('/event/')) return null;
    if (state.matchedLocation.startsWith('/coffre/')) return null;
    if (state.matchedLocation.startsWith('/lieu/')) return null;
    // Verrou : sans inscription (email + téléphone), aucun accès hors
    // onboarding/splash. Remplace l'ancien gating sur `onboarding_done`
    // (contournable via le bouton « Passer », désormais supprimé).
    if (_userRegistered != true &&
        state.matchedLocation != '/onboarding' &&
        state.matchedLocation != '/splash') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const TotoSplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/explorer',
      builder: (context, state) => const ExplorerScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ModeShell(child: child),
      routes: [
        GoRoute(
          path: '/mode/day',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DayScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/sport',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SportScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/culture',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CultureScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/family',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FamilyScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/food',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FoodScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/gaming',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GamingScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/night',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NightScreen(),
          ),
        ),
        GoRoute(
          path: '/mode/tourisme',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TourismeScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) => EventDeeplinkScreen(
        eventId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/coffre/:token',
      builder: (context, state) => OpenSecretBoxScreen(
        prefilledToken: state.pathParameters['token'],
      ),
    ),
    GoRoute(
      path: '/lieu/:table/:id',
      builder: (context, state) => LieuDeeplinkScreen(
        table: state.pathParameters['table'] ?? '',
        id: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/test',
      builder: (context, state) => const TestScreen(),
    ),
    GoRoute(
      path: '/instagram-callback',
      builder: (context, state) => InstagramCallbackHandler(
        uri: state.uri,
      ),
    ),
  ],
);
