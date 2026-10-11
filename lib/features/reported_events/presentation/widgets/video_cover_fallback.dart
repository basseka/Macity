import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Pochette d'une story video publiee SANS miniature (`cover_url` vide :
/// extraction ratee sur le telephone au moment de publier). On extrait
/// une image de la video en ligne, une seule fois par URL (cache memoire),
/// et on affiche [fallback] pendant le chargement ou en cas d'echec.
class VideoCoverFallback extends StatelessWidget {
  final String videoUrl;
  final Widget fallback;

  const VideoCoverFallback({
    super.key,
    required this.videoUrl,
    required this.fallback,
  });

  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> _thumbnail(String url) =>
      _cache.putIfAbsent(url, () async {
        try {
          return await VideoThumbnail.thumbnailData(
            video: url,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 400,
            quality: 70,
            timeMs: 500,
          );
        } catch (_) {
          return null;
        }
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail(videoUrl),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) return fallback;
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}
