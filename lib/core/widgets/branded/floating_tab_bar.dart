import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/widgets/branded/glass_card.dart';

/// Tab bar floating (glass) avec FAB central en degrade primaire.
/// Ordre : Accueil / Carte / FAB (+) / Recherche / Favoris.
class FloatingTabBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  final VoidCallback? onFabTap;
  const FloatingTabBar({
    super.key,
    required this.current,
    required this.onTap,
    this.onFabTap,
  });

  static const _tabs = [
    (icon: Icons.home_outlined, label: 'Accueil'),
    (icon: Icons.map_outlined, label: 'Carte'),
    (icon: Icons.search, label: 'Recherche'),
    (icon: Icons.favorite_border, label: 'Favoris'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 18,
      child: GlassCard(
        radius: AppRadius.tabBar,
        blur: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tab(0),
              _tab(1),
              // FAB
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.neon(AppColors.magenta, blur: 20, y: 8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
              _tab(2),
              _tab(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i) {
    final t = _tabs[i];
    final active = i == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 24,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Icon(
              t.icon,
              size: 22,
              color: active ? AppColors.text : AppColors.textFaint,
            ),
            const SizedBox(height: 3),
            Text(
              t.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.text : AppColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
