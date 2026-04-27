import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/my_publications_sheet.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class AccountMenu {
  AccountMenu._();

  static Widget buildButton({WidgetRef? ref, double size = 22}) {
    final iconSize = size * 0.64;
    final avatarUrl = ref?.watch(userAvatarUrlProvider).valueOrNull;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.magenta, width: 1.5),
          image: DecorationImage(
            image: NetworkImage(avatarUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: AppShadows.neon(AppColors.magenta, blur: 6, y: 2),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primary,
        boxShadow: AppShadows.neon(AppColors.magenta, blur: 8, y: 2),
      ),
      child: Icon(Icons.person, color: Colors.white, size: iconSize),
    );
  }

  static void show(BuildContext context, WidgetRef ref) {
    final villeAsync = ref.read(userVilleProvider);
    final ville = villeAsync.valueOrNull ?? '';
    final prenom = ref.read(userPrenomProvider).valueOrNull ?? '';
    final proState = ref.read(proAuthProvider);
    final isProConnected = proState.status == ProAuthStatus.approved ||
        proState.status == ProAuthStatus.pendingApproval;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isProConnected
                      ? (proState.profile?.nom ?? 'Espace pro')
                      : (prenom.isNotEmpty ? 'Bonjour, $prenom' : 'Mon compte'),
                  style: GoogleFonts.geist(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                  ),
                ),
                if (ville.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 11, color: AppColors.textFaint),
                      const SizedBox(width: 3),
                      Text(
                        ville,
                        style: GoogleFonts.geistMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                ..._buildProActions(ctx, context, ref),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.article_rounded,
                  label: 'Mes publications',
                  subtitle: 'Mes evenements crees',
                  gradientColors: const [Color(0xFF00B894), Color(0xFF00CEC9)],
                  onTap: () {
                    // Stack sur l'AccountMenu → le chevron retour ramene ici
                    MyPublicationsSheet.show(ctx, fromAccountMenu: true);
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.favorite_rounded,
                  label: 'Mes Favoris',
                  subtitle: 'Lieux et events aimes',
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                  onTap: () {
                    showModalBottomSheet(
                      context: ctx,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const LikedPlacesBottomSheet(fromAccountMenu: true),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.tune_rounded,
                  label: 'Mon profil',
                  subtitle: 'Ville, centres d\'interet',
                  gradientColors: const [Color(0xFF4A1259), Color(0xFF6B2D7B)],
                  onTap: () {
                    NotificationPrefsSheet.show(ctx, fromAccountMenu: true);
                  },
                ),
                const SizedBox(height: 8),
                _buildConnectionButton(ctx, context, ref),
                if (isProConnected) ...[
                  const SizedBox(height: 5),
                  _buildDeleteAccountButton(ctx, context, ref),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Actions pro (infos compte, creer event/offre) — sans le bouton connexion/deconnexion.
  static List<Widget> _buildProActions(
    BuildContext ctx,
    BuildContext rootContext,
    WidgetRef ref,
  ) {
    final proState = ref.read(proAuthProvider);
    final isConnected = proState.status == ProAuthStatus.approved ||
        proState.status == ProAuthStatus.pendingApproval;

    if (!isConnected) return [];

    final proName = proState.profile?.nom ?? 'Espace pro';
    final statusLabel = proState.status == ProAuthStatus.approved
        ? 'Compte valide'
        : 'En attente de validation';
    return [
      _menuItem(
        ctx: ctx,
        icon: Icons.store_rounded,
        label: proName,
        subtitle: statusLabel,
        gradientColors: const [Color(0xFF7B2D8E), Color(0xFF9B4DCA)],
        onTap: () {},
      ),
      if (proState.status == ProAuthStatus.approved) ...[
        const SizedBox(height: 5),
        _menuItem(
          ctx: ctx,
          icon: Icons.event_rounded,
          label: 'Ajouter un evenement',
          subtitle: 'Publier un nouvel event',
          gradientColors: const [Color(0xFF4A1259), Color(0xFF7B2D8E)],
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(rootContext).push(
              MaterialPageRoute(
                builder: (_) => const CreateEventPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        _menuItem(
          ctx: ctx,
          icon: Icons.auto_awesome_rounded,
          label: 'Scanner un flyer (IA)',
          subtitle: 'Pre-remplit l\'event depuis une photo',
          gradientColors: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
          onTap: () {
            Navigator.pop(ctx);
            AddEventBottomSheet.triggerScanFlow(
              context: rootContext,
              ref: ref,
            );
          },
        ),
        const SizedBox(height: 5),
        _menuItem(
          ctx: ctx,
          icon: Icons.local_offer_rounded,
          label: 'Creer une offre',
          subtitle: 'Publier une offre promotionnelle',
          gradientColors: const [Color(0xFFFF6EB4), Color(0xFFFFD54F)],
          onTap: () {
            Navigator.pop(ctx);
            showModalBottomSheet(
              context: rootContext,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddOfferBottomSheet(),
            );
          },
        ),
      ],
    ];
  }

  /// Bouton Connexion / Deconnexion — toujours en bas du menu.
  static Widget _buildConnectionButton(
    BuildContext ctx,
    BuildContext rootContext,
    WidgetRef ref,
  ) {
    final proState = ref.read(proAuthProvider);
    final isConnected = proState.status == ProAuthStatus.approved ||
        proState.status == ProAuthStatus.pendingApproval;

    if (isConnected) {
      return _menuItem(
        ctx: ctx,
        icon: Icons.logout_rounded,
        label: 'Deconnexion',
        subtitle: 'Se deconnecter du compte pro',
        gradientColors: const [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
        onTap: () {
          Navigator.pop(ctx);
          ref.read(proAuthProvider.notifier).disconnect();
        },
      );
    }

    return _menuItem(
      ctx: ctx,
      icon: Icons.login_rounded,
      label: 'Connexion',
      subtitle: 'Espace professionnel',
      gradientColors: const [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
      onTap: () {
        Navigator.pop(ctx);
        showModalBottomSheet(
          context: rootContext,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProLoginSheet(),
        );
      },
    );
  }

  /// Bouton "Supprimer mon compte" (RGPD). Visible uniquement pour les pros
  /// connectes. Confirmation modale obligatoire avant l'appel destructeur.
  static Widget _buildDeleteAccountButton(
    BuildContext ctx,
    BuildContext rootContext,
    WidgetRef ref,
  ) {
    return _menuItem(
      ctx: ctx,
      icon: Icons.delete_forever_rounded,
      label: 'Supprimer mon compte',
      subtitle: 'Action definitive et irreversible',
      gradientColors: const [Color(0xFF8B0000), Color(0xFFB91C1C)],
      onTap: () => _confirmDeleteAccount(ctx, rootContext, ref),
    );
  }

  static Future<void> _confirmDeleteAccount(
    BuildContext ctx,
    BuildContext rootContext,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Supprimer votre compte ?',
          style: TextStyle(color: AppColors.text, fontSize: 16),
        ),
        content: const Text(
          'Cette action est definitive. Vos donnees pro seront supprimees '
          'et vous ne pourrez plus vous connecter avec cet email. '
          'Vous pourrez creer un nouveau compte plus tard si besoin.',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textFaint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFE91E8C), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(rootContext);
    Navigator.pop(ctx);
    try {
      await ref.read(proAuthProvider.notifier).deleteAccount();
      messenger.showSnackBar(
        const SnackBar(content: Text('Compte supprime')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Echec de la suppression — reessayez')),
      );
    }
  }

  static Widget _menuItem({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: AppColors.surfaceHi,
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.geist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.geist(
                        fontSize: 9,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textFaint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
