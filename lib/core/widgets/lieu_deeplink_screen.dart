import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/services/lieu_deeplink_service.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';

/// Ecran de deep link generique pour toute fiche etablissement, quelle que
/// soit la categorie (Food, Famille, Culture, Sport, Night).
///
/// URL : macity.app/lieu/{table}/{id}. Charge la fiche via
/// [LieuDeeplinkService], navigue vers le feed puis ouvre le detail unifie.
class LieuDeeplinkScreen extends ConsumerStatefulWidget {
  final String table;
  final String id;
  const LieuDeeplinkScreen({super.key, required this.table, required this.id});

  @override
  ConsumerState<LieuDeeplinkScreen> createState() => _LieuDeeplinkScreenState();
}

class _LieuDeeplinkScreenState extends ConsumerState<LieuDeeplinkScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndShow();
  }

  Future<void> _loadAndShow() async {
    try {
      final id = int.tryParse(widget.id);
      if (id == null || id <= 0) {
        appRouter.go('/home');
        return;
      }

      final commerce = await LieuDeeplinkService().fetchById(widget.table, id);

      // Naviguer vers le feed dans tous les cas.
      appRouter.go('/home');

      if (commerce != null) {
        await Future.delayed(const Duration(milliseconds: 800));
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          CommerceRowCard.openDetail(ctx, commerce);
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
