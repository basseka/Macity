import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/presentation/my_invitations_screen.dart';
import 'package:pulz_app/features/private_events/presentation/my_private_events_screen.dart';
import 'package:pulz_app/features/private_events/state/my_invitations_provider.dart';

/// Raccourcis Home, sur la ligne du bandeau « Les bons plans » : « Events
/// privés » (mes coffres) et « Invitations ». Ouvrent les mêmes écrans que le
/// menu compte ; chacun affiche son message quand la liste est vide.
class HomePrivateButtons extends ConsumerWidget {
  const HomePrivateButtons({super.key});

  Future<void> _push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInvitation =
        (ref.watch(myInvitationsCountProvider).valueOrNull ?? 0) > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HomeShortcut(
          icon: Icons.lock_outline,
          label: context.l10n.homePrivateEvents,
          colors: const [Color(0xFFE91E8C), Color(0xFF7B2D8E)],
          onTap: () => _push(context, const MyPrivateEventsScreen()),
        ),
        const SizedBox(width: 6),
        _HomeShortcut(
          icon: Icons.celebration_outlined,
          label: context.l10n.homeInvitations,
          colors: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
          showBadge: hasInvitation,
          onTap: () async {
            await _push(context, const MyInvitationsScreen());
            // Le point se met à jour au retour (venue annulée, etc.).
            ref.invalidate(myInvitationsCountProvider);
          },
        ),
      ],
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final bool showBadge;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          // Même hauteur que TonightCtaBanner (46).
          width: 66,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.magenta,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
