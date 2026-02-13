import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class ProLoginSheet extends ConsumerStatefulWidget {
  const ProLoginSheet({super.key});

  @override
  ConsumerState<ProLoginSheet> createState() => _ProLoginSheetState();
}

class _ProLoginSheetState extends ConsumerState<ProLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telephoneController = TextEditingController();

  String _selectedType = 'association';
  bool _isLoginMode = false;
  bool _obscurePassword = true;

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  static const _typeLabels = <String, String>{
    'association': 'Association',
    'etablissement_prive': 'Etablissement prive',
    'personne_morale': 'Personne Morale approuvee',
  };

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(proAuthProvider);

    ref.listen<ProAuthState>(proAuthProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (prev?.status == ProAuthStatus.notConnected &&
          (next.status == ProAuthStatus.pendingApproval ||
              next.status == ProAuthStatus.approved)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.status == ProAuthStatus.approved
                  ? 'Connexion reussie !'
                  : _isLoginMode
                      ? 'Connexion reussie ! En attente de validation.'
                      : 'Inscription reussie ! En attente de validation.',
            ),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
    });

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

              const Text(
                'Espace Professionnel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Toggle tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTab('Inscription', !_isLoginMode),
                    _buildTab('Connexion', _isLoginMode),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLoginMode
                    ? 'Connectez-vous a votre compte'
                    : 'Inscrivez-vous pour publier des evenements',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_isLoginMode) ...[
                // ── Mode connexion ──
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'L\'email est requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration(
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _primaryColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le mot de passe est requis'
                      : null,
                ),
              ] else ...[
                // ── Mode inscription ──
                TextFormField(
                  controller: _nomController,
                  decoration: _inputDecoration(
                    label: 'Nom de la structure',
                    icon: Icons.business_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le nom est requis'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Type de structure',
                    icon: Icons.category_outlined,
                  ),
                  items: _typeLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child:
                              Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'L\'email est requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration(
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _primaryColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (v.trim().length < 6) {
                      return 'Minimum 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  decoration: _inputDecoration(
                    label: 'Telephone',
                    icon: Icons.phone_outlined,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le telephone est requis'
                      : null,
                ),
              ],
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: authState.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: authState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isLoginMode
                            ? 'Se connecter'
                            : 'Valider l\'inscription',
                        style: const TextStyle(
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

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isLoginMode = label == 'Connexion';
            _formKey.currentState?.reset();
            _passwordController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoginMode) {
      ref.read(proAuthProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } else {
      ref.read(proAuthProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nom: _nomController.text.trim(),
            type: _selectedType,
            telephone: _telephoneController.text.trim(),
          );
    }
  }
}
