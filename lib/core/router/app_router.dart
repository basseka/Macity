import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

final rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Cache the onboarding state so we only read SharedPreferences once.
bool? _onboardingDone;

Future<void> initOnboardingState() async {
  final prefs = await SharedPreferences.getInstance();
  _onboardingDone = prefs.getBool('onboarding_done') ?? false;
}

void markOnboardingComplete() {
  _onboardingDone = true;
}

late final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // Allow deep links to /event/ even if onboarding not done
    if (state.matchedLocation.startsWith('/event/')) return null;
    if (_onboardingDone == false &&
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
