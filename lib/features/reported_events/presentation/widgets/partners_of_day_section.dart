import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/reported_events/data/partners_of_day_service.dart';

/// Sous « En direct autour de vous » : 6 encarts « du jour », un par rubrique,
/// chacun mettant en avant UN partenaire. S'il y en a plusieurs, ils tournent
/// toutes les 3 min (temps d'antenne égal, rotation déterministe sur l'horloge
/// → tous les utilisateurs voient le même au même moment). Encart masqué si la
/// rubrique n'a aucun partenaire dans la ville sélectionnée.
class PartnersOfDaySection extends ConsumerStatefulWidget {
  const PartnersOfDaySection({super.key});

  @override
  ConsumerState<PartnersOfDaySection> createState() =>
      _PartnersOfDaySectionState();
}

class _PartnersOfDaySectionState extends ConsumerState<PartnersOfDaySection> {
  static const _rotation = Duration(minutes: 3);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rafraîchit l'affichage à chaque créneau de 3 min pour faire tourner les
    // partenaires. L'index affiché est calculé sur l'horloge (déterministe).
    _timer = Timer.periodic(_rotation, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Créneau courant (change toutes les 3 min).
  int get _slot =>
      DateTime.now().millisecondsSinceEpoch ~/ _rotation.inMilliseconds;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(partnersOfDayProvider);
    final rubriques = async.valueOrNull ?? const [];
    if (rubriques.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rubriques) _rubriqueBlock(r),
      ],
    );
  }

  Widget _rubriqueBlock(PartnerRubrique r) {
    final n = r.partners.length;
    final idx = n == 0 ? 0 : _slot % n;
    final partner = r.partners[idx];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.title,
                    style: GoogleFonts.geist(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A0F2E),
                    ),
                  ),
                ),
                if (n > 1) _rotationDots(n, idx),
              ],
            ),
          ),
          _PartnerCard(commerce: partner),
        ],
      ),
    );
  }

  Widget _rotationDots(int n, int active) {
    // Max 5 points pour ne pas surcharger.
    final count = n > 5 ? 5 : n;
    final activeDot = n > 5 ? (active * 5 ~/ n) : active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == activeDot ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: i == activeDot
                  ? const Color(0xFFC79A3E)
                  : const Color(0x33C79A3E),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final CommerceModel commerce;
  const _PartnerCard({required this.commerce});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = commerce.photo.startsWith('http');
    return GestureDetector(
      onTap: () => CommerceRowCard.openDetail(context, commerce),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 240,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              spreadRadius: -4,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: commerce.photo,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Color(0xFF2A1546)),
                errorWidget: (_, __, ___) => _fallback(),
              )
            else
              _fallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0x00000000), Color(0xE0000000)],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Badge PARTENAIRE
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC79A3E),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80C79A3E),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 10, color: Color(0xFF2A1E06)),
                    const SizedBox(width: 3),
                    Text(
                      'PARTENAIRE',
                      style: GoogleFonts.geist(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF2A1E06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Nom + catégorie + ville
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    commerce.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black87)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (commerce.categorie.isNotEmpty) commerce.categorie,
                      if (commerce.ville.isNotEmpty) commerce.ville,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A1D5E), Color(0xFF7B2D8E)],
          ),
        ),
      );
}
