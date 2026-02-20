import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/features/auth/state/instagram_auth_provider.dart';
import 'package:pulz_app/features/city/presentation/city_picker_bottom_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final authState = ref.watch(instagramAuthProvider);
    final formattedDate = DateFormatter.formatFull(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: modeTheme.toolbarGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Date display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // City selector button
            Material(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showCityPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Instagram button
            Material(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _handleInstagramTap(context, ref, authState),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    authState.isConnected
                        ? Icons.person
                        : Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CityPickerBottomSheet(),
    );
  }

  Future<void> _handleInstagramTap(
    BuildContext context,
    WidgetRef ref,
    InstagramAuthState authState,
  ) async {
    if (authState.isConnected) {
      _showAccountDialog(context, ref, authState);
      return;
    }

    final authUrl =
        await ref.read(instagramAuthProvider.notifier).startAuth();
    if (authUrl != null) {
      final uri = Uri.tryParse(authUrl);
      if (uri == null) return;
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  void _showAccountDialog(
    BuildContext context,
    WidgetRef ref,
    InstagramAuthState authState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compte Instagram'),
        content: Text(
          'Connecte en tant que @${authState.username ?? ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              ref.read(instagramAuthProvider.notifier).disconnect();
              Navigator.of(ctx).pop();
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
    );
  }
}
