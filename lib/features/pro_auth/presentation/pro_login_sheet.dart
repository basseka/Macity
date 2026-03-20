import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/pro_auth/data/pro_auth_service.dart';
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
  bool _isResetting = false;
  bool _showSuccess = false;
  String _successMessage = '';

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
      final wasSubmitting = prev?.isSubmitting == true;
      final isNowAuthenticated = next.status == ProAuthStatus.pendingApproval ||
          next.status == ProAuthStatus.approved;
      if (wasSubmitting && !next.isSubmitting && isNowAuthenticated && next.error == null) {
        _onSuccess(next.status);
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
      child: _showSuccess
          ? _buildSuccessView()
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Espace Professionnel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Toggle tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildTab('Inscription', !_isLoginMode),
                    _buildTab('Connexion', _isLoginMode),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoginMode
                    ? 'Connectez-vous a votre compte'
                    : 'Inscrivez-vous pour publier des evenements',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              if (_isLoginMode) ...[
                // ── Mode connexion ──
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'L\'email est requis'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(fontSize: 13),
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
                        size: 18,
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _isResetting ? null : _resetPassword,
                    child: Text(
                      _isResetting
                          ? 'Envoi en cours...'
                          : 'Mot de passe oublie ?',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isResetting ? Colors.grey : _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // ── Mode inscription ──
                TextFormField(
                  controller: _nomController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(
                    label: 'Nom de la structure',
                    icon: Icons.business_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le nom est requis'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: _inputDecoration(
                    label: 'Type de structure',
                    icon: Icons.category_outlined,
                  ),
                  items: _typeLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child:
                              Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'L\'email est requis'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(fontSize: 13),
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
                        size: 18,
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telephoneController,
                  style: const TextStyle(fontSize: 13),
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
              const SizedBox(height: 16),

              // Error message
              if (authState.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit
              ElevatedButton(
                onPressed: authState.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: authState.isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, Color(0xFFE91E8C)],
              ),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            _successMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primaryDarkColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
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
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: _primaryColor, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez votre email d\'abord'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isResetting = true);
    try {
      await ProAuthService().resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de reinitialisation envoye !'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi. Verifiez votre email.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoginMode) {
      await ref.read(proAuthProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } else {
      await ref.read(proAuthProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nom: _nomController.text.trim(),
            type: _selectedType,
            telephone: _telephoneController.text.trim(),
          );
    }

    if (!mounted) return;
    final state = ref.read(proAuthProvider);
    final isAuthenticated = state.status == ProAuthStatus.pendingApproval ||
        state.status == ProAuthStatus.approved;
    if (isAuthenticated && state.error == null) {
      _onSuccess(state.status);
    }
  }

  void _onSuccess(ProAuthStatus status) {
    if (_showSuccess) return;
    setState(() {
      _showSuccess = true;
      _successMessage = status == ProAuthStatus.approved
          ? 'Connexion reussie !'
          : _isLoginMode
              ? 'Connexion reussie ! En attente de validation.'
              : 'Inscription reussie ! En attente de validation par notre equipe.';
    });
  }
}
