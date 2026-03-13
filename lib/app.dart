import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/services/fcm_service.dart';
import 'package:pulz_app/core/services/share_intent_service.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/app_theme.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/notifications/data/mairie_notifications_service.dart';

class PulzApp extends ConsumerStatefulWidget {
  const PulzApp({super.key});

  @override
  ConsumerState<PulzApp> createState() => _PulzAppState();
}

class _PulzAppState extends ConsumerState<PulzApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareIntentService.init(ref);
      _setupNotificationTapHandler();
    });
  }

  @override
  void dispose() {
    ShareIntentService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupNotificationTapHandler() {
    FcmService.onNotificationTap = (data) {
      debugPrint('[App] notification tap data: $data');
      final type = data['type'] as String? ?? '';
      final universe = data['universe'] as String? ?? '';

      // Universes valides pour la navigation
      const validUniverses = {
        'day', 'sport', 'culture', 'family',
        'food', 'gaming', 'night', 'tourisme',
      };

      // Notification mairie → fetch link_url depuis Supabase et ouvrir le site
      if (type == 'mairie_notification') {
        final notifId = data['notification_id'] as String? ?? '';
        debugPrint('[App] mairie tap — notification_id: $notifId');
        _openMairieLink(notifId);
        return;
      }

      if (universe.isNotEmpty && validUniverses.contains(universe)) {
        // Naviguer vers le mode correspondant
        ref.read(modeSubcategoriesProvider.notifier).select(universe, null);
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
        appRouter.go('/mode/$universe');
      } else if (type == 'event_reminder') {
        // Pour les rappels d'événement, ouvrir le mode Day (calendrier)
        ref.read(modeSubcategoriesProvider.notifier).select('day', null);
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
        appRouter.go('/mode/day');
      } else {
        // Fallback: ouvrir l'accueil
        appRouter.go('/home');
      }
    };
  }

  /// Récupère le link_url de la notification mairie depuis Supabase et l'ouvre.
  Future<void> _openMairieLink(String notifId) async {
    try {
      if (notifId.isEmpty) {
        appRouter.go('/home');
        return;
      }
      final service = MairieNotificationsService();
      final linkUrl = await service.fetchLinkUrl(int.parse(notifId));
      debugPrint('[App] mairie link_url fetched: "$linkUrl"');
      if (linkUrl != null && linkUrl.isNotEmpty) {
        final uri = Uri.tryParse(linkUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      appRouter.go('/home');
    } catch (e) {
      debugPrint('[App] mairie link fetch error: $e');
      appRouter.go('/home');
    }
  }

  /// Intercepte le bouton retour Android :
  /// 1. Bottom sheet / dialog ouverte → la ferme
  /// 2. Sur /home → minimise l'app
  /// 3. Ailleurs → retour a /home
  @override
  Future<bool> didPopRoute() async {
    // 1. Fermer les modales (bottom sheets, dialogs) sur le root navigator
    final rootNav = appRouter.routerDelegate.navigatorKey.currentState;
    if (rootNav != null && rootNav.canPop()) {
      rootNav.pop();
      return true;
    }

    // 2. Dérouler la navigation interne (sous-catégorie / salle)
    final container = ProviderScope.containerOf(context);
    final currentMode = container.read(currentModeProvider);
    final subcategory = container.read(modeSubcategoriesProvider)[currentMode];

    if (subcategory != null) {
      // Niveau salle → retour à la grille des salles
      if (currentMode == 'culture' && subcategory == 'Theatre') {
        final theatreId = container.read(selectedTheatreIdProvider);
        if (theatreId != null) {
          container.read(selectedTheatreIdProvider.notifier).state = null;
          return true;
        }
      }
      if (currentMode == 'day') {
        if (subcategory == 'Concert') {
          final venue = container.read(selectedConcertVenueProvider);
          if (venue != null) {
            container.read(selectedConcertVenueProvider.notifier).state = null;
            return true;
          }
        } else if (subcategory == 'DJ set') {
          final venue = container.read(selectedDjsetVenueProvider);
          if (venue != null) {
            container.read(selectedDjsetVenueProvider.notifier).state = null;
            return true;
          }
        } else if (subcategory == 'Spectacle') {
          final venue = container.read(selectedSpectacleVenueProvider);
          if (venue != null) {
            container.read(selectedSpectacleVenueProvider.notifier).state = null;
            return true;
          }
        }
      }

      // Sous-catégorie → retour à la grille des rubriques
      container.read(modeSubcategoriesProvider.notifier).select(currentMode, null);
      container.read(dateRangeFilterProvider.notifier).state =
          const DateRangeFilter();
      return true;
    }

    // 3. Sur l'accueil → minimise l'app
    final location =
        appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location == '/home' || location == '/') {
      await SystemNavigator.pop();
      return true;
    }

    // 4. Sur tout autre ecran → retour a l'accueil
    appRouter.go('/home');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaCity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
