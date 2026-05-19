import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_chat.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/reported_event_view_tracker.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/story_video_cache.dart';
import 'package:pulz_app/features/reported_events/state/chat_provider.dart';

/// Vue story plein-écran (palette Neon) : photo en fond, header overlay,
/// rail d'actions à droite, bloc info en bas avec CTA "Y aller". Le tap sur
/// le bouton chat (rail ou CTA secondaire) ouvre une bottom-sheet discussion
/// par-dessus. La pause auto-advance + vidéo est conservée via
/// [chatInputFocusedProvider] (set à true quand la sheet est ouverte).
class ReportedEventDetailSheet extends ConsumerStatefulWidget {
  final ReportedEvent event;

  /// Auto-ouvre la sheet discussion au mount (tap sur notif `chat_message`).
  final bool initialScrollToChat;

  const ReportedEventDetailSheet({
    super.key,
    required this.event,
    this.initialScrollToChat = false,
  });

  @override
  ConsumerState<ReportedEventDetailSheet> createState() =>
      _ReportedEventDetailSheetState();
}

class _ReportedEventDetailSheetState
    extends ConsumerState<ReportedEventDetailSheet> {
  ReportedEvent get event => widget.event;

  @override
  void initState() {
    super.initState();
    if (widget.initialScrollToChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _openDiscussionSheet();
        });
      });
    }
  }

  Future<void> _openItinerary() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${event.lat},${event.lng}&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Ouvre la bottom-sheet discussion. Met le viewer story en pause tant
  /// qu'elle est ouverte (progress bars + video) en flippant le provider de
  /// focus chat — le PagedSheet écoute déjà ce flag.
  Future<void> _openDiscussionSheet() async {
    ref.read(chatInputFocusedProvider.notifier).state = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useRootNavigator: true,
      builder: (_) => _DiscussionSheet(event: event, onYAller: _openItinerary),
    );
    if (mounted) {
      ref.read(chatInputFocusedProvider.notifier).state = false;
    }
  }

  String _relativeAge() {
    final diff = DateTime.now().difference(event.createdAt);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final g = event.generated;
    final media = MediaQuery.of(context);
    final hasPhoto = event.firstPhoto != null;
    final hasVideo = event.videos.isNotEmpty;
    final prenom = event.reporterPrenom ?? '';
    final contributorsExtra = event.contributors.length - 1;

    return ReportedEventViewTracker(
      eventId: event.id,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Media full-bleed : video autoplay/loop muted si presente,
          //    sinon photo. Pause sync avec chatInputFocusedProvider (sheet
          //    ouverte / chat focus / long-press).
          _StoryMedia(
            videoUrl: hasVideo ? event.videos.first : null,
            photoUrl: hasPhoto ? event.firstPhoto : null,
          ),

          // 2. Gradient overlay bas pour lisibilité du texte
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Header (avatar + nom + LIVE + multiplicateur + sous-ligne)
          Positioned(
            top: 8,
            left: 14,
            right: 14,
            child: _StoryHeader(
              prenom: prenom,
              avatarUrl: event.reporterAvatarUrl,
              isLive: event.expiresAt.isAfter(DateTime.now()),
              multiplier:
                  contributorsExtra > 0 ? (contributorsExtra + 1) : null,
              subline: '${_relativeAge()}  ·  ${event.ville ?? ''}'.trim(),
            ),
          ),

          // 4. Rail d'actions à droite (scope visuel : Discuter + Vues)
          Positioned(
            right: 10,
            top: media.size.height * 0.36,
            child: _ActionRail(
              chatCount: 0,
              viewsLabel: event.displayViewsFormatted,
              onChatTap: _openDiscussionSheet,
              onVideoTap: null,
            ),
          ),

          // 5. Bloc info bas : tags + titre + description + CTA "Y aller"
          Positioned(
            bottom: 14 + media.padding.bottom,
            left: 0,
            right: 0,
            child: _StoryBottomBlock(
              ville: event.ville,
              tags: g?.tags ?? const <String>[],
              title: g?.title ?? event.rawTitle,
              description: g?.description ?? '',
              onYAller: _openItinerary,
              onChatTap: _openDiscussionSheet,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Media background : video autoplay/loop muted, fallback photo
// ──────────────────────────────────────────────────────────────────────────

class _StoryMedia extends ConsumerStatefulWidget {
  final String? videoUrl;
  final String? photoUrl;
  const _StoryMedia({this.videoUrl, this.photoUrl});

  @override
  ConsumerState<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends ConsumerState<_StoryMedia> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
    if (url != null && url.isNotEmpty) {
      _loadVideo(url, attempt: 0);
    }
  }

  /// Charge la video via le cache partage. Si le paged_sheet a preload, le
  /// controller est deja init -> play instantane sans round-trip reseau.
  ///
  /// Retry avec backoff : un signalement tout juste cree pointe vers une
  /// video qui n'est pas encore servie par le CDN Storage (404/403
  /// transitoire) -> la 1ere init echoue, on retombe sur le thumbnail, puis
  /// on retente quelques fois pour que la video finisse par se lancer sans
  /// que l'utilisateur n'ait a rouvrir la story.
  void _loadVideo(String url, {required int attempt}) {
    StoryVideoCache.take(url).then((ctrl) {
      if (!mounted) return;
      _ctrl = ctrl;
      ctrl.seekTo(Duration.zero);
      if (!ref.read(chatInputFocusedProvider)) ctrl.play();
      setState(() => _initialized = true);
    }).catchError((e) {
      debugPrint('[StoryMedia] video take failed (attempt $attempt): $e');
      if (!mounted || _initialized || attempt >= 3) return;
      Future<void>.delayed(
        Duration(milliseconds: 1500 * (attempt + 1)),
        () {
          if (mounted && !_initialized) {
            _loadVideo(url, attempt: attempt + 1);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    // Le controller est partage via StoryVideoCache : on ne dispose PAS ici,
    // sinon on tue la lecture pour un retour swipe arriere. On pause juste.
    final c = _ctrl;
    if (c != null && c.value.isInitialized) {
      try {
        c.pause();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pause/resume video sur chat focus (composer focus ou sheet ouverte).
    ref.listen<bool>(chatInputFocusedProvider, (prev, next) {
      final ctrl = _ctrl;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      if (next) {
        _wasPlayingBeforePause = ctrl.value.isPlaying;
        if (ctrl.value.isPlaying) ctrl.pause();
      } else if (_wasPlayingBeforePause) {
        ctrl.play();
        _wasPlayingBeforePause = false;
      }
    });

    final ctrl = _ctrl;
    if (ctrl != null && _initialized) {
      // FittedBox(cover) garantit le full-bleed quelle que soit l'AR de la
      // video (portrait, paysage, square).
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      );
    }
    // Pas de video (ou pas encore prete) -> photo en attendant
    final photo = widget.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.bgSecondary),
        errorWidget: (_, __, ___) => Container(color: AppColors.bgSecondary),
      );
    }
    return Container(color: AppColors.bgSecondary);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Header story
// ──────────────────────────────────────────────────────────────────────────

class _StoryHeader extends StatelessWidget {
  final String prenom;
  final String? avatarUrl;
  final bool isLive;
  final int? multiplier;
  final String subline;

  const _StoryHeader({
    required this.prenom,
    required this.avatarUrl,
    required this.isLive,
    required this.multiplier,
    required this.subline,
  });

  @override
  Widget build(BuildContext context) {
    final initial = prenom.isNotEmpty ? prenom[0].toUpperCase() : 'L';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar gradient avec initiale
              _AvatarBubble(initial: initial, url: avatarUrl),
              const SizedBox(width: 10),
              // Nom + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            prenom.isNotEmpty ? prenom : 'La commu',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2244),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (multiplier != null) ...[
                          const SizedBox(width: 6),
                          _GlassChip(child: Text(
                            '×$multiplier',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )),
                        ],
                      ],
                    ),
                    if (subline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subline,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String initial;
  final String? url;
  const _AvatarBubble({required this.initial, this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasUrl
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.magenta, AppColors.violet],
              ),
        image: hasUrl
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1.5),
      ),
      alignment: Alignment.center,
      child: hasUrl
          ? null
          : Text(
              initial,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final Widget child;
  const _GlassChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Rail d'actions (right side)
// ──────────────────────────────────────────────────────────────────────────

class _ActionRail extends StatelessWidget {
  final int chatCount;
  final String viewsLabel;
  final VoidCallback onChatTap;
  final VoidCallback? onVideoTap;

  const _ActionRail({
    required this.chatCount,
    required this.viewsLabel,
    required this.onChatTap,
    this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailButton(
          icon: Icons.chat_bubble_outline,
          label: chatCount > 0 ? '$chatCount' : 'discu',
          onTap: onChatTap,
        ),
        const SizedBox(height: 16),
        _RailButton(
          icon: Icons.visibility_outlined,
          label: viewsLabel,
          onTap: null,
        ),
        if (onVideoTap != null) ...[
          const SizedBox(height: 16),
          _RailButton(
            icon: Icons.play_circle_outline,
            label: 'video',
            onTap: onVideoTap,
            highlight: true,
          ),
        ],
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: highlight
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.magenta, AppColors.violet],
                      )
                    : null,
                color: highlight
                    ? null
                    : Colors.black.withValues(alpha: 0.45),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Bottom block : tags + titre + description + CTA "Y aller" + chat secondaire
// ──────────────────────────────────────────────────────────────────────────

class _StoryBottomBlock extends StatelessWidget {
  final String? ville;
  final List<String> tags;
  final String title;
  final String description;
  final VoidCallback onYAller;
  final VoidCallback onChatTap;

  const _StoryBottomBlock({
    required this.ville,
    required this.tags,
    required this.title,
    required this.description,
    required this.onYAller,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = <Widget>[
      if (ville != null && ville!.isNotEmpty)
        _Tag(label: ville!, icon: Icons.place, active: false),
      ...tags.take(3).toList().asMap().entries.map(
            (e) => _Tag(label: '#${e.value}', active: e.key == 0),
          ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allTags.isNotEmpty) ...[
            Wrap(spacing: 6, runSpacing: 6, children: allTags),
            const SizedBox(height: 10),
          ],
          // Titre H1 — spec : 28/900 line-height 1
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 16),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.92),
                shadows: const [
                  Shadow(color: Colors.black87, blurRadius: 8),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryCta(label: 'Y aller', onTap: onYAller),
              ),
              const SizedBox(width: 10),
              _SecondaryRoundButton(
                icon: Icons.chat_bubble_outline,
                onTap: onChatTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  const _Tag({required this.label, this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.magenta,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.magenta, AppColors.violet],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.magenta.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SecondaryRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryRoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Bottom sheet discussion (slide up depuis le bas)
// ──────────────────────────────────────────────────────────────────────────

class _DiscussionSheet extends ConsumerWidget {
  final ReportedEvent event;
  final VoidCallback onYAller;

  const _DiscussionSheet({required this.event, required this.onYAller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = event.generated;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // 90px du haut comme la spec ; on cale via padding top sur le scaffold sheet.
    // maxHeight retire le clavier : sinon le sheet deborde sous le clavier
    // et masque le composer.
    const topInset = 90.0;
    final maxHeight = media.size.height - topInset - keyboard;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Color(0xFF120823),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 60,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Titre + close
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      g?.description.isNotEmpty == true
                          ? g!.description
                          : (g?.title ?? event.rawTitle),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Tags
            if (g != null && g.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (event.ville != null && event.ville!.isNotEmpty)
                      _SheetTag(
                        label: event.ville!,
                        icon: Icons.place,
                        accent: true,
                      ),
                    ...g.tags.take(4).map((t) => _SheetTag(label: t)),
                  ],
                ),
              ),

            // Card "Signalé par"
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: _SignaledByCard(event: event),
            ),

            // Chat : Expanded force a remplir l'espace restant. La liste
            // de messages scrolle, le composer reste colle au bas du chat
            // -> jamais cache par le clavier ni par le CTA.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: ReportedEventChat(eventId: event.id),
              ),
            ),

            // CTA "Y aller" (caché clavier ouvert pour éviter overlap composer)
            if (keyboard == 0)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: GestureDetector(
                    onTap: onYAller,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.magenta, AppColors.violet],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.place,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Y aller',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool accent;
  const _SheetTag({required this.label, this.icon, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? AppColors.magenta.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final color = accent ? AppColors.magenta : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaledByCard extends StatelessWidget {
  final ReportedEvent event;
  const _SignaledByCard({required this.event});

  String _age(DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final prenom = event.reporterPrenom ?? 'Anonyme';
    final initial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _AvatarBubble(initial: initial, url: event.reporterAvatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(text: 'Signalé par '),
                      TextSpan(
                        text: prenom,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.magenta,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _age(event.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

