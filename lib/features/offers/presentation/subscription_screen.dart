import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';

/// Ecran de proposition d'abonnement BeThere — 5.90 EUR/mois pour debloquer
/// toutes les offres premium.
///
/// Lance depuis OfferDetailScreen quand l'utilisateur tap "J'en profite".
/// Le CTA "S'abonner" est un placeholder : le branchement paiement (Apple IAP
/// pour iOS, Google Billing pour Android) sera fait dans un second temps.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _benefits = <_Benefit>[
    _Benefit(
      icon: Icons.lock_open_rounded,
      title: 'Toutes les offres premium debloquees',
      subtitle: 'Cafe offert, reductions, places de concert, experiences...',
    ),
    _Benefit(
      icon: Icons.local_fire_department_rounded,
      title: 'Nouvelles offres chaque semaine',
      subtitle: 'Selectionnees par BeThere chez les meilleurs commerces.',
    ),
    _Benefit(
      icon: Icons.cancel_rounded,
      title: 'Annulable a tout moment',
      subtitle: 'Sans engagement. Tu arretes quand tu veux.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: Stack(
        children: [
          // ─── Fond avec degrade ───
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF2D1B4E),
                  Color(0xFF1A0A2E),
                ],
              ),
            ),
          ),

          // ─── Contenu scrollable ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Header : close button a droite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // Badge "BeThere Premium"
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  EditorialColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: EditorialColors.gold
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: EditorialColors.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'BeThere Premium',
                                  style: GoogleFonts.geist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: EditorialColors.gold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Titre hero
                          Text(
                            'Profite des meilleures\noffres de ta ville.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.geist(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            'Un abonnement, des centaines d\'offres premium\nselectionnees chez les commerces partenaires.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.geist(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Prix hero
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  EditorialColors.gold.withValues(alpha: 0.18),
                                  EditorialColors.gold.withValues(alpha: 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: EditorialColors.gold
                                    .withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '5',
                                      style: GoogleFonts.geist(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w800,
                                        color: EditorialColors.gold,
                                        height: 1.0,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Text(
                                        ',90',
                                        style: GoogleFonts.geist(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: EditorialColors.gold,
                                          height: 1.0,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, left: 4),
                                      child: Text(
                                        '€',
                                        style: GoogleFonts.geist(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: EditorialColors.gold,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'par mois',
                                  style: GoogleFonts.geist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Liste des benefices
                          for (final b in _benefits) ...[
                            _BenefitRow(benefit: b),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 16),
                          // Legal mini
                          Text(
                            'Renouvellement automatique. Annulable a tout moment depuis les reglages.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.geist(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.45),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── CTA S'abonner ───
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: brancher Apple IAP (iOS) / Google Billing
                        // (Android). Apple impose IAP pour les abonnements
                        // digitaux consommes dans l'app -> 30%/15% commission.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Paiement bientot disponible'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EditorialColors.gold,
                        foregroundColor: const Color(0xFF1A0A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'S\'abonner pour 5,90€/mois',
                        style: GoogleFonts.geist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Plus tard',
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;

  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: EditorialColors.gold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: EditorialColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            benefit.icon,
            color: EditorialColors.gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefit.title,
                style: GoogleFonts.geist(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                benefit.subtitle,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
