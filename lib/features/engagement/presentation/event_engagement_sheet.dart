import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/engagement/domain/models/event_comment.dart';
import 'package:pulz_app/features/engagement/presentation/widgets/edit_pseudonym_dialog.dart';
import 'package:pulz_app/features/engagement/presentation/widgets/engagement_avatar.dart';
import 'package:pulz_app/features/engagement/state/event_engagement_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet "type Instagram" pour un event boosté :
///  - Liste des commentaires (fake + real, plus récents en haut)
///  - Bouton ♥ like (toggle)
///  - Bouton 🔄 share (system share)
///  - Input pour ajouter un comment (assigne pseudo au 1er envoi)
class EventEngagementSheet extends ConsumerStatefulWidget {
  final String eventSource;
  final String eventIdentifiant;
  final String eventTitle;

  const EventEngagementSheet({
    super.key,
    required this.eventSource,
    required this.eventIdentifiant,
    required this.eventTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventSource,
    required String eventIdentifiant,
    required String eventTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EventEngagementSheet(
          eventSource: eventSource,
          eventIdentifiant: eventIdentifiant,
          eventTitle: eventTitle,
        ),
      ),
    );
  }

  @override
  ConsumerState<EventEngagementSheet> createState() =>
      _EventEngagementSheetState();
}

class _EventEngagementSheetState extends ConsumerState<EventEngagementSheet> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsKey = (
      source: widget.eventSource,
      identifiant: widget.eventIdentifiant,
    );
    final commentsAsync = ref.watch(eventCommentsProvider(commentsKey));
    final pseudoAsync = ref.watch(devicePseudonymProvider);

    final totalsState = ref.watch(engagementTotalsProvider);
    final tKey = engagementKey(widget.eventSource, widget.eventIdentifiant);
    final totals = totalsState.totals[tKey];
    final liked = totalsState.userLiked[tKey] ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _grabber(),
              _header(totals, liked),
              Divider(height: 1, color: AppColors.line),
              Expanded(
                child: commentsAsync.when(
                  data: (comments) => _commentsList(comments, scrollController),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Erreur de chargement',
                      style: GoogleFonts.geist(color: AppColors.textDim),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.line),
              _inputBar(pseudoAsync.valueOrNull),
            ],
          ),
        );
      },
    );
  }

  Widget _grabber() => Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(totals, bool liked) {
    final likes = totals?.likesCount ?? 0;
    final shares = totals?.sharesCount ?? 0;
    final comments = totals?.commentsCount ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.eventTitle,
              style: GoogleFonts.geist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppColors.magenta : AppColors.text,
            ),
            tooltip: '$likes',
            onPressed: () {
              ref.read(engagementTotalsProvider.notifier).toggleLike(
                    widget.eventSource,
                    widget.eventIdentifiant,
                  );
            },
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, color: AppColors.text),
            tooltip: '$shares',
            onPressed: _onShare,
          ),
          IconButton(
            icon: Icon(Icons.mode_comment_outlined, color: AppColors.text),
            tooltip: '$comments',
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _commentsList(List<EventComment> comments, ScrollController controller) {
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sois le premier à commenter',
            style: GoogleFonts.geist(color: AppColors.textDim),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) => _commentTile(comments[i]),
    );
  }

  Widget _commentTile(EventComment c) {
    final timeAgo = _timeAgo(c.createdAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EngagementAvatar(
            displayName: c.displayName,
            gender: c.gender,
            avatarUrl: c.avatarUrl,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.displayName,
                      style: GoogleFonts.geist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo,
                      style: GoogleFonts.geistMono(
                        fontSize: 10,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.text,
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(pseudo) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            if (pseudo != null)
              GestureDetector(
                onTap: () => EditPseudonymDialog.show(context, pseudo),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    EngagementAvatar(
                      displayName: pseudo.displayName,
                      gender: pseudo.gender,
                      avatarUrl: pseudo.avatarUrl,
                      size: 32,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line, width: 1),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 8,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_posting && pseudo != null,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                // Texte clair force pour rester lisible quand le champ est
                // rendu sur le fond sombre du composer (independant du
                // theme global, qui peut faire ressortir AppColors.text en
                // navy fonce -> invisible).
                style: GoogleFonts.geist(
                  fontSize: 14,
                  color: Colors.white,
                ),
                cursorColor: AppColors.magenta,
                decoration: InputDecoration(
                  hintText: pseudo != null
                      ? 'Commenter en tant que ${pseudo.displayName}…'
                      : 'Chargement…',
                  hintStyle: GoogleFonts.geist(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF241640),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.magenta),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.magenta),
              onPressed: (_posting || pseudo == null) ? null : () => _onSend(pseudo),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSend(pseudo) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      final service = ref.read(engagementServiceProvider);
      final deviceUuid = pseudo.deviceUuid as String;
      await service.postComment(
        eventSource: widget.eventSource,
        eventIdentifiant: widget.eventIdentifiant,
        deviceUuid: deviceUuid,
        displayName: pseudo.displayName as String,
        gender: pseudo.gender as String,
        avatarUrl: pseudo.avatarUrl as String?,
        text: text,
      );
      _controller.clear();
      // Refresh comments + totals
      ref.invalidate(eventCommentsProvider((
        source: widget.eventSource,
        identifiant: widget.eventIdentifiant,
      )));
      await ref.read(engagementTotalsProvider.notifier).refresh(
            widget.eventSource,
            widget.eventIdentifiant,
          );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _onShare() async {
    await Share.share(
      'Découvre cet event sur MaCity : ${widget.eventTitle}',
      subject: widget.eventTitle,
    );
    await ref.read(engagementTotalsProvider.notifier).recordShare(
          widget.eventSource,
          widget.eventIdentifiant,
        );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('d MMM', 'fr_FR').format(dt);
  }
}
