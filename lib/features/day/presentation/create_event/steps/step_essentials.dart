import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_provider.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';

class StepEssentials extends ConsumerWidget {
  const StepEssentials({super.key});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createEventProvider);
    final notifier = ref.read(createEventProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Essentiel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkColor),
          ),
          const SizedBox(height: 2),
          Text(
            'Decrivez votre evenement',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),

          // Categorie
          _sectionLabel('Categorie *'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kEventCategories.map((cat) {
              final selected = state.categorie == cat;
              return ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 11)),
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

          // Sous-categorie
          if (state.categorie != null) ...[
            _sectionLabel('Sous-categorie *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey(state.categorie),
              isExpanded: true,
              value: (kSubcategories[state.categorie] ?? []).contains(state.sousCategorie)
                  ? state.sousCategorie
                  : null,
              decoration: _inputDecoration('Choisir'),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: (kSubcategories[state.categorie] ?? [])
                  .map((sc) => DropdownMenuItem(
                        value: sc,
                        child: Text(sc, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.updateSousCategorie(v);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Format
          _sectionLabel('Format'),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kEventFormats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final fmt = kEventFormats[i];
                final selected = state.format == fmt;
                return ChoiceChip(
                  label: Text(fmt, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  selectedColor: _primaryColor.withValues(alpha: 0.15),
                  checkmarkColor: _primaryColor,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => notifier.updateFormat(fmt),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Titre
          TextFormField(
            initialValue: state.titre,
            decoration: _inputDecoration('Titre de l\'evenement *'),
            style: const TextStyle(fontSize: 13),
            onChanged: notifier.updateTitre,
          ),
          const SizedBox(height: 10),

          // Description courte
          TextFormField(
            initialValue: state.descriptionCourte,
            decoration: _inputDecoration('Description courte'),
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            onChanged: notifier.updateDescriptionCourte,
          ),
          const SizedBox(height: 14),

          // Photo + Video
          _sectionLabel('Photo *'),
          const SizedBox(height: 6),
          _PhotoPicker(
            photoPath: state.photoPath,
            onPicked: notifier.updatePhotoPath,
          ),
          const SizedBox(height: 10),
          _sectionLabel('Video teaser (optionnel, 15s max)'),
          const SizedBox(height: 6),
          _VideoPicker(
            videoPath: state.videoPath,
            onPicked: notifier.updateVideoPath,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkColor),
    );
  }

  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final ValueChanged<String> onPicked;

  const _PhotoPicker({required this.photoPath, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: photoPath != null
                ? const Color(0xFF7B2D8E).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: photoPath != null ? 1.5 : 1,
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
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey.shade300),
        const SizedBox(height: 6),
        Text(
          'Appuyez pour ajouter une photo',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
              title: const Text('Camera', style: TextStyle(fontSize: 13)),
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
          border: Border.all(color: Colors.grey.shade300),
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
                        'Video',
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
                    'Ajouter une video\n(15 sec max)',
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
              title: const Text('Camera', style: TextStyle(fontSize: 13)),
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
      maxDuration: const Duration(seconds: 15),
    );
    if (xFile != null) onPicked(xFile.path);
  }
}
