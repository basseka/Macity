import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/likes/data/liked_item_resolver.dart';
import 'package:pulz_app/features/likes/presentation/liked_item_detail_sheet.dart';
import 'package:pulz_app/features/likes/state/likes_provider.dart';

class LikedPlacesBottomSheet extends ConsumerWidget {
  const LikedPlacesBottomSheet({super.key});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedIds = ref.watch(likesProvider);
    final items = likedIds.toList()..sort();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Mes favoris (${items.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryDarkColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucun favori pour le moment',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Like des etablissements pour les retrouver ici',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final id = items[index];
                  final parsed = _parseLikeId(id);

                  return ListTile(
                    onTap: () => _openDetail(context, id),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        parsed.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      parsed.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryDarkColor,
                      ),
                    ),
                    subtitle: parsed.category.isNotEmpty
                        ? Text(
                            parsed.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                      onPressed: () {
                        ref.read(likesProvider.notifier).toggle(id);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String id) {
    if (LikedItemResolver.isCommerce(id)) {
      final commerce = LikedItemResolver.resolveCommerce(id);
      if (commerce != null) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => LikedItemDetailSheet.forCommerce(commerce),
        );
      }
    } else {
      final event = LikedItemResolver.resolveEvent(id);
      if (event != null) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => LikedItemDetailSheet.forEvent(event),
        );
      }
    }
  }

  _ParsedLike _parseLikeId(String id) {
    // Format commerce: "night_Nom du bar"
    const prefixes = {
      'night_': ('Nuit', '🌙'),
      'culture_': ('Culture', '🎨'),
      'family_': ('En Famille', '👨\u200d👩\u200d👧\u200d👦'),
      'food_': ('Food', '🍽️'),
      'sport_': ('Sport', '⚽'),
      'gaming_': ('Gaming', '🎮'),
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

    // Format event ou autre
    return _ParsedLike(
      name: id,
      category: 'Evenement',
      emoji: '📅',
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
