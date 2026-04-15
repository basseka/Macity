import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/data/detailed_interests.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // true = inscription (new user), false = connexion (existing user)
  bool _isSignUp = true;

  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _selectedModes = <String>{};
  final _selectedDetailed = <String>{};
  final _expandedCategories = <String>{};
  bool _submitting = false;
  String? _avatarPath;
  String _selectedVille = '';
  Timer? _villeDebounce;
  List<_CommuneResult> _villeSuggestions = [];
  bool _showVilleSuggestions = false;
  String? _loginError;

  static const _accentColor = Color(0xFFE91E8C);

  @override
  void dispose() {
    _villeDebounce?.cancel();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  // ── Sign Up ──
  Future<void> _submitSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _loginError = null;
    });

    try {
      // Deduire les modes principaux depuis les sous-interets
      final modesFromDetailed = <String>{};
      for (final key in _selectedDetailed) {
        modesFromDetailed.add(key.split(':').first);
      }
      final allModes = {..._selectedModes, ...modesFromDetailed};

      final svc = UserProfileService();
      String? avatarUrl;
      if (_avatarPath != null) {
        try {
          avatarUrl = await svc.uploadAvatar(_avatarPath!);
        } catch (_) {
          // Upload non bloquant : on continue sans avatar.
        }
      }
      await svc.upsert(
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _phoneController.text.trim(),
        ville: _selectedVille,
        preferences: allModes.toList(),
        avatarUrl: avatarUrl,
      );
      if (_selectedDetailed.isNotEmpty) {
        await svc.updateDetailedPreferences(_selectedDetailed.toList());
      }
      await markOnboardingDone();
      markOnboardingComplete();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de connexion, reessayez')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Login ──
  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _loginError = null;
    });

    try {
      final profile = await UserProfileService().findByCredentials(
        email: _emailController.text.trim(),
        telephone: _phoneController.text.trim(),
      );

      if (profile == null) {
        setState(() {
          _loginError = 'Aucun compte trouve avec ces identifiants';
          _submitting = false;
        });
        return;
      }

      // Link this device to the existing profile
      final existingUserId = profile['user_id'] as String;
      await UserIdentityService.setUserId(existingUserId);

      await markOnboardingDone();
      markOnboardingComplete();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = 'Erreur de connexion, reessayez';
          _submitting = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A0A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: Text('Prendre une photo',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text('Choisir dans la galerie',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Retirer la photo',
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, null),
              ),
          ],
        ),
      ),
    );

    if (source == null) {
      if (mounted) setState(() => _avatarPath = null);
      return;
    }

    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _avatarPath = picked.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de selectionner cette image')),
        );
      }
    }
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _loginError = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0618),
              Color(0xFF1A0A2E),
              Color(0xFF2D1245),
              Color(0xFF4A1259),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Logo
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 56,
                        height: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _isSignUp ? 'Bienvenue sur MaCity' : 'Content de te revoir !',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isSignUp
                          ? 'Cree ton compte en quelques secondes'
                          : 'Connecte-toi avec tes identifiants',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode toggle (Inscription / Connexion)
                  _buildModeToggle(),
                  const SizedBox(height: 24),

                  // Form fields
                  if (_isSignUp) ..._buildSignUpFields() else ..._buildLoginFields(),

                  // Error message
                  if (_loginError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: Colors.red.shade300),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loginError!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red.shade200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : (_isSignUp ? _submitSignUp : _submitLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
                        elevation: 4,
                        shadowColor: _accentColor.withValues(alpha: 0.4),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'C\'est parti !' : 'Se connecter',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Switch mode link
                  Center(
                    child: GestureDetector(
                      onTap: _submitting ? null : _switchMode,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Deja inscrit ? '
                                  : 'Pas encore de compte ? ',
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Se connecter' : 'S\'inscrire',
                              style: const TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: _accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Skip
                  Center(
                    child: TextButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              await markOnboardingDone();
                              markOnboardingComplete();
                              if (mounted) context.go('/home');
                            },
                      child: Text(
                        'Passer cette etape',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white24,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mode toggle pills ──
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isSignUp = true;
                _loginError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSignUp ? _accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    'Inscription',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: _isSignUp ? FontWeight.w600 : FontWeight.w400,
                      color: _isSignUp ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isSignUp = false;
                _loginError = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSignUp ? _accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    'Connexion',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: !_isSignUp ? FontWeight.w600 : FontWeight.w400,
                      color: !_isSignUp ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign Up fields ──
  List<Widget> _buildSignUpFields() {
    return [
      // Avatar picker
      Center(child: _buildAvatarPicker()),
      const SizedBox(height: 18),

      // Prenom ou pseudo
      _buildField(
        controller: _prenomController,
        label: 'Prenom ou pseudo',
        icon: Icons.person_outline,
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Entrez votre prenom ou pseudo'
            : null,
      ),
      const SizedBox(height: 14),

      // Email
      _buildField(
        controller: _emailController,
        label: 'Email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Entrez votre email';
          if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Telephone
      _buildField(
        controller: _phoneController,
        label: 'Telephone',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Entrez votre numero';
          if (v.trim().length < 10) return 'Numero trop court';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Ville
      _buildVilleField(),
      const SizedBox(height: 24),

      // Preferences detaillees
      Text(
        'Quelles activites t\'interessent ?',
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Selectionne tes centres d\'interet pour des notifications pertinentes. '
        'Appuie sur une categorie pour affiner.',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.white54,
        ),
      ),
      const SizedBox(height: 12),

      ...kDetailedInterests.map((cat) {
        final modeSelected = _selectedModes.contains(cat.mode);
        final isExpanded = _expandedCategories.contains(cat.mode);
        final count = _selectedDetailed.where((k) => k.startsWith('${cat.mode}:')).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_expandedCategories.contains(cat.mode)) {
                    _expandedCategories.remove(cat.mode);
                  } else {
                    _expandedCategories.add(cat.mode);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: modeSelected
                      ? _accentColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: modeSelected
                        ? _accentColor.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    // Mode checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (modeSelected) {
                            _selectedModes.remove(cat.mode);
                            _selectedDetailed.removeWhere((k) => k.startsWith('${cat.mode}:'));
                          } else {
                            _selectedModes.add(cat.mode);
                          }
                        });
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: modeSelected ? _accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: modeSelected ? _accentColor : Colors.white38,
                            width: 1.5,
                          ),
                        ),
                        child: modeSelected
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(cat.icon, size: 18, color: modeSelected ? _accentColor : Colors.white60),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: modeSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
            // Sub-interests
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cat.items.map((item) {
                    final key = item.key(cat.mode);
                    final selected = _selectedDetailed.contains(key);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedDetailed.remove(key);
                          } else {
                            _selectedDetailed.add(key);
                            _selectedModes.add(cat.mode);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? _accentColor
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? _accentColor : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 13,
                              color: selected ? Colors.white : Colors.white60,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? Colors.white : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      }),
    ];
  }

  // ── Login fields ──
  List<Widget> _buildLoginFields() {
    return [
      // Illustration / hint
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock_open_rounded,
              size: 36,
              color: _accentColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              'Entre ton email et numero de telephone\npour retrouver ton compte',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      // Email
      _buildField(
        controller: _emailController,
        label: 'Email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Entrez votre email';
          if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Telephone
      _buildField(
        controller: _phoneController,
        label: 'Telephone',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Entrez votre numero';
          if (v.trim().length < 10) return 'Numero trop court';
          return null;
        },
      ),
    ];
  }

  Widget _buildVilleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _villeController,
          validator: (v) =>
              _selectedVille.isEmpty ? 'Selectionnez votre ville' : null,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          onChanged: (query) {
            _villeDebounce?.cancel();
            if (query.length < 2) {
              setState(() {
                _villeSuggestions = [];
                _showVilleSuggestions = false;
              });
              return;
            }
            _villeDebounce = Timer(const Duration(milliseconds: 350), () {
              _searchCommunes(query);
            });
          },
          decoration: InputDecoration(
            labelText: 'Ville ou village',
            labelStyle:
                GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
            prefixIcon: const Icon(Icons.location_city_outlined,
                color: Colors.white54, size: 20),
            suffixIcon: _selectedVille.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white54, size: 18),
                    onPressed: () {
                      _villeController.clear();
                      setState(() {
                        _selectedVille = '';
                        _villeSuggestions = [];
                        _showVilleSuggestions = false;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_showVilleSuggestions && _villeSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1245),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _villeSuggestions.length,
              itemBuilder: (context, index) {
                final commune = _villeSuggestions[index];
                return InkWell(
                  onTap: () {
                    final display =
                        '${commune.nom} (${commune.codePostal})';
                    _villeController.text = display;
                    _villeController.selection =
                        TextSelection.collapsed(offset: display.length);
                    setState(() {
                      _selectedVille = display;
                      _showVilleSuggestions = false;
                      _villeSuggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: _accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            commune.nom,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          commune.codePostal,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white54),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commune.departement,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _searchCommunes(String query) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://geo.api.gouv.fr/communes',
        queryParameters: {
          'nom': query,
          'fields': 'nom,codesPostaux,codeDepartement',
          'boost': 'population',
          'limit': '15',
        },
      );
      final results = <_CommuneResult>[];
      for (final item in response.data as List) {
        final nom = item['nom'] as String;
        final codes =
            (item['codesPostaux'] as List?)?.cast<String>() ?? [];
        final dep = item['codeDepartement'] as String? ?? '';
        final cp = codes.isNotEmpty ? codes.first : '';
        results.add(_CommuneResult(
            nom: nom, codePostal: cp, departement: dep));
      }
      if (mounted) {
        setState(() {
          _villeSuggestions = results;
          _showVilleSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {
      // Silently ignore network errors
    }
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.6),
                width: 2,
              ),
              image: _avatarPath != null
                  ? DecorationImage(
                      image: FileImage(File(_avatarPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _avatarPath == null
                ? const Icon(Icons.person_add_alt_1,
                    color: Colors.white54, size: 36)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _avatarPath == null ? Icons.camera_alt : Icons.edit,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _CommuneResult {
  final String nom;
  final String codePostal;
  final String departement;

  const _CommuneResult({
    required this.nom,
    required this.codePostal,
    required this.departement,
  });
}
