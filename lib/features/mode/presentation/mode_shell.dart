import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/presentation/widgets/swipe_detector.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/core/widgets/mode_video_banner.dart';

class ModeShell extends ConsumerWidget {
  final Widget child;

  const ModeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/home');
          });
        }
      },
      child: Scaffold(
      backgroundColor: modeTheme.backgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
      body: SwipeDetector(
        onSwipeLeft: () => ref.read(currentModeProvider.notifier).nextMode(),
        onSwipeRight: () => ref.read(currentModeProvider.notifier).previousMode(),
        child: SafeArea(
          bottom: false,
          child: Column(
          children: [
            // Logo + search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MaCity',
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.grey.shade400, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Trouve un evenement',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => const AppBottomNavBar().showAddEvent(context, ref),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
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
                            style: GoogleFonts.montserrat(
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

