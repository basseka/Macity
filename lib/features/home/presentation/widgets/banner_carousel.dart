import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/home/domain/models/banner.dart' as model;
import 'package:pulz_app/features/home/state/banners_provider.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/presentation/offer_code_popup.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';

/// Item unifie pour le carrousel : soit un banner, soit une offre pro.
class _CarouselItem {
  final model.Banner? banner;
  final Offer? offer;
  _CarouselItem.fromBanner(this.banner) : offer = null;
  _CarouselItem.fromOffer(this.offer) : banner = null;

  bool get isBanner => banner != null;
  String get linkUrl => banner?.linkUrl ?? offer?.businessUrl ?? '';
}

class BannerCarouselDialog extends ConsumerWidget {
  const BannerCarouselDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const BannerCarouselDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);
    final offersAsync = ref.watch(activeOffersProvider);

    final isLoading = bannersAsync.isLoading || offersAsync.isLoading;
    final hasError = bannersAsync.hasError && offersAsync.hasError;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8A0BF)),
      );
    }

    if (hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Impossible de charger les offres',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    final banners = bannersAsync.valueOrNull ?? [];
    final offers = offersAsync.valueOrNull ?? [];

    final items = <_CarouselItem>[
      ...banners.map(_CarouselItem.fromBanner),
      ...offers.map(_CarouselItem.fromOffer),
    ];

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Aucune offre disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: _BannerCarousel(items: items),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<_CarouselItem> items;
  const _BannerCarousel({required this.items});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceOffset;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _bounceOffset = Tween(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final currentItem = items[_currentPage];

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Carrousel
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.50,
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.isBanner) {
                    return _buildBannerSlide(item.banner!);
                  } else {
                    return _buildOfferSlide(item.offer!);
                  }
                },
              ),
            ),

            // CTA button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (currentItem.offer != null) {
                    OfferCodePopup.show(context, currentItem.offer!);
                  } else if (currentItem.linkUrl.isNotEmpty) {
                    _openLink(currentItem.linkUrl);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A0A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'J\'en profite',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Swipe hint + dots
            if (items.length > 1) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _bounceOffset,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_bounceOffset.value, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, color: Colors.white.withValues(alpha: 0.5), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Glisse pour decouvrir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),

        // Close button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlide(model.Banner banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: banner.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8A0BF), strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          height: 200,
          child: Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 40)),
        ),
      ),
    );
  }

  Widget _buildOfferSlide(Offer offer) {
    final hasImage = offer.imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle decorative glow
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE91E8C).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8A0BF).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                if (hasImage)
                  Flexible(
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: offer.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(
                            height: 140,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFE8A0BF),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        // Gradient overlay on image
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF1A0A2E).withValues(alpha: 0.8),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Info
                Padding(
                  padding: EdgeInsets.fromLTRB(16, hasImage ? 8 : 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji + title
                      Row(
                        children: [
                          if (offer.emoji.isNotEmpty)
                            Text(offer.emoji, style: const TextStyle(fontSize: 24)),
                          if (offer.emoji.isNotEmpty) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (offer.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          offer.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Business name + spots badge (glassmorphism)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.storefront_rounded,
                                  color: Color(0xFFE8A0BF),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    offer.businessName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: offer.hasSpots
                                        ? const Color(0xFFE8A0BF).withValues(alpha: 0.2)
                                        : Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: offer.hasSpots
                                          ? const Color(0xFFE8A0BF).withValues(alpha: 0.3)
                                          : Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    offer.hasSpots
                                        ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''}'
                                        : 'Complet',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: offer.hasSpots
                                          ? const Color(0xFFE8A0BF)
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
