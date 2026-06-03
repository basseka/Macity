import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';
import 'package:pulz_app/features/offers/state/offers_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class AddOfferBottomSheet extends ConsumerStatefulWidget {
  final String? initialPhotoPath;

  /// Si fourni, on est en mode EDITION : champs preremplis depuis cette offre
  /// et la soumission appelle updateOffer au lieu d'insertOffer.
  final Offer? existing;

  const AddOfferBottomSheet({
    super.key,
    this.initialPhotoPath,
    this.existing,
  });

  @override
  ConsumerState<AddOfferBottomSheet> createState() =>
      _AddOfferBottomSheetState();
}

class _AddOfferBottomSheetState extends ConsumerState<AddOfferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emojiController = TextEditingController();
  final _addressController = TextEditingController();
  final _spotsController = TextEditingController(text: '10');

  DateTime? _expiresAt;
  String? _photoPath;
  String? _existingImageUrl;
  bool _isSubmitting = false;
  bool _unlimitedSpots = false;
  bool _noExpiration = false;

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
    final existing = widget.existing;
    if (existing != null) {
      _businessNameController.text = existing.businessName;
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _emojiController.text = existing.emoji;
      _addressController.text = existing.businessAddress;
      _unlimitedSpots = existing.isUnlimited;
      _spotsController.text = existing.isUnlimited
          ? '10'
          : existing.totalSpots.toString();
      _noExpiration = existing.hasNoExpiration;
      _expiresAt = existing.hasNoExpiration ? null : existing.expiresAt;
      _existingImageUrl = existing.imageUrl;
    } else {
      // Pre-remplir avec le nom du pro (modifiable).
      final pro = ref.read(proAuthProvider).profile;
      if (pro != null) {
        _businessNameController.text = pro.nom;
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    _addressController.dispose();
    _spotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proState = ref.watch(proAuthProvider);
    final profile = proState.profile;

    // Gate : un pro non encore approuve ne peut pas publier d'offres.
    // L'admin valide manuellement via admin.html apres appel telephonique.
    if (profile == null || !profile.approved) {
      return _PendingApprovalSheet(hasProfile: profile != null);
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                _isEditing ? 'Modifier l\'offre' : 'Creer une offre',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // City indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_city, size: 14, color: _primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        ref.watch(selectedCityProvider),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primaryDarkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nom de l'etablissement qui offre (pre-rempli depuis le
              // profil pro, editable si l'offre concerne une autre entite).
              TextFormField(
                controller: _businessNameController,
                decoration: _inputDecoration(
                  label: "Nom de l'etablissement",
                  icon: Icons.business_outlined,
                ),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Le nom de l'etablissement est requis"
                    : null,
              ),
              const SizedBox(height: 10),

              // Titre de l'offre
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: "Titre de l'offre (ex: Massage offert)",
                  icon: Icons.local_offer,
                ),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le titre est requis'
                    : null,
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(
                  label: 'Description (ex: 30 min offert pour toute reservation)',
                  icon: Icons.description_outlined,
                ),
                style: TextStyle(fontSize: 13, color: AppColors.text),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // Emoji
              TextFormField(
                controller: _emojiController,
                decoration: _inputDecoration(
                  label: 'Emoji (1 seul)',
                  icon: Icons.emoji_emotions_outlined,
                ),
                style: TextStyle(fontSize: 13, color: AppColors.text),
              ),
              const SizedBox(height: 10),

              // Photo
              if (_photoPath == null)
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera, size: 16),
                  label: const Text('Ajouter une photo', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                )
              else
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_photoPath!),
                        width: double.infinity,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(height: 130),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: GestureDetector(
                        onTap: () => setState(() => _photoPath = null),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                ),
                style: TextStyle(fontSize: 13, color: AppColors.text),
              ),
              const SizedBox(height: 10),

              // Nombre de places (cache si "illimite" coche)
              if (!_unlimitedSpots) ...[
                TextFormField(
                  controller: _spotsController,
                  decoration: _inputDecoration(
                    label: 'Nombre de places',
                    icon: Icons.people_outline,
                  ),
                  style: TextStyle(fontSize: 13, color: AppColors.text),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_unlimitedSpots) return null;
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
                const SizedBox(height: 6),
              ],
              // Toggle "Places illimitees"
              _CompactToggle(
                value: _unlimitedSpots,
                label: 'Places illimitees',
                icon: Icons.all_inclusive_rounded,
                color: _primaryColor,
                onChanged: (v) => setState(() => _unlimitedSpots = v),
              ),
              const SizedBox(height: 10),

              // Date d'expiration (cachee si "sans expiration" coche)
              if (!_noExpiration) ...[
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
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      validator: (_) {
                        if (_noExpiration) return null;
                        return _expiresAt == null
                            ? "La date d'expiration est requise"
                            : null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Toggle "Sans date d'expiration"
              _CompactToggle(
                value: _noExpiration,
                label: "Sans date d'expiration",
                icon: Icons.event_repeat_rounded,
                color: _primaryColor,
                onChanged: (v) => setState(() => _noExpiration = v),
              ),
              const SizedBox(height: 16),

              // Submit
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Enregistrer' : 'Publier',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 8),

              // Cancel
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDarkColor,
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
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
      labelStyle: TextStyle(fontSize: 12, color: AppColors.textFaint),
      prefixIcon: Icon(icon, color: _primaryColor, size: 18),
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

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
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

    final xFile = await picker.pickImage(source: source, maxWidth: 1024);
    if (xFile != null) {
      setState(() => _photoPath = xFile.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = OfferSupabaseService();
      final proState = ref.read(proAuthProvider);
      final profile = proState.profile;
      final city = ref.read(selectedCityProvider);

      // Si nouvelle photo locale -> upload. Sinon on garde l'URL existante
      // (mode edition sans changement de photo).
      String? imageUrl;
      if (_photoPath != null) {
        imageUrl = await service.uploadPhoto(_photoPath!);
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        imageUrl = _existingImageUrl;
      }

      final existing = widget.existing;

      // Sentinelles : 99999 = illimite, DateTime(2099) = sans expiration.
      // Pas de migration DB necessaire (colonnes NOT NULL preservees).
      final effectiveTotalSpots = _unlimitedSpots
          ? Offer.unlimitedSpotsSentinel
          : (int.tryParse(_spotsController.text.trim()) ?? 10);
      final effectiveExpiresAt = _noExpiration
          ? DateTime(Offer.noExpirationYear, 12, 31)
          : (_expiresAt ?? DateTime.now().add(const Duration(days: 7)));

      final offer = Offer(
        id: existing?.id ?? '',
        proProfileId: existing?.proProfileId ?? profile?.id ?? '',
        businessName: _businessNameController.text.trim(),
        businessAddress: _addressController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _emojiController.text.trim(),
        imageUrl: imageUrl ?? '',
        totalSpots: effectiveTotalSpots,
        claimedSpots: existing?.claimedSpots ?? 0,
        startsAt: existing?.startsAt ?? DateTime.now(),
        expiresAt: effectiveExpiresAt,
        isActive: existing?.isActive ?? true,
        city: existing?.city ?? city,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await service.updateOffer(offer);
      } else {
        await service.insertOffer(offer);
      }

      // Rafraichir les providers (active + mes offres)
      ref.invalidate(activeOffersProvider);
      ref.invalidate(myOffersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Offre modifiee avec succes !'
                : 'Offre publiee avec succes !'),
            backgroundColor: const Color(0xFF7B2D8E),
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

/// Affiche quand un pro non encore approuve tente de creer une offre.
/// Le compte est soit en cours de validation manuelle par l'admin (appel
/// telephonique avant approbation), soit non connecte du tout.
class _PendingApprovalSheet extends StatelessWidget {
  final bool hasProfile;

  const _PendingApprovalSheet({required this.hasProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF7B2D8E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFF7B2D8E),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasProfile
                ? 'Compte en cours de validation'
                : 'Connexion pro requise',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A0A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            hasProfile
                ? 'Ton compte pro est bien créé. Notre équipe va t\'appeler très bientôt au numéro renseigné pour valider ton inscription. Tu pourras publier des offres dès que ton compte sera approuvé.'
                : 'Tu dois être connecté avec un compte pro approuvé pour publier une offre.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textFaint,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2D8E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 0,
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle compact ligne unique : icone + label + Switch a droite.
/// Utilise pour "Places illimitees" et "Sans date d'expiration".
class _CompactToggle extends StatelessWidget {
  final bool value;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _CompactToggle({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.75)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
