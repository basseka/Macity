import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart'
    show RubriqueTheme;
import 'package:pulz_app/features/sport/data/sport_news_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bloc "Actu sport toulousain" : carrousel de mini-articles (table
/// `sport_news`, reformulés par IA). Style calqué sur "Inspirations". Le tap
/// ouvre une fiche détail avec le résumé complet + lien vers la source.
/// Entièrement masqué quand il n'y a aucun article.
class SportNewsSection extends ConsumerWidget {
  const SportNewsSection({super.key});

  static const _accent = Color(0xFFA020F0); // violet Sport

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(sportNewsProvider).valueOrNull ?? const <SportNews>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'Actu sport',
            style: RubriqueTheme.sectionHeader(fontSize: 14),
          ),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _SportNewsCard(
              news: items[i],
              onTap: () => _showDetail(context, items[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showDetail(BuildContext context, SportNews news) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: RubriqueTheme.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _SportNewsDetail(news: news, onOpenSource: _openSource),
    );
  }
}

Widget _imageOrGradient(String url, {required double height}) {
  const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x8CA020F0), RubriqueTheme.dark],
  );
  if (url.trim().isEmpty) {
    return SizedBox(
      height: height,
      child: const DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
    );
  }
  return SizedBox(
    height: height,
    width: double.infinity,
    child: CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          const DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      errorWidget: (_, __, ___) =>
          const DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
    ),
  );
}

class _SportNewsCard extends StatelessWidget {
  final SportNews news;
  final VoidCallback onTap;

  const _SportNewsCard({required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: RubriqueTheme.dark,
          borderRadius: BorderRadius.circular(RubriqueTheme.rInspiration),
          boxShadow: RubriqueTheme.mini,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _imageOrGradient(news.imageUrl, height: 92),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${news.sportEmoji}  ${news.sourceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RubriqueTheme.tinyTag(
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 9.5,
                        spacing: 0,
                        w: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      news.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: RubriqueTheme.meta(
                          color: Colors.white, w: FontWeight.w600),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: SportNewsSection._accent,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportNewsDetail extends StatelessWidget {
  final SportNews news;
  final Future<void> Function(String url) onOpenSource;

  const _SportNewsDetail({required this.news, required this.onOpenSource});

  @override
  Widget build(BuildContext context) {
    final hasSource = news.sourceUrl.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: _imageOrGradient(news.imageUrl, height: 150),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${news.sportEmoji}  ${news.sourceName}',
                    style: RubriqueTheme.tinyTag(
                      color: SportNewsSection._accent,
                      size: 11,
                      spacing: 0.5,
                      w: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    style: RubriqueTheme.sectionHeader(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news.summary,
                    style: RubriqueTheme.meta(
                        color: Colors.white.withValues(alpha: 0.82),
                        w: FontWeight.w400),
                  ),
                  if (hasSource) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onOpenSource(news.sourceUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SportNewsSection._accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: Text(
                          news.sourceName.isEmpty
                              ? 'Lire l\'article'
                              : 'Lire sur ${news.sourceName}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
