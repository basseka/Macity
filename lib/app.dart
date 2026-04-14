import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/services/deep_link_service.dart';
import 'package:pulz_app/core/services/fcm_service.dart';
import 'package:pulz_app/core/services/share_intent_service.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/app_theme.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
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
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareIntentService.init(ref);
      _setupNotificationTapHandler();
      // Reset du badge au cold start (l'utilisateur a ouvert l'app
      // donc les notifs en attente sont consommees).
      FcmService.resetBadge();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Quand l'utilisateur revient dans l'app (foreground),
    // on efface le badge sur l'icone du launcher.
    if (state == AppLifecycleState.resumed) {
      FcmService.resetBadge();
    }
  }

  void _initDeepLinks() {
    // Ecouter les liens entrants (app déjà ouverte)
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[DeepLink] stream: $uri');
      final eventId = parseDeepLinkEventId(uri);
      if (eventId != null) {
        // App ouverte : charger l'event et naviguer
        ScrapedEventsSupabaseService().fetchEventById(eventId).then((event) {
          if (event != null) {
            deepLinkSetPending(event);
            appRouter.go('/home');
          }
        });
      }
    });

    // Lien initial (app fermée) — stocker juste l'ID, pas de fetch
    // Le FeedScreen fera le fetch quand il sera monté
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('[DeepLink] initial: $uri');
        final eventId = parseDeepLinkEventId(uri);
        if (eventId != null) {
          deepLinkSetPendingId(eventId);
        }
      }
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
      } else if (type == 'daily_digest' || type == 'event_reminder') {
        // Ouvrir le detail de l'event si event_id présent
        final eventId = data['event_id'] as String? ?? '';
        if (eventId.isNotEmpty) {
          ScrapedEventsSupabaseService().fetchEventById(eventId).then((event) {
            if (event != null) {
              deepLinkSetPending(event);
              appRouter.go('/home');
            } else {
              appRouter.go('/home');
            }
          });
        } else {
          appRouter.go('/home');
        }
        return;
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
        final venue = container.read(selectedConcertVenueProvider);
        if (venue != null) {
          container.read(selectedConcertVenueProvider.notifier).state = null;
          return true;
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
      builder: (context, child) {
        return _AppShell(child: child!);
      },
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  String _location = '/splash';

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRouteChange);
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    final newLocation = appRouter.routerDelegate.currentConfiguration.uri.toString();
    if (newLocation != _location) {
      setState(() => _location = newLocation);
      // Synchroniser le provider avec la route
      if (newLocation == '/home' || newLocation == '/') {
        ref.read(navBarIndexProvider.notifier).state = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNavBar = _location.startsWith('/home') || _location.startsWith('/mode');

    if (!showNavBar) return widget.child;

    return Column(
      children: [
        Expanded(child: widget.child),
        const AppBottomNavBar(),
      ],
    );
  }
}
