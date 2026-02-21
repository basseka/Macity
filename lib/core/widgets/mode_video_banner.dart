import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

class ModeVideoBanner extends ConsumerStatefulWidget {
  const ModeVideoBanner({super.key});

  @override
  ConsumerState<ModeVideoBanner> createState() => _ModeVideoBannerState();
}

class _ModeVideoBannerState extends ConsumerState<ModeVideoBanner> {
  VideoPlayerController? _controller;
  String? _currentMode;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  void _initController(String modeName) {
    final mode = AppMode.fromName(modeName);
    final url = VideoConstants.bannerVideos[mode];
    if (url == null) return;

    _currentMode = modeName;
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
    final modeName = ref.watch(currentModeProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    if (_currentMode != modeName) {
      _disposeController();
      _initController(modeName);
    }

    final controller = _controller;
    final isReady =
        controller != null && controller.value.isInitialized && !_hasError;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120,
          width: double.infinity,
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
  }
}
