import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Sheet de verification par code 6-chiffres envoye par mail a l'inscription.
/// (Anciennement "En attente de validation par l'equipe" — remplace par un
/// flow self-service de verification email.)
class ProPendingSheet extends ConsumerStatefulWidget {
  const ProPendingSheet({super.key});

  @override
  ConsumerState<ProPendingSheet> createState() => _ProPendingSheetState();
}

class _ProPendingSheetState extends ConsumerState<ProPendingSheet> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  final _codeController = TextEditingController();
  bool _isResending = false;
  bool _codeVerified = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez les 6 chiffres du code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final ok = await ref.read(proAuthProvider.notifier).verifyCode(code);
    if (!mounted) return;
    if (ok) {
      // Code valide : l'email est verifie cote DB (approval_code clear).
      // Mais le compte reste approved=false : l'admin doit valider via
      // admin.html apres appel telephonique. On affiche un ecran d'attente.
      setState(() => _codeVerified = true);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(proAuthProvider.notifier).resendCode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouveau code envoye par mail'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du renvoi du code'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(proAuthProvider);
    final email = authState.profile?.email ?? '';

    ref.listen<ProAuthState>(proAuthProvider, (prev, next) {
      if (next.status == ProAuthStatus.approved) {
        // L'admin a valide via admin.html pendant qu'on etait sur l'ecran.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte approuve ! Bienvenue sur MaCity'),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
      if (next.status == ProAuthStatus.notConnected) {
        Navigator.of(context).pop();
      }
    });

    // Apres une saisie reussie du code email, on affiche un ecran "en
    // cours de validation par l'admin" plutot que de fermer la sheet
    // (le compte reste approved=false tant que l'admin n'a pas valide).
    if (_codeVerified) {
      return _AwaitingAdminApprovalView(
        email: email,
        onClose: () => Navigator.of(context).pop(),
      );
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 32,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Verification par email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDim,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Un code a 6 chiffres a ete envoye a\n',
                  ),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _primaryDarkColor,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Pas recu ? Pensez a verifier vos spams / courriers indesirables.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDim,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Input code
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
                color: _primaryDarkColor,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: TextStyle(
                  color: AppColors.lineStrong,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: AppColors.surfaceHi,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.lineStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.lineStrong),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),

            if (authState.error != null) ...[
              const SizedBox(height: 10),
              Text(
                authState.error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                child: authState.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Valider',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            TextButton(
              onPressed: _isResending ? null : _resend,
              child: Text(
                _isResending ? 'Envoi en cours...' : 'Renvoyer le code',
                style: TextStyle(
                  fontSize: 13,
                  color: _isResending ? Colors.grey : _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            TextButton(
              onPressed: () =>
                  ref.read(proAuthProvider.notifier).disconnect(),
              child: const Text(
                'Se deconnecter',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ecran affiche apres une saisie reussie du code email : le code etait
/// bon (email verifie cote DB), mais le compte attend la validation
/// manuelle de l'admin par telephone via admin.html.
class _AwaitingAdminApprovalView extends StatelessWidget {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  final String email;
  final VoidCallback onClose;

  const _AwaitingAdminApprovalView({
    required this.email,
    required this.onClose,
  });

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
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 36,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Email verifie !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Compte en cours de validation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const Text(
              'Notre equipe va t\'appeler tres bientot au numero que tu as renseigne pour finaliser la validation de ton compte.\n\nUne fois ton compte approuve, tu pourras publier des offres et acceder a toutes les fonctionnalites pro.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK, j\'attends l\'appel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
