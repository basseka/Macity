import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/notifications/presentation/notification_prefs_sheet.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/pro_auth/presentation/pro_login_sheet.dart';

class AccountMenu {
  AccountMenu._();

  static Widget buildButton() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 14),
    );
  }

  static void show(BuildContext context, WidgetRef ref) {
    final villeAsync = ref.read(userVilleProvider);
    final ville = villeAsync.valueOrNull ?? '';
    final prenom = ref.read(userPrenomProvider).valueOrNull ?? '';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCF8FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4A1259), Color(0xFFE91E8C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E8C).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  prenom.isNotEmpty ? 'Bonjour, $prenom' : 'Mon compte',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0A2E),
                  ),
                ),
                if (ville.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        ville,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.person_add_rounded,
                  label: 'Inscription',
                  subtitle: 'Creer un profil',
                  gradientColors: const [Color(0xFF7B2D8E), Color(0xFF9B4DCA)],
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/onboarding');
                  },
                ),
                const SizedBox(height: 10),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.login_rounded,
                  label: 'Connexion',
                  subtitle: 'Espace professionnel',
                  gradientColors: const [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ProLoginSheet(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _menuItem(
                  ctx: ctx,
                  icon: Icons.tune_rounded,
                  label: 'Mes preferences',
                  subtitle: 'Ville, centres d\'interet',
                  gradientColors: const [Color(0xFF4A1259), Color(0xFF6B2D7B)],
                  onTap: () {
                    Navigator.pop(ctx);
                    NotificationPrefsSheet.show(context);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _menuItem({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A0A2E),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
