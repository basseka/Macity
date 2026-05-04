import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';

class ModeVideoBanner extends ConsumerStatefulWidget {
  const ModeVideoBanner({super.key});

  @override
  ConsumerState<ModeVideoBanner> createState() => _ModeVideoBannerState();
}

class _ModeVideoBannerState extends ConsumerState<ModeVideoBanner> {
  VideoPlayerController? _controller;
  String? _currentUrl;
  bool _hasError = false;

  void _initController(String url) {
    _currentUrl = url;
    _hasError = false;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    controller.setLooping(true);
    controller.setVolume(0);
    controller.initialize().then((_) {
      if (mounted) {
        controller.play();
        setState(() {});
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);
    final bannerAsync = ref.watch(modeBannerVideoProvider);

    return bannerAsync.when(
      data: (banner) {
        if (banner == null) return const SizedBox.shrink();
        final url = banner.videoUrl;

        // Changer de vidéo si l'URL a changé
        if (_currentUrl != url) {
          _disposeController();
          _initController(url);
        }

        final controller = _controller;
        final size = controller?.value.size;
        final isReady = controller != null &&
            controller.value.isInitialized &&
            !_hasError &&
            size != null &&
            size.width > 0 &&
            size.height > 0;

        final video = Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        modeTheme.primaryColor,
                        modeTheme.primaryDarkColor,
                      ],
                    ),
                  ),
                  child: _hasError
                      ? null
                      : const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                        ),
                ),
              // Pill discret "En savoir plus" en bas-droite si link_url
              if (banner.linkUrl != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _openLink(banner.linkUrl!),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'En savoir plus',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        // Si link_url present, tap n'importe ou sur le banner ouvre l'URL.
        return banner.linkUrl != null
            ? GestureDetector(
                onTap: () => _openLink(banner.linkUrl!),
                child: video,
              )
            : video;
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
