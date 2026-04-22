import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/data/detailed_interests.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/notifications/state/mairie_notifications_provider.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class NotificationPrefsSheet extends ConsumerStatefulWidget {
  const NotificationPrefsSheet({super.key, this.fromAccountMenu = false});

  final bool fromAccountMenu;

  static void show(BuildContext context, {bool fromAccountMenu = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationPrefsSheet(fromAccountMenu: fromAccountMenu),
    );
  }

  @override
  ConsumerState<NotificationPrefsSheet> createState() =>
      _NotificationPrefsSheetState();
}

class _NotificationPrefsSheetState extends ConsumerState<NotificationPrefsSheet> {
  static const _accentColor = Color(0xFFE91E8C);
  static const _darkColor = Color(0xFF4A1259);

  final _service = UserProfileService();

  // Modes principaux (backward compat)
  final _selectedModes = <String>{};
  // Sous-interets detailles : "mode:tag"
  final _selectedDetailed = <String>{};
  // Categories depliees dans l'UI
  final _expandedCategories = <String>{};

  final _prenomController = TextEditingController();
  String? _initialPrenom;
  String? _avatarUrl;
  String? _newAvatarPath;
  bool _avatarRemoved = false;

  final _villeController = TextEditingController();
  final _selectedVilles = <String>[];
  List<String> _initialVilles = [];
  Timer? _villeDebounce;
  List<_CommuneResult> _villeSuggestions = [];
  bool _showVilleSuggestions = false;
  String _selectedHub = '';
  bool _loading = true;
  bool _saving = false;

  static const _hubCities = [
    'Aix-en-Provence', 'Angers', 'Bordeaux', 'Brest', 'Clermont-Ferrand',
    'Dijon', 'Grenoble', 'Le Havre', 'Le Mans', 'Lille',
    'Lyon', 'Marseille', 'Montpellier', 'Nantes', 'Nice',
    'Nimes', 'Paris', 'Reims', 'Rennes', 'Saint-Denis',
    'Saint-Etienne', 'Strasbourg', 'Toulon', 'Toulouse',
  ];

  @override
  void initState() {
    super.initState();
    _selectedHub = ref.read(selectedCityProvider);
    _villeController.addListener(_onVilleTextChanged);
    _loadPreferences();
  }

  void _onVilleTextChanged() {
    final query = _villeController.text;
    _villeDebounce?.cancel();
    if (query.length < 2) {
      if (_showVilleSuggestions || _villeSuggestions.isNotEmpty) {
        setState(() {
          _villeSuggestions = [];
          _showVilleSuggestions = false;
        });
      }
      return;
    }
    _villeDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchCommunes(query);
    });
  }

  @override
  void dispose() {
    _villeController.removeListener(_onVilleTextChanged);
    _villeDebounce?.cancel();
    _villeController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await _service.fetchProfile();
      if (profile != null) {
        final prefs = (profile['preferences'] as List?)?.cast<String>() ?? [];
        final detailed = (profile['preferences_detailed'] as List?)?.cast<String>() ?? [];
        final villes = (profile['villes_notifications'] as List?)?.cast<String>() ?? [];
        final ville = (profile['ville'] as String?) ?? '';
        final resolvedVilles = villes.isNotEmpty ? villes : (ville.isNotEmpty ? [ville] : <String>[]);
        final prenom = (profile['prenom'] as String?) ?? '';
        final avatar = profile['avatar_url'] as String?;
        setState(() {
          _selectedModes.addAll(prefs);
          _selectedDetailed.addAll(detailed);
          _selectedVilles.addAll(resolvedVilles);
          _initialVilles = List.of(resolvedVilles);
          _prenomController.text = prenom;
          _initialPrenom = prenom;
          _avatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      // Deduire les modes principaux depuis les sous-interets
      final modesFromDetailed = <String>{};
      for (final key in _selectedDetailed) {
        final mode = key.split(':').first;
        modesFromDetailed.add(mode);
      }
      // Fusionner : modes coches + modes ayant au moins un sous-interet
      final allModes = {..._selectedModes, ...modesFromDetailed};

      await _service.updatePreferences(allModes.toList());
      await _service.updateDetailedPreferences(_selectedDetailed.toList());

      // Villes
      final villesChanged = !_listEquals(_selectedVilles, _initialVilles);
      if (villesChanged) {
        await _service.updateVillesNotifications(_selectedVilles);
        if (_selectedVilles.isNotEmpty) {
          await _service.updateVille(_selectedVilles.first);
        }
        ref.invalidate(userVilleProvider);
        ref.invalidate(userVillesNotificationsProvider);
        ref.invalidate(mairieNotificationsProvider);
      }

      // Hub ville
      final currentHub = ref.read(selectedCityProvider);
      if (_selectedHub != currentHub) {
        ref.read(selectedCityProvider.notifier).setCity(_selectedHub);
      }

      // Profil : prenom
      final newPrenom = _prenomController.text.trim();
      if (newPrenom.isNotEmpty && newPrenom != (_initialPrenom ?? '')) {
        await _service.updatePrenom(newPrenom);
        ref.invalidate(userPrenomProvider);
      }

      // Profil : avatar
      if (_newAvatarPath != null) {
        try {
          final url = await _service.uploadAvatar(_newAvatarPath!);
          await _service.updateAvatar(url);
          ref.invalidate(userAvatarUrlProvider);
        } catch (_) {}
      } else if (_avatarRemoved) {
        await _service.updateAvatar(null);
        ref.invalidate(userAvatarUrlProvider);
      }

      ref.invalidate(userPreferencesProvider);
      ref.invalidate(userDetailedPreferencesProvider);
      ref.invalidate(todayTomorrowEventsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Preferences mises a jour'),
              ],
            ),
            backgroundColor: _darkColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur, reessayez')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleMode(String mode) {
    setState(() {
      if (_selectedModes.contains(mode)) {
        _selectedModes.remove(mode);
        // Retirer tous les sous-interets de ce mode
        _selectedDetailed.removeWhere((k) => k.startsWith('$mode:'));
      } else {
        _selectedModes.add(mode);
      }
    });
  }

  void _toggleDetailedItem(String mode, String tag) {
    final key = '$mode:$tag';
    setState(() {
      if (_selectedDetailed.contains(key)) {
        _selectedDetailed.remove(key);
      } else {
        _selectedDetailed.add(key);
        // Auto-cocher le mode parent
        _selectedModes.add(mode);
      }
    });
  }

  void _toggleExpand(String mode) {
    setState(() {
      if (_expandedCategories.contains(mode)) {
        _expandedCategories.remove(mode);
      } else {
        _expandedCategories.add(mode);
      }
    });
  }

  /// Nombre de sous-interets selectionnes pour un mode.
  int _countSelected(String mode) {
    return _selectedDetailed.where((k) => k.startsWith('$mode:')).length;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle + retour (si depuis le menu compte)
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (widget.fromAccountMenu)
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 26),
                      color: AppColors.textDim,
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Retour',
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lineStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Mon profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkColor,
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Mon profil ──
                  _buildSectionHeader(
                    'Mon profil',
                    'Modifie ton prenom/pseudo et ta photo',
                  ),
                  if (!_loading) _buildProfileSection(),

                  // ── Mes mairies ──
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    'Mes mairies',
                    'Recevez les notifications de plusieurs mairies',
                  ),
                  if (!_loading) _buildMultiVilleSelector(),

                  // ── Hub ville ──
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    'Mon Hub',
                    'Choisissez votre ville principale pour les evenements',
                  ),
                  if (!_loading) _buildHubCitySelector(),

                  // ── Centres d'interet detailles ──
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    'Centres d\'interet',
                    'Selectionnez vos activites pour des notifications pertinentes. '
                        'Appuyez sur une categorie pour affiner vos choix.',
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    ..._buildDetailedInterests(),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Save button
            if (!_loading)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Section profil (avatar + prenom) ──
  Widget _buildProfileSection() {
    final hasLocalAvatar = _newAvatarPath != null;
    final hasRemoteAvatar = !_avatarRemoved && _avatarUrl != null && !hasLocalAvatar;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: _accentColor.withValues(alpha: 0.5), width: 2),
                    image: hasLocalAvatar
                        ? DecorationImage(
                            image: FileImage(File(_newAvatarPath!)),
                            fit: BoxFit.cover,
                          )
                        : hasRemoteAvatar
                            ? DecorationImage(
                                image: NetworkImage(_avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (!hasLocalAvatar && !hasRemoteAvatar)
                      ? Icon(Icons.person, color: AppColors.textFaint, size: 32)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _prenomController,
              style: const TextStyle(fontSize: 14, color: _darkColor),
              decoration: InputDecoration(
                labelText: 'Prenom ou pseudo',
                labelStyle: TextStyle(fontSize: 13, color: AppColors.textDim),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _accentColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final hasAvatar = _newAvatarPath != null ||
        (!_avatarRemoved && _avatarUrl != null);
    final picker = ImagePicker();
    final source = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _darkColor),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _darkColor),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Retirer la photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == _AvatarAction.remove) {
      setState(() {
        _newAvatarPath = null;
        _avatarRemoved = true;
      });
      return;
    }
    try {
      final picked = await picker.pickImage(
        source: source == _AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _newAvatarPath = picked.path;
          _avatarRemoved = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de selectionner cette image')),
        );
      }
    }
  }

  // ── Section header ──
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Detailed interests (expandable categories) ──
  List<Widget> _buildDetailedInterests() {
    return kDetailedInterests.map((cat) {
      final modeSelected = _selectedModes.contains(cat.mode);
      final isExpanded = _expandedCategories.contains(cat.mode);
      final count = _countSelected(cat.mode);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header (toggleable + expandable)
          GestureDetector(
            onTap: () => _toggleExpand(cat.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: modeSelected
                    ? _accentColor.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: modeSelected
                      ? _accentColor.withValues(alpha: 0.3)
                      : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  // Checkbox du mode principal
                  GestureDetector(
                    onTap: () => _toggleMode(cat.mode),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: modeSelected ? _accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: modeSelected ? _accentColor : AppColors.textFaint,
                          width: 1.5,
                        ),
                      ),
                      child: modeSelected
                          ? const Icon(Icons.check, size: 15, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(cat.icon, size: 18, color: modeSelected ? _accentColor : AppColors.textDim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: modeSelected ? _darkColor : AppColors.textDim,
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
                    color: AppColors.textFaint,
                  ),
                ],
              ),
            ),
          ),

          // Sub-interests (visible when expanded)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cat.items.map((item) {
                  final key = item.key(cat.mode);
                  final selected = _selectedDetailed.contains(key);
                  return GestureDetector(
                    onTap: () => _toggleDetailedItem(cat.mode, item.tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accentColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? _accentColor
                              : AppColors.lineStrong,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 14,
                            color: selected ? Colors.white : AppColors.textDim,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? Colors.white : AppColors.textDim,
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
    }).toList();
  }

  // ── Hub city selector ──
  Widget _buildHubCitySelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _hubCities.map((city) {
        final selected = _selectedHub == city;
        return GestureDetector(
          onTap: () => setState(() => _selectedHub = city),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? _accentColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _accentColor : AppColors.lineStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_city,
                  size: 14,
                  color: selected ? Colors.white : AppColors.textDim,
                ),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Multi-ville selector ──
  Widget _buildMultiVilleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedVilles.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedVilles.map((ville) {
              final cityName = ville.contains('(')
                  ? ville.substring(0, ville.indexOf('(')).trim()
                  : ville;
              return Chip(
                label: Text(
                  cityName,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF1565C0),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                onDeleted: () => setState(() => _selectedVilles.remove(ville)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        if (_selectedVilles.isNotEmpty)
          const SizedBox(height: 8),
        TextField(
          controller: _villeController,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ajouter une ville...',
            hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 13),
            prefixIcon: Icon(Icons.add_location_alt, size: 20, color: AppColors.textFaint),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1565C0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (_showVilleSuggestions && _villeSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lineStrong),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _villeSuggestions.length,
              itemBuilder: (context, index) {
                final commune = _villeSuggestions[index];
                final display = '${commune.nom} (${commune.codePostal})';
                final alreadyAdded = _selectedVilles.contains(display);
                return InkWell(
                  onTap: alreadyAdded ? null : () {
                    _villeController.clear();
                    setState(() {
                      _selectedVilles.add(display);
                      _showVilleSuggestions = false;
                      _villeSuggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          alreadyAdded ? Icons.check_circle : Icons.location_on,
                          size: 16,
                          color: alreadyAdded ? Colors.green : const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            commune.nom,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: alreadyAdded ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          commune.codePostal,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textFaint),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commune.departement,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textFaint),
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

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
        final codes = (item['codesPostaux'] as List?)?.cast<String>() ?? [];
        final dep = item['codeDepartement'] as String? ?? '';
        final cp = codes.isNotEmpty ? codes.first : '';
        results.add(_CommuneResult(nom: nom, codePostal: cp, departement: dep));
      }
      if (mounted) {
        setState(() {
          _villeSuggestions = results;
          _showVilleSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {}
  }
}

enum _AvatarAction { camera, gallery, remove }

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
