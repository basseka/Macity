import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/state/commerce_add_provider.dart';

class AddCommerceBottomSheet extends ConsumerStatefulWidget {
  const AddCommerceBottomSheet({super.key});

  @override
  ConsumerState<AddCommerceBottomSheet> createState() =>
      _AddCommerceBottomSheetState();
}

class _AddCommerceBottomSheetState
    extends ConsumerState<AddCommerceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _horairesController = TextEditingController();
  String? _selectedCategorie;

  static const _categories = [
    'Restaurant',
    'Bar',
    'Cafe',
    'Boulangerie',
    'Pharmacie',
    'Epicerie',
    'Coiffeur',
    'Fleuriste',
    'Librairie',
    'Pressing',
    'Autre',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _horairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);
    final addState = ref.watch(commerceAddProvider);
    final isLoading = addState is AsyncLoading;

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
              Text(
                'Ajouter un commerce',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: modeTheme.primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Nom field
              TextFormField(
                controller: _nomController,
                decoration: _inputDecoration(
                  label: 'Nom du commerce',
                  icon: Icons.store,
                  modeTheme: modeTheme,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Adresse field
              TextFormField(
                controller: _adresseController,
                decoration: _inputDecoration(
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                  modeTheme: modeTheme,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "L'adresse est requise";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Categorie dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategorie,
                decoration: _inputDecoration(
                  label: 'Categorie',
                  icon: Icons.category_outlined,
                  modeTheme: modeTheme,
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategorie = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'La categorie est requise';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Telephone field
              TextFormField(
                controller: _telephoneController,
                decoration: _inputDecoration(
                  label: 'Telephone (optionnel)',
                  icon: Icons.phone_outlined,
                  modeTheme: modeTheme,
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Horaires field
              TextFormField(
                controller: _horairesController,
                decoration: _inputDecoration(
                  label: 'Horaires (optionnel)',
                  icon: Icons.access_time,
                  modeTheme: modeTheme,
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: modeTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: isLoading
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
    required dynamic modeTheme,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: modeTheme.primaryColor, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: modeTheme.primaryColor,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final city = ref.read(selectedCityProvider);

    final success = await ref.read(commerceAddProvider.notifier).addCommerce(
          nom: _nomController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: city,
          codePostal: '',
          categorie: _selectedCategorie!,
          latitude: 0.0,
          longitude: 0.0,
          horaires: _horairesController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commerce ajoute avec succes !'),
            backgroundColor: Color(0xFF7B2D8E),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'ajout du commerce"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
