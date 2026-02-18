import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

/// Fiche detail generique ouverte au tap sur une carte (commerce, event, match, venue).
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
  static const _primaryDarkColor = Color(0xFF4A1259);

  /// Ouvre le detail sheet en modal bottom sheet.
  static void show(BuildContext context, ItemDetailSheet sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked =
        likeId != null ? ref.watch(likesProvider).contains(likeId) : false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryDarkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Info rows
                  ...infos.map(
                    (info) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(info.icon, size: 13, color: _primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              info.text,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Primary action
                  if (primaryAction != null)
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(primaryAction!.url),
                        icon: Icon(primaryAction!.icon, size: 14),
                        label: Text(primaryAction!.label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (primaryAction != null) const SizedBox(height: 6),

                  // Secondary actions + like + share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...secondaryActions.map(
                        (action) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildCircleButton(
                            icon: action.icon,
                            label: action.label,
                            onTap: () => _openUrl(action.url),
                          ),
                        ),
                      ),
                      if (likeId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildCircleButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: isLiked ? 'Retirer' : 'Ajouter',
                            color: isLiked ? Colors.red : null,
                            onTap: () {
                              ref.read(likesProvider.notifier).toggle(likeId!);
                            },
                          ),
                        ),
                      if (shareText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildCircleButton(
                            icon: Icons.share_outlined,
                            label: 'Partager',
                            onTap: () => Share.share(shareText),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? _primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: c),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
