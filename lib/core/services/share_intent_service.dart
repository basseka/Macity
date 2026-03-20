import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';

class ShareIntentService {
  static StreamSubscription<List<SharedMediaFile>>? _sub;
  static WidgetRef? _ref;

  static void init(WidgetRef ref) {
    _ref = ref;

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((files) => _handleShared(files));

    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((files) => _handleShared(files));
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _ref = null;
  }

  static BuildContext? get _navContext => rootNavigatorKey.currentContext;

  static Future<void> _handleShared(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final ctx = _navContext;
    if (ctx == null) return;

    final imageFile = files.firstWhere(
      (f) => f.type == SharedMediaType.image,
      orElse: () => files.first,
    );

    if (imageFile.type != SharedMediaType.image) return;

    final photoPath = imageFile.path;

    final ref = _ref;
    if (ref == null) return;

    // Attendre que le status pro soit charge
    var proState = ref.read(proAuthProvider);
    if (proState.status == ProAuthStatus.loading) {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        proState = ref.read(proAuthProvider);
        if (proState.status != ProAuthStatus.loading) break;
      }
    }

    if (proState.status == ProAuthStatus.notConnected) {
      final navCtx = _navContext;
      if (navCtx == null) return;
      showModalBottomSheet(
        context: navCtx,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ProLoginSheet(),
      );
    } else {
      _showActionChoice(photoPath);
    }

    ReceiveSharingIntent.instance.reset();
  }

  /// Propose le choix : creer un event ou une offre.
  static void _showActionChoice(String photoPath) {
    appRouter.go('/home');

    Future.delayed(const Duration(milliseconds: 400), () {
      final ctx = _navContext;
      if (ctx == null) return;

      showModalBottomSheet(
        context: ctx,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Que souhaitez-vous publier ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A1259),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.event, color: Color(0xFF7B2D8E)),
                  title: const Text('Ajouter un evenement'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    final navCtx = _navContext;
                    if (navCtx != null) {
                      Navigator.of(navCtx).push(
                        MaterialPageRoute(
                          builder: (_) => CreateEventPage(
                            initialPhotoPath: photoPath,
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer,
                      color: Color(0xFFE91E8C)),
                  title: const Text('Creer une offre promotionnelle'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _openSheet(
                      AddOfferBottomSheet(initialPhotoPath: photoPath),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }

  static void _openSheet(Widget sheet) {
    Future.delayed(const Duration(milliseconds: 300), () {
      final ctx = _navContext;
      if (ctx == null) return;

      showModalBottomSheet(
        context: ctx,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );
    });
  }
}
