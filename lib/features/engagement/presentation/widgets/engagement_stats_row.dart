import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/engagement/presentation/event_engagement_sheet.dart';
import 'package:pulz_app/features/engagement/state/event_engagement_provider.dart';

/// Ligne stats type Instagram : ♥ likes · 💬 comments · 🔄 shares.
/// Tap n'importe où → ouvre [EventEngagementSheet] focus sur l'onglet adapté.
/// Affiche rien si l'event n'est pas boosté.
class EngagementStatsRow extends ConsumerStatefulWidget {
  final String eventSource;
  final String eventIdentifiant;
  final String eventTitle;
  final Color iconColor;
  final Color textColor;
  final double iconSize;
  final double fontSize;
  final bool compact;
  final bool showComments;

  const EngagementStatsRow({
    super.key,
    required this.eventSource,
    required this.eventIdentifiant,
    required this.eventTitle,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.iconSize = 11,
    this.fontSize = 10,
    this.compact = false,
    this.showComments = true,
  });

  @override
  ConsumerState<EngagementStatsRow> createState() => _EngagementStatsRowState();
}

class _EngagementStatsRowState extends ConsumerState<EngagementStatsRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(engagementTotalsProvider.notifier)
          .request(widget.eventSource, widget.eventIdentifiant);
      ref
          .read(engagementTotalsProvider.notifier)
          .loadUserLiked(widget.eventSource, widget.eventIdentifiant);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(engagementTotalsProvider);
    final key = engagementKey(widget.eventSource, widget.eventIdentifiant);
    final totals = state.totals[key];
    final liked = state.userLiked[key] ?? false;

    final likesCount = totals?.likesCount ?? 0;
    final commentsCount = totals?.commentsCount ?? 0;
    final sharesCount = totals?.sharesCount ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stat(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            iconColor: liked ? AppColors.magenta : widget.iconColor,
            count: likesCount,
          ),
          if (widget.showComments) ...[
            SizedBox(width: widget.compact ? 8 : 12),
            _stat(
              icon: Icons.mode_comment_outlined,
              iconColor: widget.iconColor,
              count: commentsCount,
            ),
          ],
          SizedBox(width: widget.compact ? 8 : 12),
          _stat(
            icon: Icons.send_outlined,
            iconColor: widget.iconColor,
            count: sharesCount,
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color iconColor,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: widget.iconSize, color: iconColor),
        const SizedBox(width: 3),
        Text(
          _format(count),
          style: GoogleFonts.geistMono(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w600,
            color: widget.textColor,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  String _format(int n) {
    if (n < 1000) return n.toString();
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000).round()}k';
  }

  void _openSheet(BuildContext context) {
    EventEngagementSheet.show(
      context,
      eventSource: widget.eventSource,
      eventIdentifiant: widget.eventIdentifiant,
      eventTitle: widget.eventTitle,
    );
  }
}
