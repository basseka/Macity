import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/onboarding/data/email_verification_service.dart';

/// Feuille de saisie du code de confirmation email (6 chiffres).
/// Renvoie `true` (via Navigator.pop) si le code est validé, sinon `null`.
///
/// Le code doit déjà avoir été demandé par l'appelant ([EmailVerificationService.requestCode])
/// avant l'ouverture ; la feuille gère le renvoi.
class EmailVerificationSheet extends StatefulWidget {
  final String email;
  final String? prenom;

  const EmailVerificationSheet({super.key, required this.email, this.prenom});

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    String? prenom,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: const Color(0xFF1A0A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EmailVerificationSheet(email: email, prenom: prenom),
    );
  }

  @override
  State<EmailVerificationSheet> createState() => _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<EmailVerificationSheet> {
  final _svc = EmailVerificationService();
  final _codeController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Entrez le code à 6 chiffres');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final ok = await _svc.verifyCode(email: widget.email, code: code);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Code incorrect ou expiré';
          _verifying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de vérification, réessayez';
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await _svc.requestCode(email: widget.email, prenom: widget.prenom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau code envoyé')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de renvoyer le code');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirmez votre email',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mark_email_unread_outlined,
                      size: 15, color: Colors.white54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pas reçu ? Pensez à vérifier vos spams / courriers indésirables.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_verifying,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                  if (v.length == 6) _verify();
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: Colors.white24,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE91E8C)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFFF6B81),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E8C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Confirmer',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _verifying
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(
                      _resending ? 'Envoi…' : 'Renvoyer le code',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
