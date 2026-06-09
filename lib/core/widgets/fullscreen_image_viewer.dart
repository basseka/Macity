import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Viewer plein ecran d'une affiche unique : fond noir, image centree
/// (contain), pinch-zoom + deplacement via [InteractiveViewer], tap n'importe
/// ou (ou la croix) pour fermer.
///
/// Source resolue dans l'ordre : [imageUrl] (reseau, deja en cache donc
/// instantane si l'affiche etait deja affichee) -> [imageFile] (fichier local,
/// ex: photo capturee) -> [imageAsset] (asset bundle). Au moins une doit etre
/// non vide, sinon l'appel est ignore.
void showFullscreenImage(
  BuildContext context, {
  String? imageUrl,
  String? imageAsset,
  String? imageFile,
}) {
  final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
  final hasFile = imageFile != null && imageFile.isNotEmpty;
  final hasAsset = imageAsset != null && imageAsset.isNotEmpty;
  if (!hasUrl && !hasFile && !hasAsset) return;

  Widget fallback() {
    if (hasAsset) return Image.asset(imageAsset, fit: BoxFit.contain);
    return const Icon(Icons.broken_image, color: Colors.white30, size: 48);
  }

  Widget imageWidget;
  if (hasUrl) {
    imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => hasAsset
          ? Image.asset(imageAsset, fit: BoxFit.contain)
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
            ),
      errorWidget: (_, __, ___) => fallback(),
    );
  } else if (hasFile) {
    imageWidget = Image.file(
      File(imageFile),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback(),
    );
  } else {
    imageWidget = Image.asset(imageAsset!, fit: BoxFit.contain);
  }

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.95),
    builder: (dialogCtx) => Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(dialogCtx).pop(),
          child: SizedBox.expand(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(child: imageWidget),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(dialogCtx).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    ),
  );
}
