import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/router/app_router.dart';

/// Ecran de deep link : charge un event par son identifiant,
/// navigue vers le feed et affiche le detail en popup.
class EventDeeplinkScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDeeplinkScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDeeplinkScreen> createState() => _EventDeeplinkScreenState();
}

class _EventDeeplinkScreenState extends ConsumerState<EventDeeplinkScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndShow();
  }

  Future<void> _loadAndShow() async {
    try {
      final service = ScrapedEventsSupabaseService();
      final event = await service.fetchEventById(widget.eventId);

      // Naviguer vers le feed dans tous les cas
      appRouter.go('/home');

      if (event != null) {
        // Attendre que le feed soit rendu puis ouvrir le popup
        await Future.delayed(const Duration(milliseconds: 800));
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          EventFullscreenPopup.show(ctx, event, 'assets/images/pochette_default.jpg');
        }
      }
    } catch (_) {
      appRouter.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A0A2E),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
      ),
    );
  }
}
