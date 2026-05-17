import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/rsvp_avatars_row.dart';
import 'package:url_launcher/url_launcher.dart';

/// Coffre secret : champ token + passcode + animation cadenas → reveal event.
class OpenSecretBoxScreen extends StatefulWidget {
  final String? prefilledToken;

  const OpenSecretBoxScreen({super.key, this.prefilledToken});

  @override
  State<OpenSecretBoxScreen> createState() => _OpenSecretBoxScreenState();
}

class _OpenSecretBoxScreenState extends State<OpenSecretBoxScreen>
    with SingleTickerProviderStateMixin {
  final _service = PrivateEventService();
  final _tokenCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  PrivateEventReveal? _revealed;

  late final AnimationController _unlockCtrl;

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.prefilledToken != null) {
      _tokenCtrl.text = widget.prefilledToken!;
    }
    _unlockCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passcodeCtrl.dispose();
    _unlockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteToken() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = data?.text?.trim() ?? '';
    // Si l'invite a colle le texte d'invitation entier, on extrait le token.
    final match = _uuidRegex.firstMatch(txt) ??
        RegExp(
          r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          caseSensitive: false,
        ).firstMatch(txt);
    if (match != null && mounted) {
      setState(() => _tokenCtrl.text = match.group(0)!);
    }
  }

  Future<void> _open() async {
    final token = _tokenCtrl.text.trim().toLowerCase();
    if (!_uuidRegex.hasMatch(token)) {
      setState(() => _error = 'Lien invalide (format UUID attendu)');
      return;
    }
    final code = _passcodeCtrl.text.trim();
    if (code.length != 4 || int.tryParse(code) == null) {
      setState(() => _error = 'Le code doit faire 4 chiffres');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reveal = await _service.openPrivateEvent(
        token: token,
        passcode: code,
      );
      if (!mounted) return;
      // Animation d'ouverture puis reveal.
      await _unlockCtrl.forward();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _revealed = reveal;
      });
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _humanizeError(e);
      });
    }
  }

  String _humanizeError(PrivateEventException e) {
    switch (e.code) {
      case PrivateEventError.notFound:
        return 'Aucun coffre trouve avec ce lien';
      case PrivateEventError.wrongPasscode:
        return 'Code incorrect';
      case PrivateEventError.expired:
        return 'Cet event est passé';
      case PrivateEventError.quotaExceeded:
        return 'Ce coffre a atteint sa limite d\'ouvertures';
      case PrivateEventError.invalidInput:
        return e.message ?? 'Donnee invalide';
      case PrivateEventError.network:
        return 'Erreur reseau, reessaie';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          _revealed != null ? 'Coffre ouvert' : 'Ouvrir un coffre',
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _revealed != null
            ? _RevealView(
                key: const ValueKey('reveal'),
                event: _revealed!,
                token: _tokenCtrl.text.trim().toLowerCase(),
                passcode: _passcodeCtrl.text.trim(),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Cadenas anime
        Center(
          child: AnimatedBuilder(
            animation: _unlockCtrl,
            builder: (_, __) {
              final t = _unlockCtrl.value;
              final unlocked = t > 0.5;
              final scale = 1 + (t * 0.4);
              return Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: unlocked ? 0.25 : 0,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.neon(
                        AppColors.magenta,
                        blur: 24 + t * 24,
                        y: 6,
                      ),
                    ),
                    child: Icon(
                      unlocked ? Icons.lock_open : Icons.lock,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Tape le lien et le code recus',
          textAlign: TextAlign.center,
          style: GoogleFonts.geist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'L\'organisateur t\'a partage un token + un code 4 chiffres.',
          textAlign: TextAlign.center,
          style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim),
        ),
        const SizedBox(height: 26),

        // Token
        Text(
          'Lien (token)',
          style: GoogleFonts.geist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            TextField(
              controller: _tokenCtrl,
              maxLines: 2,
              minLines: 2,
              style: GoogleFonts.geistMono(
                fontSize: 12,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                hintStyle: GoogleFonts.geistMono(
                  fontSize: 12,
                  color: AppColors.textFaint,
                ),
                filled: true,
                fillColor: AppColors.surfaceHi,
                contentPadding: const EdgeInsets.fromLTRB(12, 12, 50, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(
                    color: AppColors.magenta,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton(
                onPressed: _pasteToken,
                icon: const Icon(Icons.content_paste, size: 18),
                tooltip: 'Coller',
                color: AppColors.magenta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Passcode
        Text(
          'Code',
          style: GoogleFonts.geist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _passcodeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          maxLength: 4,
          textAlign: TextAlign.center,
          style: GoogleFonts.geistMono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            hintStyle: GoogleFonts.geistMono(
              fontSize: 24,
              letterSpacing: 10,
              color: AppColors.textFaint,
            ),
            filled: true,
            fillColor: AppColors.surfaceHi,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(
                color: AppColors.magenta,
                width: 1.5,
              ),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.geist(
              fontSize: 13,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],

        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _open,
            icon: const Icon(Icons.lock_open, size: 20),
            label: Text(
              _busy ? 'Ouverture...' : 'Ouvrir le coffre',
              style: GoogleFonts.geist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vue affichee une fois le coffre ouvert : carte event + section RSVP.
class _RevealView extends StatefulWidget {
  final PrivateEventReveal event;
  final String token;
  final String passcode;

  const _RevealView({
    super.key,
    required this.event,
    required this.token,
    required this.passcode,
  });

  @override
  State<_RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends State<_RevealView> {
  final _service = PrivateEventService();
  late List<PrivateEventRsvp> _rsvps;
  String? _currentUserId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rsvps = widget.event.rsvps;
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final uid = await UserIdentityService.getUserId();
    if (mounted) setState(() => _currentUserId = uid);
  }

  bool get _isMine =>
      _currentUserId != null && _rsvps.any((r) => r.userId == _currentUserId);

  Future<void> _toggleRsvp() async {
    if (_currentUserId == null) return;
    setState(() => _busy = true);
    try {
      final updated = _isMine
          ? await _service.cancelMyRsvp(
              token: widget.token,
              userId: _currentUserId!,
            )
          : await _service.rsvpToPrivateEvent(
              token: widget.token,
              passcode: widget.passcode,
              userId: _currentUserId!,
            );
      if (!mounted) return;
      setState(() {
        _rsvps = updated;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec, reessaie')),
      );
    }
  }

  String _friendlyDate() {
    final d = DateTime.tryParse(widget.event.date);
    if (d == null) return widget.event.date;
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d);
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(
      widget.event.adresse.isNotEmpty
          ? widget.event.adresse
          : widget.event.lieu,
    );
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final hasPhoto = event.photoUrl != null && event.photoUrl!.isNotEmpty;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomInset),
      children: [
        // Cadenas ouvert + label
        Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.neon(
                    AppColors.magenta,
                    blur: 14,
                    y: 4,
                  ),
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'COFFRE OUVERT',
                style: GoogleFonts.geistMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.magenta,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Carte event
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhoto)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: event.photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _photoFallback(),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _photoFallback(),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.geist(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.calendar_today, _friendlyDate()),
                    if (event.heure.isNotEmpty)
                      _infoRow(Icons.schedule, event.heure),
                    if (event.lieu.isNotEmpty)
                      _infoRow(Icons.place, event.lieu),
                    if (event.adresse.isNotEmpty)
                      _infoRow(Icons.location_on_outlined, event.adresse),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (event.adresse.isNotEmpty || event.lieu.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(
                            'Itineraire',
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
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
        const SizedBox(height: 16),

        // ── Section RSVP : avatars + bouton "Je viens" ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 18,
                    color: AppColors.magenta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _rsvps.isEmpty
                        ? 'Personne pour l\'instant'
                        : '${_rsvps.length} ${_rsvps.length > 1 ? "personnes viennent" : "personne vient"}',
                    style: GoogleFonts.geist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              if (_rsvps.isNotEmpty) ...[
                const SizedBox(height: 12),
                RsvpAvatarsRow(rsvps: _rsvps),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: _isMine
                    ? OutlinedButton.icon(
                        onPressed: _busy ? null : _toggleRsvp,
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(
                          _busy ? '...' : 'Annuler ma venue',
                          style: GoogleFonts.geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B6B),
                          side: const BorderSide(color: Color(0xFFFF6B6B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _busy ? null : _toggleRsvp,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          _busy ? 'Envoi...' : 'Je viens',
                          style: GoogleFonts.geist(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.magenta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          elevation: 0,
                        ),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: Text(
            '${event.openCount} / ${event.maxOpens} ouvertures',
            style: GoogleFonts.geistMono(
              fontSize: 10,
              color: AppColors.textFaint,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: const Center(
        child: Text('🎉', style: TextStyle(fontSize: 64)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
