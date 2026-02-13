import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

class ProPendingSheet extends ConsumerWidget {
  const ProPendingSheet({super.key});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(proAuthProvider);
    final nom = authState.profile?.nom ?? '';

    ref.listen<ProAuthState>(proAuthProvider, (prev, next) {
      if (next.status == ProAuthStatus.approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre compte a ete approuve !'),
            backgroundColor: _primaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
      if (next.status == ProAuthStatus.notConnected) {
        Navigator.of(context).pop();
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Hourglass icon
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
            const SizedBox(height: 24),

            // Title
            const Text(
              'En attente de validation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Votre inscription pour "$nom" est en cours de verification par notre equipe.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Refresh button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(proAuthProvider.notifier).refreshStatus(),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'Verifier le statut',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Disconnect link
            TextButton(
              onPressed: () =>
                  ref.read(proAuthProvider.notifier).disconnect(),
              child: const Text(
                'Se deconnecter',
                style: TextStyle(
                  fontSize: 14,
                  color: _primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
