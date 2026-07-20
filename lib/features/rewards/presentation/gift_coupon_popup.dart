import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/rewards/data/story_rewards_service.dart';
import 'package:pulz_app/features/rewards/state/rewards_provider.dart';

/// Popup « cadeau » : ouvre un coupon (tire un cadeau au hasard) et affiche le
/// cadeau gagné + son code de retrait à présenter au commerçant.
class GiftCouponPopup extends ConsumerStatefulWidget {
  final int couponId;
  final int palier;

  const GiftCouponPopup({super.key, required this.couponId, required this.palier});

  static Future<void> show(BuildContext context,
      {required int couponId, required int palier}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => GiftCouponPopup(couponId: couponId, palier: palier),
    );
  }

  @override
  ConsumerState<GiftCouponPopup> createState() => _GiftCouponPopupState();
}

class _GiftCouponPopupState extends ConsumerState<GiftCouponPopup> {
  GiftReward? _gift;
  String? _error;
  bool _loading = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final gift = await StoryRewardsService().openCoupon(widget.couponId);
      if (!mounted) return;
      setState(() {
        _gift = gift;
        _loading = false;
      });
      // Rafraîchit l'état City-Miles (le coupon est passé "opened").
      ref.invalidate(cityMilesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('no_gift')
            ? "Aucun cadeau disponible pour l'instant. Reviens bientôt !"
            : "Impossible d'ouvrir le coupon.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1148), Color(0xFF1A0F2E)],
          ),
          border: Border.all(color: const Color(0x55E8A63C), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x88000000), blurRadius: 30, spreadRadius: -6),
          ],
        ),
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildGift(),
      ),
    );
  }

  Widget _buildLoading() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Ouverture de ton cadeau…',
              style: GoogleFonts.geist(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8A63C)),
          ),
        ],
      );

  Widget _buildError() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(fontSize: 14, color: Colors.white)),
          const SizedBox(height: 18),
          _closeButton('Fermer'),
        ],
      );

  Widget _buildGift() {
    final g = _gift!;
    final hasImg = g.imageUrl.startsWith('http');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎉 Tu as gagné !',
            style: GoogleFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: const Color(0xFFF6E6B8))),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 150,
            height: 150,
            child: hasImg
                ? CachedNetworkImage(
                    imageUrl: g.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _giftFallback(),
                  )
                : _giftFallback(),
          ),
        ),
        const SizedBox(height: 14),
        Text(g.nom,
            textAlign: TextAlign.center,
            style: GoogleFonts.geist(
                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        if (g.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(g.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.35)),
        ],
        const SizedBox(height: 18),
        // Code de retrait à présenter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x55E8A63C)),
          ),
          child: Column(
            children: [
              Text('CODE À PRÉSENTER',
                  style: GoogleFonts.geist(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              Text(g.code,
                  style: GoogleFonts.geistMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: const Color(0xFFF6E6B8))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: g.code));
                  setState(() => _copied = true);
                },
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16, color: Colors.white),
                label: Text(_copied ? 'Copié' : 'Copier',
                    style: GoogleFonts.geist(color: Colors.white, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x44FFFFFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _closeButton('Super !')),
          ],
        ),
      ],
    );
  }

  Widget _giftFallback() => Container(
        color: const Color(0xFF3A1D5E),
        alignment: Alignment.center,
        child: const Text('🎁', style: TextStyle(fontSize: 60)),
      );

  Widget _closeButton(String label) => ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: GoogleFonts.geist(fontWeight: FontWeight.w700, fontSize: 14)),
      );
}
