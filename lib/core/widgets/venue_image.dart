import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche une image de venue : URL reseau ou asset local.
/// Si [imageUrl] commence par "http", affiche un CachedNetworkImage.
/// Sinon, tente Image.asset avec fallback sur [defaultAsset].
class VenueImage extends StatelessWidget {
  final String imageUrl;
  final String defaultAsset;
  final BoxFit fit;

  const VenueImage({
    super.key,
    required this.imageUrl,
    this.defaultAsset = 'assets/images/pochette_theatre.png',
    this.fit = BoxFit.cover,
  });

  static bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/embed')) return false;
    if (lower.contains('secret=')) return false;
    // Accepter les URLs avec extensions image ou les CDN connus
    const validExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    const validHosts = ['supabase.co', 'ticketmaster.com', 'songkick.com',
        'eventbrite.com', 'festik.net', 'cloudinary', 'imgur', 'unsplash'];
    if (validExtensions.any((ext) => lower.contains(ext))) return true;
    if (validHosts.any((host) => lower.contains(host))) return true;
    // Accepter les URLs avec content-type image (CDN generiques)
    return !lower.endsWith('.html') && !lower.endsWith('/');
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http') && _isValidImageUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 400,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => _buildAsset(imageUrl: defaultAsset),
        errorWidget: (_, __, ___) => _buildAsset(imageUrl: defaultAsset),
      );
    }

    return _buildAsset(imageUrl: imageUrl.isNotEmpty ? imageUrl : defaultAsset);
  }

  Widget _buildAsset({required String imageUrl}) {
    return Image.asset(
      imageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_outlined, size: 28, color: Colors.grey),
      ),
    );
  }
}
