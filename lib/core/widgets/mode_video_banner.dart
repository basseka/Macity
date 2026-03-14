import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/core/constants/video_constants.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

class ModeVideoBanner extends ConsumerStatefulWidget {
  const ModeVideoBanner({super.key});

  @override
  ConsumerState<ModeVideoBanner> createState() => _ModeVideoBannerState();
}

class _ModeVideoBannerState extends ConsumerState<ModeVideoBanner> {
  VideoPlayerController? _controller;
  String? _currentKey;
  bool _hasError = false;

  void _initController(String modeName, String ville) {
    final mode = AppMode.fromName(modeName);
    final url = VideoConstants.bannerVideoUrl(mode, ville);
    if (url == null) return;

    _currentKey = '${modeName}_$ville';
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
    final ville = ref.watch(selectedCityProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final key = '${modeName}_$ville';

    if (_currentKey != key) {
      _disposeController();
      _initController(modeName, ville);
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
