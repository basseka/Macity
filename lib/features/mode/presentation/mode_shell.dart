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
import 'package:pulz_app/features/home/presentation/widgets/ad_banner_marquee.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('M', style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: Color(0xFF7B2D8E),
                          ),),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'MaCity',
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold,
                              color: Colors.white, letterSpacing: 0.06,
                            ),
                          ),
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

            // City selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

            // Ad banner
            const AdBannerMarquee(),

            // Mode header: back + arrows + title + dots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            // Child content (mode screen)
            Expanded(child: child),
          ],
        ),
      ),
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
