import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';

class StepExtras extends ConsumerStatefulWidget {
  const StepExtras({super.key});

  @override
  ConsumerState<StepExtras> createState() => _StepExtrasState();
}

class _StepExtrasState extends ConsumerState<StepExtras> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);
  late final TextEditingController _videoUrlController;
  late final TextEditingController _tagController;
  late final TextEditingController _ageMinController;
  late final TextEditingController _materielController;
  late final TextEditingController _annulationController;
  bool _initialized = false;

  static const _accessibiliteOptions = [
    'Acces handicape',
    'Parking',
    'Transport en commun',
  ];

  @override
  void initState() {
    super.initState();
    _videoUrlController = TextEditingController();
    _tagController = TextEditingController();
    _ageMinController = TextEditingController();
    _materielController = TextEditingController();
    _annulationController = TextEditingController();
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _tagController.dispose();
    _ageMinController.dispose();
    _materielController.dispose();
    _annulationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    if (!_initialized) {
      _initialized = true;
      _videoUrlController.text = state.videoUrl;
      _ageMinController.text = state.ageMinimum;
      _materielController.text = state.materielRequis;
      _annulationController.text = state.conditionsAnnulation;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Extras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Optionnel',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Galerie photos
          _sectionLabel('Galerie photos (max 5)'),
          const SizedBox(height: 6),
          _GalleryPicker(
            paths: state.galleryPaths,
            onChanged: notifier.updateGalleryPaths,
          ),
          const SizedBox(height: 14),

          // Video URL
          TextFormField(
            controller: _videoUrlController,
            decoration: _inputDecoration('URL video (YouTube, etc.)'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            keyboardType: TextInputType.url,
            onChanged: notifier.updateVideoUrl,
          ),
          const SizedBox(height: 14),

          // Tags
          _sectionLabel('Tags / mots-cles'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...state.tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.text)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () {
                      final updated = List<String>.from(state.tags)..remove(tag);
                      notifier.updateTags(updated);
                    },
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  decoration: _inputDecoration('Ajouter un tag'),
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                  onFieldSubmitted: (v) => _addTag(v, state, notifier),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.add_circle, color: _primaryColor, size: 22),
                onPressed: () => _addTag(_tagController.text, state, notifier),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Programme
          _subsectionLabel('Programme'),
          const SizedBox(height: 6),
          ...state.programme.asMap().entries.map((entry) {
            final i = entry.key;
            final session = entry.value;
            return _ProgrammeSessionRow(
              index: i,
              session: session,
              onChanged: (updated) {
                final list = List<ProgrammeSession>.from(state.programme);
                list[i] = updated;
                notifier.updateProgramme(list);
              },
              onRemoved: () {
                final list = List<ProgrammeSession>.from(state.programme)
                  ..removeAt(i);
                notifier.updateProgramme(list);
              },
            );
          }),
          TextButton.icon(
            onPressed: () {
              final list = List<ProgrammeSession>.from(state.programme)
                ..add(const ProgrammeSession());
              notifier.updateProgramme(list);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter une session', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 14),

          // Accessibilite
          _sectionLabel('Accessibilite'),
          const SizedBox(height: 4),
          ...Iterable.generate(_accessibiliteOptions.length, (i) {
            final opt = _accessibiliteOptions[i];
            return CheckboxListTile(
              value: state.accessibilite.contains(opt),
              title: Text(opt, style: const TextStyle(fontSize: 12, color: AppColors.text)),
              activeColor: _primaryColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => notifier.toggleAccessibilite(opt),
            );
          }),
          const SizedBox(height: 14),

          // Regles
          _subsectionLabel('Regles'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageMinController,
            decoration: _inputDecoration('Age minimum'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            keyboardType: TextInputType.number,
            onChanged: notifier.updateAgeMinimum,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _materielController,
            decoration: _inputDecoration('Materiel requis'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            onChanged: notifier.updateMaterielRequis,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _annulationController,
            decoration: _inputDecoration('Conditions d\'annulation'),
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            maxLines: 2,
            onChanged: notifier.updateConditionsAnnulation,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _addTag(String value, dynamic state, CreateEventNotifier notifier) {
    final tag = value.trim();
    if (tag.isNotEmpty && !state.tags.contains(tag)) {
      notifier.updateTags([...state.tags, tag]);
      _tagController.clear();
    }
  }

  static Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkColor),
    );
  }

  static Widget _subsectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkColor),
    );
  }

  static InputDecoration _inputDecoration(String label) {
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

class _GalleryPicker extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;

  const _GalleryPicker({required this.paths, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...paths.asMap().entries.map((entry) {
            final i = entry.key;
            final path = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.line,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<String>.from(paths)..removeAt(i);
                        onChanged(updated);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (paths.length < 5)
            GestureDetector(
              onTap: () => _pickImage(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(Icons.add_photo_alternate, color: AppColors.textFaint, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (xFile != null) {
      onChanged([...paths, xFile.path]);
    }
  }
}

class _ProgrammeSessionRow extends StatefulWidget {
  final int index;
  final ProgrammeSession session;
  final ValueChanged<ProgrammeSession> onChanged;
  final VoidCallback onRemoved;

  const _ProgrammeSessionRow({
    required this.index,
    required this.session,
    required this.onChanged,
    required this.onRemoved,
  });

  @override
  State<_ProgrammeSessionRow> createState() => _ProgrammeSessionRowState();
}

class _ProgrammeSessionRowState extends State<_ProgrammeSessionRow> {
  late final TextEditingController _heureCtrl;
  late final TextEditingController _activiteCtrl;
  late final TextEditingController _intervenantCtrl;

  @override
  void initState() {
    super.initState();
    _heureCtrl = TextEditingController(text: widget.session.heure);
    _activiteCtrl = TextEditingController(text: widget.session.activite);
    _intervenantCtrl = TextEditingController(text: widget.session.intervenant);
  }

  @override
  void dispose() {
    _heureCtrl.dispose();
    _activiteCtrl.dispose();
    _intervenantCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(ProgrammeSession(
      heure: _heureCtrl.text,
      activite: _activiteCtrl.text,
      intervenant: _intervenantCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _heureCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Heure',
                      hintStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                    onChanged: (_) => _notifyChange(),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _activiteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Activite',
                      hintStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                    onChanged: (_) => _notifyChange(),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _intervenantCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Intervenant',
                      hintStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                    onChanged: (_) => _notifyChange(),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
              onPressed: widget.onRemoved,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
