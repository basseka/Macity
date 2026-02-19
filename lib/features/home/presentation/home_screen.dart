import 'dart:async';

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
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_pending_sheet.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/home/presentation/widgets/treasure_hunt_sheet.dart';
import 'package:pulz_app/features/home/presentation/widgets/offer_popup.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';
import 'package:pulz_app/features/offers/presentation/add_offer_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    _offerTimer = Timer(const Duration(seconds: 10), _showOfferPopup);
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    super.dispose();
  }

  void _showOfferPopup() {
    if (!mounted) return;
    final offers = ref.read(activeOffersProvider).valueOrNull ?? [];
    if (offers.isEmpty) return;
    OfferPopup.show(context, offers.first);
  }

  @override
  Widget build(BuildContext context) {
    // Pre-charger le scraping des clubs des le lancement.
    ref.read(nineClubEventsProvider);
    ref.read(etoileEventsProvider);
    // Pre-charger les offres pour que le popup ait les donnees pretes.
    ref.watch(activeOffersProvider);

    final city = ref.watch(selectedCityProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                    // Title
                    Flexible(
                      child: Column(
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
                    const SizedBox(width: 8),
                    _AddEventButton(
                      onTap: _showAddEvent,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // City selector + treasure button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 10),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                const _TreasureBoxButton(),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad banner marquee (hidden in landscape)
                  if (!isLandscape) const AdBannerMarquee(),
                  SizedBox(height: isLandscape ? 6 : 16),

                  // Header + heart button
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
                        _LikeCountButton(
                          onTap: () => _showLikedPlaces(context),
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
                        return _buildModeCard(mode, compact: isLandscape);
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

  static const _modeBackgroundImages = <String, String>{
    'day': 'assets/images/pochette_concert.png',
    'sport': 'assets/images/home_bg_sport.png',
    'culture': 'assets/images/pochette_culture_art.png',
    'food': 'assets/images/pochette_food.png',
    'gaming': 'assets/images/pochette_gaming.png',
    'family': 'assets/images/pochette_enfamille.png',
    'night': 'assets/images/home_bg_night.png',
  };

  Widget _buildModeCard(AppMode mode, {bool compact = false}) {
    final theme = ModeTheme.fromModeName(mode.name);
    final bgImage = _modeBackgroundImages[mode.name];

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
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
            height: compact ? 100 : 160,
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

  void _showInfoPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Bon à savoir \u{1F4A1}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A1259),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('—  ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B2D8E))),
                Flexible(
                  child: Text(
                    'Rajoute un évènement dans ta ville avec le bouton Ajouter \u{1F60A}',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('—  ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B2D8E))),
                Flexible(
                  child: Text(
                    'Like les évènements avec le \u{2764}\u{FE0F} et reçois les notifications de rappel !',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
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

  Future<void> _showAddEvent() async {
    var status = ref.read(proAuthProvider).status;

    // Wait for auth to finish loading
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
        _showProActionChoice();
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

  void _showProActionChoice() {
    showModalBottomSheet(
      context: context,
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
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddEventBottomSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer, color: Color(0xFFE91E8C)),
                title: const Text('Creer une offre promotionnelle'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddOfferBottomSheet(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
}

class _LikeCountButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _LikeCountButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(likesProvider).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0D6F7),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF7B2D8E), width: 1.5),
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
              color: count > 0 ? Colors.red : const Color(0xFF4A1259),
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

class _TreasureBoxButton extends StatefulWidget {
  const _TreasureBoxButton();

  @override
  State<_TreasureBoxButton> createState() => _TreasureBoxButtonState();
}

class _TreasureBoxButtonState extends State<_TreasureBoxButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TreasureHuntSheet.show(context),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) {
          final t = _glow.value;
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ),
              border: Border.all(
                color: const Color(0xFFFFB300),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.3 + t * 0.4),
                  blurRadius: 8 + t * 6,
                  spreadRadius: 1 + t * 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '\u{1F381}',
                style: TextStyle(fontSize: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddEventButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddEventButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
