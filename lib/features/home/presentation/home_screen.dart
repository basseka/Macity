import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/presentation/widgets/ad_banner_marquee.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FA),
      body: Column(
        children: [
          // Toolbar with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A1259), Color(0xFF7B2D8E), Color(0xFFE91E8C)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title
                    Flexible(
                      child: Column(
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
                            'Tous les évènements dans ta ville',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ShimmerInfoButton(
                      onTap: () => _showInfoPopup(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // City selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GestureDetector(
              onTap: () => _showCityPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0D6F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7B2D8E), width: 1.5),
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
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: Color(0xFF4A1259),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF4A1259)),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad banner marquee
                  const AdBannerMarquee(),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Que faire aujourd\'hui ?',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF7B2D8E),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddEvent(context),
                          child: _buildHeaderButton('Ajouter', const Color(0xFF7B2D8E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode cards (vertical stack)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: AppMode.order.map((mode) {
                        return _buildModeCard(context, ref, mode);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _modeBackgroundImages = {
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.png',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.png',
    'family': 'assets/images/pochette_enfamille.png',
    'night': 'assets/images/home_bg_night.png',
  };

  Widget _buildModeCard(BuildContext context, WidgetRef ref, AppMode mode) {
    final theme = ModeTheme.fromModeName(mode.name);
    final bgImage = _modeBackgroundImages[mode.name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0x207B2D8E),
          onTap: () {
            ref.read(currentModeProvider.notifier).setMode(mode.name);
            context.go(mode.routePath);
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: bgImage == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.primaryDarkColor, theme.primaryColor],
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // Background image
                if (bgImage != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        bgImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Dark overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                // Content
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mode.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme.subtitleString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _showInfoPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
          'Toi aussi rajoute un évènement dans ta ville en utilisant le bouton Ajouter \u{1F60A}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityPickerBottomSheet(),
    );
  }

  void _showAddEvent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEventBottomSheet(),
    );
  }
}

class _ShimmerInfoButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ShimmerInfoButton({required this.onTap});

  @override
  State<_ShimmerInfoButton> createState() => _ShimmerInfoButtonState();
}

class _ShimmerInfoButtonState extends State<_ShimmerInfoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: _opacity.value * 0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.help_outline, color: Colors.white, size: 26),
              ),
            ),
          );
        },
      ),
    );
  }
}
