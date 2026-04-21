import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/notifications/state/mairie_notifications_provider.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

/// Sheet dediee a la gestion des villes (mairies) suivies pour les notifs.
/// Ajout / suppression via l'API communes de gouv.fr.
/// Ouvrable depuis MairieNotificationsSheet via le bouton engrenage.
class ManageMairiesSheet extends ConsumerStatefulWidget {
  const ManageMairiesSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManageMairiesSheet(),
    );
  }

  @override
  ConsumerState<ManageMairiesSheet> createState() =>
      _ManageMairiesSheetState();
}

class _ManageMairiesSheetState extends ConsumerState<ManageMairiesSheet> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _darkColor = Color(0xFF4A1259);
  static const _accentColor = Color(0xFFE91E8C);

  final _service = UserProfileService();
  final _villeController = TextEditingController();

  final _selectedVilles = <String>[];
  List<String> _initialVilles = const [];
  List<_CommuneResult> _suggestions = [];
  bool _showSuggestions = false;
  bool _loading = true;
  bool _saving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _villeController.addListener(_onQueryChanged);
    _load();
  }

  @override
  void dispose() {
    _villeController.removeListener(_onQueryChanged);
    _villeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _service.fetchProfile();
      final villes = (profile?['villes_notifications'] as List?)?.cast<String>() ?? [];
      final ville = (profile?['ville'] as String?) ?? '';
      final resolved = villes.isNotEmpty
          ? villes
          : (ville.isNotEmpty ? [ville] : <String>[]);
      if (!mounted) return;
      setState(() {
        _selectedVilles.addAll(resolved);
        _initialVilles = List.of(resolved);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged() {
    final q = _villeController.text;
    _debounce?.cancel();
    if (q.trim().length < 2) {
      if (_showSuggestions) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final dio = Dio();
      // Si la query contient une apostrophe, on cherche aussi la variante sans
      // (ex: "l'herm" → trouve "Lherm" 31600 ET "L'Herm" 09000). Sans ca,
      // l'API geo.api.gouv.fr manque souvent les communes collees.
      final variants = <String>{query};
      if (query.contains("'") || query.contains('\u2019')) {
        variants.add(query.replaceAll(RegExp(r"['\u2019]"), ''));
      }

      final futures = variants.map((q) => dio.get(
            'https://geo.api.gouv.fr/communes',
            queryParameters: {
              'nom': q,
              'fields': 'nom,codesPostaux,codeDepartement,code',
              'boost': 'population',
              'limit': '15',
            },
          ));
      final responses = await Future.wait(futures);

      final seen = <String>{};
      final results = <_CommuneResult>[];
      for (final res in responses) {
        for (final item in res.data as List) {
          final code = item['code'] as String? ?? '';
          if (code.isEmpty || seen.contains(code)) continue;
          seen.add(code);
          final nom = item['nom'] as String;
          final codes = (item['codesPostaux'] as List?)?.cast<String>() ?? [];
          final dep = item['codeDepartement'] as String? ?? '';
          if (codes.isEmpty) continue;
          results.add(_CommuneResult(nom: nom, codePostal: codes.first, departement: dep));
        }
      }
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_listEquals(_selectedVilles, _initialVilles)) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.updateVillesNotifications(_selectedVilles);
      if (_selectedVilles.isNotEmpty) {
        await _service.updateVille(_selectedVilles.first);
      }
      ref.invalidate(userVilleProvider);
      ref.invalidate(userVillesNotificationsProvider);
      ref.invalidate(mairieNotificationsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Mairies mises a jour'),
            ],
          ),
          backgroundColor: _darkColor,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur, reessayez')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF0FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance, size: 18, color: _primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gerer mes mairies',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _darkColor,
                        ),
                      ),
                      Text(
                        'Ajoutez ou retirez les villes suivies',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _primaryColor),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedVilles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucune mairie suivie pour le moment',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedVilles.map((ville) {
                          final name = ville.contains('(')
                              ? ville.substring(0, ville.indexOf('(')).trim()
                              : ville;
                          return Chip(
                            label: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: _primaryColor,
                            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                            onDeleted: () => setState(() => _selectedVilles.remove(ville)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _villeController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ajouter une ville...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.add_location_alt, size: 20, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    if (_showSuggestions && _suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, i) {
                            final c = _suggestions[i];
                            final display = '${c.nom} (${c.codePostal})';
                            final already = _selectedVilles.contains(display);
                            return InkWell(
                              onTap: already
                                  ? null
                                  : () {
                                      _villeController.clear();
                                      setState(() {
                                        _selectedVilles.add(display);
                                        _showSuggestions = false;
                                        _suggestions = [];
                                      });
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      already ? Icons.check_circle : Icons.location_on,
                                      size: 16,
                                      color: already ? Colors.green : _primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.nom,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: already ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.codePostal,
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.departement,
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Enregistrer',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _CommuneResult {
  final String nom;
  final String codePostal;
  final String departement;
  const _CommuneResult({required this.nom, required this.codePostal, required this.departement});
}
