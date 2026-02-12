import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/features/splash/presentation/splash_screen.dart';
import 'package:pulz_app/features/home/presentation/home_screen.dart';
import 'package:pulz_app/features/mode/presentation/mode_shell.dart';
import 'package:pulz_app/features/day/presentation/day_screen.dart';
import 'package:pulz_app/features/sport/presentation/sport_screen.dart';
import 'package:pulz_app/features/night/presentation/night_screen.dart';
import 'package:pulz_app/features/culture/presentation/culture_screen.dart';
import 'package:pulz_app/features/family/presentation/family_screen.dart';
import 'package:pulz_app/features/food/presentation/food_screen.dart';
import 'package:pulz_app/features/gaming/presentation/gaming_screen.dart';
import 'package:pulz_app/features/auth/presentation/instagram_callback_handler.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
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
