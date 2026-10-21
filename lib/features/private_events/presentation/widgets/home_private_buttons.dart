import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/features/private_events/presentation/my_invitations_screen.dart';
import 'package:pulz_app/features/private_events/presentation/my_private_events_screen.dart';
import 'package:pulz_app/features/private_events/state/my_invitations_provider.dart';

/// Raccourcis Home, en pastilles dans le bandeau sombre du haut (piste C) :
/// « Events privés » (mes coffres) et « Invitations » avec le nombre
/// d'invitations en cours. Ouvrent les mêmes écrans que le menu compte ;
/// chacun affiche son message quand la liste est vide. Sur la même ligne que
/// le bouton bons plans : les pastilles prennent sa hauteur et rétrécissent
/// (libellé tronqué) plutôt que de déborder.
class HomePrivateButtons extends ConsumerWidget {
  const HomePrivateButtons({super.key});

  Future<void> _push(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myInvitationsCountProvider).valueOrNull ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: _HomeShortcut(
            icon: Icons.lock_outline,
            label: context.l10n.homePrivateEvents,
            onTap: () => _push(context, const MyPrivateEventsScreen()),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: _HomeShortcut(
            icon: Icons.mail_outline_rounded,
            label: context.l10n.homeInvitations,
            count: invitations,
            onTap: () async {
              await _push(context, const MyInvitationsScreen());
              // Le badge se met à jour au retour (venue annulée, etc.).
              ref.invalidate(myInvitationsCountProvider);
            },
          ),
        ),
      ],
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
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
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8177A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
