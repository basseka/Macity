import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_kicker.dart';

/// Ligne d'event : vignette gauche (88x88 ou 110x110 si featured) + overlay
/// date + kicker + Fraunces title + sous-titre italique + meta lieu/people +
/// prix + favori. Separateur 1px en bas.
class EditorialEventRowCard extends StatelessWidget {
  /// Mois 3 lettres uppercase (ex "AVR"). Si null/vide, l'overlay date est cache.
  final String? dateMonth;
  final String? dateDay;
  final String? weekDay; // ex "ven."
  final String? time; // ex "20h30"
  final String title;
  final String? subtitle;
  final String? venue;
  final int? interested;
  final String? price; // string libre. "Gratuit" -> traitement vert.
  final String? imageUrl;
  final Color accent;
  final bool featured;
  final bool saved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSave;

  const EditorialEventRowCard({
    super.key,
    this.dateMonth,
    this.dateDay,
    this.weekDay,
    this.time,
    required this.title,
    this.subtitle,
    this.venue,
    this.interested,
    this.price,
    this.imageUrl,
    required this.accent,
    this.featured = false,
    this.saved = false,
    this.onTap,
    this.onToggleSave,
  });

  /// Image qui supporte URL HTTP (CachedNetworkImage) ET asset path (Image.asset).
  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: EditorialColors.dividerSoft);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: EditorialColors.dividerSoft),
        errorWidget: (_, __, ___) => Container(color: EditorialColors.dividerSoft),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, __, ___) => Container(color: EditorialColors.dividerSoft),
    );
  }

  String _fmtInterested(int n) {
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = featured ? 110.0 : 88.0;
    final isFree = (price ?? '').toLowerCase() == 'gratuit';

    final kickerText = [
      if (weekDay != null && weekDay!.isNotEmpty) weekDay!,
      if (time != null && time!.isNotEmpty) time!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      splashColor: accent.withValues(alpha: 0.18),
      highlightColor: accent.withValues(alpha: 0.06),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: EditorialColors.dividerSoft, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vignette
            SizedBox(
              width: size,
              height: size,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(imageUrl),
                    // Overlay date
                    if (dateMonth != null && dateDay != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
                          decoration: BoxDecoration(
                            color: EditorialColors.ink,
                            border: Border(
                              left: BorderSide(color: accent, width: 2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                dateMonth!.toUpperCase(),
                                style: EditorialText.kicker(
                                  color: EditorialColors.paper.withValues(alpha: 0.7),
                                  size: 9,
                                ).copyWith(letterSpacing: 1.08),
                              ),
                              Text(
                                dateDay!,
                                style: EditorialText.dateOverlayDay(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kickerText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: EditorialKicker(kickerText, color: accent, size: 9),
                    ),
                  Text(
                    title,
                    style: EditorialText.eventTitle(featured: featured),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: EditorialText.subtitleItalic(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Meta lieu + people
                  if ((venue != null && venue!.isNotEmpty) || interested != null)
                    Row(
                      children: [
                        if (venue != null && venue!.isNotEmpty) ...[
                          const Icon(
                            Icons.place_outlined,
                            size: 11,
                            color: EditorialColors.paperMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              venue!,
                              style: EditorialText.meta(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (interested != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.people_outline,
                            size: 11,
                            color: EditorialColors.paperMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmtInterested(interested!),
                            style: EditorialText.meta(),
                          ),
                        ],
                      ],
                    ),
                  // Prix + favori
                  if (price != null || onToggleSave != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (price != null && price!.isNotEmpty)
                          Text(
                            isFree ? 'GRATUIT' : price!,
                            style: isFree
                                ? EditorialText.priceFree()
                                : EditorialText.pricePaid(),
                          ),
                        const Spacer(),
                        if (onToggleSave != null)
                          GestureDetector(
                            onTap: onToggleSave,
                            child: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: saved ? accent : EditorialColors.paperMuted,
                            ),
                          ),
                      ],
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
