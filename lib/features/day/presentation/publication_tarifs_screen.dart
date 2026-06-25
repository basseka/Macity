import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/data/publication_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

/// Écran de choix de la formule de diffusion d'un event public (particulier).
/// Tier (Standard / Au top / À la une) × durée (1 semaine / 1 mois / jusqu'à
/// la date). Prix lus depuis `publication_prices`. Au paiement → Stripe.
class PublicationTarifsScreen extends StatefulWidget {
  final UserEvent event;
  const PublicationTarifsScreen({super.key, required this.event});

  @override
  State<PublicationTarifsScreen> createState() => _PublicationTarifsScreenState();
}

class _TierMeta {
  final String key;
  final String label;
  final String emoji;
  final String desc;
  const _TierMeta(this.key, this.label, this.emoji, this.desc);
}

class _DurMeta {
  final String key;
  final String label;
  const _DurMeta(this.key, this.label);
}

class _PublicationTarifsScreenState extends State<PublicationTarifsScreen> {
  static const _tiers = [
    _TierMeta('a_la_une', 'À la une', '⭐', 'En tête du feed'),
    _TierMeta('au_top', 'Au top', '🔝', 'Bandeau dédié'),
    _TierMeta('standard', 'Standard', '📋', 'Feed standard'),
  ];
  static const _durations = [
    _DurMeta('date', 'Jusqu\'à la date'),
    _DurMeta('semaine', '1 semaine'),
    _DurMeta('mois', '1 mois'),
  ];

  final _service = PublicationService();
  List<PublicationPrice> _prices = [];
  bool _loading = true;
  bool _paying = false;
  String? _error;

  String _tier = 'a_la_une';
  String _duration = 'date';

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    try {
      final p = await _service.fetchPrices();
      if (!mounted) return;
      setState(() {
        _prices = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les tarifs';
        _loading = false;
      });
    }
  }

  PublicationPrice? _priceFor(String tier, String duration) {
    for (final p in _prices) {
      if (p.tier == tier && p.durationKey == duration) return p;
    }
    return null;
  }

  String _priceLabel(String tier, String duration) =>
      _priceFor(tier, duration)?.formatted ?? '—';

  Future<void> _pay() async {
    final price = _priceFor(_tier, _duration);
    if (price == null) {
      setState(() => _error = 'Tarif indisponible pour cette formule');
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final userId = await UserIdentityService.getUserId();
      final payload = widget.event.toSupabaseJson(userId: userId);
      final opened = await _service.checkout(
        payload: payload,
        tier: _tier,
        durationKey: _duration,
        userId: userId,
        ville: widget.event.ville,
        eventTitle: widget.event.titre,
      );
      if (!mounted) return;
      if (opened) {
        _showPendingAndPop();
      } else {
        setState(() {
          _paying = false;
          _error = 'Le paiement n\'a pas pu s\'ouvrir. Réessaie.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = 'Erreur : $e';
      });
    }
  }

  void _showPendingAndPop() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Paiement en cours',
            style: GoogleFonts.geist(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text(
          'Termine le paiement dans la page Stripe. Ton event sera publié '
          'automatiquement dès la confirmation. ✨',
          style: GoogleFonts.geist(color: AppColors.textDim, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text('OK', style: GoogleFonts.geist(color: AppColors.magenta, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Diffuser mon event',
            style: GoogleFonts.geist(color: AppColors.text, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.magenta))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      children: [
                        Text('Ton event « ${widget.event.titre} »',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 12.5)),
                        const SizedBox(height: 12),
                        ..._tiers.map(_buildTierCard),
                        const SizedBox(height: 14),
                        Text('Durée de diffusion',
                            style: GoogleFonts.geist(
                                color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: _durations.map((d) {
                            final selected = d.key == _duration;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _duration = d.key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.magenta.withValues(alpha: 0.16)
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? AppColors.magenta : AppColors.line,
                                        width: selected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(d.label,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style: GoogleFonts.geist(
                                                color: AppColors.text,
                                                fontSize: 11,
                                                height: 1.15,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 3),
                                        Text(_priceLabel(_tier, d.key),
                                            style: GoogleFonts.geist(
                                                color: selected ? AppColors.magenta : AppColors.textDim,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!,
                              style: GoogleFonts.geist(color: Colors.red.shade300, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                  _buildPayBar(),
                ],
              ),
            ),
    );
  }

  Widget _buildTierCard(_TierMeta t) {
    final selected = t.key == _tier;
    return GestureDetector(
      onTap: () => setState(() => _tier = t.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.magenta : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.label,
                      style: GoogleFonts.geist(
                          color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(t.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(_priceLabel(t.key, _duration),
                style: GoogleFonts.geist(
                    color: selected ? AppColors.magenta : AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayBar() {
    final price = _priceFor(_tier, _duration);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: (_paying || price == null) ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magenta,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: _paying
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(
                    price != null ? 'Payer ${price.formatted} et publier' : 'Indisponible',
                    style: GoogleFonts.geist(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
