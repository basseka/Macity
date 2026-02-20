import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Fiche detail generique ouverte au tap sur une carte (commerce, event, match, venue).
/// Affichee en popup plein ecran avec pochette en fond et infos overlayees.
class ItemDetailSheet extends ConsumerWidget {
  final String title;
  final String emoji;
  final String? imageAsset;
  final List<DetailInfoItem> infos;
  final DetailAction? primaryAction;
  final List<DetailAction> secondaryActions;
  final String shareText;
  final String? likeId;

  const ItemDetailSheet({
    super.key,
    required this.title,
    this.emoji = '',
    this.imageAsset,
    this.infos = const [],
    this.primaryAction,
    this.secondaryActions = const [],
    this.shareText = '',
    this.likeId,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  /// Ouvre le popup plein ecran.
  static void show(BuildContext context, ItemDetailSheet sheet) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked =
        likeId != null ? ref.watch(likesProvider).contains(likeId) : false;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasImage = imageAsset != null && imageAsset!.isNotEmpty;

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
                // ── Fond : image ou gradient ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: hasImage
                          ? Image.asset(
                              imageAsset!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildGradientFallback(),
                            )
                          : _buildGradientFallback(),
                    ),
                  ],
                ),

                // ── Gradient overlay ──
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

                // ── Contenu overlay ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermer
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
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),

                    const Spacer(),

                    // ── Infos en bas ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Titre
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

                          const SizedBox(height: 10),

                          // Info rows
                          ...infos.map(
                            (info) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    info.icon,
                                    size: 15,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      info.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Boutons actions ──
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              // Like
                              if (likeId != null)
                                _buildPillButton(
                                  icon: isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  label: isLiked ? 'Aime' : 'Aimer',
                                  color:
                                      isLiked ? Colors.red : Colors.white,
                                  onTap: () => ref
                                      .read(likesProvider.notifier)
                                      .toggle(likeId!),
                                ),
                              // Share
                              if (shareText.isNotEmpty)
                                _buildPillButton(
                                  icon: Icons.share_outlined,
                                  label: 'Partager',
                                  color: Colors.white,
                                  onTap: () => Share.share(shareText),
                                ),
                              // Secondary actions
                              ...secondaryActions.map(
                                (action) => _buildPillButton(
                                  icon: action.icon,
                                  label: action.label,
                                  color: Colors.white,
                                  onTap: () => _openUrl(action.url),
                                ),
                              ),
                            ],
                          ),

                          // Primary action
                          if (primaryAction != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openUrl(primaryAction!.url),
                                icon: Icon(primaryAction!.icon, size: 18),
                                label: Text(
                                  primaryAction!.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                        ],
                      ),
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
          ? Center(
              child: Text(emoji, style: const TextStyle(fontSize: 80)),
            )
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Sur Android, Instagram intercepte les liens instagram.com
    // et ouvre le feed au lieu du profil. On force l'ouverture
    // dans le navigateur via un Intent explicite.
    if (Platform.isAndroid && uri.host.contains('instagram.com')) {
      try {
        const channel = MethodChannel('com.pulzapp.toulouse/browser');
        await channel.invokeMethod('openInBrowser', {'url': url});
        return;
      } catch (_) {
        // Fallback si le channel natif n'existe pas.
      }
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }
}

class DetailInfoItem {
  final IconData icon;
  final String text;
  const DetailInfoItem(this.icon, this.text);
}

class DetailAction {
  final IconData icon;
  final String label;
  final String url;
  const DetailAction({
    required this.icon,
    required this.label,
    required this.url,
  });
}
