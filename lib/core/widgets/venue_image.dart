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

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
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
