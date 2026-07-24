import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Garde-fou de publication : les actions qui créent du contenu (publier un
/// event, poster une story/live) sont réservées aux utilisateurs INSCRITS.
/// Les anonymes ("Explorer sans compte") sont interceptés et invités à créer
/// leur compte (→ onboarding).
class AccountGate {
  /// Retourne true si l'action peut continuer (device inscrit). Sinon affiche
  /// une invitation à créer un compte et retourne false.
  static bool requirePublish(BuildContext context, {required String action}) {
    if (isDeviceRegistered()) return true;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccountNudge(action: action),
    );
    return false;
  }
}

class _AccountNudge extends StatelessWidget {
  final String action;
  const _AccountNudge({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('🔒', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text(
                'Crée ton compte pour $action',
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ça prend 30 secondes. Tu débloques aussi tes favoris et tes récompenses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  color: AppColors.textDim,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    appRouter.go('/onboarding');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E8C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Créer mon compte',
                    style: GoogleFonts.geist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Plus tard',
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    color: AppColors.textFaint,
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
