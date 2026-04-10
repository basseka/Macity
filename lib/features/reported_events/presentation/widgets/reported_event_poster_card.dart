import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';

/// "Affiche prefaite" generee par Claude Haiku pour un signalement.
///
/// Carte stylisee avec gradient + emoji + texte IA. Pas d'image generee — la
/// "magie" vient du texte editorial Claude + du gradient choisi par categorie.
///
/// Si [event.status] == 'ai_generating', un placeholder shimmer est affiche.
class ReportedEventPosterCard extends StatelessWidget {
  final ReportedEvent event;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const ReportedEventPosterCard({
    super.key,
    required this.event,
    this.onTap,
    this.width = 240,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (event.isGenerating) {
      return _ShimmerPlaceholder(width: width, height: height);
    }

    // 3 modes d'affichage selon la taille : ultra-compact / compact / normal.
    final isUltra = height < 80;
    final isCompact = height < 140;

    final g = event.generated;
    final from = _parseHex(g?.gradientFrom) ?? const Color(0xFF7C3AED);
    final to = _parseHex(g?.gradientTo) ?? const Color(0xFFEC4899);
    final firstPhoto = event.firstPhoto;
    final hasPhoto = firstPhoto != null && firstPhoto.isNotEmpty;

    final emojiSize = isUltra ? 16.0 : (isCompact ? 22.0 : 28.0);
    final titleFontSize = isUltra ? 10.0 : (isCompact ? 12.0 : 14.0);
    final metaFontSize = isUltra ? 8.0 : (isCompact ? 9.0 : 10.0);
    final padding = isUltra ? 6.0 : (isCompact ? 8.0 : 12.0);
    final titleMaxLines = isUltra ? 1 : 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [from, to],
            ),
            boxShadow: [
              BoxShadow(
                color: from.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo de fond si fournie (1ere photo accumulee)
              if (hasPhoto)
                CachedNetworkImage(
                  imageUrl: firstPhoto,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),

              // Overlay sombre bottom-heavy pour la lisibilite du texte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: hasPhoto ? 0.7 : 0.45),
                    ],
                    stops: const [0.25, 1.0],
                  ),
                ),
              ),

              // Top-left : badge time_label
              Positioned(
                top: padding,
                left: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimeBadge(label: g?.timeLabel ?? 'LIVE'),
                    // Badge "corrobore par N personnes" si merge
                    if (event.isCommunityConfirmed) ...[
                      const SizedBox(width: 4),
                      _CommunityBadge(count: event.reportCount),
                    ],
                  ],
                ),
              ),

              // Top-right : emoji (+ compteur photos si plusieurs)
              Positioned(
                top: padding - 4,
                right: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.photos.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${event.photos.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      g?.emoji ?? '📍',
                      style: TextStyle(fontSize: emojiSize),
                    ),
                  ],
                ),
              ),

              // Bottom : titre + lieu/mood + tags (tags caches en compact)
              Positioned(
                left: padding,
                right: padding,
                bottom: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g?.title ?? event.rawTitle,
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black54),
                        ],
                      ),
                    ),
                    // Meta row cachee en mode ultra-compact (gain de place)
                    if (!isUltra) ...[
                      SizedBox(height: isCompact ? 2 : 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.ville != null && event.ville!.isNotEmpty)
                            Flexible(
                              child: Text(
                                event.ville!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: metaFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          if (event.ville != null &&
                              event.ville!.isNotEmpty &&
                              (g?.mood.isNotEmpty ?? false))
                            Text(
                              ' · ',
                              style: GoogleFonts.poppins(
                                fontSize: metaFontSize,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          if (g?.mood.isNotEmpty ?? false)
                            Flexible(
                              child: Text(
                                g!.mood,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: metaFontSize,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    // Tags uniquement en mode large
                    if (!isCompact && (g?.tags.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: g!.tags
                            .take(3)
                            .map((t) => _TagChip(label: t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Footer "commu" uniquement en mode large
              if (!isCompact)
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 9,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'commu',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v == null ? null : Color(v);
  }
}

class _TimeBadge extends StatelessWidget {
  final String label;
  const _TimeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: const Color(0xFF1A0A2E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge "×N personnes" affiche quand un signalement a ete corrobore par
/// plusieurs users (merge en DB via upsert_reported_event).
class _CommunityBadge extends StatelessWidget {
  final int count;
  const _CommunityBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '×$count',
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '#$label',
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerPlaceholder({required this.width, required this.height});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _ctrl.value, -1),
              end: Alignment(1 + 2 * _ctrl.value, 1),
              colors: const [
                Color(0xFFE5E0EE),
                Color(0xFFF3F0F8),
                Color(0xFFE5E0EE),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 24, color: Color(0xFF7B2D8E)),
                const SizedBox(height: 6),
                Text(
                  'Generation IA...',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B2D8E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
