import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/day/data/author_position.dart';
import 'package:pulz_app/features/day/data/publication_service.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/core/services/analytics_service.dart';

/// Écran de choix de la formule de diffusion d'un event public (particulier).
/// Tier (Standard / Au top / À la une) × durée (1 semaine / 1 mois / jusqu'à
/// la date). Prix lus depuis `publication_prices`. Au paiement → Stripe.
class PublicationTarifsScreen extends StatefulWidget {
  final UserEvent event;

  /// Compte pro : l'event est publié sous son identifiant pro (visible et
  /// modifiable dans son espace) et rattaché à son établissement. La formule
  /// Standard est masquée (gratuite pour un pro).
  final String? proUserId;
  final String? establishmentId;

  const PublicationTarifsScreen({
    super.key,
    required this.event,
    this.proUserId,
    this.establishmentId,
  });

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
  static const _allTiers = [
    _TierMeta('a_la_une', 'À la une', '⭐', 'En tête du feed'),
    _TierMeta('au_top', 'Au top', '🔝', 'Bandeau dédié'),
    _TierMeta('standard', 'Standard', '📋', 'Feed standard'),
  ];
  static const _durations = [
    _DurMeta('date', 'Jusqu\'à la date'),
    _DurMeta('semaine', '1 semaine'),
    _DurMeta('mois', '1 mois'),
  ];

  bool get _isPro => widget.proUserId != null;
  List<_TierMeta> get _tiers => _isPro
      ? _allTiers.where((t) => t.key != 'standard').toList()
      : _allTiers;

  final _service = PublicationService();
  List<PublicationPrice> _prices = [];
  bool _loading = true;
  bool _paying = false;
  String? _error;

  String _tier = 'a_la_une';
  String _duration = 'date';

  // Option « Notification push + teaser » (À la une / Au top uniquement).
  PushTeaserAvailability? _push;
  bool _pushOn = false;
  bool _uploadingVideo = false;
  late String _videoUrl = widget.event.videoUrl;

  bool get _tierAllowsPush => _tier == 'a_la_une' || _tier == 'au_top';
  bool get _pushSelected =>
      _pushOn && _tierAllowsPush && (_push?.available ?? false);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('/publier-event/tarifs');
    _loadPrices();
    _loadPush();
  }

  Future<void> _loadPush() async {
    final e = widget.event;
    if (e.ville.isEmpty || e.date.isEmpty) return;
    final a = await _service.fetchPushTeaserAvailability(
      ville: e.ville,
      date: e.date,
      heure: e.heure,
    );
    if (!mounted) return;
    setState(() => _push = a);
  }

  Future<void> _pickTeaserVideo() async {
    final xFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (xFile == null || !mounted) return;
    setState(() {
      _uploadingVideo = true;
      _error = null;
    });
    try {
      final url = await UserEventSupabaseService().uploadVideo(xFile.path);
      if (!mounted) return;
      setState(() {
        _videoUrl = url;
        _uploadingVideo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingVideo = false;
        _error = "La vidéo n'a pas pu être envoyée. Vérifie ta connexion et réessaie.";
      });
    }
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
    final withPush = _pushSelected;
    if (withPush && _videoUrl.isEmpty) {
      setState(() => _error =
          "Ajoute ta vidéo teaser : c'est elle qui se lance quand on tape sur la notification.",);
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final userId =
          widget.proUserId ?? await UserIdentityService.getUserId();
      // La photo choisie n'est qu'un chemin local : l'envoyer au Storage
      // AVANT de figer le payload, sinon l'event paye est publie sans image
      // (le webhook ne fait que recopier ce payload dans user_events).
      var event = widget.event;
      if (_videoUrl.isNotEmpty && _videoUrl != event.videoUrl) {
        event = event.copyWith(videoUrl: _videoUrl);
      }
      final localPhoto = event.photoPath;
      if (localPhoto != null && localPhoto.isNotEmpty &&
          (event.photoUrl == null || event.photoUrl!.isEmpty)) {
        try {
          final url = await UserEventSupabaseService().uploadPhoto(localPhoto);
          event = event.copyWith(photoUrl: url);
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _paying = false;
            _error = "La photo n'a pas pu être envoyée. Vérifie ta connexion et réessaie.";
          });
          return;
        }
      }
      final payload = event.toSupabaseJson(userId: userId);
      // Position de l'auteur : le webhook recopie ce payload tel quel.
      AuthorPosition.addTo(
        payload,
        await AuthorPosition.resolve(
          adresse: event.lieuAdresse,
          codePostal: event.codePostal,
          pays: event.pays,
        ),
      );
      final checkoutError = await _service.checkout(
        payload: payload,
        tier: _tier,
        durationKey: _duration,
        userId: userId,
        ville: widget.event.ville,
        eventTitle: widget.event.titre,
        pushTeaser: withPush,
        establishmentId: widget.establishmentId,
      );
      if (!mounted) return;
      if (checkoutError == null) {
        _showPendingAndPop();
      } else {
        setState(() {
          _paying = false;
          _error = checkoutError;
        });
        // La place a pu partir entre-temps : rafraîchir l'option.
        if (withPush) _loadPush();
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
            style: GoogleFonts.geist(color: AppColors.text, fontWeight: FontWeight.w700),),
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
            style: GoogleFonts.geist(color: AppColors.text, fontWeight: FontWeight.w700),),
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
                            style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 12.5),),
                        const SizedBox(height: 12),
                        ..._tiers.map(_buildTierCard),
                        const SizedBox(height: 14),
                        Text('Durée de diffusion',
                            style: GoogleFonts.geist(
                                color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700,),),
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
                                                fontWeight: FontWeight.w600,),),
                                        const SizedBox(height: 3),
                                        Text(_priceLabel(_tier, d.key),
                                            style: GoogleFonts.geist(
                                                color: selected ? AppColors.magenta : AppColors.textDim,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,),),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_tierAllowsPush && (_push?.isShown ?? false)) ...[
                          const SizedBox(height: 18),
                          _buildPushCard(_push!),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!,
                              style: GoogleFonts.geist(color: Colors.red.shade300, fontSize: 13),),
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
                          color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700,),),
                  Text(t.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 11.5),),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(_priceLabel(t.key, _duration),
                style: GoogleFonts.geist(
                    color: selected ? AppColors.magenta : AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,),),
          ],
        ),
      ),
    );
  }

  static const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  static const _mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
    'août', 'septembre', 'octobre', 'novembre', 'décembre',];

  static String _milliers(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}\u202F',);

  static String _quand(DateTime d) =>
      '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]} à '
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  Widget _buildPushCard(PushTeaserAvailability p) {
    final full = !p.available;
    final on = _pushSelected;
    final dim = GoogleFonts.geist(color: AppColors.textDim, fontSize: 12, height: 1.4);
    return Opacity(
      opacity: full ? 0.55 : 1,
      child: GestureDetector(
        onTap: full ? null : () => setState(() => _pushOn = !_pushOn),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: on ? AppColors.magenta.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? AppColors.magenta : AppColors.line,
              width: on ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: on ? AppColors.magenta : AppColors.textDim, size: 24,),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('📲 Notification push + teaser vidéo',
                        style: GoogleFonts.geist(
                            color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700,),),
                  ),
                  Text('+ ${p.formattedPrice}',
                      style: GoogleFonts.geist(
                          color: on ? AppColors.magenta : AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,),),
                ],
              ),
              const SizedBox(height: 8),
              if (full)
                Text('Complet : les 2 notifications de cette soirée à ${p.villeLabel} sont déjà réservées.',
                    style: dim,)
              else ...[
                Text(
                  'Envoyée ${p.sendAt != null ? '${_quand(p.sendAt!)} ' : ''}à tous les utilisateurs '
                  'MaCity de ${p.villeLabel} : entre ${_milliers(p.minPhones)} et '
                  '${_milliers(p.maxPhones)} téléphones touchés.',
                  style: dim,
                ),
                const SizedBox(height: 4),
                Text('Au tap, ton teaser vidéo se lance en plein écran.', style: dim),
                const SizedBox(height: 4),
                Text("Validée par l'équipe MaCity avant l'envoi, remboursée si refusée.",
                    style: dim,),
              ],
              if (on) ...[
                const SizedBox(height: 12),
                _uploadingVideo
                    ? Row(children: [
                        const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magenta),),
                        const SizedBox(width: 10),
                        Text('Envoi de la vidéo…', style: dim),
                      ],)
                    : _videoUrl.isEmpty
                        ? OutlinedButton.icon(
                            onPressed: _pickTeaserVideo,
                            icon: const Icon(Icons.videocam_rounded, color: AppColors.magenta),
                            label: Text('Ajouter ta vidéo teaser (30 s max)',
                                style: GoogleFonts.geist(
                                    color: AppColors.magenta, fontWeight: FontWeight.w700,),),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.magenta),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : Row(children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Vidéo teaser prête',
                                  style: GoogleFonts.geist(
                                      color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600,),),
                            ),
                            TextButton(
                              onPressed: _pickTeaserVideo,
                              child: Text('Changer',
                                  style: GoogleFonts.geist(
                                      color: AppColors.magenta, fontWeight: FontWeight.w700,),),
                            ),
                          ],),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayBar() {
    final price = _priceFor(_tier, _duration);
    final pushCents = _pushSelected ? (_push?.priceCents ?? 0) : 0;
    final total = price == null
        ? null
        : PublicationPrice(
            tier: price.tier,
            durationKey: price.durationKey,
            amountCents: price.amountCents + pushCents,
            isActive: true,
          );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: (_paying || _uploadingVideo || price == null) ? null : _pay,
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
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),)
                : Text(
                    total != null ? 'Payer ${total.formatted} et publier' : 'Indisponible',
                    style: GoogleFonts.geist(fontSize: 16, fontWeight: FontWeight.w700),),
          ),
        ),
      ),
    );
  }
}
