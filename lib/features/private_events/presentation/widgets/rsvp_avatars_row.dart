import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';

/// Rangee d'avatars superposes (style Instagram). Affiche jusqu'a [maxVisible]
/// cercles + un "+N" si plus.
class RsvpAvatarsRow extends StatelessWidget {
  final List<PrivateEventRsvp> rsvps;
  final int maxVisible;
  final double size;

  const RsvpAvatarsRow({
    super.key,
    required this.rsvps,
    this.maxVisible = 5,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (rsvps.isEmpty) return const SizedBox.shrink();
    final visible = rsvps.take(maxVisible).toList();
    final hidden = rsvps.length - visible.length;
    final overlap = size * 0.35;
    final totalWidth = visible.length * size - (visible.length - 1) * overlap;

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: totalWidth,
            child: Stack(
              children: [
                for (int i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * (size - overlap),
                    child: _avatar(visible[i]),
                  ),
              ],
            ),
          ),
          if (hidden > 0) ...[
            const SizedBox(width: 6),
            Container(
              height: size,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHi,
                borderRadius: BorderRadius.circular(size / 2),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$hidden',
                style: GoogleFonts.geist(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar(PrivateEventRsvp r) {
    final hasPhoto = r.avatarUrl != null && r.avatarUrl!.isNotEmpty;
    final initial = (r.prenom ?? '?').isNotEmpty
        ? r.prenom![0].toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHi,
        border: Border.all(color: AppColors.bg, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? CachedNetworkImage(
              imageUrl: r.avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initialFallback(initial),
              placeholder: (_, __) => _initialFallback(initial),
            )
          : _initialFallback(initial),
    );
  }

  Widget _initialFallback(String initial) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.geist(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
