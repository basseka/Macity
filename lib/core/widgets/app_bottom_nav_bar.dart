import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';
import 'package:pulz_app/features/home/presentation/home_screen.dart';
import 'package:pulz_app/features/home/presentation/widgets/banner_carousel.dart';
import 'package:pulz_app/features/home/state/banners_provider.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/snap_camera_screen.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_pending_sheet.dart';
import 'package:pulz_app/features/private_events/presentation/create_private_event_sheet.dart';
import 'package:pulz_app/features/home/presentation/today_events_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/mairie_notifications_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';

/// Index global du bouton nav selectionne.
/// 0=Home, 1=Feed, 2=Publier, 3=Explorer, 4=Ma Ville (favoris -> pill HomeQuickPills)
final navBarIndexProvider = StateProvider<int>((ref) => 0);

/// Pop toute route pushee au dessus de la racine (sheet / dialog / etc.)
/// avant d'ouvrir une nouvelle sheet depuis la nav bar. Sans ca, une sheet
/// deja ouverte empeche le switch vers un autre onglet.
void _dismissOpenSheet() {
  final nav = rootNavigatorKey.currentState;
  while (nav != null && nav.canPop()) {
    nav.pop();
  }
}

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, this.currentIndex = 0});

  /// Le context du navigateur root (à l'intérieur du Navigator, pas du builder).
  BuildContext get _navContext => rootNavigatorKey.currentContext!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-load banners so carousel has data ready.
    ref.watch(activeBannersProvider);

    final _selectedIndex = ref.watch(navBarIndexProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // La navbar reste toujours en couleurs claires, peu importe le mode :
    // sur Night, ModeShell bascule AppColors.isLightTheme=false ce qui rendait
    // navBg=AppColors.surface (violet 0xFF1A0F2E). On hardcode pour eviter ce
    // flip selon le mode courant.
    const navBg = Color(0xFFFFFFFF);
    return Material(
      color: navBg,
      elevation: 0,
      child: Container(
      decoration: const BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: Color(0x401A0F2E))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0 - Home (accueil = greeting + carrousels + grille feed)
              // Toujours dispo : depuis n'importe quelle page on retombe sur
              // /home (FeedScreen) ; on pop d'abord les sheets/modales ouvertes.
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _selectedIndex == 0,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 0;
                  final nav = rootNavigatorKey.currentState;
                  if (nav != null) {
                    while (nav.canPop()) {
                      nav.pop();
                    }
                  }
                  appRouter.go('/home');
                },
              ),
              // 1 - Feed (raccourci vers /home — les favoris sont desormais
              // accessibles via la pill "Mes favoris" dans HomeQuickPills).
              _NavBarItem(
                icon: Icons.dynamic_feed_rounded,
                label: 'Feed',
                isActive: _selectedIndex == 1,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 1;
                  final nav = rootNavigatorKey.currentState;
                  if (nav != null) {
                    while (nav.canPop()) {
                      nav.pop();
                    }
                  }
                  appRouter.go('/home');
                },
              ),
              // 2 - + (publier event ou story Map Live) — bouton central
              // proéminent : cercle plein magenta + "Publier" dessous.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 2;
                  _dismissOpenSheet();
                  _showPublishMenu(context, ref);
                },
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF1E6E), Color(0xFFFF5A93)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF1E6E)
                                  .withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Publier',
                        style: GoogleFonts.geist(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.05,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 3 - Favoris (lieux likes)
              _NavBarItem(
                icon: Icons.favorite_rounded,
                label: 'Favoris',
                isActive: _selectedIndex == 3,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 3;
                  _showSheet(const LikedPlacesBottomSheet());
                },
              ),
              // 4 - Ma Ville (mairie notifications sheet)
              _NavBarItem(
                icon: Icons.account_balance,
                label: 'Ma Ville',
                isActive: _selectedIndex == 4,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 4;
                  _showSheet(const MairieNotificationsSheet());
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showSheet(Widget sheet) {
    _dismissOpenSheet();
    showModalBottomSheet(
      context: _navContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  /// Bottom sheet "Publier" : 2 options — event classique OU story Map Live.
  void _showPublishMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: _navContext,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(sheetCtx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Que veux-tu publier ?',
                style: GoogleFonts.geist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              _PublishOptionTile(
                icon: Icons.event_outlined,
                title: 'Publier un event',
                subtitle: 'Concert, soirée, expo, atelier…',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D8B), Color(0xFFA855F7)],
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  // Delegue au gating pro : approved → choice sheet,
                  // pendingApproval → ProPendingSheet, notConnected →
                  // ProLoginSheet (qui propose pro ou soiree privee).
                  showAddEvent(_navContext, ref);
                },
              ),
              const SizedBox(height: 10),
              _PublishOptionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Story Map Live',
                subtitle: 'Photo / vidéo d\'un évent en cours autour de toi',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF472B6), Color(0xFFFBBF24)],
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(_navContext).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SnapCameraScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration:
                          const Duration(milliseconds: 200),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityPickerBottomSheet(),
    );
  }

  void _showLikedPlaces(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LikedPlacesBottomSheet(),
    );
  }

  void _showModeGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeScreenSheet(),
    );
  }

  Future<void> showAddEvent(BuildContext context, WidgetRef ref) async {
    var status = ref.read(proAuthProvider).status;

    if (status == ProAuthStatus.loading) {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!context.mounted) return;
        status = ref.read(proAuthProvider).status;
        if (status != ProAuthStatus.loading) break;
      }
      if (status == ProAuthStatus.loading) {
        status = ProAuthStatus.notConnected;
      }
    }

    if (!context.mounted) return;

    switch (status) {
      case ProAuthStatus.approved:
        // Pro connecte et approuve → push direct la page de creation
        // d'event public.
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateEventPage()),
        );
      case ProAuthStatus.pendingApproval:
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProPendingSheet(),
        );
      case ProAuthStatus.notConnected:
        // Pas connecte pro → 2 choix : soiree privee (sans auth) ou
        // acces pro (login/register).
        _showPrivateOrProChoice(context);
      case ProAuthStatus.loading:
        break;
    }
  }

  /// Sheet "Soirée privée OU Accès pro" affiche au tap "Publier un event"
  /// quand l'utilisateur n'est pas connecte en pro.
  void _showPrivateOrProChoice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(sheetCtx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Quel type d\'event ?',
                style: GoogleFonts.geist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              _PublishOptionTile(
                icon: Icons.lock_outline,
                title: 'Event privé',
                subtitle: 'Entre amis, code d\'accès, pas dans le feed public',
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  CreatePrivateEventSheet.show(_navContext);
                },
              ),
              const SizedBox(height: 10),
              _PublishOptionTile(
                icon: Icons.verified_user_outlined,
                title: 'Accès pro',
                subtitle: 'Publier un event public (lieu, organisateur)',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D8B), Color(0xFFFBBF24)],
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  showModalBottomSheet(
                    context: _navContext,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ProLoginSheet(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProActionChoice(BuildContext context, WidgetRef ref) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Que souhaitez-vous faire ?',
                style: GoogleFonts.geist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.event, color: AppColors.magenta),
                title: Text(
                  'Ajouter un evenement',
                  style: GoogleFonts.geist(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateEventPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.violet,
                ),
                title: Text(
                  'Scanner un flyer (IA)',
                  style: GoogleFonts.geist(color: AppColors.text),
                ),
                subtitle: Text(
                  'Pre-remplit l\'event a partir d\'une photo',
                  style: GoogleFonts.geist(fontSize: 11, color: AppColors.textFaint),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  AddEventBottomSheet.triggerScanFlow(
                    context: context,
                    ref: ref,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer, color: AppColors.magenta),
                title: Text(
                  'Creer une offre promotionnelle',
                  style: GoogleFonts.geist(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddOfferBottomSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune, color: AppColors.cyan),
                title: Text(
                  'Mes preferences',
                  style: GoogleFonts.geist(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  NotificationPrefsSheet.show(context);
                },
              ),
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFFF1E6E) : AppColors.textFaint;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.geist(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.05,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldenNavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GoldenNavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Center(
          child: Icon(icon, color: Colors.black, size: 24),
        ),
      ),
    );
  }
}

class _PulsingNavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PulsingNavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PulsingNavBarItem> createState() => _PulsingNavBarItemState();
}

class _PulsingNavBarItemState extends State<_PulsingNavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _colorAnim = ColorTween(
      begin: const Color(0xFFE91E8C),
      end: const Color(0xFF7B2D8E),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _colorAnim,
        builder: (context, _) {
          final color = _colorAnim.value!;
          return SizedBox(
            width: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: color, size: 22),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


/// Tile colorée pour le menu "Publier" (event ou story Map Live).
class _PublishOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PublishOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.geist(
                      fontSize: 11,
                      color: AppColors.textDim,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textFaint, size: 20),
          ],
        ),
      ),
    );
  }
}
