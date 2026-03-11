import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';
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

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pre-load banners so carousel has data ready.
    ref.watch(activeBannersProvider);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1 - Accueil
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              // 2 - Ma Ville (notifications mairie)
              _NavBarItem(
                icon: Icons.account_balance,
                label: 'Ma Ville',
                isActive: false,
                onTap: () => MairieNotificationsSheet.show(context),
              ),
              // 3 - Offres
              _NavBarItem(
                icon: Icons.card_giftcard,
                label: 'Offres',
                isActive: false,
                onTap: () => BannerCarouselDialog.show(context),
              ),
              // 3b - Event (clignotant)
              _PulsingNavBarItem(
                icon: Icons.event,
                label: 'Event',
                onTap: () => TodayEventsSheet.show(context),
              ),
              // 4 - Favoris
              _NavBarItem(
                icon: Icons.favorite,
                label: 'Favoris',
                isActive: ref.watch(likesProvider).isNotEmpty,
                activeColor: Colors.red,
                onTap: () => _showLikedPlaces(context),
              ),
            ],
          ),
        ),
      ),
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
        _showProActionChoice(context);
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

  void _showProActionChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A1259),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.event, color: Color(0xFF7B2D8E)),
                title: const Text('Ajouter un evenement'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddEventBottomSheet(),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.local_offer, color: Color(0xFFE91E8C)),
                title: const Text('Creer une offre promotionnelle'),
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
                leading:
                    const Icon(Icons.tune, color: Color(0xFF4A1259)),
                title: const Text('Mes preferences'),
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
    final color = isActive
        ? (activeColor ?? const Color(0xFF7B2D8E))
        : const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
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
