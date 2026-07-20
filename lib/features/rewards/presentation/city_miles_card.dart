import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/rewards/data/story_rewards_service.dart';
import 'package:pulz_app/features/rewards/presentation/gift_coupon_popup.dart';
import 'package:pulz_app/features/rewards/state/rewards_provider.dart';

/// Carte affichée en tête de « Publications » : City-Miles + Totem de
/// progression + accès aux coupons cadeaux débloqués.
class CityMilesCard extends ConsumerWidget {
  const CityMilesCard({super.key});

  static const _magenta = Color(0xFFE91E8C);
  static const _gold = Color(0xFFE8A63C);
  static const _ink = Color(0xFF1A0F2E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cityMilesProvider);
    return async.when(
      loading: () => const SizedBox(height: 96),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => _card(context, ref, s),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, CityMilesState s) {
    final ready = s.unopened.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF3FF), Color(0xFFFFF6EC)],
          ),
          border: Border.all(color: const Color(0x22E91E8C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _totem(s.inCycle),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tes City-Miles',
                          style: GoogleFonts.geist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _ink.withValues(alpha: 0.6))),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${s.cityMiles}',
                              style: GoogleFonts.geist(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: _magenta)),
                          const SizedBox(width: 6),
                          Text('City-Miles',
                              style: GoogleFonts.geist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.inCycle / 40,
                          minHeight: 8,
                          backgroundColor: const Color(0x22E91E8C),
                          valueColor: const AlwaysStoppedAnimation(_gold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ready
                            ? '🎁 Ta récompense est prête !'
                            : 'Plus que ${s.toNext} avant ton prochain cadeau 🎁',
                        style: GoogleFonts.geist(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ready ? _magenta : _ink.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final c in s.unopened) ...[
              const SizedBox(height: 12),
              _couponButton(context, ref, c),
            ],
          ],
        ),
      ),
    );
  }

  /// Totem : 8 blocs empilés qui se remplissent (1 bloc = 5 City-Miles).
  Widget _totem(int inCycle) {
    const n = 8;
    final filled = (inCycle / 5).ceil().clamp(0, n);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🗿', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        for (var i = 0; i < n; i++)
          Container(
            width: i == 0 ? 26 : (i == n - 1 ? 40 : 34),
            height: 8,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: (n - i) <= filled
                  ? const LinearGradient(colors: [_magenta, _gold])
                  : null,
              color: (n - i) <= filled ? null : const Color(0x14000000),
            ),
          ),
      ],
    );
  }

  Widget _couponButton(BuildContext context, WidgetRef ref, RewardCoupon c) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await GiftCouponPopup.show(context, couponId: c.id, palier: c.palier);
          ref.invalidate(cityMilesProvider);
        },
        icon: const Text('🎁', style: TextStyle(fontSize: 16)),
        label: Text('Ouvre ta récompense (palier ${c.palier})',
            style: GoogleFonts.geist(
                fontWeight: FontWeight.w800, fontSize: 13.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _magenta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
