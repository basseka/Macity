import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/features/reported_events/state/report_form_provider.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Modal de signalement Waze-style — 1 ecran ultra-leger.
///
/// Flow :
/// 1. Auto-locate GPS au open
/// 2. Mini-carte avec pin draggable
/// 3. Selecteur de categorie (6 boutons emoji)
/// 4. Titre court optionnel
/// 5. Photo optionnelle
/// 6. CTA "Signaler ici"
class ReportEventModal extends ConsumerStatefulWidget {
  final String? initialVideoPath;
  const ReportEventModal({super.key, this.initialVideoPath});

  @override
  ConsumerState<ReportEventModal> createState() => _ReportEventModalState();
}

class _ReportEventModalState extends ConsumerState<ReportEventModal> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportFormProvider.notifier).initLocation();
      // Si lance depuis le bouton video, pre-remplir le chemin video
      if (widget.initialVideoPath != null) {
        ref.read(reportFormProvider.notifier).setVideo(widget.initialVideoPath!);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final xFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
        requestFullMetadata: false,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xFile != null && mounted) {
        ref.read(reportFormProvider.notifier).setPhoto(xFile.path);
      }
    } catch (e) {
      debugPrint('[ReportEventModal] pickPhoto failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Echec du chargement de la photo',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final notifier = ref.read(reportFormProvider.notifier);
    notifier.setTitle(_titleCtrl.text);
    notifier.setLocationName(_locationCtrl.text);
    final id = await notifier.submit();
    if (!mounted) return;
    if (id != null) {
      // Invalide le feed pour recharger apres ~3s (le temps que l'edge function finisse)
      Future.delayed(const Duration(seconds: 3), () {
        ref.invalidate(reportedEventsFeedProvider);
      });
      // Et un refresh immediat aussi pour voir le placeholder shimmer
      ref.invalidate(reportedEventsFeedProvider);
      Navigator.of(context).pop();
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
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.95,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F0FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 4, 4),
              child: Row(
                children: [
                  const Text('📍', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Signaler ce qui bouge',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1259),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.close, color: Color(0xFF4A1259)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Localisation GPS (sans carte)
                    _LocationBadge(state: state),
                    const SizedBox(height: 10),

                    // Lieu (pre-rempli par reverse geocoding, editable)
                    _LocationNameField(
                      controller: _locationCtrl,
                      state: state,
                    ),
                    const SizedBox(height: 14),

                    // Categorie
                    Text(
                      'C\'est quoi ?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1259),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CategoryGrid(
                      selected: state.category,
                      onSelect: (c) =>
                          ref.read(reportFormProvider.notifier).setCategory(c),
                    ),

                    const SizedBox(height: 14),

                    // Titre court
                    TextField(
                      controller: _titleCtrl,
                      maxLength: 50,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _placeholderForCategory(state.category),
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF7B2D8E),
                            width: 1.4,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        counterText: '',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Photo optionnelle
                    _PhotoButton(
                      photoPath: state.localPhotoPath,
                      onPick: () => _showPhotoSheet(),
                      onClear: () =>
                          ref.read(reportFormProvider.notifier).setPhoto(null),
                    ),

                    // Video attachee (depuis le bouton camera)
                    if (state.localVideoPath != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2D8E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF7B2D8E).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.videocam,
                              size: 16,
                              color: Color(0xFF7B2D8E),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Video attachee (10s max)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A1259),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (state.error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 14,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // CTA bottom
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: state.canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                        : const Icon(Icons.flag, size: 16),
                    label: Text(
                      state.isSubmitting ? 'Envoi...' : 'Signaler ici',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7B2D8E)),
              title: Text(
                'Prendre une photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _pickPhoto(ImageSource.camera);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF7B2D8E)),
              title: Text(
                'Choisir depuis la galerie',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _pickPhoto(ImageSource.gallery);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _placeholderForCategory(String c) {
    switch (c) {
      case 'concert':
        return 'ex: Concert improvise dans la rue';
      case 'soiree':
        return 'ex: Soiree au bar/club...';
      case 'fete':
        return 'ex: Fete de quartier place...';
      case 'festival':
        return 'ex: Festival musique au parc';
      case 'marche':
        return 'ex: Marche de Noel sur...';
      case 'sport':
        return 'ex: Tournoi 3x3 au parc';
      case 'food':
        return 'ex: Food truck devant...';
      case 'exposition':
        return 'ex: Expo photo au musee...';
      case 'salon':
        return 'ex: Salon du livre place...';
      default:
        return 'Decris en quelques mots...';
    }
  }
}

// ───────────────────────────────────────────
// Badge de localisation (sans carte)
// ───────────────────────────────────────────

class _LocationBadge extends ConsumerWidget {
  final ReportFormState state;
  const _LocationBadge({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // En cours de localisation
    if (state.isLocating || (state.lat == null && state.error == null)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'On te localise...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Echec
    if (state.lat == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.error ?? 'Impossible de te localiser',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () =>
                  ref.read(reportFormProvider.notifier).initLocation(),
              child: Text(
                'Reessayer',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B2D8E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Localise OK
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0D6F7).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7B2D8E).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.my_location_rounded,
            size: 18,
            color: Color(0xFF7B2D8E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Position GPS detectee',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A1259),
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Colors.green.shade600,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Grille de categories
// ───────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({required this.selected, required this.onSelect});

  static const _categories = <_CatItem>[
    _CatItem('concert', Icons.music_note_rounded, 'Concert',
        Color(0xFF7C3AED), Color(0xFF9333EA),),
    _CatItem('soiree', Icons.nightlife_rounded, 'Soiree',
        Color(0xFFEC4899), Color(0xFFF472B6),),
    _CatItem('fete', Icons.celebration_rounded, 'Fete',
        Color(0xFFE91E8C), Color(0xFFEC4899),),
    _CatItem('festival', Icons.festival_rounded, 'Festival',
        Color(0xFF6C5CE7), Color(0xFFA29BFE),),
    _CatItem('marche', Icons.storefront_rounded, 'Marche',
        Color(0xFF10B981), Color(0xFF34D399),),
    _CatItem('sport', Icons.sports_soccer_rounded, 'Sport',
        Color(0xFFE11D48), Color(0xFFFB7185),),
    _CatItem('food', Icons.restaurant_rounded, 'Food',
        Color(0xFFD97706), Color(0xFFFBBF24),),
    _CatItem('exposition', Icons.palette_rounded, 'Expo',
        Color(0xFF0891B2), Color(0xFF22D3EE),),
    _CatItem('salon', Icons.groups_rounded, 'Salon',
        Color(0xFF059669), Color(0xFF6EE7B7),),
    _CatItem('autre', Icons.more_horiz_rounded, 'Autre',
        Color(0xFF64748B), Color(0xFF94A3B8),),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = cat.id == selected;
        return GestureDetector(
          onTap: () => onSelect(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: (MediaQuery.of(context).size.width - 28 - 16) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cat.colorStart, cat.colorEnd],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cat.colorStart : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cat.colorStart.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : cat.colorStart.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat.icon,
                    size: 20,
                    color: isSelected ? Colors.white : cat.colorStart,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF4A1259),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CatItem {
  final String id;
  final IconData icon;
  final String label;
  final Color colorStart;
  final Color colorEnd;
  const _CatItem(this.id, this.icon, this.label, this.colorStart, this.colorEnd);
}

// ───────────────────────────────────────────
// Bouton photo
// ───────────────────────────────────────────

class _PhotoButton extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PhotoButton({
    required this.photoPath,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(photoPath!),
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Photo ajoutee',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A1259),
                ),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 14,
                icon: const Icon(Icons.close),
                onPressed: onClear,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0D6F7).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7B2D8E).withValues(alpha: 0.3),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              size: 18,
              color: Color(0xFF7B2D8E),
            ),
            const SizedBox(width: 8),
            Text(
              'Ajouter une photo (optionnel)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A1259),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────
// Champ lieu (reverse geocode + editable)
// ───────────────────────────────────────────

class _LocationNameField extends StatefulWidget {
  final TextEditingController controller;
  final ReportFormState state;

  const _LocationNameField({
    required this.controller,
    required this.state,
  });

  @override
  State<_LocationNameField> createState() => _LocationNameFieldState();
}

class _LocationNameFieldState extends State<_LocationNameField> {
  bool _prefilled = false;

  @override
  void didUpdateWidget(covariant _LocationNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pre-remplir une seule fois quand le reverse geocode arrive
    if (!_prefilled &&
        widget.state.locationName.isNotEmpty &&
        widget.controller.text.isEmpty) {
      widget.controller.text = widget.state.locationName;
      _prefilled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLength: 80,
      style: GoogleFonts.poppins(fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Bar, rue, place...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          Icons.place_outlined,
          size: 16,
          color: Colors.grey.shade500,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        suffixIcon: widget.state.locationName.isNotEmpty &&
                widget.controller.text.isEmpty
            ? const SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF7B2D8E),
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        counterText: '',
      ),
    );
  }
}
