import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/contributor_profile_sheet.dart';

/// Palette fixe (sombre), voir _CoffreColors dans open_secret_box_screen.dart
/// et my_invitations_screen.dart : ce widget est utilise exclusivement par
/// les ecrans coffre/invitations, qui doivent garder le meme rendu quelle
/// que soit la rubrique visitee juste avant (AppColors.isLightTheme global).
class _CoffreColors {
  static const bg = Color(0xFF0A0514);
  static const surfaceHi = Color(0xFF241640);
  static const text = Color(0xFFF5F0FF);
  static const line = Color(0x12FFFFFF);
}

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
                    child: GestureDetector(
                      onTap: () => ContributorProfileSheet.show(
                        context,
                        userId: visible[i].userId,
                        fallbackPrenom: visible[i].prenom?.trim() ?? '',
                        fallbackAvatarUrl: visible[i].avatarUrl,
                      ),
                      child: _avatar(visible[i]),
                    ),
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
                color: _CoffreColors.surfaceHi,
                borderRadius: BorderRadius.circular(size / 2),
                border: Border.all(color: _CoffreColors.line),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$hidden',
                style: GoogleFonts.geist(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _CoffreColors.text,
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
    final prenom = r.prenom?.trim() ?? '';
    final initial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _CoffreColors.surfaceHi,
        border: Border.all(color: _CoffreColors.bg, width: 2),
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
