import 'package:flutter/material.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_page.dart';

/// Compact launcher bottom sheet.
/// Shows a brief intro then navigates to the full-screen wizard.
class AddEventBottomSheet extends StatelessWidget {
  final String? initialPhotoPath;

  const AddEventBottomSheet({super.key, this.initialPhotoPath});

  static const _primaryColor = Color(0xFF7B2D8E);
  static const _primaryDarkColor = Color(0xFF4A1259);

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _primaryColor,
                    _primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: const Icon(Icons.event_available, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),

            const Text(
              'Creez votre evenement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Concert, atelier, sport, festival...\nPartagez votre evenement en quelques etapes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEventPage(
                        initialPhotoPath: initialPhotoPath,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Commencer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
