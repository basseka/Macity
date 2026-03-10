import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulz_app/features/home/presentation/home_screen.dart';
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

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) {
    if (_onboardingDone == false && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
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
      path: '/instagram-callback',
      builder: (context, state) => InstagramCallbackHandler(
        uri: state.uri,
      ),
    ),
  ],
);
