import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/presentation/private_event_chat_screen.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/create_private_event_sheet.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/contributor_profile_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Liste des soirees privees creees par ce device. Permet de re-partager le
/// lien+code et de supprimer un event.
class MyPrivateEventsScreen extends StatefulWidget {
  const MyPrivateEventsScreen({super.key});

  @override
  State<MyPrivateEventsScreen> createState() => _MyPrivateEventsScreenState();
}

class _MyPrivateEventsScreenState extends State<MyPrivateEventsScreen> {
  final _service = PrivateEventService();
  Future<List<PrivateEvent>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = () async {
        final uuid = await UserIdentityService.getUserId();
        return _service.listMyPrivateEvents(hostDeviceUuid: uuid);
      }();
    });
  }

  Future<void> _showGuests(PrivateEvent event) async {
    final hostUuid = await UserIdentityService.getUserId();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestsSheet(
        event: event,
        hostDeviceUuid: hostUuid,
      ),
    );
  }

  Future<void> _delete(PrivateEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Supprimer ce coffre ?',
          style: GoogleFonts.geist(color: AppColors.text),
        ),
        content: Text(
          'L\'event "${event.title}" ne sera plus accessible aux invites.',
          style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final uuid = await UserIdentityService.getUserId();
      await _service.deleteMyPrivateEvent(
        token: event.accessToken,
        hostDeviceUuid: uuid,
      );
      if (mounted) _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de la suppression')),
      );
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
          'Mes events privés',
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      body: FutureBuilder<List<PrivateEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.magenta),
            );
          }
          final events = snap.data ?? [];
          if (events.isEmpty) return _empty();
          return RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EventTile(
                event: events[i],
                onShare: (btnCtx) => sharePrivateEventInvite(btnCtx, events[i]),
                onChat: () => PrivateEventChatScreen.open(
                  context,
                  token: events[i].accessToken,
                  title: events[i].title,
                  isHost: true,
                ),
                onEdit: () => CreatePrivateEventSheet.showEdit(
                  context,
                  events[i],
                  onSaved: _reload,
                ),
                onDelete: () => _delete(events[i]),
                onShowGuests: () => _showGuests(events[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreatePrivateEventSheet.show(
          context,
          onCreated: _reload,
        ),
        backgroundColor: AppColors.magenta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.lock_outline),
        label: Text(
          'Nouvel event',
          style: GoogleFonts.geist(fontWeight: FontWeight.w600),
        ),
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
                color: AppColors.magenta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 38,
                color: AppColors.magenta,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucun event privé',
              style: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cree un coffre secret et invite tes amis avec un lien+code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.geist(
                fontSize: 13,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final PrivateEvent event;
  /// Recoit le context du bouton (ancrage de la feuille de partage iOS).
  final void Function(BuildContext buttonContext) onShare;
  final VoidCallback onChat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowGuests;

  const _EventTile({
    required this.event,
    required this.onShare,
    required this.onChat,
    required this.onEdit,
    required this.onDelete,
    required this.onShowGuests,
  });

  String _friendlyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE d MMM', 'fr_FR').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photoUrl != null && event.photoUrl!.isNotEmpty;
    return InkWell(
      onTap: onShowGuests,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : photo + titre + date
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHi,
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
                          color: AppColors.text,
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
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _friendlyDate(event.date) +
                                (event.heure.isNotEmpty
                                    ? ' · ${event.heure}'
                                    : ''),
                            style: GoogleFonts.geist(
                              fontSize: 11,
                              color: AppColors.textDim,
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
                              color: AppColors.textFaint,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.lieu,
                                style: GoogleFonts.geist(
                                  fontSize: 11,
                                  color: AppColors.textDim,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _OpensBadge(open: event.openCount),
              ],
            ),
            const SizedBox(height: 10),

            // Code + actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.magenta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: AppColors.magenta.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.key,
                        size: 12,
                        color: AppColors.magenta,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.passcode,
                        style: GoogleFonts.geistMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.magenta,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ParticipantsBadge(
                  count: event.rsvpCount,
                  max: event.maxParticipants,
                ),
                const Spacer(),
                Builder(builder: (btnCtx) => IconButton(
                  onPressed: () => onShare(btnCtx),
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: AppColors.magenta,
                  ),
                  tooltip: 'Partager',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                )),
                IconButton(
                  onPressed: onChat,
                  icon: const Icon(
                    Icons.forum_outlined,
                    size: 18,
                    color: AppColors.magenta,
                  ),
                  tooltip: 'Discussion',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.magenta,
                  ),
                  tooltip: 'Modifier',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFFF6B6B),
                  ),
                  tooltip: 'Supprimer',
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: AppColors.surfaceHi,
        child: Icon(
          Icons.celebration,
          color: AppColors.textFaint,
          size: 22,
        ),
      );
}

/// Nombre d'ouvertures du coffre (statistique, plus de limite).
class _OpensBadge extends StatelessWidget {
  final int open;

  const _OpensBadge({required this.open});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 11, color: AppColors.textDim),
          const SizedBox(width: 4),
          Text(
            '$open',
            style: GoogleFonts.geistMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet liste des invites ayant accepte. Charge a l'ouverture via la RPC
/// host_list_event_rsvps (filtre serveur sur host_device_uuid).
class _GuestsSheet extends StatefulWidget {
  final PrivateEvent event;
  final String hostDeviceUuid;

  const _GuestsSheet({required this.event, required this.hostDeviceUuid});

  @override
  State<_GuestsSheet> createState() => _GuestsSheetState();
}

class _GuestsSheetState extends State<_GuestsSheet> {
  final _service = PrivateEventService();
  Future<List<PrivateEventRsvp>>? _future;
  // Onglet « Confirmés » : seulement si l'hote a active la confirmation.
  Future<List<PrivateEventConfirmation>>? _confFuture;
  bool _showConfirmed = false;

  @override
  void initState() {
    super.initState();
    _future = _service.hostListEventRsvps(
      token: widget.event.accessToken,
      hostDeviceUuid: widget.hostDeviceUuid,
    );
    if (widget.event.confirmationRequise) {
      _confFuture = _service.hostListConfirmations(
        token: widget.event.accessToken,
        hostDeviceUuid: widget.hostDeviceUuid,
      );
    }
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.magenta : AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              label,
              style: GoogleFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
          ),
        ),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.geist(
              fontSize: 13,
              color: AppColors.textDim,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );

  /// Liste des confirmes, dans l'ordre de confirmation (1er confirme en haut).
  Widget _confirmedList() {
    return FutureBuilder<List<PrivateEventConfirmation>>(
      future: _confFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.magenta),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return _empty('Aucune confirmation pour l\'instant.\n'
              'Les participants confirment depuis « Mes invitations ».');
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ConfirmedRow(rank: i + 1, c: list[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 20,
                    color: AppColors.magenta,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inscrits ${widget.event.maxParticipants != null ? "${widget.event.rsvpCount}/${widget.event.maxParticipants}" : "(${widget.event.rsvpCount})"} : ${widget.event.title}',
                      style: GoogleFonts.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_confFuture != null) ...[
                Row(
                  children: [
                    _tab('Participants', !_showConfirmed,
                        () => setState(() => _showConfirmed = false)),
                    const SizedBox(width: 8),
                    _tab('✅ Confirmés', _showConfirmed,
                        () => setState(() => _showConfirmed = true)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_showConfirmed)
                Flexible(child: _confirmedList())
              else
              Flexible(
                child: FutureBuilder<List<PrivateEventRsvp>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.magenta,
                        ),
                      );
                    }
                    final rsvps = snap.data ?? [];
                    if (rsvps.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Personne pour l\'instant',
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              color: AppColors.textDim,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: rsvps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _GuestRow(rsvp: rsvps[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
    // Tap -> fiche profil publique (photo, prenom, ville, bio).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ContributorProfileSheet.show(
        context,
        userId: rsvp.userId,
        fallbackPrenom: prenom,
        fallbackAvatarUrl: rsvp.avatarUrl,
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
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
              rsvp.prenom ?? 'Anonyme',
              style: GoogleFonts.geist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          rsvp.confirmed
              ? const Icon(Icons.verified, size: 18, color: Color(0xFF22C55E))
              : const Icon(Icons.check_circle, size: 16, color: AppColors.magenta),
        ],
      ),
      ),
    );
  }

  Widget _initialFallback(String initial) => Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.geist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

/// Un participant confirme, vu par l'hote : rang, identite, age, contact.
/// Telephone et e-mail cliquables (appel / e-mail).
class _ConfirmedRow extends StatelessWidget {
  final int rank;
  final PrivateEventConfirmation c;
  const _ConfirmedRow({required this.rank, required this.c});

  @override
  Widget build(BuildContext context) {
    final fullName = '${c.prenom} ${c.nom.toUpperCase()}'.trim();
    final pseudo = c.pseudo?.trim() ?? '';
    final when = c.confirmedAt == null
        ? ''
        : DateFormat("d MMM 'à' HH'h'mm", 'fr_FR').format(c.confirmedAt!.toLocal());
    final small = GoogleFonts.geist(fontSize: 12, color: AppColors.textDim);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
            ),
            child: Text(
              '$rank',
              style: GoogleFonts.geist(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.age != null ? '$fullName · ${c.age} ans' : fullName,
                  style: GoogleFonts.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                if (pseudo.isNotEmpty || when.isNotEmpty)
                  Text(
                    [if (pseudo.isNotEmpty) '@$pseudo', if (when.isNotEmpty) 'confirmé le $when']
                        .join(' · '),
                    style: small,
                  ),
                const SizedBox(height: 6),
                if (c.tel.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: c.tel.replaceAll(' ', ''))),
                    child: Text('📞 ${c.tel}',
                        style: small.copyWith(color: AppColors.text, decoration: TextDecoration.underline)),
                  ),
                if (c.email.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrl(Uri(scheme: 'mailto', path: c.email)),
                    child: Text('✉️ ${c.email}',
                        style: small.copyWith(color: AppColors.text, decoration: TextDecoration.underline)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nombre d'inscrits toujours visible par l'hote : « 12 » ou « 12 / 20 »,
/// en rouge quand c'est complet.
class _ParticipantsBadge extends StatelessWidget {
  final int count;
  final int? max;
  const _ParticipantsBadge({required this.count, this.max});

  @override
  Widget build(BuildContext context) {
    final full = max != null && count >= max!;
    final color = full ? const Color(0xFFFF6B6B) : AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: full ? color : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            max != null ? '$count / $max${full ? ' · complet' : ''}' : '$count inscrit${count > 1 ? 's' : ''}',
            style: GoogleFonts.geist(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
