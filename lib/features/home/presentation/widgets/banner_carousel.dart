import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/home/domain/models/banner.dart' as model;
import 'package:pulz_app/features/home/state/banners_provider.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Impossible de charger les offres',
            style: TextStyle(color: Colors.white, fontSize: 16),
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
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
            if (currentItem.linkUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openLink(currentItem.linkUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF4E342E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'J\'en profite !',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // Swipe hint + dots
            if (items.length > 1) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _bounceOffset,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_bounceOffset.value, 0),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Glisse pour voir les offres',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFFD54F)
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlide(model.Banner banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CachedNetworkImage(
        imageUrl: banner.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          height: 200,
          child: Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
        ),
      ),
    );
  }

  Widget _buildOfferSlide(Offer offer) {
    final hasImage = offer.imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1259), Color(0xFF7B2D8E)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image de l'offre (si disponible)
            if (hasImage)
              Flexible(
                child: CachedNetworkImage(
                  imageUrl: offer.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Infos de l'offre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji + titre
                  Row(
                    children: [
                      if (offer.emoji.isNotEmpty)
                        Text(offer.emoji, style: const TextStyle(fontSize: 28)),
                      if (offer.emoji.isNotEmpty) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          offer.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (offer.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      offer.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Business name + places restantes
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offer.businessName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: offer.hasSpots
                              ? const Color(0xFFFFD54F)
                              : Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          offer.hasSpots
                              ? '${offer.remainingSpots} place${offer.remainingSpots > 1 ? 's' : ''}'
                              : 'Complet',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: offer.hasSpots
                                ? const Color(0xFF4E342E)
                                : Colors.white,
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
      ),
    );
  }
}
