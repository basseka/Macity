import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/data/inspiration_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/food_design_tokens.dart';
import 'package:pulz_app/features/food/presentation/food_restaurants_fullscreen_map.dart';
import 'package:pulz_app/features/food/presentation/restaurant_detail_sheet.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Écran "Rubrique Food" — refonte hi-fi (handoff mai 2026).
/// Hero vidéo + chips de filtre + carrousel restaurants + inspirations
/// + bannière réservation. Fond papier crème, accents vert sapin / teal.
class FoodRubriqueView extends ConsumerStatefulWidget {
  const FoodRubriqueView({super.key});

  @override
  ConsumerState<FoodRubriqueView> createState() => _FoodRubriqueViewState();
}

class _FoodRubriqueViewState extends ConsumerState<FoodRubriqueView> {
  static const _chips = <_Chip>[
    _Chip('Restaurants', Icons.restaurant_rounded, null),
    _Chip('Guinguette', Icons.deck_rounded, 'Guinguette'),
    _Chip('Buffets', Icons.room_service_rounded, 'Buffet'),
    _Chip('Salon de Thé', Icons.local_cafe_rounded, 'Salon de the'),
    _Chip('Brunch', Icons.egg_alt_rounded, 'Brunch'),
  ];

  String _activeChip = 'Restaurants';
  final Set<String> _saved = {};

  VideoPlayerController? _video;
  String? _videoUrl;
  bool _videoError = false;

  void _initVideo(String url) {
    _videoUrl = url;
    _videoError = false;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    c.setLooping(true);
    c.setVolume(0);
    c.initialize().then((_) {
      if (mounted) {
        c.play();
        setState(() {});
      }
    }).catchError((_) {
      if (mounted) setState(() => _videoError = true);
    });
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<RestaurantVenue> _filtered(List<RestaurantVenue> all) {
    final chip = _chips.firstWhere((c) => c.label == _activeChip);
    if (chip.theme == null) return all;
    return all.where((r) => r.matchesTheme(chip.theme!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsSupabaseProvider);

    return Container(
      color: FoodTokens.bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(
              video: _video,
              videoError: _videoError,
              onInitVideo: _initVideo,
              onDisposeVideo: _disposeVideo,
              currentVideoUrl: _videoUrl,
              onBack: () => context.go('/home'),
              onMapLive: () => ref
                  .read(modeSubcategoriesProvider.notifier)
                  .select('food', FoodRestaurantsFullscreenMap.mapTag),
              onOpenLink: _openLink,
            ),
            const SizedBox(height: 18),
            _chipsRow(),
            _sectionHeader('Restaurants', onSeeAll: () {}),
            restaurantsAsync.when(
              data: (all) {
                final list = _filtered(all);
                if (list.isEmpty) return _emptyCarousel();
                return SizedBox(
                  height: 212,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _RestaurantCard(
                      venue: list[i],
                      coupDeCoeur: i == 0,
                      saved: _saved.contains(list[i].id),
                      onToggleSaved: () => setState(() {
                        final id = list[i].id;
                        _saved.contains(id)
                            ? _saved.remove(id)
                            : _saved.add(id);
                      }),
                      onTap: () => RestaurantDetailSheet.show(
                        context,
                        list[i],
                        siblings: list,
                        index: i,
                      ),
                    ),
                  ),
                );
              },
              loading: () => _loadingCarousel(),
              error: (_, __) => _emptyCarousel(),
            ),
            ..._inspirationsSection(),
            _reservationBanner(),
          ],
        ),
      ),
    );
  }

  // ─── Chips ───────────────────────────────────────────────────────────
  Widget _chipsRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final c = _chips[i];
          final active = c.label == _activeChip;
          return GestureDetector(
            onTap: () => setState(() => _activeChip = c.label),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 9 : 8,
                vertical: active ? 5 : 4,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? FoodTokens.teal : FoodTokens.surface,
                borderRadius: BorderRadius.circular(FoodTokens.rPill),
                border: active
                    ? null
                    : Border.all(color: FoodTokens.stroke, width: 1),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x802BAB9A),
                          blurRadius: 14,
                          spreadRadius: -6,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon,
                      size: 11,
                      color: active ? Colors.white : FoodTokens.ink),
                  const SizedBox(width: 5),
                  Text(
                    c.label,
                    style: FoodTokens.chip(
                      color: active ? Colors.white : FoodTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────
  Widget _sectionHeader(String title,
      {required VoidCallback onSeeAll, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: FoodTokens.sectionHeader(fontSize: fontSize ?? 14),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voir tout',
                  style: FoodTokens.chip(color: FoodTokens.forest),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 16, color: FoodTokens.forest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCarousel() => const SizedBox(
        height: 212,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(FoodTokens.forest),
            ),
          ),
        ),
      );

  Widget _emptyCarousel() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Text(
          'Aucune adresse pour cette sélection.',
          style: FoodTokens.body(),
        ),
      );

  // ─── Inspirations ────────────────────────────────────────────────────
  /// Carrousel dynamique alimente par la table `inspirations` (rubrique='food')
  /// (editee depuis /admin.html). Masque entierement la section — titre
  /// inclus — tant qu'il n'y a aucune carte active pour la ville.
  List<Widget> _inspirationsSection() {
    final items =
        ref.watch(inspirationsProvider('food')).valueOrNull ?? const [];
    if (items.isEmpty) return const [];
    return [
      _sectionHeader('Inspirations du moment',
          onSeeAll: () {}, fontSize: 11.5),
      SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _InspirationCard(
            data: items[i],
            onTap: () => _onInspirationTap(items[i]),
            onOpenSite: () => _openSite(items[i].siteUrl),
          ),
        ),
      ),
    ];
  }

  /// Tap carte : si le thème correspond à un chip Food on bascule le
  /// filtre dessus ; sinon, à défaut, on ouvre le site s'il y en a un.
  void _onInspirationTap(Inspiration insp) {
    final theme = insp.theme.trim();
    if (theme.isNotEmpty) {
      final match = _chips.where((c) =>
          c.theme != null &&
          c.theme!.toLowerCase() == theme.toLowerCase());
      if (match.isNotEmpty) {
        setState(() => _activeChip = match.first.label);
        return;
      }
    }
    _openSite(insp.siteUrl);
  }

  Future<void> _openSite(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ─── Bannière réservation ────────────────────────────────────────────
  Widget _reservationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: FoodTokens.surface,
          borderRadius: BorderRadius.circular(FoodTokens.rCard),
          border: Border.all(color: FoodTokens.hairline, width: 1),
          boxShadow: FoodTokens.banner,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1F2BAB9A),
                borderRadius: BorderRadius.circular(FoodTokens.rIconTile),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  size: 20, color: FoodTokens.forest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Réservez, découvrez, régalez-vous.',
                      style: FoodTokens.bannerTitle()),
                  const SizedBox(height: 2),
                  Text('Les meilleures tables vous attendent.',
                      style: FoodTokens.meta(color: FoodTokens.muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final list =
                    _filtered(ref.read(restaurantsSupabaseProvider).value ?? []);
                if (list.isNotEmpty) {
                  RestaurantDetailSheet.show(context, list.first);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FoodTokens.forest,
                  borderRadius: BorderRadius.circular(FoodTokens.rPill),
                  boxShadow: FoodTokens.ctaPill(),
                ),
                child: Text(
                  'Découvrir',
                  style: FoodTokens.chip(
                      color: Colors.white, w: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip {
  final String label;
  final IconData icon;
  final String? theme; // null = "Restaurants" (tout)
  const _Chip(this.label, this.icon, this.theme);
}


// ─── Hero ──────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final VideoPlayerController? video;
  final bool videoError;
  final String? currentVideoUrl;
  final void Function(String url) onInitVideo;
  final VoidCallback onDisposeVideo;
  final VoidCallback onBack;
  final VoidCallback onMapLive;
  final Future<void> Function(String url) onOpenLink;

  const _Hero({
    required this.video,
    required this.videoError,
    required this.currentVideoUrl,
    required this.onInitVideo,
    required this.onDisposeVideo,
    required this.onBack,
    required this.onMapLive,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Consumer(
      builder: (context, ref, _) {
        final bannerAsync = ref.watch(modeBannerVideoProvider);
        final banner = bannerAsync.asData?.value;
        if (banner != null && currentVideoUrl != banner.videoUrl) {
          onDisposeVideo();
          onInitVideo(banner.videoUrl);
        }
        final c = video;
        final ready = c != null &&
            c.value.isInitialized &&
            !videoError &&
            c.value.size.width > 0;

        return SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vidéo / poster fallback
              if (ready)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A1F14), Color(0xFF7A3B22)],
                    ),
                  ),
                ),

              // Gradient haut (lisibilité status bar)
              const Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient bas (fond → crème)
              const Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x73000000),
                          Color(0xD90B1410),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Top row : back + Map Live
              Positioned(
                top: topPad + 8,
                left: 18,
                right: 18,
                child: Row(
                  children: [
                    _glassCircle(
                      onTap: onBack,
                      child: const Icon(Icons.chevron_left,
                          size: 17, color: FoodTokens.ink),
                    ),
                    const Spacer(),
                    _mapLivePill(onMapLive),
                  ],
                ),
              ),

              // Bloc bas : eyebrow + titre + sous-titre + "En savoir plus"
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Food.', style: FoodTokens.heroTitle()),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 230),
                                child: Text(
                                  'Des restaurants, des saveurs à partager.',
                                  style: FoodTokens.body(
                                      color: Colors.white
                                          .withValues(alpha: 0.78)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (banner?.linkUrl != null) {
                                onOpenLink(banner!.linkUrl!);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  FoodTokens.rPill),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 14, sigmaY: 14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xC70B1410),
                                    borderRadius: BorderRadius.circular(
                                        FoodTokens.rPill),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.14),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'En savoir plus',
                                        style: FoodTokens.chip(
                                            color: Colors.white,
                                            w: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_outward_rounded,
                                          size: 10, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glassCircle({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.96),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }


  Widget _mapLivePill(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FoodTokens.rPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 28,
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            decoration: BoxDecoration(
              color: const Color(0x8C142019),
              borderRadius: BorderRadius.circular(FoodTokens.rPill),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me_rounded,
                    size: 12, color: FoodTokens.teal),
                const SizedBox(width: 5),
                Text(
                  'Map Live',
                  style: FoodTokens.chip(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Carte restaurant ──────────────────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final RestaurantVenue venue;
  final bool coupDeCoeur;
  final bool saved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.venue,
    required this.coupDeCoeur,
    required this.saved,
    required this.onToggleSaved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        venue.photo.isNotEmpty && venue.photo.startsWith('http');
    final cuisine = [
      if (venue.theme.isNotEmpty) venue.theme,
      if (venue.quartier.isNotEmpty) venue.quartier,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FoodTokens.rCard),
          border: Border.all(color: FoodTokens.hairline, width: 1),
          boxShadow: FoodTokens.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: venue.photo,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(
                    color: Color(0xFF2A332D)),
                errorWidget: (_, __, ___) => const _CardGradient(),
              )
            else
              const _CardGradient(),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x59000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xD9000000),
                  ],
                  stops: [0.0, 0.28, 0.45, 1.0],
                ),
              ),
            ),

            if (coupDeCoeur)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  decoration: BoxDecoration(
                    color: FoodTokens.teal,
                    borderRadius: BorderRadius.circular(FoodTokens.rPill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x802BAB9A),
                        blurRadius: 6,
                        spreadRadius: -2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite,
                          size: 5, color: Color(0xFF08221C)),
                      const SizedBox(width: 2),
                      Text('COUP DE CŒUR',
                          style: FoodTokens.tinyTag(
                            color: const Color(0xFF08221C),
                            size: 5,
                            spacing: 0.5,
                            w: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onToggleSaved,
                behavior: HitTestBehavior.opaque,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1),
                      ),
                      child: Icon(
                        saved ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FoodTokens.cardName(),
                  ),
                  if (cuisine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      cuisine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.meta(
                          color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x33FFFFFF), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (venue.style.isNotEmpty) ...[
                          const Icon(Icons.local_dining_rounded,
                              size: 12, color: FoodTokens.amber),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              venue.style,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FoodTokens.meta(
                                  color: Colors.white, w: FontWeight.w600),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (venue.quartier.isNotEmpty) ...[
                          Icon(Icons.location_on_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(width: 4),
                          Text(
                            venue.quartier,
                            style: FoodTokens.meta(
                                color:
                                    Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGradient extends StatelessWidget {
  const _CardGradient();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A332D), Color(0xFF142019)],
          ),
        ),
      );
}

// ─── Carte inspiration ─────────────────────────────────────────────────
class _InspirationCard extends StatelessWidget {
  final Inspiration data;
  final VoidCallback onTap;
  final VoidCallback onOpenSite;
  const _InspirationCard({
    required this.data,
    required this.onTap,
    required this.onOpenSite,
  });

  static const _imgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A1F14), Color(0xFF7A3B22)],
  );

  @override
  Widget build(BuildContext context) {
    final hasSite = data.siteUrl.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 124,
        decoration: BoxDecoration(
          color: FoodTokens.dark,
          borderRadius: BorderRadius.circular(FoodTokens.rInspiration),
          boxShadow: FoodTokens.mini,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 62,
              child: data.photoUrl.trim().isEmpty
                  ? const DecoratedBox(
                      decoration: BoxDecoration(gradient: _imgGradient),
                    )
                  : CachedNetworkImage(
                      imageUrl: data.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const DecoratedBox(
                        decoration: BoxDecoration(gradient: _imgGradient),
                      ),
                      errorWidget: (_, __, ___) => const DecoratedBox(
                        decoration: BoxDecoration(gradient: _imgGradient),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FoodTokens.meta(
                          color: Colors.white, w: FontWeight.w600),
                    ),
                    if (data.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FoodTokens.tinyTag(
                          color: Colors.white.withValues(alpha: 0.62),
                          size: 9.5,
                          spacing: 0,
                          w: FontWeight.w400,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: hasSite ? onOpenSite : onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: FoodTokens.teal,
                          ),
                          child: const Icon(Icons.arrow_outward_rounded,
                              size: 11, color: Color(0xFF08221C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
