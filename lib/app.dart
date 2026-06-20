import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/services/app_update_service.dart';
import 'package:pulz_app/core/services/deep_link_service.dart';
import 'package:pulz_app/core/services/fcm_service.dart';
import 'package:pulz_app/core/services/share_intent_service.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/macity_theme.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/core/widgets/force_update_screen.dart';
import 'package:pulz_app/core/widgets/update_prompt_banner.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/notifications/data/mairie_notifications_service.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_events_paged_sheet.dart';
import 'package:pulz_app/features/private_events/presentation/my_private_events_screen.dart';

class PulzApp extends ConsumerStatefulWidget {
  const PulzApp({super.key});

  @override
  ConsumerState<PulzApp> createState() => _PulzAppState();
}

class _PulzAppState extends ConsumerState<PulzApp> with WidgetsBindingObserver {
  late final AppLinks _appLinks;

  AppUpdateStatus? _updateStatus;
  bool _bannerDismissed = false;

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
      _checkAppUpdate();
      _maybeShowPushDiagnostic();
    });
  }

  /// DIAGNOSTIC TEMPORAIRE (push iOS) : si le token FCM n'a pas pu etre
  /// enregistre sur iOS, affiche un dialogue avec l'etat exact de la chaine
  /// (permission / APNs / FCM / upsert) + bouton Copier. Evite Console.app.
  /// A retirer une fois le push iOS valide.
  void _maybeShowPushDiagnostic() {
    if (!Platform.isIOS) return;
    // Timeout de secours : si l'init se bloque/leve avant de completer le
    // Completer, on affiche quand meme le diagnostic apres 22s.
    Future.any<void>([
      FcmService.diagnosticReady.future,
      Future<void>.delayed(const Duration(seconds: 22)),
    ]).then((_) => _showPushDiagnosticDialog());
  }

  void _showPushDiagnosticDialog([int attempt = 0]) {
    if (!mounted) return;
    if (FcmService.lastFcmToken != null && FcmService.lastUpsertOk) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      // Navigator pas encore pret : on retente quelques fois.
      if (attempt < 6) {
        Future.delayed(
          const Duration(seconds: 1),
          () => _showPushDiagnosticDialog(attempt + 1),
        );
      }
      return;
    }
    final report = FcmService.buildDiagnosticReport();
    showDialog<void>(
      // ignore: use_build_context_synchronously
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Diagnostic Push iOS'),
        content: SingleChildScrollView(child: SelectableText(report)),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: report)),
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAppUpdate() async {
    final status = await AppUpdateService.instance.check();
    if (!mounted) return;
    if (status.isForceUpdate || status.isUpdateAvailable) {
      setState(() => _updateStatus = status);
    }
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
      // Coffre (soiree privee) : ouvre l'ecran avec le token pre-rempli.
      final coffreToken = parseDeepLinkCoffreToken(uri);
      if (coffreToken != null) {
        appRouter.go('/coffre/$coffreToken');
        return;
      }
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
        final coffreToken = parseDeepLinkCoffreToken(uri);
        if (coffreToken != null) {
          // Cold start : on attend que le router soit monte avant de naviguer.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appRouter.go('/coffre/$coffreToken');
          });
          return;
        }
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

      // Notification chat → ouvrir le detail sheet du signalement
      if (type == 'chat_message') {
        final eventId = data['event_id'] as String? ?? '';
        if (eventId.isNotEmpty) {
          _openReportedEventSheet(eventId);
        } else {
          appRouter.go('/home');
        }
        return;
      }

      // Notification RSVP soiree privee (un invite a fait "Je viens") →
      // ouvrir la liste "Mes soirees privees" de l'organisateur.
      if (type == 'private_event_rsvp') {
        _openMyPrivateEvents();
        return;
      }

      // Notification "live" (signalement proche, edge fn
      // notify-nearby-reported-event) → ouvrir directement l'affiche.
      // Le payload utilise `reported_event_id` (≠ `event_id` du chat).
      if (type == 'reported_event') {
        final eventId = data['reported_event_id'] as String? ?? '';
        if (eventId.isNotEmpty) {
          _openReportedEventSheet(eventId, scrollToChat: false);
        } else {
          appRouter.go('/home');
        }
        return;
      }

      // Notification mairie → fetch link_url depuis Supabase et ouvrir le site
      if (type == 'mairie_notification') {
        final notifId = data['notification_id'] as String? ?? '';
        debugPrint('[App] mairie tap — notification_id: $notifId');
        _openMairieLink(notifId);
        return;
      }

      // Notification "ouvrir une URL externe" (ex: mise à jour requise,
      // annonce marketing, lien press release…). Le champ data.url contient
      // l'URL à ouvrir dans le navigateur externe.
      if (type == 'open_url') {
        final url = data['url'] as String? ?? '';
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        return;
      }

      // Notification "À la une" (digest featured 15h) → toujours ouvrir
      // l'accueil, que l'app soit ouverte, en arriere-plan ou fermee.
      if (type == 'featured_digest') {
        appRouter.go('/home');
        return;
      }

      if (universe.isNotEmpty && validUniverses.contains(universe)) {
        // Naviguer vers le mode correspondant
        ref.read(modeSubcategoriesProvider.notifier).select(universe, null);
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
        appRouter.go('/mode/$universe');
      } else if (type == 'daily_digest') {
        // Selection du soir : plusieurs events → container plein ecran
        // swipeable. Nouveau payload : data.event_ids (ids separes par
        // virgule). Fallback sur data.event_id (anciennes notifs deja
        // distribuees qui ne portent qu'un seul event).
        final ids = (data['event_ids'] as String? ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (ids.length > 1) {
          ScrapedEventsSupabaseService().fetchEventsByIds(ids).then((events) {
            if (events.isNotEmpty) {
              deepLinkSetPendingDigest(events);
              appRouter.go('/home');
              // Cold start : FeedScreen est peut-etre deja monte (son
              // initState ne re-jouera pas). On declenche aussi l'affichage
              // ici ; le guard _isShowing + la consommation du pending
              // evitent tout double affichage.
              Future.delayed(
                const Duration(milliseconds: 800),
                deepLinkShowPending,
              );
            } else {
              appRouter.go('/home');
            }
          });
        } else {
          final eventId = ids.isNotEmpty
              ? ids.first
              : (data['event_id'] as String? ?? '');
          if (eventId.isNotEmpty) {
            ScrapedEventsSupabaseService().fetchEventById(eventId).then((event) {
              if (event != null) deepLinkSetPending(event);
              appRouter.go('/home');
            });
          } else {
            appRouter.go('/home');
          }
        }
        return;
      } else if (type == 'event_reminder') {
        // Rappel d'un event precis → ouvrir son detail.
        final eventId = data['event_id'] as String? ?? '';
        if (eventId.isNotEmpty) {
          ScrapedEventsSupabaseService().fetchEventById(eventId).then((event) {
            if (event != null) deepLinkSetPending(event);
            appRouter.go('/home');
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

  /// Ouvre le bottom sheet d'un signalement apres tap sur une notif chat
  /// ou une notif "live". [scrollToChat] = true pour les notifs chat (on
  /// veut voir le message), false pour une notif live (on montre l'affiche).
  Future<void> _openReportedEventSheet(
    String eventId, {
    bool scrollToChat = true,
  }) async {
    try {
      appRouter.go('/home');
      final event = await ReportedEventsService().fetchById(eventId);
      if (event == null) return;
      final rootNav = appRouter.routerDelegate.navigatorKey.currentState;
      final ctx = rootNav?.context;
      if (ctx == null) return;
      // Petit delai pour laisser le go('/home') s'achever avant d'ouvrir la sheet.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!ctx.mounted) return;
      ReportedEventsPagedSheet.open(
        ctx,
        events: [event],
        initialIndex: 0,
        initialScrollToChat: scrollToChat,
      );
    } catch (e) {
      debugPrint('[App] open reported event sheet failed: $e');
    }
  }

  /// Ouvre l'ecran "Mes soirees privees" (cote organisateur) apres tap sur
  /// une notif RSVP : le host voit la liste de ses events + les venues.
  Future<void> _openMyPrivateEvents() async {
    try {
      appRouter.go('/home');
      final rootNav = appRouter.routerDelegate.navigatorKey.currentState;
      if (rootNav == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      rootNav.push(
        MaterialPageRoute<void>(
          builder: (_) => const MyPrivateEventsScreen(),
        ),
      );
    } catch (e) {
      debugPrint('[App] open my private events failed: $e');
    }
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
      // Niveau salle → retour à la liste des events
      if (currentMode == 'culture' && subcategory == 'Theatre') {
        final venue = container.read(selectedTheatreVenueProvider);
        if (venue != null) {
          container.read(selectedTheatreVenueProvider.notifier).state = null;
          return true;
        }
      }
      if (currentMode == 'culture' && subcategory == 'Cinema') {
        final venue = container.read(selectedCinemaVenueProvider);
        if (venue != null) {
          container.read(selectedCinemaVenueProvider.notifier).state = null;
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
      theme: MacityTheme.dark(),
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
        // Force update : remplace tout le contenu, bloque la nav.
        final status = _updateStatus;
        if (status != null && status.isForceUpdate) {
          return ForceUpdateScreen(status: status);
        }
        // Update available : superpose une banniere fine au-dessus.
        Widget content = _AppShell(child: child!);
        if (status != null && status.isUpdateAvailable && !_bannerDismissed) {
          content = Column(
            children: [
              UpdatePromptBanner(
                status: status,
                onDismissed: () => setState(() => _bannerDismissed = true),
              ),
              Expanded(child: content),
            ],
          );
        }
        return content;
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
      } else if (newLocation.startsWith('/explorer')) {
        ref.read(navBarIndexProvider.notifier).state = 3;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNavBar = _location.startsWith('/home') ||
        _location.startsWith('/mode') ||
        _location.startsWith('/explorer');

    if (!showNavBar) return widget.child;

    return Column(
      children: [
        Expanded(child: widget.child),
        const AppBottomNavBar(),
      ],
    );
  }
}
