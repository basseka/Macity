import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/presentation/add_event_bottom_sheet.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Etape 0 — Essentiel.
/// Champs obligatoires pour publier : categorie (parmi les 7 du feed),
/// titre, photo/video, date+heure, adresse, prix (toggle gratuit + montant).
class StepEssentials extends ConsumerStatefulWidget {
  const StepEssentials({super.key});

  @override
  ConsumerState<StepEssentials> createState() => _StepEssentialsState();
}

class _StepEssentialsState extends ConsumerState<StepEssentials> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);

  late final TextEditingController _titreController;
  late final TextEditingController _adresseController;
  late final TextEditingController _prixController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _billetterieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _adresseController = TextEditingController();
    _prixController = TextEditingController();
    _descriptionController = TextEditingController();
    _billetterieController = TextEditingController();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _adresseController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    _billetterieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);
    final city = ref.watch(selectedCityProvider);
    final isPro =
        ref.watch(proAuthProvider).status == ProAuthStatus.approved;

    if (!_initialized) {
      _initialized = true;
      _titreController.text = state.titre;
      _adresseController.text = state.lieuAdresse;
      _prixController.text = state.prix;
      _descriptionController.text = state.descriptionCourte;
      _billetterieController.text = state.lienBilletterie;
      if (state.ville.isEmpty) {
        Future.microtask(() => notifier.updateVille(city));
      }
    }

    ref.listen<CreateEventState>(createEventProvider, (prev, next) {
      if (prev != null && prev.prefillRevision != next.prefillRevision) {
        _titreController.text = next.titre;
        _adresseController.text = next.lieuAdresse;
        _prixController.text = next.prix;
        _descriptionController.text = next.descriptionCourte;
        _billetterieController.text = next.lienBilletterie;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'L\'essentiel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkColor),
          ),
          const SizedBox(height: 2),
          Text(
            'Le minimum pour publier ton event.',
            style: TextStyle(fontSize: 12, color: AppColors.textFaint),
          ),
          const SizedBox(height: 14),

          // Scan IA (pros uniquement).
          if (isPro && !state.isEditing) ...[
            InkWell(
              onTap: () => AddEventBottomSheet.triggerScanFlow(
                context: context,
                ref: ref,
                alreadyOnWizard: true,
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanner un flyer (IA)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Remplit tout automatiquement',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Categorie : 7 chips alignes sur le feed
          _label('Catégorie *'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kEventCategories.map((cat) {
              final selected = state.categorie == cat;
              return ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                selected: selected,
                selectedColor: _primaryColor.withValues(alpha: 0.15),
                checkmarkColor: _primaryColor,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => notifier.updateCategorie(cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 2. Titre
          TextFormField(
            controller: _titreController,
            decoration: _input('Titre de l\'évènement *'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            onChanged: notifier.updateTitre,
          ),
          const SizedBox(height: 14),

          // 2bis. Description courte
          TextFormField(
            controller: _descriptionController,
            decoration: _input('Description (optionnel)'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            maxLines: 3,
            minLines: 2,
            maxLength: 300,
            onChanged: notifier.updateDescriptionCourte,
          ),
          const SizedBox(height: 6),

          // 2ter. Lien billetterie / site web
          TextFormField(
            controller: _billetterieController,
            decoration: _input('Lien billetterie ou site web (optionnel)'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            keyboardType: TextInputType.url,
            onChanged: notifier.updateLienBilletterie,
          ),
          const SizedBox(height: 14),

          // 3. Vidéo + Photo (vidéo en premier pour inciter au teaser)
          _label('Vidéo teaser (recommandée, 30s max)'),
          const SizedBox(height: 6),
          _VideoPicker(
            videoPath: state.videoPath,
            onPicked: notifier.updateVideoPath,
          ),
          const SizedBox(height: 10),
          _label('Photo *'),
          const SizedBox(height: 6),
          _PhotoPicker(
            photoPath: state.photoPath,
            existingPhotoUrl: state.existingPhotoUrl,
            onPicked: notifier.updatePhotoPath,
          ),
          const SizedBox(height: 14),

          // 4. Date + heure
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Date *',
                  value: state.dateDebut,
                  onPicked: notifier.updateDateDebut,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimePickerField(
                  label: 'Heure *',
                  value: state.heureDebut,
                  onPicked: notifier.updateHeureDebut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Adresse + ville (ville auto)
          TextFormField(
            controller: _adresseController,
            decoration: _input('Adresse *'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            onChanged: notifier.updateLieuAdresse,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_city, size: 14, color: _primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      state.ville.isNotEmpty ? state.ville : city,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _darkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 6. Prix : toggle gratuit + montant
          SwitchListTile(
            value: state.estGratuit,
            onChanged: notifier.updateEstGratuit,
            title: const Text(
              'Évènement gratuit',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            activeTrackColor: _primaryColor.withValues(alpha: 0.4),
            thumbColor: const WidgetStatePropertyAll(_primaryColor),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (!state.estGratuit) ...[
            const SizedBox(height: 6),
            TextFormField(
              controller: _prixController,
              decoration: _input('Prix (€)'),
              style: const TextStyle(fontSize: 13, color: AppColors.text),
              keyboardType: TextInputType.number,
              onChanged: notifier.updatePrix,
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  static Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkColor),
    );
  }

  static InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: AppColors.textFaint),
      filled: true,
      fillColor: AppColors.surfaceHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Pickers (photo / video / date / time)
// ──────────────────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final String? existingPhotoUrl;
  final ValueChanged<String> onPicked;

  const _PhotoPicker({
    required this.photoPath,
    required this.onPicked,
    this.existingPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null ||
        (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty);
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto
                ? const Color(0xFF7B2D8E).withValues(alpha: 0.3)
                : AppColors.line,
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        child: photoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  File(photoPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            : (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      existingPhotoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.lineStrong),
        const SizedBox(height: 6),
        Text(
          'Appuie pour ajouter une photo',
          style: TextStyle(fontSize: 11, color: AppColors.textFaint),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 20),
              title: const Text('Caméra', style: TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 20),
              title: const Text('Galerie', style: TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final xFile = await ImagePicker().pickImage(source: source, maxWidth: 1024);
    if (xFile != null) onPicked(xFile.path);
  }
}

class _VideoPicker extends StatelessWidget {
  final String? videoPath;
  final ValueChanged<String> onPicked;
  const _VideoPicker({required this.videoPath, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: videoPath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.videocam, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Vidéo',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 6),
                  Text(
                    'Ajouter\n(30 sec max)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, size: 20),
              title: const Text('Caméra', style: TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library, size: 20),
              title: const Text('Galerie', style: TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final xFile = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (xFile != null) onPicked(xFile.path);
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  void _showPicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var selected = value ?? today;
    if (selected.isBefore(today)) selected = today;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final pickerHeight = screenHeight * 0.8 < 320 ? screenHeight * 0.8 : 320.0;
        return Container(
          height: pickerHeight + bottomPadding,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler', style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                    ),
                    const Text('Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPicked(selected);
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.magenta,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(fontSize: 20, color: AppColors.text),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumDate: today,
                    maximumDate: today.add(const Duration(days: 365)),
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? _primaryColor.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primaryColor.withValues(alpha: 0.3) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue ? DateFormat('d MMM yyyy', 'fr_FR').format(value!) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  static const _primaryColor = Color(0xFF7B2D8E);

  void _showPicker(BuildContext context) {
    final now = DateTime.now();
    final defaultMinute = (value?.minute ?? 0);
    final roundedMinute = (defaultMinute / 5).round() * 5;
    var selected = value != null
        ? DateTime(now.year, now.month, now.day, value!.hour, roundedMinute.clamp(0, 55))
        : DateTime(now.year, now.month, now.day, 20, 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final pickerHeight = screenHeight * 0.8 < 320 ? screenHeight * 0.8 : 320.0;
        return Container(
          height: pickerHeight + bottomPadding,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler', style: TextStyle(color: AppColors.textFaint, fontSize: 14)),
                    ),
                    const Text('Heure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onPicked(TimeOfDay(hour: selected.hour, minute: selected.minute));
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.magenta, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppColors.magenta,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(fontSize: 22, color: AppColors.text),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selected,
                    use24hFormat: true,
                    minuteInterval: 5,
                    onDateTimeChanged: (dt) => selected = dt,
                  ),
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? _primaryColor.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? _primaryColor.withValues(alpha: 0.3) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: hasValue ? _primaryColor : AppColors.textFaint),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasValue ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}' : label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasValue ? _primaryColor : AppColors.textFaint,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
