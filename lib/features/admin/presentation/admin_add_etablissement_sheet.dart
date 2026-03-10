import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

class AdminAddEtablissementSheet extends StatefulWidget {
  const AdminAddEtablissementSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminAddEtablissementSheet(),
    );
  }

  @override
  State<AdminAddEtablissementSheet> createState() =>
      _AdminAddEtablissementSheetState();
}

class _AdminAddEtablissementSheetState
    extends State<AdminAddEtablissementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _horairesController = TextEditingController();
  final _siteWebController = TextEditingController();
  final _lienMapsController = TextEditingController();
  final _latController = TextEditingController(text: '0');
  final _lonController = TextEditingController(text: '0');

  String _rubrique = 'food';
  String _categorie = '';
  String _theme = '';
  String _quartier = '';
  String _style = '';
  String? _photoPath;
  bool _submitting = false;
  bool _success = false;

  static const _rubriques = ['food', 'nuit', 'culture', 'famille'];

  static const _themes = [
    '', 'Francais', 'Asiatique', 'Japonais', 'Italien', 'Orientale',
    'Mediterraneen', 'Mexicain', 'Africain', 'Indien', 'Fusion',
    'Sud-Ouest', 'Fruits de mer', 'Vegetarien',
  ];

  static const _quartiers = [
    '', 'Capitole', 'Saint-Georges', 'Esquirol', 'Saint-Etienne',
    'Carmes', 'Saint-Cyprien', 'Compans-Caffarelli', 'Francois-Verdier',
    'Matabiau', 'Cote Pavee', 'Lardenne', 'Rangueil', 'Minimes',
    'Empalot', 'Bagatelle', 'Mirail',
  ];

  static const _styles = [
    '', 'Romantique', 'Chic', 'Gastronomique', 'Bistronomique',
    'Convivial', 'Familial', 'Festif', 'Cosy', 'Decontracte',
    'Traditionnel', 'Authentique', 'Moderne', 'Branche',
    'Instagrammable', 'Rooftop', 'Street food', 'Lounge',
    'Tapas / partage', 'Bar a vin', 'Gourmet', 'A theme',
  ];

  static const _primaryColor = Color(0xFF7B2D8E);

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _horairesController.dispose();
    _siteWebController.dispose();
    _lienMapsController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Etablissement ajoute !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _success = false;
                _nomController.clear();
                _adresseController.clear();
                _telephoneController.clear();
                _horairesController.clear();
                _siteWebController.clear();
                _lienMapsController.clear();
                _latController.text = '0';
                _lonController.text = '0';
                _categorie = '';
                _theme = '';
                _quartier = '';
                _style = '';
                _photoPath = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Ajouter un autre',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Colors.red, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Admin — Ajouter un etablissement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1259),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rubrique
            _buildDropdown(
              label: 'Rubrique *',
              value: _rubrique,
              items: _rubriques,
              onChanged: (v) => setState(() => _rubrique = v!),
            ),
            const SizedBox(height: 12),

            // Nom
            _buildField(_nomController, 'Nom *', Icons.store,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),

            // Categorie
            _buildField(
              TextEditingController(text: _categorie),
              'Categorie (ex: Bistrot, Bar, Musee)',
              Icons.category,
              onChanged: (v) => _categorie = v,
            ),
            const SizedBox(height: 12),

            // Adresse
            _buildField(_adresseController, 'Adresse', Icons.location_on),
            const SizedBox(height: 12),

            // Telephone
            _buildField(_telephoneController, 'Telephone', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),

            // Horaires
            _buildField(_horairesController, 'Horaires', Icons.access_time),
            const SizedBox(height: 12),

            // Site web
            _buildField(_siteWebController, 'Site web', Icons.language,
                keyboardType: TextInputType.url),
            const SizedBox(height: 12),

            // Lien Maps
            _buildField(_lienMapsController, 'Lien Google Maps', Icons.map,
                keyboardType: TextInputType.url),
            const SizedBox(height: 12),

            // Lat / Lon
            Row(
              children: [
                Expanded(
                  child: _buildField(
                      _latController, 'Latitude', Icons.my_location,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                      _lonController, 'Longitude', Icons.my_location,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Theme / Quartier / Style (pour food)
            if (_rubrique == 'food') ...[
              const Text('Filtres restaurant',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF4A1259))),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Theme culinaire',
                value: _theme.isEmpty ? '' : _theme,
                items: _themes,
                displayEmpty: '-- Aucun --',
                onChanged: (v) => setState(() => _theme = v ?? ''),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Quartier',
                value: _quartier.isEmpty ? '' : _quartier,
                items: _quartiers,
                displayEmpty: '-- Auto-detect --',
                onChanged: (v) => setState(() => _quartier = v ?? ''),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                label: 'Style / ambiance',
                value: _style.isEmpty ? '' : _style,
                items: _styles,
                displayEmpty: '-- Aucun --',
                onChanged: (v) => setState(() => _style = v ?? ''),
              ),
              const SizedBox(height: 16),
            ],

            // Photo
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: Icon(
                      _photoPath != null
                          ? Icons.check_circle
                          : Icons.photo_camera,
                      size: 18,
                    ),
                    label: Text(
                        _photoPath != null ? 'Photo ajoutee' : 'Photo (optionnel)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_photoPath != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_photoPath!),
                        width: 44, height: 44, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Submit
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Ajouter',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Annuler'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String displayEmpty = '',
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e.isEmpty ? (displayEmpty.isNotEmpty ? displayEmpty : '--') : e,
                  style: TextStyle(
                    fontSize: 14,
                    color: e.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
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
    if (xFile != null) setState(() => _photoPath = xFile.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
      dio.interceptors.add(SupabaseInterceptor());

      await dio.post(
        'etablissements',
        data: {
          'nom': _nomController.text.trim(),
          'rubrique': _rubrique,
          'categorie': _categorie.trim(),
          'adresse': _adresseController.text.trim(),
          'ville': 'Toulouse',
          'telephone': _telephoneController.text.trim(),
          'horaires': _horairesController.text.trim(),
          'site_web': _siteWebController.text.trim(),
          'lien_maps': _lienMapsController.text.trim(),
          'photo': '',
          'latitude': double.tryParse(_latController.text) ?? 0,
          'longitude': double.tryParse(_lonController.text) ?? 0,
          'theme': _theme,
          'quartier': _quartier,
          'style': _style,
        },
        options: Options(
          headers: {'Prefer': 'return=minimal'},
        ),
      );

      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException && e.response?.data != null) {
          final body = e.response!.data;
          if (body is Map) {
            msg = (body['message'] ?? body['msg'] ?? msg).toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
