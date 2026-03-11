import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/today_events_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

class NotificationPrefsSheet extends ConsumerStatefulWidget {
  const NotificationPrefsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationPrefsSheet(),
    );
  }

  @override
  ConsumerState<NotificationPrefsSheet> createState() =>
      _NotificationPrefsSheetState();
}

class _NotificationPrefsSheetState extends ConsumerState<NotificationPrefsSheet> {
  static const _modeOptions = [
    (mode: AppMode.day, label: 'Concerts & Spectacles', icon: Icons.music_note),
    (mode: AppMode.sport, label: 'Sport', icon: Icons.sports_soccer),
    (mode: AppMode.culture, label: 'Culture & Arts', icon: Icons.palette),
    (mode: AppMode.family, label: 'En Famille', icon: Icons.family_restroom),
    (mode: AppMode.food, label: 'Food & Lifestyle', icon: Icons.restaurant),
    (mode: AppMode.gaming, label: 'Gaming', icon: Icons.videogame_asset),
    (mode: AppMode.night, label: 'Nuit & Sorties', icon: Icons.nightlife),
    (mode: AppMode.tourisme, label: 'Tourisme', icon: Icons.flight),
  ];

  final _service = UserProfileService();
  final _selectedModes = <String>{};
  final _villeController = TextEditingController();
  String _currentVille = '';
  String _selectedVille = '';
  Timer? _villeDebounce;
  List<_CommuneResult> _villeSuggestions = [];
  bool _showVilleSuggestions = false;
  String _selectedHub = '';
  bool _loading = true;
  bool _saving = false;

  static const _hubCities = [
    'Toulouse', 'Montpellier', 'Nice', 'Marseille', 'Bordeaux',
    'Lyon', 'Paris', 'Lille', 'Strasbourg', 'Rennes',
    'Dijon', 'Orleans', 'Rouen', 'Nantes',
  ];

  @override
  void initState() {
    super.initState();
    _selectedHub = ref.read(selectedCityProvider);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await _service.fetchProfile();
      if (profile != null) {
        final prefs = (profile['preferences'] as List?)?.cast<String>() ?? [];
        final ville = (profile['ville'] as String?) ?? '';
        setState(() {
          _selectedModes.addAll(prefs);
          _currentVille = ville;
          _selectedVille = ville;
          _villeController.text = ville;
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
      await _service.updatePreferences(_selectedModes.toList());
      if (_selectedVille != _currentVille && _selectedVille.isNotEmpty) {
        await _service.updateVille(_selectedVille);
        ref.invalidate(userVilleProvider);
      }
      // Mettre a jour le hub ville
      final currentHub = ref.read(selectedCityProvider);
      if (_selectedHub != currentHub) {
        ref.read(selectedCityProvider.notifier).setCity(_selectedHub);
      }
      // Rafraichir les providers pour mettre a jour les events affiches
      ref.invalidate(userPreferencesProvider);
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
            backgroundColor: Color(0xFF4A1259),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mes preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A1259),
                ),
              ),

              // --- Ma ville ---
              const SizedBox(height: 16),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ma ville',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A1259),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recevez les notifications de votre Mairie',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildVilleSelector(),
                ),

              // --- Hub ville ---
              const SizedBox(height: 16),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mon Hub',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A1259),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choisissez votre ville principale pour les evenements',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hubCities.map((city) {
                      final selected = _selectedHub == city;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedHub = city),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE91E8C)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFE91E8C)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_city,
                                size: 14,
                                color: selected ? Colors.white : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                city,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  color: selected ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // --- Centres d'interet ---
              const SizedBox(height: 16),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Centres d\'interet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A1259),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selectionnez vos activites pour des notifications pertinentes',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modeOptions.map((opt) {
                      final selected =
                          _selectedModes.contains(opt.mode.name);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedModes.remove(opt.mode.name);
                            } else {
                              _selectedModes.add(opt.mode.name);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE91E8C)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFE91E8C)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt.icon,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              if (!_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1259),
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVilleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _villeController,
          style: GoogleFonts.inter(fontSize: 14),
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
            hintText: 'Rechercher une ville...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.location_city, size: 20, color: Colors.grey.shade500),
            suffixIcon: _selectedVille.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade500),
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
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E8C)),
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
              border: Border.all(color: Colors.grey.shade300),
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
                return InkWell(
                  onTap: () {
                    final display = '${commune.nom} (${commune.codePostal})';
                    _villeController.text = display;
                    _villeController.selection = TextSelection.collapsed(offset: display.length);
                    setState(() {
                      _selectedVille = display;
                      _showVilleSuggestions = false;
                      _villeSuggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFFE91E8C)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            commune.nom,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          commune.codePostal,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commune.departement,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
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
