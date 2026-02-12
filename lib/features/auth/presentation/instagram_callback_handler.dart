import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/auth/state/instagram_auth_provider.dart';

class InstagramCallbackHandler extends ConsumerStatefulWidget {
  final Uri uri;

  const InstagramCallbackHandler({super.key, required this.uri});

  @override
  ConsumerState<InstagramCallbackHandler> createState() =>
      _InstagramCallbackHandlerState();
}

class _InstagramCallbackHandlerState
    extends ConsumerState<InstagramCallbackHandler> {
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final code = widget.uri.queryParameters['code'];

      if (code == null || code.isEmpty) {
        setState(() {
          _error = 'Code d\'autorisation manquant';
          _isProcessing = false;
        });
        return;
      }

      await ref.read(instagramAuthProvider.notifier).handleCallback(code);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la connexion Instagram';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Scaffold(
      backgroundColor: modeTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modeTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retour'),
                ),
              ] else ...[
                CircularProgressIndicator(
                  color: modeTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Connexion Instagram en cours...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
