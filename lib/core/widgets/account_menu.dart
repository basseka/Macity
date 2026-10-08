import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/language_sheet.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/day/presentation/my_publications_sheet.dart';
import 'package:pulz_app/features/day/presentation/publish_choice_sheet.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';
import 'package:pulz_app/features/offers/presentation/my_offers_screen.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/private_events/presentation/memories_screen.dart';
import 'package:pulz_app/features/private_events/presentation/my_invitations_screen.dart';
import 'package:pulz_app/features/private_events/state/my_invitations_provider.dart';
import 'package:pulz_app/features/private_events/presentation/my_private_events_screen.dart';
import 'package:pulz_app/features/private_events/presentation/open_secret_box_screen.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_venue_edit_sheet.dart';
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
    // Anonyme ("Explorer sans compte") : pas inscrit, pas pro → on lui propose
    // de créer son compte (conversion).
    final showCreateAccount = !isProConnected && !isDeviceRegistered();
    final hasInvitation =
        (ref.read(myInvitationsCountProvider).valueOrNull ?? 0) > 0;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        decoration: BoxDecoration(
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
                      ? (proState.profile?.nom ?? ctx.l10n.accountProSpace)
                      : (prenom.isNotEmpty
                          ? ctx.l10n.accountHello(prenom)
                          : ctx.l10n.accountTitle),
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
                      Icon(Icons.location_on,
                          size: 11, color: AppColors.textFaint),
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
                if (showCreateAccount) ...[
                  _menuItem(
                    ctx: ctx,
                    icon: Icons.person_add_alt_1_rounded,
                    label: ctx.l10n.accountCreate,
                    subtitle: ctx.l10n.accountCreateSubtitle,
                    gradientColors: const [
                      Color(0xFFE91E8C),
                      Color(0xFF7B2D8E)
                    ],
                    onTap: () {
                      Navigator.pop(ctx);
                      appRouter.go('/onboarding');
                    },
                  ),
                  const SizedBox(height: 5),
                ],
                ..._buildProActions(ctx, context, ref),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.add_circle_outline_rounded,
                  label: ctx.l10n.publishEventTitle,
                  subtitle: ctx.l10n.accountPublishSubtitle,
                  gradientColors: const [Color(0xFFFF6B00), Color(0xFFE91E63)],
                  onTap: () {
                    Navigator.pop(ctx);
                    PublishChoiceSheet.show(context);
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.article_rounded,
                  label: ctx.l10n.accountMyPosts,
                  subtitle: ctx.l10n.accountMyPostsSubtitle,
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
                  label: ctx.l10n.accountFavorites,
                  subtitle: ctx.l10n.accountFavoritesSubtitle,
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                  onTap: () {
                    showModalBottomSheet(
                      context: ctx,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          const LikedPlacesBottomSheet(fromAccountMenu: true),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.lock_outline,
                  label: ctx.l10n.accountPrivateEvents,
                  subtitle: ctx.l10n.accountPrivateEventsSubtitle,
                  gradientColors: const [Color(0xFFE91E8C), Color(0xFF7B2D8E)],
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyPrivateEventsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.key,
                  label: ctx.l10n.accountOpenVault,
                  subtitle: ctx.l10n.accountOpenVaultSubtitle,
                  gradientColors: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OpenSecretBoxScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.celebration_outlined,
                  label: ctx.l10n.accountInvitations,
                  subtitle: ctx.l10n.accountInvitationsSubtitle,
                  gradientColors: const [Color(0xFF00B4D8), Color(0xFF48CAE4)],
                  showBadge: hasInvitation,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyInvitationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.auto_awesome,
                  label: ctx.l10n.accountMemories,
                  subtitle: ctx.l10n.accountMemoriesSubtitle,
                  gradientColors: const [Color(0xFFFF9F43), Color(0xFFE91E8C)],
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MemoriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.tune_rounded,
                  label: ctx.l10n.accountProfile,
                  subtitle: ctx.l10n.accountProfileSubtitle,
                  gradientColors: const [Color(0xFF4A1259), Color(0xFF6B2D7B)],
                  onTap: () {
                    NotificationPrefsSheet.show(ctx, fromAccountMenu: true);
                  },
                ),
                const SizedBox(height: 5),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.translate_rounded,
                  label: ctx.l10n.accountLanguage,
                  subtitle: _currentLanguageLabel(ctx, ref),
                  gradientColors: const [Color(0xFF0077B6), Color(0xFF00B4D8)],
                  onTap: () => LanguageSheet.show(ctx),
                ),
                const SizedBox(height: 8),
                _buildConnectionButton(ctx, context, ref),
                if (isProConnected) ...[
                  const SizedBox(height: 5),
                  _buildDeleteAccountButton(ctx, context, ref),
                ] else if (isDeviceRegistered()) ...[
                  const SizedBox(height: 5),
                  _buildDeleteNormalAccountButton(ctx, context, ref),
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

    final proName = proState.profile?.nom ?? ctx.l10n.accountProSpace;
    final statusLabel = proState.status == ProAuthStatus.approved
        ? ctx.l10n.accountProApproved
        : ctx.l10n.accountProPending;
    return [
      _menuItem(
        ctx: ctx,
        icon: Icons.store_rounded,
        label: proName,
        subtitle: proState.status == ProAuthStatus.approved
            ? ctx.l10n.accountProEditListing
            : statusLabel,
        gradientColors: const [Color(0xFF7B2D8E), Color(0xFF9B4DCA)],
        onTap: proState.status == ProAuthStatus.approved
            ? () {
                Navigator.pop(ctx);
                ProVenueEditSheet.show(rootContext);
              }
            : () {},
      ),
      if (proState.status == ProAuthStatus.approved) ...[
        const SizedBox(height: 5),
        _menuItem(
          ctx: ctx,
          icon: Icons.event_rounded,
          label: ctx.l10n.proAddEvent,
          subtitle: ctx.l10n.proAddEventSubtitle,
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
          icon: Icons.local_offer_rounded,
          label: ctx.l10n.accountCreateOffer,
          subtitle: ctx.l10n.accountCreateOfferSubtitle,
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
        const SizedBox(height: 5),
        _menuItem(
          ctx: ctx,
          icon: Icons.list_alt_rounded,
          label: ctx.l10n.accountMyOffers,
          subtitle: ctx.l10n.accountMyOffersSubtitle,
          gradientColors: const [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(rootContext).push(
              MaterialPageRoute(
                builder: (_) => const MyOffersScreen(),
              ),
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
        label: ctx.l10n.accountLogout,
        subtitle: ctx.l10n.accountLogoutSubtitle,
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
      label: ctx.l10n.proAccessTitle,
      subtitle: ctx.l10n.accountProAccessSubtitle,
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
      label: ctx.l10n.accountDelete,
      subtitle: ctx.l10n.accountDeleteSubtitle,
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
        title: Text(
          ctx.l10n.accountDeleteDialogTitle,
          style: TextStyle(color: AppColors.text, fontSize: 16),
        ),
        content: Text(
          ctx.l10n.accountDeleteProDialogBody,
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              dialogCtx.l10n.commonCancel,
              style: TextStyle(color: AppColors.textFaint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              dialogCtx.l10n.commonDelete,
              style: TextStyle(
                  color: Color(0xFFE91E8C), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(rootContext);
    final deletedMsg = ctx.l10n.accountDeleted;
    final failedMsg = ctx.l10n.accountDeleteFailed;
    Navigator.pop(ctx);
    try {
      await ref.read(proAuthProvider.notifier).deleteAccount();
      messenger.showSnackBar(
        SnackBar(content: Text(deletedMsg)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(failedMsg)),
      );
    }
  }

  /// Bouton "Supprimer mon compte" pour un utilisateur NORMAL inscrit (RGPD +
  /// exigence stores). Distinct du flux pro.
  static Widget _buildDeleteNormalAccountButton(
    BuildContext ctx,
    BuildContext rootContext,
    WidgetRef ref,
  ) {
    return _menuItem(
      ctx: ctx,
      icon: Icons.delete_forever_rounded,
      label: ctx.l10n.accountDelete,
      subtitle: ctx.l10n.accountDeleteSubtitle,
      gradientColors: const [Color(0xFF8B0000), Color(0xFFB91C1C)],
      onTap: () => _confirmDeleteNormalAccount(ctx, rootContext),
    );
  }

  static Future<void> _confirmDeleteNormalAccount(
    BuildContext ctx,
    BuildContext rootContext,
  ) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          ctx.l10n.accountDeleteDialogTitle,
          style: TextStyle(color: AppColors.text, fontSize: 16),
        ),
        content: Text(
          ctx.l10n.accountDeleteUserDialogBody,
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child:
                Text(dialogCtx.l10n.commonCancel,
                    style: TextStyle(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              dialogCtx.l10n.commonDelete,
              style: TextStyle(
                  color: Color(0xFFE91E8C), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(rootContext);
    final deletedMsg = ctx.l10n.accountDeleted;
    final failedMsg = ctx.l10n.accountDeleteFailed;
    Navigator.pop(ctx);
    try {
      await UserProfileService().deleteMyAccount();
      // Re-verrouille l'app sur l'onboarding et repart de zéro.
      await resetRegistration();
      resetOnboardingCache();
      appRouter.go('/onboarding');
      messenger.showSnackBar(
        SnackBar(content: Text(deletedMsg)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(failedMsg)),
      );
    }
  }

  /// Sous-titre de l'entree Langue : la langue choisie, ou "Automatique".
  static String _currentLanguageLabel(BuildContext ctx, WidgetRef ref) {
    final locale = ref.read(localeProvider);
    if (locale == null) return ctx.l10n.languageSystem;
    return kAppLanguages[locale.languageCode] ?? ctx.l10n.languageSystem;
  }

  static Widget _menuItem({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return _MenuItemCard(
      icon: icon,
      label: label,
      subtitle: subtitle,
      gradientColors: gradientColors,
      onTap: onTap,
      pulse: showBadge,
    );
  }
}

/// Carte de _menuItem, extraite en widget pour pouvoir clignoter (fond,
/// bordure, halo) quand [pulse] est actif : le petit point sur l'icone seul
/// etait trop discret (signale) pour "Mes invitations" quand une soiree a
/// venir attend une confirmation "Je viens".
class _MenuItemCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool pulse;

  const _MenuItemCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    this.pulse = false,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c == null) return _buildCard(0);
    return AnimatedBuilder(
      animation: _c!,
      builder: (_, __) => _buildCard(_c!.value),
    );
  }

  Widget _buildCard(double t) {
    final accent = widget.gradientColors[0];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            color: widget.pulse
                ? Color.lerp(AppColors.surfaceHi,
                    accent.withValues(alpha: 0.28), t)
                : AppColors.surfaceHi,
            border: Border.all(
              color: widget.pulse
                  ? accent.withValues(alpha: 0.4 + t * 0.6)
                  : AppColors.line,
              width: widget.pulse ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(
                    alpha: widget.pulse ? 0.18 + t * 0.5 : 0.18),
                blurRadius: widget.pulse ? 10 + t * 10 : 10,
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
                    colors: widget.gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors[0].withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.geist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.geist(
                        fontSize: 9,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
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
