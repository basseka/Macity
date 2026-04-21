import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          border: Border.all(color: const Color(0xFFE91E8C), width: 1),
          image: DecorationImage(
            image: NetworkImage(avatarUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
        ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCF8FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isProConnected
                      ? (proState.profile?.nom ?? 'Espace pro')
                      : (prenom.isNotEmpty ? 'Bonjour, $prenom' : 'Mon compte'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0A2E),
                  ),
                ),
                if (ville.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        ville,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                ..._buildProActions(ctx, context, ref),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A0A2E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
