import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

/// Choix de la langue de l'app : automatique (langue du telephone) ou
/// francais / anglais / espagnol. Le choix est memorise (cf. localeProvider)
/// et s'applique immediatement a toute l'app.
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider)?.languageCode;
    final l10n = context.l10n;

    Widget option(String? code, String label) {
      final selected = current == code;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () async {
            await ref.read(localeProvider.notifier).setLanguage(code);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              color: selected
                  ? AppColors.magenta.withValues(alpha: 0.12)
                  : AppColors.surfaceHi,
              border: Border.all(
                color: selected ? AppColors.magenta : AppColors.line,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded,
                      color: AppColors.magenta, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.languageSheetTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              option(null, l10n.languageSystem),
              for (final e in kAppLanguages.entries) ...[
                const SizedBox(height: 6),
                option(e.key, e.value),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.languageContentNote,
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(
                  fontSize: 11,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
