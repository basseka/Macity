import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulz_app/features/offers/data/offer_supabase_service.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';

/// Popup glamour qui affiche un code a 6 chiffres apres avoir claim une place.
class OfferCodePopup extends StatefulWidget {
  final Offer offer;

  const OfferCodePopup({super.key, required this.offer});

  static Future<void> show(BuildContext context, Offer offer) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => OfferCodePopup(offer: offer),
    );
  }

  @override
  State<OfferCodePopup> createState() => _OfferCodePopupState();
}

class _OfferCodePopupState extends State<OfferCodePopup>
    with SingleTickerProviderStateMixin {
  String? _code;
  bool _loading = true;
  String? _error;
  bool _copied = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _claimAndGenerateCode();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _claimAndGenerateCode() async {
    try {
      await OfferSupabaseService().claimSpot(widget.offer.id);
      final code = _generateCode();
      if (mounted) {
        setState(() {
          _code = code;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de valider l\'offre';
          _loading = false;
        });
      }
    }
  }

  String _generateCode() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8A0BF).withValues(alpha: 0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative glows
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE91E8C).withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -40,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE8A0BF).withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Emoji
                          if (widget.offer.emoji.isNotEmpty)
                            Text(widget.offer.emoji, style: const TextStyle(fontSize: 36)),
                          if (widget.offer.emoji.isNotEmpty)
                            const SizedBox(height: 8),

                          // Title
                          Text(
                            widget.offer.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.offer.businessName,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFE8A0BF).withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          // Divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFE8A0BF).withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (_loading) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE8A0BF),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Generation du code...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ] else if (_error != null) ...[
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade300,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            // Label
                            Text(
                              'VOTRE CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Code display
                            GestureDetector(
                              onTap: _copyCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE8A0BF).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _code!.split('').join('  '),
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      _copied ? Icons.check : Icons.copy_rounded,
                                      color: const Color(0xFFE8A0BF),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _copied
                                    ? 'Code copie !'
                                    : 'Appuyez pour copier',
                                key: ValueKey(_copied),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _copied
                                      ? const Color(0xFFE8A0BF)
                                      : Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Instructions
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.white.withValues(alpha: 0.4),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Presentez ce code au commercant pour beneficier de l\'offre',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.45),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Close button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A0A2E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Fermer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
