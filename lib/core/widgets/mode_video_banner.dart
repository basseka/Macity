import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);
    final videoAsync = ref.watch(modeBannerVideoProvider);

    return videoAsync.when(
      data: (url) {
        // Pas de vidéo pour cette ville/mode → ne rien afficher
        if (url == null || url.isEmpty) return const SizedBox.shrink();

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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.hero),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                border: Border.all(color: AppColors.line),
              ),
              child: isReady
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : Container(
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
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
