import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/presentation/widgets/swipe_detector.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/core/widgets/mode_video_banner.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_pending_sheet.dart';

class ModeShell extends ConsumerWidget {
  final Widget child;

  const ModeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final city = ref.watch(selectedCityProvider);
    final mode = AppMode.fromName(currentMode);
    final modeIndex = AppMode.order.indexOf(mode);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d MMM', 'fr_FR').format(now);
    final capitalizedDate = dateStr[0].toUpperCase() + dateStr.substring(1);

    // Navigate to the correct route when mode changes
    ref.listen<String>(currentModeProvider, (previous, next) {
      final newMode = AppMode.fromName(next);
      context.go(newMode.routePath);
    });

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: modeTheme.backgroundColor,
      body: SwipeDetector(
        onSwipeLeft: () => ref.read(currentModeProvider.notifier).nextMode(),
        onSwipeRight: () => ref.read(currentModeProvider.notifier).previousMode(),
        child: Column(
          children: [
            // Toolbar with gradient
            Container(
              decoration: BoxDecoration(
                gradient: modeTheme.toolbarGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 10),
                  child: Row(
                    children: [
                      // Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: isLandscape ? 32 : 42,
                          height: isLandscape ? 32 : 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MaCity',
                            style: TextStyle(
                              fontSize: isLandscape ? 18 : 24, fontWeight: FontWeight.bold,
                              color: Colors.white, letterSpacing: 0.06,
                            ),
                          ),
                          if (!isLandscape)
                            Text(
                              'event',
                              style: TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        capitalizedDate,
                        style: TextStyle(
                          fontSize: 13, color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // City selector + heart button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 2 : 6),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CityPickerBottomSheet(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: modeTheme.primaryLightColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: modeTheme.primaryColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold,
                                  color: modeTheme.primaryDarkColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: modeTheme.primaryDarkColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ModeShellAddButton(
                    primaryColor: modeTheme.primaryColor,
                    primaryLightColor: modeTheme.primaryLightColor,
                    primaryDarkColor: modeTheme.primaryDarkColor,
                  ),
                  const SizedBox(width: 8),
                  _ModeShellLikeButton(
                    primaryColor: modeTheme.primaryColor,
                    primaryLightColor: modeTheme.primaryLightColor,
                    primaryDarkColor: modeTheme.primaryDarkColor,
                  ),
                ],
              ),
            ),

            // Mode header: back + arrows + title + dots
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: isLandscape ? 2 : 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation row
                  Row(
                    children: [
                      // Back to home button
                      _buildNavButton(
                        icon: Icons.home_rounded,
                        color: modeTheme.primaryColor,
                        darkColor: modeTheme.primaryDarkColor,
                        onTap: () => context.go('/home'),
                      ),
                      const SizedBox(width: 8),
                      // Left arrow
                      if (modeIndex > 0)
                        _buildNavButton(
                          icon: Icons.chevron_left_rounded,
                          color: modeTheme.primaryColor,
                          darkColor: modeTheme.primaryDarkColor,
                          onTap: () => ref.read(currentModeProvider.notifier).previousMode(),
                        )
                      else
                        const SizedBox(width: 34),
                      const SizedBox(width: 6),
                      // Mode title
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            mode.label,
                            key: ValueKey(currentMode),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: modeTheme.primaryDarkColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Right arrow
                      if (modeIndex < AppMode.order.length - 1)
                        _buildNavButton(
                          icon: Icons.chevron_right_rounded,
                          color: modeTheme.primaryColor,
                          darkColor: modeTheme.primaryDarkColor,
                          onTap: () => ref.read(currentModeProvider.notifier).nextMode(),
                        )
                      else
                        const SizedBox(width: 34),
                    ],
                  ),
                  if (!isLandscape) ...[
                    const SizedBox(height: 8),
                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(AppMode.order.length, (i) {
                        final isActive = i == modeIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: isActive ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: isActive
                                ? LinearGradient(colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor])
                                : null,
                            color: isActive ? null : const Color(0xFFE0E0E0),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Indicator bar
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: modeTheme.chipColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),

            // Video banner (hidden in landscape)
            if (!isLandscape) const ModeVideoBanner(),

            // Child content (mode screen)
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _showLikedPlaces(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LikedPlacesBottomSheet(),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required Color color,
    required Color darkColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, darkColor],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ModeShellAddButton extends ConsumerWidget {
  final Color primaryColor;
  final Color primaryLightColor;
  final Color primaryDarkColor;

  const _ModeShellAddButton({
    required this.primaryColor,
    required this.primaryLightColor,
    required this.primaryDarkColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddEvent(context, ref),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primaryLightColor,
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.add, color: primaryDarkColor, size: 22),
      ),
    );
  }

  Future<void> _showAddEvent(BuildContext context, WidgetRef ref) async {
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
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddEventBottomSheet(),
        );
      case ProAuthStatus.pendingApproval:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProPendingSheet(),
        );
      case ProAuthStatus.notConnected:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ProLoginSheet(),
        );
      case ProAuthStatus.loading:
        break;
    }
  }
}

class _ModeShellLikeButton extends ConsumerWidget {
  final Color primaryColor;
  final Color primaryLightColor;
  final Color primaryDarkColor;

  const _ModeShellLikeButton({
    required this.primaryColor,
    required this.primaryLightColor,
    required this.primaryDarkColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(likesProvider).length;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LikedPlacesBottomSheet(),
      ),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: primaryLightColor,
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              count > 0 ? Icons.favorite : Icons.favorite_border,
              color: count > 0 ? Colors.red : primaryDarkColor,
              size: 20,
            ),
            if (count > 0)
              Positioned(
                top: 4,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 99 ? '99' : '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
