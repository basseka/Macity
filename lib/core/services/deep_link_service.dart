import 'package:flutter/material.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Clé globale pour accéder au NavigatorState root.
/// Doit être assignée depuis app_router.dart (rootNavigatorKey).
GlobalKey<NavigatorState>? deepLinkNavigatorKey;

/// Event ID en attente (lien initial, app fermée).
String? _pendingEventId;

/// Event déjà chargé en attente (stream, app ouverte).
Event? _pendingEvent;

/// Sélection d'events en attente pour le container "Ta sélection"
/// (tap sur la notif digest du soir) — affichée en carrousel plein écran.
List<Event>? _pendingDigestEvents;

/// Guard pour éviter les doubles appels.
bool _isShowing = false;

/// Stocker juste l'ID (pour le lien initial — pas de fetch immédiat).
void deepLinkSetPendingId(String eventId) {
  _pendingEventId = eventId;
}

/// Stocker un event déjà chargé (app ouverte, stream).
void deepLinkSetPending(Event event) {
  _pendingEvent = event;
}

/// Stocker une sélection d'events (notif digest du soir) à afficher en
/// carrousel plein écran swipeable.
void deepLinkSetPendingDigest(List<Event> events) {
  _pendingDigestEvents = events;
}

/// Appelé depuis FeedScreen.initState — charge et affiche le deep link en attente.
/// Utilise le NavigatorState global pour éviter les context invalides.
Future<void> deepLinkShowPending() async {
  if (_isShowing) return;

  // Cas digest : une sélection de plusieurs events → carrousel plein écran.
  final digest = _pendingDigestEvents;
  if (digest != null && digest.isNotEmpty) {
    _pendingDigestEvents = null;
    final navContext = deepLinkNavigatorKey?.currentContext;
    if (navContext == null) return;
    _isShowing = true;
    try {
      await EventFullscreenPopup.showPaged(
        navContext,
        events: digest,
        initialIndex: 0,
        fallbackAssetBuilder: (_) => 'assets/images/pochette_default.jpg',
        badge: 'Ta sélection',
      );
    } catch (e) {
      debugPrint('[DeepLink] error showing digest popup: $e');
    }
    _isShowing = false;
    return;
  }

  Event? eventToShow;

  // Cas 1 : event déjà chargé
  if (_pendingEvent != null) {
    eventToShow = _pendingEvent;
    _pendingEvent = null;
  }
  // Cas 2 : juste un ID — charger maintenant
  else if (_pendingEventId != null) {
    final eventId = _pendingEventId!;
    _pendingEventId = null;
    try {
      eventToShow = await ScrapedEventsSupabaseService().fetchEventById(eventId);
    } catch (e) {
      debugPrint('[DeepLink] error loading event: $e');
    }
  }

  if (eventToShow == null) return;

  // Utiliser le navigator global pour ouvrir le dialog
  final navContext = deepLinkNavigatorKey?.currentContext;
  if (navContext == null) return;

  _isShowing = true;
  try {
    await EventFullscreenPopup.show(navContext, eventToShow, 'assets/images/pochette_default.jpg');
  } catch (e) {
    debugPrint('[DeepLink] error showing popup: $e');
  }
  _isShowing = false;
}

/// Parse un URI deep link de coffre (soiree privee) et retourne le token.
/// Format : pulzapp://coffre/{token} (ou https://macity.app/coffre/{token}).
/// Le token pre-remplit l'ecran "Ouvrir un coffre" ; l'invite n'a plus qu'a
/// taper le code a 4 chiffres.
String? parseDeepLinkCoffreToken(Uri uri) {
  if (uri.scheme == 'pulzapp' && uri.host == 'coffre') {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.path.startsWith('/coffre/')) {
    return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  }
  return null;
}

/// Parse un URI deep link et retourne l'event ID.
String? parseDeepLinkEventId(Uri uri) {
  if (uri.scheme == 'pulzapp' && uri.host == 'event') {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.path.startsWith('/event/')) {
    return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  }
  return null;
}
