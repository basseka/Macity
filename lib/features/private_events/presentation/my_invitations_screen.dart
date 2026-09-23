import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/rsvp_avatars_row.dart';
import 'package:url_launcher/url_launcher.dart';

const _accentColor = Color(0xFF00B4D8);

/// Palette fixe (sombre), volontairement independante du flag global
/// `AppColors.isLightTheme` (bascule selon la rubrique visitee : Night =
/// sombre, tout le reste = clair, cf design_tokens.dart). Le coffre/les
/// invitations n'appartiennent a aucune rubrique : sans ca, l'ecran heritait
/// du theme clair ou sombre laisse par le dernier mode visite, d'ou un rendu
/// incoherent entre deux ouvertures (signale : rendu different Android/iPhone).
class _CoffreColors {
  static const bg = Color(0xFF0A0514);
  static const surface = Color(0xFF1A0F2E);
  static const surfaceHi = Color(0xFF241640);
  static const text = Color(0xFFF5F0FF);
  static const textDim = Color(0xFFB5A8D0);
  static const textFaint = Color(0xFF7A6E95);
  static const line = Color(0x12FFFFFF);
  static const lineStrong = Color(0x24FFFFFF);
}

/// Liste des soirees auxquelles ce device a confirme sa venue ("Je viens").
/// Distincte de [MyPrivateEventsScreen] qui liste les events crees PAR le user.
class MyInvitationsScreen extends StatefulWidget {
  const MyInvitationsScreen({super.key});

  @override
  State<MyInvitationsScreen> createState() => _MyInvitationsScreenState();
}

class _MyInvitationsScreenState extends State<MyInvitationsScreen> {
  final _service = PrivateEventService();
  Future<List<PrivateEventReveal>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = () async {
        final uuid = await UserIdentityService.getUserId();
        return _service.listMyInvitations(userId: uuid);
      }();
    });
  }

  Future<void> _showDetails(PrivateEventReveal event) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvitationDetailSheet(event: event),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CoffreColors.bg,
      appBar: AppBar(
        backgroundColor: _CoffreColors.bg,
        elevation: 0,
        title: Text(
          'Mes invitations',
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _CoffreColors.text,
          ),
        ),
        iconTheme: IconThemeData(color: _CoffreColors.text),
      ),
      body: FutureBuilder<List<PrivateEventReveal>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }
          final events = snap.data ?? [];
          if (events.isEmpty) return _empty();
          return RefreshIndicator(
            color: _accentColor,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _InvitationTile(
                event: events[i],
                onTap: () => _showDetails(events[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_outlined,
                size: 38,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucune invitation',
              style: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _CoffreColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quand tu cliqueras "Je viens" sur un coffre, l\'event apparaitra ici.',
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: _CoffreColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  final PrivateEventReveal event;
  final VoidCallback onTap;

  const _InvitationTile({required this.event, required this.onTap});

  String _friendlyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE d MMM', 'fr_FR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photoUrl != null && event.photoUrl!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        decoration: BoxDecoration(
          color: _CoffreColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _CoffreColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _CoffreColors.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: event.photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _CoffreColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: _CoffreColors.textFaint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _friendlyDate(event.date) +
                              (event.heure.isNotEmpty
                                  ? ' · ${event.heure}'
                                  : ''),
                          style: GoogleFonts.geist(
                            fontSize: 11,
                            color: _CoffreColors.textDim,
                          ),
                        ),
                      ],
                    ),
                    if (event.lieu.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: _CoffreColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.lieu,
                              style: GoogleFonts.geist(
                                fontSize: 11,
                                color: _CoffreColors.textDim,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.rsvps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RsvpAvatarsRow(
                            rsvps: event.rsvps,
                            maxVisible: 3,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${event.rsvps.length} present${event.rsvps.length > 1 ? "s" : ""}',
                            style: GoogleFonts.geist(
                              fontSize: 10,
                              color: _CoffreColors.textFaint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'JE VIENS',
                  style: GoogleFonts.geistMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: _CoffreColors.surfaceHi,
        child: Icon(
          Icons.celebration,
          color: _CoffreColors.textFaint,
          size: 22,
        ),
      );
}

/// Bottom sheet de detail d'une invitation : description, adresse complete,
/// liste des autres acceptants, bouton "Annuler ma venue".
class _InvitationDetailSheet extends StatefulWidget {
  final PrivateEventReveal event;

  const _InvitationDetailSheet({required this.event});

  @override
  State<_InvitationDetailSheet> createState() => _InvitationDetailSheetState();
}

class _InvitationDetailSheetState extends State<_InvitationDetailSheet> {
  final _service = PrivateEventService();
  late List<PrivateEventRsvp> _rsvps;
  bool _cancelling = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _rsvps = widget.event.rsvps;
  }

  String _friendlyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d);
  }

  Future<void> _openMaps() async {
    final ev = widget.event;
    final query = Uri.encodeComponent(
      ev.adresse.isNotEmpty ? ev.adresse : ev.lieu,
    );
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cancel() async {
    final token = widget.event.accessToken;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _CoffreColors.surface,
        title: Text(
          'Annuler ta venue ?',
          style: GoogleFonts.geist(color: _CoffreColors.text),
        ),
        content: Text(
          'Tu pourras toujours revenir en cliquant "Je viens" depuis le coffre.',
          style: GoogleFonts.geist(color: _CoffreColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Annuler ma venue',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cancelling = true);
    try {
      final uuid = await UserIdentityService.getUserId();
      await _service.cancelMyRsvp(token: token, userId: uuid);
      if (!mounted) return;
      setState(() {
        _cancelled = true;
        _cancelling = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de l\'annulation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    final hasPhoto = ev.photoUrl != null && ev.photoUrl!.isNotEmpty;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: _CoffreColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _CoffreColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton fermer explicite : la simple poignee de drag n'etait
              // pas assez claire comme affordance de fermeture (signale).
              SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _CoffreColors.lineStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      right: -8,
                      child: IconButton(
                        icon: Icon(Icons.close,
                            size: 20, color: _CoffreColors.textDim),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Fermer',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _CoffreColors.surfaceHi,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: _CoffreColors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pas d'AspectRatio fixe : l'affiche d'un event
                            // prive est le plus souvent en portrait (infos
                            // texte + pictos imprimes dessus, cf coffre) :
                            // un cadrage 16:10 + cover en coupait le bas.
                            // Ici l'image garde son ratio naturel, entiere.
                            if (hasPhoto)
                              CachedNetworkImage(
                                imageUrl: ev.photoUrl!,
                                fit: BoxFit.fitWidth,
                                width: double.infinity,
                                placeholder: (_, __) => AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child:
                                      Container(color: _CoffreColors.surface),
                                ),
                                errorWidget: (_, __, ___) => AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: Container(
                                    color: _CoffreColors.surface,
                                    child: Icon(
                                      Icons.celebration,
                                      color: _CoffreColors.textFaint,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ev.title,
                                    style: GoogleFonts.geist(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _CoffreColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    Icons.calendar_today,
                                    _friendlyDate(ev.date) +
                                        (ev.heure.isNotEmpty
                                            ? ' · ${ev.heure}'
                                            : ''),
                                  ),
                                  if (ev.lieu.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _detailRow(Icons.place, ev.lieu),
                                  ],
                                  if (ev.adresse.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _detailRow(Icons.map_outlined, ev.adresse),
                                  ],
                                  if (ev.description.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      ev.description,
                                      style: GoogleFonts.geist(
                                        fontSize: 13,
                                        color: _CoffreColors.textDim,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (ev.adresse.isNotEmpty ||
                                      ev.lieu.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _openMaps,
                                        icon: const Icon(Icons.map_outlined,
                                            size: 18),
                                        label: Text(
                                          'Itineraire',
                                          style: GoogleFonts.geist(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _CoffreColors.text,
                                          side: BorderSide(
                                              color: _CoffreColors.line),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.chip),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _CoffreColors.surfaceHi,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: _CoffreColors.line),
                        ),
                        child: _GuestsBlock(rsvps: _rsvps),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_cancelling || _cancelled) ? null : _cancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cancelled
                        ? _CoffreColors.surfaceHi
                        : const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _CoffreColors.surfaceHi,
                    disabledForegroundColor: _CoffreColors.textFaint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    elevation: 0,
                  ),
                  icon: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _cancelled ? Icons.check : Icons.event_busy,
                          size: 18,
                        ),
                  label: Text(
                    _cancelled ? 'Venue annulee' : 'Annuler ma venue',
                    style: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.geist(
              fontSize: 13,
              color: _CoffreColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestsBlock extends StatelessWidget {
  final List<PrivateEventRsvp> rsvps;
  const _GuestsBlock({required this.rsvps});

  @override
  Widget build(BuildContext context) {
    if (rsvps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _CoffreColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(
          'Personne d\'autre n\'a encore confirme.',
          style: GoogleFonts.geist(
            fontSize: 12,
            color: _CoffreColors.textFaint,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presents (${rsvps.length})',
          style: GoogleFonts.geist(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _CoffreColors.textDim,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        ...rsvps.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GuestRow(rsvp: r),
          ),
        ),
      ],
    );
  }
}

class _GuestRow extends StatelessWidget {
  final PrivateEventRsvp rsvp;
  const _GuestRow({required this.rsvp});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = rsvp.avatarUrl != null && rsvp.avatarUrl!.isNotEmpty;
    final prenom = rsvp.prenom?.trim() ?? '';
    final initial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _CoffreColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _CoffreColors.surfaceHi,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: rsvp.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _initialFallback(initial),
                    placeholder: (_, __) => _initialFallback(initial),
                  )
                : _initialFallback(initial),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prenom.isNotEmpty ? prenom : 'Anonyme',
              style: GoogleFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _CoffreColors.text,
              ),
            ),
          ),
          const Icon(Icons.check_circle, size: 14, color: _accentColor),
        ],
      ),
    );
  }

  Widget _initialFallback(String initial) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentColor, Color(0xFF0077B6)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.geist(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}
