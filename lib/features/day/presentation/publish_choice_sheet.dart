import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/private_events/presentation/create_private_event_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Feuille de choix déclenchée par « Publier ». Trois voies :
///   • Event privé  → coffre secret sur invitation (gratuit)
///   • Accès Pro    → espace pro (publication illimitée si approuvé)
///   • Event public → publication payante particulier (écran Tarifs + Stripe)
class PublishChoiceSheet extends ConsumerWidget {
  const PublishChoiceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PublishChoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proState = ref.watch(proAuthProvider);
    final isProApproved = proState.status == ProAuthStatus.approved;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Publier un event',
              style: GoogleFonts.geist(
                  color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Choisis le type de publication',
              style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 13)),
          const SizedBox(height: 20),

          // Retour pro : rappelle son palier d'abonnement et l'effet sur le
          // placement de ses events dans le feed.
          if (isProApproved) ...[
            _tierBanner(proState.profile?.subscriptionTier ?? 'normal'),
            const SizedBox(height: 14),
          ],

          _choice(
            emoji: '🔒',
            title: 'Event privé',
            subtitle: 'Coffre secret sur invitation — gratuit',
            gradient: const [Color(0xFFE91E8C), Color(0xFF7B2D8E)],
            onTap: () {
              Navigator.of(context).pop();
              CreatePrivateEventSheet.show(context);
            },
          ),
          const SizedBox(height: 10),
          _choice(
            emoji: '🌍',
            title: 'Event public',
            subtitle: 'Visible par tous — formules à partir de 1,99 €',
            gradient: const [Color(0xFFFF6B00), Color(0xFFE91E63)],
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateEventPage(paidPublicMode: true),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _choice(
            emoji: '👔',
            title: isProApproved ? 'Publier en tant que pro' : 'Accès Pro',
            subtitle: isProApproved
                ? 'Publication illimitée (compte pro validé)'
                : 'Espace professionnel (inscription / connexion)',
            gradient: const [Color(0xFF4A1259), Color(0xFF7B2D8E)],
            onTap: () {
              Navigator.of(context).pop();
              if (isProApproved) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateEventPage()),
                );
              } else {
                showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ProLoginSheet(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Bandeau qui indique au pro son palier et l'effet sur ses publications.
  Widget _tierBanner(String tier) {
    final ({String label, String effet, List<Color> grad}) meta = switch (tier) {
      'premium' => (
          label: '💎 Abonnement Premium',
          effet: 'Tous vos events passent à la une du feed.',
          grad: [Color(0xFF7B2D8E), Color(0xFFA855F7)],
        ),
      'gold' => (
          label: '🥇 Abonnement Gold',
          effet: 'Tous vos events sont mis au top du feed.',
          grad: [Color(0xFFB8860B), Color(0xFFF59E0B)],
        ),
      _ => (
          label: 'Abonnement Normal',
          effet: 'Vos events apparaissent dans le feed standard.',
          grad: [Color(0xFF3A3A3A), Color(0xFF5A5A5A)],
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: meta.grad,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(meta.label,
                    style: GoogleFonts.geist(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(meta.effet,
                    style: GoogleFonts.geist(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.geist(
                          color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.geist(
                          color: AppColors.textDim, fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
