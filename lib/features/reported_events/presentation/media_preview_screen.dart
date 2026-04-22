import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:pulz_app/features/reported_events/state/report_form_provider.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Ecran preview plein ecran style Snapchat.
///
/// Affiche la photo ou video capturee avec une interface overlay :
/// - Categories en chips horizontaux animes
/// - Champ titre flottant
/// - Champ lieu (pre-rempli par reverse geocode)
/// - Bouton publier
class MediaPreviewScreen extends ConsumerStatefulWidget {
  final String? photoPath;
  final String? videoPath;
  final String initialCategory;

  const MediaPreviewScreen({
    super.key,
    this.photoPath,
    this.videoPath,
    this.initialCategory = '',
  });

  @override
  ConsumerState<MediaPreviewScreen> createState() =>
      _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends ConsumerState<MediaPreviewScreen>
    with TickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  VideoPlayerController? _videoCtrl;
  late AnimationController _chipsAnimCtrl;
  late AnimationController _bottomAnimCtrl;
  bool _locationPrefilled = false;

  static const _categories = <_CatDef>[
    _CatDef('concert', Icons.music_note_rounded, 'Concert', Color(0xFF7C3AED)),
    _CatDef('soiree', Icons.nightlife_rounded, 'Soiree', Color(0xFFEC4899)),
    _CatDef('fete', Icons.celebration_rounded, 'Fete', Color(0xFFE91E8C)),
    _CatDef('festival', Icons.festival_rounded, 'Festival', Color(0xFF6C5CE7)),
    _CatDef('marche', Icons.storefront_rounded, 'Marche', Color(0xFF10B981)),
    _CatDef('sport', Icons.sports_soccer_rounded, 'Sport', Color(0xFFE11D48)),
    _CatDef('food', Icons.restaurant_rounded, 'Food', Color(0xFFD97706)),
    _CatDef('exposition', Icons.palette_rounded, 'Expo', Color(0xFF0891B2)),
    _CatDef('salon', Icons.groups_rounded, 'Salon', Color(0xFF059669)),
    _CatDef('autre', Icons.more_horiz_rounded, 'Autre', Color(0xFF64748B)),
  ];

  bool get _isVideo => widget.videoPath != null;

  @override
  void initState() {
    super.initState();

    // Animations
    _chipsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bottomAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Lance les animations apres le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chipsAnimCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _bottomAnimCtrl.forward();
      });

      // GPS + reverse geocode
      ref.read(reportFormProvider.notifier).initLocation();

      // Pre-remplir categorie depuis le camera screen
      if (widget.initialCategory.isNotEmpty) {
        ref.read(reportFormProvider.notifier).setCategory(widget.initialCategory);
      }

      // Pre-remplir le media
      if (widget.photoPath != null) {
        ref.read(reportFormProvider.notifier).setPhoto(widget.photoPath);
      }
      if (widget.videoPath != null) {
        ref.read(reportFormProvider.notifier).setVideo(widget.videoPath!);
      }
    });

    // Init video player si video
    if (_isVideo) {
      _videoCtrl = VideoPlayerController.file(File(widget.videoPath!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoCtrl!.setLooping(true);
            _videoCtrl!.play();
          }
        });
    }

    // Immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _videoCtrl?.dispose();
    _chipsAnimCtrl.dispose();
    _bottomAnimCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(reportFormProvider.notifier);
    notifier.setTitle(_titleCtrl.text);
    notifier.setLocationName(_locationCtrl.text);
    final result = await notifier.submit();
    if (!mounted) return;
    if (result != null) {
      // Garder une ref au container avant le pop
      final container = ProviderScope.containerOf(context);
      Navigator.of(context).pop();
      // Refresh immediat (affiche le shimmer ai_generating)
      container.invalidate(reportedEventsFeedProvider);
      // Refresh apres ~4s (l'edge function aura fini, status=published)
      Future.delayed(const Duration(seconds: 4), () {
        container.invalidate(reportedEventsFeedProvider);
      });
      // Refresh supplementaire a ~8s (securite)
      Future.delayed(const Duration(seconds: 8), () {
        container.invalidate(reportedEventsFeedProvider);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7B2D8E),
          content: Text(
            'Signale ! L\'affiche se prepare...',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportFormProvider);

    // Pre-remplir le lieu une seule fois
    if (!_locationPrefilled &&
        state.locationName.isNotEmpty &&
        _locationCtrl.text.isEmpty) {
      _locationCtrl.text = state.locationName;
      _locationPrefilled = true;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Media background ──
          if (_isVideo && _videoCtrl != null && _videoCtrl!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoCtrl!.value.aspectRatio,
                child: VideoPlayer(_videoCtrl!),
              ),
            )
          else if (_isVideo)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (widget.photoPath != null)
            Image.file(
              File(widget.photoPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

          // ── Gradient overlay top ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Gradient overlay bottom ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar : close + GPS status ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _GlassButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                // GPS indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.lat != null
                            ? Icons.my_location
                            : Icons.location_searching,
                        size: 12,
                        color: state.lat != null
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.lat != null ? 'GPS OK' : 'Localisation...',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isVideo)
                  _GlassButton(
                    icon: _videoCtrl?.value.isPlaying ?? false
                        ? Icons.pause
                        : Icons.play_arrow,
                    onTap: () {
                      setState(() {
                        if (_videoCtrl!.value.isPlaying) {
                          _videoCtrl!.pause();
                        } else {
                          _videoCtrl!.play();
                        }
                      });
                    },
                  ),
              ],
            ),
          ),

          // ── Categories chips (animated) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _chipsAnimCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _chipsAnimCtrl,
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = state.category == cat.id;
                      return GestureDetector(
                        onTap: () => ref
                            .read(reportFormProvider.notifier)
                            .setCategory(cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                cat.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
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
            ),
          ),

          // ── Bottom : location + title + publish ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 14,
            right: 14,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _bottomAnimCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _bottomAnimCtrl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lieu + Titre dans un seul bloc compact
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade800,
                        ),
                      ),
                      child: Column(
                        children: [
                          _InlineField(
                            controller: _locationCtrl,
                            label: 'Lieu',
                            hint: 'Bar, rue, place...',
                            icon: Icons.place,
                            maxLength: 80,
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          _InlineField(
                            controller: _titleCtrl,
                            label: 'Titre',
                            hint: 'En quelques mots...',
                            icon: Icons.edit,
                            maxLength: 50,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Annuler + Publier
                    Row(
                      children: [
                        // Annuler
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Publier
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed:
                                  state.canSubmit && !state.isSubmitting
                                      ? _submit
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                disabledForegroundColor:
                                    Colors.white.withValues(alpha: 0.4),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: state.isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: Text(
                                state.isSubmitting ? 'Envoi...' : 'Publier',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Error
                    if (state.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Widgets glass-morphism
// ───────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLength;

  const _InlineField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(icon, size: 14, color: AppColors.textFaint),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textFaint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              cursorColor: Colors.white,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textDim,
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
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
