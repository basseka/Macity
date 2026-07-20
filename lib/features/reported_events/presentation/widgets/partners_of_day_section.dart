import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/reported_events/data/partners_of_day_service.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/tonight_events_sheet.dart';

/// Sous « En direct autour de vous » : 6 encarts « du jour », un par rubrique,
/// chacun mettant en avant UN partenaire. S'il y en a plusieurs, ils tournent
/// toutes les 5 s (temps d'antenne égal, rotation déterministe sur l'horloge
/// → tous les utilisateurs voient le même au même moment). Encart masqué si la
/// rubrique n'a aucun partenaire dans la ville sélectionnée.
class PartnersOfDaySection extends ConsumerStatefulWidget {
  const PartnersOfDaySection({super.key});

  @override
  ConsumerState<PartnersOfDaySection> createState() =>
      _PartnersOfDaySectionState();
}

class _PartnersOfDaySectionState extends ConsumerState<PartnersOfDaySection> {
  static const _rotation = Duration(seconds: 5);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rafraîchit l'affichage à chaque créneau de 5 s pour faire tourner les
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rubriques) _rubriqueBlock(r),
        // ─── 3 bulles fixes (style stripe), après « Le moment évasion » ───
        _bubblesRow(),
      ],
    );
  }

  /// Rangée de 3 bulles fixes, dans le style des stories du bandeau.
  Widget _bubblesRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bubble(
            label: 'Quoi faire ce soir',
            onTap: () => TonightEventsSheet.show(context),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
                ),
              ),
              child: Center(
                child: Icon(Icons.nightlife_rounded, color: Colors.white, size: 42),
              ),
            ),
          ),
          _bubble(
            label: 'La Dépêche du Midi',
            external: true,
            onTap: () => _openUrl('https://www.ladepeche.fr'),
            child: ColoredBox(
              color: const Color(0xFFED1C24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/images/depeche-midi.png', fit: BoxFit.contain),
              ),
            ),
          ),
          _bubble(
            label: 'Toulouse FM',
            external: true,
            onTap: () => _openUrl('https://www.toulousefm.fr'),
            child: ColoredBox(
              color: const Color(0xFFEE0F8B),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/images/toulouse-fm.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Une bulle carrée arrondie + libellé dessous (comme les stories du bandeau).
  Widget _bubble({
    required Widget child,
    required String label,
    required VoidCallback onTap,
    bool external = false,
  }) {
    const size = 84.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x22000000), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          spreadRadius: -3,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  if (external)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.north_east_rounded,
                            size: 12, color: Color(0xFF1A0F2E)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: const Color(0xFF1A0F2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _rubriqueBlock(PartnerRubrique r) {
    final n = r.partners.length;
    final idx = n == 0 ? 0 : _slot % n;
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
          _PartnerCard(commerces: r.partners, index: idx),
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
  /// Tous les partenaires de la rubrique (pour swiper entre eux dans la fiche).
  final List<CommerceModel> commerces;
  final int index;
  const _PartnerCard({required this.commerces, required this.index});

  @override
  Widget build(BuildContext context) {
    final commerce = commerces[index];
    final hasPhoto = commerce.photo.startsWith('http');
    return GestureDetector(
      onTap: () => CommerceRowCard.openDetail(
        context,
        commerce,
        siblings: commerces,
        index: index,
      ),
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
