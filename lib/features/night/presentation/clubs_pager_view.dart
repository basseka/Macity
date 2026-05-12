import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Pager swipable horizontalement entre les fiches detail de clubs.
/// Ouvert depuis la liste Night → Club Discotheque : l'user tape un club,
/// arrive sur son detail, et peut swiper de droite vers la gauche pour
/// passer au suivant dans la liste.
class ClubsPagerView extends StatefulWidget {
  final List<CommerceModel> clubs;
  final int initialIndex;

  const ClubsPagerView({
    super.key,
    required this.clubs,
    required this.initialIndex,
  });

  /// Push le pager en mode dialog plein ecran (background noir 70%).
  static Future<void> open(
    BuildContext context, {
    required List<CommerceModel> clubs,
    required int initialIndex,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        pageBuilder: (_, __, ___) => ClubsPagerView(
          clubs: clubs,
          initialIndex: initialIndex.clamp(0, clubs.length - 1),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  State<ClubsPagerView> createState() => _ClubsPagerViewState();
}

class _ClubsPagerViewState extends State<ClubsPagerView> {
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
        itemCount: widget.clubs.length,
        // PageView consomme les drags horizontaux : le swipe gauche-droite
        // passe d'une fiche a l'autre. Les drags verticaux (scroll a
        // l'interieur de l'ItemDetailSheet) restent gerees par le contenu.
        itemBuilder: (_, i) => CommerceRowCard.buildDetailSheet(widget.clubs[i]),
      ),
    );
  }
}
