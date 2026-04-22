import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/likes/data/liked_item_resolver.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';
import 'package:pulz_app/features/likes/presentation/liked_item_detail_sheet.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

class LikedPlacesBottomSheet extends ConsumerWidget {
  const LikedPlacesBottomSheet({super.key, this.fromAccountMenu = false});

  final bool fromAccountMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedIds = ref.watch(likesProvider);
    final items = likedIds.toList()..sort();
    final metaAsync = ref.watch(likesMetaProvider);
    final meta = metaAsync.valueOrNull ?? {};

    // Build a lookup map from live events data for fallback resolution
    final eventsData = ref.watch(todayTomorrowEventsProvider).valueOrNull;
    final eventsById = <String, Event>{};
    if (eventsData != null) {
      for (final e in eventsData.events) {
        if (e.identifiant.isNotEmpty) {
          eventsById[e.identifiant] = e;
        }
      }
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: _StarryBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle + retour (si depuis le menu compte)
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (fromAccountMenu)
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 26),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Retour',
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mes favoris',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E8C).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grid
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border, size: 44,
                          color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun favori',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aime des events pour les retrouver ici',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final id = items[index];
                      var effectiveMeta = meta[id];
                      final liveEvent = eventsById[id];
                      if (effectiveMeta == null && liveEvent != null) {
                        effectiveMeta = LikeMetadata(
                          title: liveEvent.titre,
                          imageUrl: liveEvent.photoPath,
                          category: liveEvent.categorie,
                        );
                      }
                      final parsed = _parseLikeId(id, effectiveMeta);
                      final image = _resolveImage(id, parsed, effectiveMeta);

                      return _FavCard(
                        id: id,
                        parsed: parsed,
                        image: image,
                        onTap: () => _openDetail(
                          context, id, liveEvent, effectiveMeta, parsed, image,
                        ),
                        onUnlike: () => ref.read(likesProvider.notifier).toggle(id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    String id,
    Event? liveEvent,
    LikeMetadata? meta,
    _ParsedLike parsed,
    String image,
  ) {
    if (LikedItemResolver.isCommerce(id)) {
      final commerce = LikedItemResolver.resolveCommerce(id);
      if (commerce != null) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => LikedItemDetailSheet.forCommerce(commerce),
        );
        return;
      }
    }

    final event = liveEvent ?? LikedItemResolver.resolveEvent(id);
    if (event != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (_) => LikedItemDetailSheet.forEvent(event),
      );
      return;
    }

    // Fallback: show a minimal detail from metadata
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _MetaDetailPopup(
        id: id,
        title: parsed.name,
        category: parsed.category,
        emoji: parsed.emoji,
        image: image,
        meta: meta,
      ),
    );
  }

  // Same pochette map as test_screen for resolving event images by category
  static const _eventCategoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'expo': 'assets/images/pochette_culture_art.png',
    'vernissage': 'assets/images/pochette_culture_art.png',
    'musee': 'assets/images/pochette_visite.png',
    'football': 'assets/images/pochette_football.png',
    'rugby': 'assets/images/pochette_rugby.png',
    'basketball': 'assets/images/pochette_basketball.png',
    'soiree': 'assets/images/pochette_discotheque.png',
    'club': 'assets/images/pochette_discotheque.png',
    'bar': 'assets/images/pochette_pub.png',
    'restaurant': 'assets/images/pochette_food.png',
    'cinema': 'assets/images/pochette_spectacle.png',
  };

  static const _commerceImages = <String, String>{
    'bar': 'assets/images/sc_pub.jpg',
    'pub': 'assets/images/sc_pub.jpg',
    'club': 'assets/images/sc_discotheque.png',
    'discotheque': 'assets/images/sc_discotheque.png',
    'restaurant': 'assets/images/pochette_food.png',
    'chicha': 'assets/images/sc_chicha.jpg',
    'tabac': 'assets/images/sc_tabac_nuit.png',
  };

  static const _categoryFallback = <String, String>{
    'Nuit': 'assets/images/sc_pub.jpg',
    'Culture': 'assets/images/pochette_culture_art.png',
    'En Famille': 'assets/images/pochette_enfamille.jpg',
    'Food': 'assets/images/pochette_food.png',
    'Sport': 'assets/images/home_bg_sport.jpg',
    'Gaming': 'assets/images/pochette_gaming.jpg',
    'Evenement': 'assets/images/pochette_concert.png',
  };

  String _resolveImage(String id, _ParsedLike parsed, LikeMetadata? meta) {
    // 1. Use cached metadata network image
    if (meta != null && meta.imageUrl != null && meta.imageUrl!.isNotEmpty) {
      return meta.imageUrl!;
    }

    // 2. Use cached metadata asset image
    if (meta != null && meta.assetImage != null && meta.assetImage!.isNotEmpty) {
      return meta.assetImage!;
    }

    // 3. Resolve pochette from event category (same logic as test_screen)
    if (meta != null && meta.category != null && meta.category!.isNotEmpty) {
      final cat = meta.category!.toLowerCase();
      for (final entry in _eventCategoryImages.entries) {
        if (cat.contains(entry.key)) return entry.value;
      }
    }

    // 4. Commerce resolution
    if (LikedItemResolver.isCommerce(id)) {
      final commerce = LikedItemResolver.resolveCommerce(id);
      if (commerce != null && commerce.photo.isNotEmpty) {
        return commerce.photo;
      }
      if (commerce != null) {
        final cat = commerce.categorie.toLowerCase();
        for (final entry in _commerceImages.entries) {
          if (cat.contains(entry.key)) return entry.value;
        }
      }
    }

    // 5. Keyword-based fallback from title
    final nameLower = parsed.name.toLowerCase();
    if (nameLower.contains('nine') || nameLower.contains('etoile') ||
        nameLower.contains('club') || nameLower.contains('disco')) {
      return 'assets/images/sc_discotheque.png';
    }
    if (nameLower.contains('soiree') || nameLower.contains('bar') ||
        nameLower.contains('pub') || nameLower.contains('nuit')) {
      return 'assets/images/sc_pub.jpg';
    }
    if (nameLower.contains('concert') || nameLower.contains('festival') ||
        nameLower.contains('live') || nameLower.contains('dj')) {
      return 'assets/images/pochette_concert.png';
    }
    if (nameLower.contains('rugby')) return 'assets/images/pochette_rugby.png';
    if (nameLower.contains('foot')) return 'assets/images/pochette_football.png';
    if (nameLower.contains('basket')) return 'assets/images/pochette_basketball.png';
    if (nameLower.contains('theatre') || nameLower.contains('opera')) {
      return 'assets/images/pochette_theatre.png';
    }
    if (nameLower.contains('expo') || nameLower.contains('musee')) {
      return 'assets/images/pochette_culture_art.png';
    }
    return _categoryFallback[parsed.category] ?? 'assets/images/pochette_concert.png';
  }

  _ParsedLike _parseLikeId(String id, LikeMetadata? meta) {
    // If we have cached metadata, use the real title
    if (meta != null && meta.title.isNotEmpty) {
      // Determine category from metadata or ID prefix
      const prefixes = {
        'night_': ('Nuit', '\u{1F319}'),
        'culture_': ('Culture', '\u{1F3A8}'),
        'family_': ('En Famille', '\u{1F468}\u200d\u{1F469}\u200d\u{1F467}\u200d\u{1F466}'),
        'food_': ('Food', '\u{1F37D}\uFE0F'),
        'sport_': ('Sport', '\u26BD'),
        'gaming_': ('Gaming', '\u{1F3AE}'),
        'match_': ('Sport', '\u26BD'),
      };

      for (final entry in prefixes.entries) {
        if (id.startsWith(entry.key)) {
          return _ParsedLike(
            name: meta.title,
            category: entry.value.$1,
            emoji: entry.value.$2,
          );
        }
      }

      return _ParsedLike(
        name: meta.title,
        category: meta.category ?? 'Evenement',
        emoji: '',
      );
    }

    // Fallback: parse from ID prefix
    const prefixes = {
      'night_': ('Nuit', '\u{1F319}'),
      'culture_': ('Culture', '\u{1F3A8}'),
      'family_': ('En Famille', '\u{1F468}\u200d\u{1F469}\u200d\u{1F467}\u200d\u{1F466}'),
      'food_': ('Food', '\u{1F37D}\uFE0F'),
      'sport_': ('Sport', '\u26BD'),
      'gaming_': ('Gaming', '\u{1F3AE}'),
    };

    for (final entry in prefixes.entries) {
      if (id.startsWith(entry.key)) {
        return _ParsedLike(
          name: id.substring(entry.key.length),
          category: entry.value.$1,
          emoji: entry.value.$2,
        );
      }
    }

    return _ParsedLike(
      name: id,
      category: 'Evenement',
      emoji: '',
    );
  }
}

class _ParsedLike {
  final String name;
  final String category;
  final String emoji;

  const _ParsedLike({
    required this.name,
    required this.category,
    required this.emoji,
  });
}

// ── Carte favori ──
class _FavCard extends StatelessWidget {
  final String id;
  final _ParsedLike parsed;
  final String image;
  final VoidCallback onTap;
  final VoidCallback onUnlike;

  const _FavCard({
    required this.id,
    required this.parsed,
    required this.image,
    required this.onTap,
    required this.onUnlike,
  });

  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildAssetImage(),
                          errorWidget: (_, __, ___) => _buildAssetImage(),
                        )
                      : _buildAssetImage(),

                  // Gradient subtil en bas de l'image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badge categorie
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(parsed.emoji, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            parsed.category,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _primaryDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton unlike
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onUnlike,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Infos en bas
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parsed.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryDarkColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.chevron_right, size: 14, color: AppColors.textFaint),
                      const SizedBox(width: 2),
                      Text(
                        'Voir le detail',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetImage() {
    return Image.asset(
      image.startsWith('http') ? 'assets/images/pochette_concert.png' : image,
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, __, ___) => Container(
        color: _primaryDarkColor.withValues(alpha: 0.08),
        child: Center(child: Text(parsed.emoji, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}

// ── Starry animated background ──

class _StarryBackground extends StatefulWidget {
  final Widget child;
  const _StarryBackground({required this.child});

  @override
  State<_StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<_StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _stars = List.generate(60, (_) => _Star.random(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _StarPainter(
          stars: _stars,
          animValue: _controller.value,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Star {
  final double x; // 0..1
  final double y; // 0..1
  final double size;
  final double phase; // 0..1 offset for twinkle
  final double speed; // twinkle speed multiplier
  final bool isBright; // golden bright star vs white dim

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
    required this.isBright,
  });

  factory _Star.random(Random rng) {
    return _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 2.5 + 0.5,
      phase: rng.nextDouble(),
      speed: rng.nextDouble() * 0.6 + 0.7,
      isBright: rng.nextDouble() > 0.7,
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animValue;

  _StarPainter({required this.stars, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A0A2E), // deep night purple
          Color(0xFF2D1B4E), // mid purple
          Color(0xFF4A1259), // app dark purple
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Stars
    for (final star in stars) {
      final twinkle = sin((animValue * star.speed + star.phase) * 2 * pi);
      final opacity = (0.4 + 0.6 * ((twinkle + 1) / 2)).clamp(0.0, 1.0);
      final scaledSize = star.size * (0.7 + 0.3 * ((twinkle + 1) / 2));

      final color = star.isBright
          ? Color.fromRGBO(255, 213, 79, opacity) // golden
          : Color.fromRGBO(255, 255, 255, opacity * 0.7);

      final center = Offset(star.x * size.width, star.y * size.height);
      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scaledSize * 0.5);

      canvas.drawCircle(center, scaledSize, paint);

      // Sharp center dot
      canvas.drawCircle(
        center,
        scaledSize * 0.4,
        Paint()..color = color.withValues(alpha: opacity),
      );

      // Cross sparkle for bright stars
      if (star.isBright && scaledSize > 1.5) {
        final sparklePaint = Paint()
          ..color = Color.fromRGBO(255, 213, 79, opacity * 0.5)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round;
        final len = scaledSize * 2.5;
        canvas.drawLine(
          Offset(center.dx - len, center.dy),
          Offset(center.dx + len, center.dy),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - len),
          Offset(center.dx, center.dy + len),
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.animValue != animValue;
}

/// Minimal detail popup when we only have metadata (no live Event or Commerce).
class _MetaDetailPopup extends ConsumerWidget {
  final String id;
  final String title;
  final String category;
  final String emoji;
  final String image;
  final LikeMetadata? meta;

  const _MetaDetailPopup({
    required this.id,
    required this.title,
    required this.category,
    required this.emoji,
    required this.image,
    this.meta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(likesProvider).contains(id);
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // Background image
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: image.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (_, __, ___) =>
                                  _buildGradientFallback(),
                            )
                          : Image.asset(
                              image,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildGradientFallback(),
                            ),
                    ),
                  ],
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.55, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content overlay
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Emoji
                    if (emoji.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 32)),
                      ),

                    const Spacer(),

                    // Info at bottom
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Action buttons
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              // Like/unlike
                              _buildPillButton(
                                icon: isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: isLiked ? 'Retirer' : 'Aimer',
                                color: isLiked ? Colors.red : Colors.white,
                                onTap: () {
                                  ref.read(likesProvider.notifier).toggle(id);
                                  if (isLiked) Navigator.of(context).pop();
                                },
                              ),
                              // Share
                              _buildPillButton(
                                icon: Icons.share_outlined,
                                label: 'Partager',
                                color: Colors.white,
                                onTap: () {
                                  final text = '$title\n$category\n\nDecouvre sur MaCity';
                                  Share.share(text);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2D8E), Color(0xFFE91E8C)],
        ),
      ),
      child: emoji.isNotEmpty
          ? Center(child: Text(emoji, style: const TextStyle(fontSize: 80)))
          : null,
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
