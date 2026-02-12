import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

class HomeModeCard extends StatelessWidget {
  final AppMode mode;
  final ModeTheme theme;
  final VoidCallback onTap;

  const HomeModeCard({
    super.key,
    required this.mode,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.primaryColor, theme.primaryDarkColor],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                mode.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const Spacer(),
              Text(
                mode.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.subtitleString,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
