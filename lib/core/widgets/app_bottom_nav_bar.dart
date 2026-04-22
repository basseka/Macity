import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_pending_sheet.dart';
import 'package:pulz_app/features/home/presentation/today_events_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/mairie_notifications_sheet.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';

/// Index global du bouton nav selectionne.
/// 0=Accueil, 1=MaVille, 2=Offres, 3=Explorer, 4=Favoris
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

    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
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
              // 1 - Accueil
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
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
              // 2 - Ma Ville
              _NavBarItem(
                icon: Icons.account_balance,
                label: 'Ma Ville',
                isActive: _selectedIndex == 1,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 1;
                  _showSheet(const MairieNotificationsSheet());
                },
              ),
              // 3 - Offres
              _NavBarItem(
                icon: Icons.card_giftcard,
                label: 'Offres',
                isActive: _selectedIndex == 2,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 2;
                  _dismissOpenSheet();
                  BannerCarouselDialog.show(_navContext);
                },
              ),
              // 4 - Explorer
              _NavBarItem(
                icon: Icons.search,
                label: 'Explorer',
                isActive: _selectedIndex == 3,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 3;
                  _showSheet(const HomeScreenSheet());
                },
              ),
              // 5 - Favoris
              _NavBarItem(
                icon: Icons.favorite,
                label: 'Favoris',
                isActive: _selectedIndex == 4,
                onTap: () {
                  ref.read(navBarIndexProvider.notifier).state = 4;
                  _showSheet(const LikedPlacesBottomSheet());
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
        _showProActionChoice(context, ref);
      case ProAuthStatus.pendingApproval:
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProPendingSheet(),
        );
      case ProAuthStatus.notConnected:
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProLoginSheet(),
        );
      case ProAuthStatus.loading:
        break;
    }
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
        decoration: const BoxDecoration(
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
    final color = isActive ? AppColors.text : AppColors.textFaint;

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
