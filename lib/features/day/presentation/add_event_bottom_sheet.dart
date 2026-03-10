import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/helpers/lieu_suggestions.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/etablissements/state/etablissements_provider.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class AddEventBottomSheet extends ConsumerStatefulWidget {
  final String? initialPhotoPath;

  const AddEventBottomSheet({super.key, this.initialPhotoPath});

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
  String? _selectedLieu;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _photoPath;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _rubriqueSubcategories = <String, List<String>>{
    'Concerts & Spectacles': ['Concert', 'Festival', 'Spectacle', 'Stand up', 'Opera', 'DJ set', 'Showcase'],
    'Sport': ['Football', 'Rugby', 'Basketball', 'Tennis', 'Course', 'Autre sport'],
    'Culture & Arts': ['Expo', 'Vernissage', 'Theatre', 'Visites guidees', 'Musee', 'Animations culturelles'],
    'En Famille': ['Parc', 'Cinema', 'Bowling', 'Spectacle enfant'],
    'Food & lifestyle': ['Restaurant', 'Cafe', 'Brunch', 'Marche'],
    'Gaming': ['Tournoi e-sport', 'Convention', 'Bar a jeux'],
    'Nuit': ['Bar', 'Club', 'Soiree', 'Concert live', 'Showcase'],
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
      child: _showSuccess
          ? _buildSuccessView()
          : SingleChildScrollView(
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
                    _selectedLieu = null;
                    _lieuNomController.clear();
                    _lieuAdresseController.clear();
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
              ..._buildLieuFields(),
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
                        errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Submit ──
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ajouter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 10),

              // ── Cancel ──
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDarkColor,
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Annuler',
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

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, Color(0xFFE91E8C)],
              ),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Evenement ajoute avec succes !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _primaryDarkColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Il sera visible dans la rubrique correspondante.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildLieuFields() {
    // Map display rubrique to Supabase key
    final supabaseKey = rubriqueDisplayToKey[_selectedRubrique ?? ''];
    final danceVenuesList = ref.watch(danceVenuesProvider).valueOrNull ?? [];
    final danceSuggestions = danceVenuesList
        .map((v) => LieuSuggestion(nom: v.name, adresse: ''))
        .toList();

    // Try Supabase data first, fallback to static
    List<LieuSuggestion> lieux;
    if (supabaseKey != null) {
      final etablissements =
          ref.watch(etablissementsProvider(supabaseKey)).valueOrNull;
      if (etablissements != null && etablissements.isNotEmpty) {
        lieux = getLieuxFromCommerces(
          etablissements,
          danceVenues: supabaseKey == 'culture' ? danceSuggestions : [],
        );
      } else {
        lieux = getLieuxForRubrique(
          _selectedRubrique ?? '',
          danceVenues: danceSuggestions,
        );
      }
    } else {
      lieux = getLieuxForRubrique(
        _selectedRubrique ?? '',
        danceVenues: danceSuggestions,
      );
    }

    if (lieux.isEmpty) {
      return [
        TextFormField(
          controller: _lieuNomController,
          decoration: _inputDecoration(
            label: 'Lieu (optionnel)',
            icon: Icons.place_outlined,
          ),
        ),
      ];
    }

    return [
      DropdownButtonFormField<String>(
        key: ValueKey('lieu_$_selectedRubrique'),
        isExpanded: true,
        value: _selectedLieu,
        decoration: _inputDecoration(
          label: 'Lieu (optionnel)',
          icon: Icons.place_outlined,
        ),
        items: [
          ...lieux.map(
            (l) => DropdownMenuItem(
              value: l.nom,
              child: Text(l.nom, overflow: TextOverflow.ellipsis),
            ),
          ),
          const DropdownMenuItem(
            value: 'Autre',
            child: Text('Autre (saisie libre)'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedLieu = value;
            if (value != null && value != 'Autre') {
              final match = lieux.where((l) => l.nom == value).firstOrNull;
              if (match != null) {
                _lieuAdresseController.text = match.adresse;
              }
              _lieuNomController.clear();
            } else {
              _lieuAdresseController.clear();
            }
          });
        },
      ),
      if (_selectedLieu == 'Autre') ...[
        const SizedBox(height: 16),
        TextFormField(
          controller: _lieuNomController,
          decoration: _inputDecoration(
            label: 'Nom du lieu',
            icon: Icons.edit_location_outlined,
          ),
        ),
      ],
    ];
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
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_photoPath == null) {
      setState(() => _errorMessage = 'Une photo est requise pour ajouter un evenement');
      return;
    }

    if (_selectedCategorie == null || _selectedRubrique == null) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs obligatoires');
      return;
    }
    final rubrique = _rubriqueToModeName[_selectedRubrique!];
    if (rubrique == null) {
      setState(() => _errorMessage = 'Rubrique invalide');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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
        rubrique: rubrique,
        date: dateStr,
        heure: timeStr,
        lieuNom: (_selectedLieu != null && _selectedLieu != 'Autre')
            ? _selectedLieu!
            : _lieuNomController.text.trim(),
        lieuAdresse: _lieuAdresseController.text.trim(),
        photoPath: _photoPath,
        ville: city,
        createdAt: DateTime.now(),
      );

      String? establishmentId;
      final proState = ref.read(proAuthProvider);
      if (proState.status == ProAuthStatus.approved && proState.profile != null) {
        establishmentId = proState.profile!.id;
      }

      await ref
          .read(userEventsProvider.notifier)
          .addEvent(event, establishmentId: establishmentId);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      debugPrint('[AddEvent] submit error: $e');
      if (mounted) {
        String detail = e.toString();
        // Extraire le message Supabase depuis DioException
        if (e is DioException && e.response?.data != null) {
          final body = e.response!.data;
          if (body is Map) {
            detail = (body['message'] ?? body['msg'] ?? body['error'] ?? detail).toString();
          }
        }
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Erreur : $detail';
        });
      }
    }
  }
}
