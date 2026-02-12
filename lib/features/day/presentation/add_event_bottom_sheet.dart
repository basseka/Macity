import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';

class AddEventBottomSheet extends ConsumerStatefulWidget {
  const AddEventBottomSheet({super.key});

  @override
  ConsumerState<AddEventBottomSheet> createState() =>
      _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _lieuNomController = TextEditingController();
  final _lieuAdresseController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedRubrique;
  String? _selectedCategorie;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _photoPath;

  static const _rubriqueSubcategories = <String, List<String>>{
    'Concerts & Spectacles': ['Concert', 'Festival', 'Opera', 'DJ set', 'Showcase', 'Spectacle'],
    'Sport': ['Football', 'Rugby', 'Basketball', 'Tennis', 'Course', 'Autre sport'],
    'Culture & Arts': ['Expo', 'Vernissage', 'Theatre', 'Visites guidees', 'Musee', 'Animations culturelles'],
    'En Famille': ['Parc', 'Cinema', 'Bowling', 'Spectacle enfant'],
    'Food & lifestyle': ['Restaurant', 'Cafe', 'Brunch', 'Marche'],
    'Gaming': ['Tournoi e-sport', 'Convention', 'Bar a jeux'],
    'Nuit': ['Bar', 'Club', 'Soiree', 'Concert live'],
  };

  /// Maps display rubrique name → AppMode name for storage.
  static const _rubriqueToModeName = <String, String>{
    'Concerts & Spectacles': 'day',
    'Sport': 'sport',
    'Culture & Arts': 'culture',
    'En Famille': 'family',
    'Food & lifestyle': 'food',
    'Gaming': 'gaming',
    'Nuit': 'night',
  };

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  void dispose() {
    _titreController.dispose();
    _lieuNomController.dispose();
    _lieuAdresseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _selectedRubrique != null
        ? _rubriqueSubcategories[_selectedRubrique]!
        : <String>[];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Ajouter un evenement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Rubrique ──
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedRubrique,
                decoration: _inputDecoration(
                  label: 'Rubrique',
                  icon: Icons.category_outlined,
                ),
                items: _rubriqueSubcategories.keys
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, overflow: TextOverflow.ellipsis),
                        ),)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRubrique = value;
                    _selectedCategorie = null;
                  });
                },
                validator: (v) => v == null ? 'La rubrique est requise' : null,
              ),
              const SizedBox(height: 16),

              // ── Type d'evenement (dynamic) ──
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedRubrique),
                isExpanded: true,
                initialValue: _selectedCategorie,
                decoration: _inputDecoration(
                  label: "Type d'evenement",
                  icon: Icons.event_note,
                ),
                items: subcategories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategorie = value;
                  });
                },
                validator: (v) =>
                    v == null ? "Le type d'evenement est requis" : null,
              ),
              const SizedBox(height: 16),

              // ── Titre ──
              TextFormField(
                controller: _titreController,
                decoration: _inputDecoration(
                  label: "Titre de l'evenement",
                  icon: Icons.title,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le titre est requis'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Date ──
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      label: _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Date',
                      icon: Icons.calendar_today,
                    ),
                    validator: (_) =>
                        _selectedDate == null ? 'La date est requise' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Heure ──
              GestureDetector(
                onTap: _pickTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      label: _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Heure',
                      icon: Icons.access_time,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Lieu ──
              TextFormField(
                controller: _lieuNomController,
                decoration: _inputDecoration(
                  label: 'Lieu (optionnel)',
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // ── Adresse ──
              TextFormField(
                controller: _lieuAdresseController,
                decoration: _inputDecoration(
                  label: 'Adresse (optionnel)',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(
                  label: 'Description (optionnel)',
                  icon: Icons.description_outlined,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ── Photo (obligatoire) ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: Icon(
                        _photoPath != null ? Icons.check_circle : Icons.photo_camera,
                        size: 18,
                      ),
                      label: Text(
                        _photoPath != null ? 'Photo ajoutee' : 'Ajouter une photo *',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _photoPath != null ? _primaryColor : Colors.red.shade700,
                        side: BorderSide(
                          color: _photoPath != null
                              ? _primaryColor.withValues(alpha: 0.3)
                              : Colors.red.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await picker.pickImage(source: source, maxWidth: 1024);
    if (xFile != null) {
      setState(() => _photoPath = xFile.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une photo est requise pour ajouter un evenement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final city = ref.read(selectedCityProvider);
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : '';
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    final event = UserEvent(
      id: id,
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
      categorie: _selectedCategorie!,
      rubrique: _rubriqueToModeName[_selectedRubrique!]!,
      date: dateStr,
      heure: timeStr,
      lieuNom: _lieuNomController.text.trim(),
      lieuAdresse: _lieuAdresseController.text.trim(),
      photoPath: _photoPath,
      ville: city,
      createdAt: DateTime.now(),
    );

    await ref.read(userEventsProvider.notifier).addEvent(event);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evenement ajoute avec succes !'),
          backgroundColor: Color(0xFF7B2D8E),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
