import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
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
    showNudge(context, action: action);
    return false;
  }

  /// Affiche l'invitation a creer un compte. [beforeSignup] est appele juste
  /// avant d'aller sur l'onboarding (ex : memoriser ou revenir ensuite).
  static void showNudge(
    BuildContext context, {
    required String action,
    Future<void> Function()? beforeSignup,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _AccountNudge(action: action, beforeSignup: beforeSignup),
    );
  }
}

class _AccountNudge extends StatelessWidget {
  final String action;
  final Future<void> Function()? beforeSignup;
  const _AccountNudge({required this.action, this.beforeSignup});

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
                context.l10n.gateTitle(_actionLabel(context, action)),
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.gateBody,
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
                  onPressed: () async {
                    Navigator.pop(context);
                    await beforeSignup?.call();
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
                    context.l10n.accountCreate,
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
                  context.l10n.commonLater,
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

/// Action passee en francais par les appelants ('publier un event'...).
String _actionLabel(BuildContext context, String action) => switch (action) {
      'publier un event' => context.l10n.gateActionPublishEvent,
      'poster une story' => context.l10n.gateActionPostStory,
      'participer a la discussion' => context.l10n.gateActionChat,
      'confirmer ta venue' => context.l10n.gateActionConfirm,
      'ajouter des photos' => context.l10n.gateActionAddPhotos,
      _ => action,
    };
