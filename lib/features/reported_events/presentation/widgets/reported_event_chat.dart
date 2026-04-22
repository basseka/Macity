import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/utils/bad_words_filter.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/reported_events/domain/models/chat_message.dart';
import 'package:pulz_app/features/reported_events/state/chat_provider.dart';

class ReportedEventChat extends ConsumerStatefulWidget {
  final String eventId;
  const ReportedEventChat({super.key, required this.eventId});

  @override
  ConsumerState<ReportedEventChat> createState() => _ReportedEventChatState();
}

class _ReportedEventChatState extends ConsumerState<ReportedEventChat> {
  static const _accent = Color(0xFFE91E8C);
  static const _dark = Color(0xFF4A1259);

  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String? _userId;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    UserIdentityService.getUserId().then((id) {
      if (mounted) setState(() => _userId = id);
    });
    _controller.addListener(_touchActivity);
    _scrollCtrl.addListener(_touchActivity);
  }

  void _touchActivity() {
    ref.read(chatActivityProvider(widget.eventId).notifier).touch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _sending) return;

    if (BadWordsFilter.contains(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message refuse : langage inapproprie'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final prenom = ref.read(userPrenomProvider).valueOrNull ?? '';
    final avatar = ref.read(userAvatarUrlProvider).valueOrNull;
    final userId = _userId ?? await UserIdentityService.getUserId();

    if (prenom.isEmpty) {
      // Garde-fou : ne devrait pas arriver, l'UI cache l'input dans ce cas.
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(reportedEventChatServiceProvider).sendMessage(
            eventId: widget.eventId,
            userId: userId,
            prenom: prenom,
            avatarUrl: avatar,
            content: raw,
          );
      _controller.clear();
      // Refresh immediat (sans attendre le polling)
      ref.invalidate(reportedEventChatProvider(widget.eventId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Echec de l\'envoi, reessayez')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmReport(ChatMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler ce message ?'),
        content: const Text(
            'Si plusieurs personnes signalent ce message, il sera masque automatiquement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Signaler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(reportedEventChatServiceProvider).reportMessage(msg.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message signale, merci.')),
        );
      }
      ref.invalidate(reportedEventChatProvider(widget.eventId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Echec du signalement')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(reportedEventChatProvider(widget.eventId));
    final prenom = ref.watch(userPrenomProvider).valueOrNull ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.forum_rounded, size: 16, color: _dark),
                const SizedBox(width: 8),
                Text(
                  'Discussion',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const Spacer(),
                messagesAsync.when(
                  data: (msgs) => Text(
                    '${msgs.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textFaint,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, minHeight: 80),
            child: messagesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Impossible de charger la discussion',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDim),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Sois le premier a poser une question !',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                  );
                }
                // Auto-scroll vers le bas si nouveau message
                if (messages.length != _lastCount) {
                  _lastCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl.animateTo(
                        _scrollCtrl.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) =>
                      _buildMessageRow(messages[i], _userId == messages[i].userId),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Input ou CTA inscription
          if (prenom.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Termine ton inscription pour participer a la discussion.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 500,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Pose une question...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: AppColors.textFaint),
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceHi,
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
                          borderSide: const BorderSide(color: _accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: _accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage msg, bool isMine) {
    final hasAvatar = msg.avatarUrl != null && msg.avatarUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (hasAvatar)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(msg.avatarUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_dark, _accent],
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          const SizedBox(width: 8),

          // Bulle
          Expanded(
            child: GestureDetector(
              onLongPress: isMine ? null : () => _confirmReport(msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isMine
                      ? _accent.withValues(alpha: 0.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            msg.prenom,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(msg.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.content,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF1A0A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isMine)
            IconButton(
              icon: Icon(Icons.flag_outlined,
                  size: 14, color: AppColors.textFaint),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Signaler',
              onPressed: () => _confirmReport(msg),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
