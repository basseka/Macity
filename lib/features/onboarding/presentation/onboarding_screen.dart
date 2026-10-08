import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/language_sheet.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/services/analytics_service.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/private_events/data/pending_coffre_rsvp.dart';

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
  bool _submitting = false;
  String? _avatarPath;
  String _selectedVille = '';
  Timer? _villeDebounce;
  List<_CommuneResult> _villeSuggestions = [];
  bool _showVilleSuggestions = false;
  String? _loginError;

  static const _accentColor = Color(0xFFE91E8C);

  // Les 6 rubriques principales (mode DB, libellé, icône).
  static const List<(String, String, IconData)> _rubriques = [
    ('food', 'Food', Icons.restaurant),
    ('culture', 'Culture', Icons.palette),
    ('family', 'Famille', Icons.family_restroom),
    ('night', 'Night', Icons.nightlife),
    ('sport', 'Sport', Icons.sports_soccer),
    ('tourisme', 'Évasion', Icons.flight_takeoff),
  ];

  /// Pastille "🌐 FR" ouvrant le choix de la langue.
  Widget _buildLanguageButton() {
    final code = Localizations.localeOf(context).languageCode.toUpperCase();
    return GestureDetector(
      onTap: () => LanguageSheet.show(context),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              code,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Libelle traduit d'une rubrique (r.$2 = libelle francais de reference).
  static String _rubriqueLabel(BuildContext context, String mode) {
    final l10n = context.l10n;
    return switch (mode) {
      'food' => l10n.rubriqueFood,
      'culture' => l10n.rubriqueCulture,
      'family' => l10n.rubriqueFamily,
      'night' => l10n.rubriqueNight,
      'sport' => l10n.rubriqueSport,
      'tourisme' => l10n.rubriqueEvasion,
      _ => mode,
    };
  }

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
      // Création du profil directement (plus de code de confirmation email).
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
        preferences: _selectedModes.toList(),
        avatarUrl: avatarUrl,
      );
      await markOnboardingDone();
      await markRegistered();
      markRegisteredComplete();
      AnalyticsService.signupCompleted();
      final route = await PendingCoffreRsvp.postAuthRoute();
      if (mounted) context.go(route);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.onboardingLoginError)),
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
          _loginError = context.l10n.onboardingLoginNotFound;
          _submitting = false;
        });
        return;
      }

      // Link this device to the existing profile
      final existingUserId = profile['user_id'] as String;
      await UserIdentityService.setUserId(existingUserId);

      await markOnboardingDone();
      await markRegistered();
      markRegisteredComplete();
      final route = await PendingCoffreRsvp.postAuthRoute();
      if (mounted) context.go(route);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = context.l10n.onboardingLoginError;
          _submitting = false;
        });
      }
    }
  }

  // ── Explorer sans compte (skip) ──
  Future<void> _skipOnboarding() async {
    setState(() => _submitting = true);
    // Journalise l'entrée anonyme (best-effort, ne bloque jamais l'accès).
    await UserProfileService().logAnonymousEntry();
    await markSkipped();
    markSkippedComplete();
    // Pas d'inscription : le RSVP en attente ne pourra pas aboutir.
    await PendingCoffreRsvp.clear();
    AnalyticsService.exploreNoAccount();
    if (mounted) context.go('/home');
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
              title: Text(ctx.l10n.onboardingTakePhoto,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(ctx.l10n.onboardingChooseFromGallery,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(ctx.l10n.onboardingRemovePhoto,
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
          SnackBar(content: Text(context.l10n.onboardingImageError)),
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
                  // Choix de la langue, accessible avant toute inscription.
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildLanguageButton(),
                  ),
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
                      _isSignUp
                          ? context.l10n.onboardingWelcome
                          : context.l10n.onboardingWelcomeBack,
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
                          ? context.l10n.onboardingSignUpSubtitle
                          : context.l10n.onboardingLoginSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Explorer sans compte — au-dessus de Inscription/Connexion
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _skipOnboarding,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        context.l10n.onboardingExploreWithoutAccount,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                              _isSignUp
                                  ? context.l10n.onboardingSubmitSignUp
                                  : context.l10n.onboardingSubmitLogin,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
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
                                  ? context.l10n.onboardingAlreadyRegistered
                                  : context.l10n.onboardingNoAccountYet,
                            ),
                            TextSpan(
                              text: _isSignUp
                                  ? context.l10n.onboardingSubmitLogin
                                  : context.l10n.onboardingSwitchToSignUp,
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
                    context.l10n.onboardingTabSignUp,
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
                    context.l10n.onboardingTabLogin,
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
        label: context.l10n.onboardingFieldName,
        icon: Icons.person_outline,
        validator: (v) => v == null || v.trim().isEmpty
            ? context.l10n.onboardingFieldNameError
            : null,
      ),
      const SizedBox(height: 14),

      // Email
      _buildField(
        controller: _emailController,
        label: context.l10n.onboardingFieldEmail,
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.l10n.onboardingFieldEmailEmpty;
          if (!v.contains('@') || !v.contains('.')) return context.l10n.onboardingFieldEmailInvalid;
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Telephone
      _buildField(
        controller: _phoneController,
        label: context.l10n.onboardingFieldPhone,
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.l10n.onboardingFieldPhoneEmpty;
          if (v.trim().length < 10) return context.l10n.onboardingFieldPhoneTooShort;
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Ville
      _buildVilleField(),
      const SizedBox(height: 24),

      // Rubriques principales (6) — pour des notifications pertinentes.
      Text(
        context.l10n.onboardingInterestsTitle,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        context.l10n.onboardingInterestsSubtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.white54,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _rubriques.map((r) {
          final mode = r.$1;
          final label = _rubriqueLabel(context, mode);
          final icon = r.$3;
          final selected = _selectedModes.contains(mode);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedModes.remove(mode);
              } else {
                _selectedModes.add(mode);
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? _accentColor
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? _accentColor
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 15,
                      color: selected ? Colors.white : Colors.white60),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
              context.l10n.onboardingLoginHint,
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
        label: context.l10n.onboardingFieldEmail,
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.l10n.onboardingFieldEmailEmpty;
          if (!v.contains('@') || !v.contains('.')) return context.l10n.onboardingFieldEmailInvalid;
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Telephone
      _buildField(
        controller: _phoneController,
        label: context.l10n.onboardingFieldPhone,
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.l10n.onboardingFieldPhoneEmpty;
          if (v.trim().length < 10) return context.l10n.onboardingFieldPhoneTooShort;
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
              _selectedVille.isEmpty ? context.l10n.onboardingFieldCityError : null,
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
            labelText: context.l10n.onboardingFieldCity,
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
