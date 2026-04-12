import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/reported_events/presentation/media_preview_screen.dart';

/// Ecran camera plein ecran style Snapchat.
///
/// - Preview live camera en fond
/// - Categories en overlay (selectables avant capture)
/// - Bouton central : tap = photo, long press = video (max 10s)
/// - Animation du bouton pendant l'enregistrement
/// - Flip camera
class SnapCameraScreen extends StatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  State<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends State<SnapCameraScreen>
    with TickerProviderStateMixin {
  CameraController? _camCtrl;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isReady = false;
  bool _isRecording = false;
  String _selectedCategory = '';

  // Animation du bouton d'enregistrement
  late AnimationController _recordAnimCtrl;
  late Animation<double> _recordScale;
  late Animation<double> _recordProgress;

  // Timer 10s max
  static const _maxRecordDuration = Duration(seconds: 10);

  static const _categories = <_CatDef>[
    _CatDef('concert', Icons.music_note_rounded, 'Concert', Color(0xFF7C3AED)),
    _CatDef('fete', Icons.celebration_rounded, 'Fete', Color(0xFFE91E8C)),
    _CatDef('festival', Icons.festival_rounded, 'Festival', Color(0xFF6C5CE7)),
    _CatDef('marche', Icons.storefront_rounded, 'Marche', Color(0xFF10B981)),
    _CatDef('sport', Icons.sports_soccer_rounded, 'Sport', Color(0xFFE11D48)),
    _CatDef('food', Icons.restaurant_rounded, 'Food', Color(0xFFD97706)),
    _CatDef('exposition', Icons.palette_rounded, 'Expo', Color(0xFF0891B2)),
    _CatDef('salon', Icons.groups_rounded, 'Salon', Color(0xFF059669)),
    _CatDef('autre', Icons.more_horiz_rounded, 'Autre', Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _recordAnimCtrl = AnimationController(
      vsync: this,
      duration: _maxRecordDuration,
    );
    _recordScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(
        parent: _recordAnimCtrl,
        curve: const Interval(0, 0.1, curve: Curves.easeOut),
      ),
    );
    _recordProgress = Tween<double>(begin: 0, end: 1).animate(_recordAnimCtrl);
    _recordAnimCtrl.addStatusListener((status) {
      // Auto-stop a 10s
      if (status == AnimationStatus.completed && _isRecording) {
        _stopVideo();
      }
    });

    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    await _setupCamera(_cameraIndex);
  }

  Future<void> _setupCamera(int index) async {
    _camCtrl?.dispose();
    _camCtrl = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await _camCtrl!.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      debugPrint('[SnapCamera] init failed: $e');
    }
  }

  void _flipCamera() {
    if (_cameras.length < 2 || _isRecording) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isReady = false;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    });
    _setupCamera(_cameraIndex);
  }

  // ── Capture photo ──
  Future<void> _takePhoto() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    HapticFeedback.mediumImpact();
    try {
      final xFile = await _camCtrl!.takePicture();
      if (!mounted) return;
      _goToPreview(photoPath: xFile.path);
    } catch (e) {
      debugPrint('[SnapCamera] photo failed: $e');
    }
  }

  // ── Start video ──
  Future<void> _startVideo() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    HapticFeedback.heavyImpact();
    try {
      await _camCtrl!.startVideoRecording();
      setState(() => _isRecording = true);
      _recordAnimCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('[SnapCamera] video start failed: $e');
    }
  }

  // ── Stop video ──
  Future<void> _stopVideo() async {
    if (_camCtrl == null || !_isRecording) return;
    HapticFeedback.lightImpact();
    _recordAnimCtrl.stop();
    setState(() => _isRecording = false);
    try {
      final xFile = await _camCtrl!.stopVideoRecording();
      if (!mounted) return;
      _goToPreview(videoPath: xFile.path);
    } catch (e) {
      debugPrint('[SnapCamera] video stop failed: $e');
    }
  }

  void _goToPreview({String? photoPath, String? videoPath}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MediaPreviewScreen(
          photoPath: photoPath,
          videoPath: videoPath,
          initialCategory: _selectedCategory,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _recordAnimCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──
          if (_isReady && _camCtrl != null)
            Center(
              child: CameraPreview(_camCtrl!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Top gradient ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar : close + flip ──
          Positioned(
            top: mq.padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _GlassBtn(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _GlassBtn(
                  icon: Icons.flip_camera_android,
                  onTap: _flipCamera,
                ),
              ],
            ),
          ),

          // ── Categories chips (overlay, avant capture) ──
          Positioned(
            top: mq.padding.top + 56,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory =
                            isSelected ? '' : cat.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color
                            : Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Bottom gradient ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Hint text ──
          Positioned(
            bottom: mq.padding.bottom + 110,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isRecording ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Appuie = photo  ·  Maintiens = video',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          // ── Capture button ──
          Positioned(
            bottom: mq.padding.bottom + 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _recordAnimCtrl,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _recordScale.value : 1.0,
                    child: GestureDetector(
                      onTap: _isRecording ? null : _takePhoto,
                      onLongPressStart: (_) => _startVideo(),
                      onLongPressEnd: (_) {
                        if (_isRecording) _stopVideo();
                      },
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _CaptureButtonPainter(
                            progress: _isRecording
                                ? _recordProgress.value
                                : 0,
                            isRecording: _isRecording,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Recording timer ──
          if (_isRecording)
            Positioned(
              bottom: mq.padding.bottom + 120,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _recordProgress,
                builder: (context, _) {
                  final seconds =
                      (_recordProgress.value * 10).ceil().clamp(0, 10);
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${seconds}s / 10s',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Bouton capture custom (cercle + arc progress)
// ───────────────────────────────────────────

class _CaptureButtonPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  _CaptureButtonPainter({
    required this.progress,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 6;

    // Outer ring (blanc)
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Inner circle
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = isRecording
            ? const Color(0xFFDC2626)
            : Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // Progress arc (rouge) pendant l'enregistrement
    if (isRecording && progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: outerRadius);
      canvas.drawArc(
        rect,
        -3.14159 / 2, // start from top
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CaptureButtonPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      isRecording != oldDelegate.isRecording;
}

// ───────────────────────────────────────────
// Glass button
// ───────────────────────────────────────────

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CatDef {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  const _CatDef(this.id, this.icon, this.label, this.color);
}
