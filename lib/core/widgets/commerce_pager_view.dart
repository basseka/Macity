import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Pager swipable horizontalement entre les fiches détail de commerces.
///
/// L'utilisateur tape un item dans une liste, arrive sur sa fiche détail, et
/// peut swiper de gauche/droite pour passer au précédent/suivant de la liste —
/// comme la rubrique Night. Réutilisé par toutes les rubriques.
class CommercePagerView extends StatefulWidget {
  final List<CommerceModel> commerces;
  final int initialIndex;

  const CommercePagerView({
    super.key,
    required this.commerces,
    required this.initialIndex,
  });

  /// Pousse le pager en dialog plein écran (fond noir 70%).
  static Future<void> open(
    BuildContext context, {
    required List<CommerceModel> commerces,
    required int initialIndex,
  }) {
    if (commerces.isEmpty) return Future.value();
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        pageBuilder: (_, __, ___) => CommercePagerView(
          commerces: commerces,
          initialIndex: initialIndex.clamp(0, commerces.length - 1),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  State<CommercePagerView> createState() => _CommercePagerViewState();
}

class _CommercePagerViewState extends State<CommercePagerView> {
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.commerces.length,
        // PageView consomme les drags horizontaux : le swipe gauche-droite
        // passe d'une fiche à l'autre. Les drags verticaux (scroll dans
        // l'ItemDetailSheet) restent gérés par le contenu.
        itemBuilder: (_, i) =>
            CommerceRowCard.buildDetailSheet(widget.commerces[i]),
      ),
    );
  }
}
