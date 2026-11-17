import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/features/city/state/search_area_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/screens/tonight_bons_plans_page.dart';

/// Bandeau « 📍 Bienvenue à X ! » affiché à l'accueil quand le GPS détecte
/// une nouvelle commune (voir `SearchAreaNotifier._maybeAnnounceArrival`).
/// Un appui ouvre les bons plans ; il disparaît seul au bout de 15 s.
class CityArrivalBanner extends ConsumerStatefulWidget {
  const CityArrivalBanner({super.key});

  @override
  ConsumerState<CityArrivalBanner> createState() => _CityArrivalBannerState();
}

class _CityArrivalBannerState extends ConsumerState<CityArrivalBanner> {
  static const _pink = Color(0xFFE8177A);
  Timer? _timer;
  String? _shown;

  void _close() {
    _timer?.cancel();
    ref.read(cityArrivalProvider.notifier).state = null;
  }

  void _arm(String city) {
    if (_shown == city) return;
    _shown = city;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      if (mounted && ref.read(cityArrivalProvider) == city) _close();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(cityArrivalProvider);
    if (city != null) _arm(city);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: city == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: _pink,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _close();
                    TonightBonsPlansPage.show(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
                    child: Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.cityArrivalTitle(city),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                context.l10n.cityArrivalBody,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: .9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18,),
                          onPressed: _close,
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
