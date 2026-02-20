import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class AddOfferBottomSheet extends ConsumerStatefulWidget {
  const AddOfferBottomSheet({super.key});

  @override
  ConsumerState<AddOfferBottomSheet> createState() =>
      _AddOfferBottomSheetState();
}

class _AddOfferBottomSheetState extends ConsumerState<AddOfferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emojiController = TextEditingController();
  final _addressController = TextEditingController();
  final _spotsController = TextEditingController(text: '10');

  DateTime? _expiresAt;
  bool _isSubmitting = false;

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    _addressController.dispose();
    _spotsController.dispose();
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
                'Creer une offre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Titre de l'offre
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: "Titre de l'offre (ex: Massage offert)",
                  icon: Icons.local_offer,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le titre est requis'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(
                  label: 'Description (ex: 30 min offert pour toute reservation)',
                  icon: Icons.description_outlined,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Emoji
              TextFormField(
                controller: _emojiController,
                decoration: _inputDecoration(
                  label: 'Emoji (1 seul)',
                  icon: Icons.emoji_emotions_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // Nombre de places
              TextFormField(
                controller: _spotsController,
                decoration: _inputDecoration(
                  label: 'Nombre de places',
                  icon: Icons.people_outline,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le nombre de places est requis';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Entrez un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date d'expiration
              GestureDetector(
                onTap: _pickExpirationDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      label: _expiresAt != null
                          ? DateFormat('dd/MM/yyyy').format(_expiresAt!)
                          : "Date d'expiration",
                      icon: Icons.calendar_today,
                    ),
                    validator: (_) => _expiresAt == null
                        ? "La date d'expiration est requise"
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Publier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // Cancel
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
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final proState = ref.read(proAuthProvider);
      final profile = proState.profile;
      final city = ref.read(selectedCityProvider);

      final offer = Offer(
        id: '',
        proProfileId: profile?.id ?? '',
        businessName: profile?.nom ?? '',
        businessAddress: _addressController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _emojiController.text.trim(),
        totalSpots: int.tryParse(_spotsController.text.trim()) ?? 10,
        startsAt: DateTime.now(),
        expiresAt: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
        city: city,
        createdAt: DateTime.now(),
      );

      await OfferSupabaseService().insertOffer(offer);

      // Rafraichir le provider
      ref.invalidate(activeOffersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre publiee avec succes !'),
            backgroundColor: Color(0xFF7B2D8E),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
