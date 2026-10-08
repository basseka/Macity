import 'package:cached_network_image/cached_network_image.dart';
import 'package:pulz_app/core/l10n/labels.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/presentation/private_event_chat_screen.dart';
import 'package:pulz_app/features/private_events/presentation/event_album_screen.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/create_private_event_sheet.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/contributor_profile_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/guest_list_pdf.dart';
import 'package:pulz_app/features/private_events/presentation/widgets/album_button.dart';
import 'package:pulz_app/core/services/analytics_service.dart';

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
    AnalyticsService.logScreenView('/event-prive/mes-events');
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
    var changed = false;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestsSheet(
        event: event,
        hostDeviceUuid: hostUuid,
        onChanged: () => changed = true,
      ),
    );
    // Participant retire ou confirmation activee : carte a jour.
    if (changed && mounted) _reload();
  }

  Future<bool> _toggleConfirmation(PrivateEvent event, bool enabled) async {
    try {
      final uuid = await UserIdentityService.getUserId();
      await _service.setConfirmationRequired(
        token: event.accessToken,
        hostDeviceUuid: uuid,
        enabled: enabled,
      );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enabled
            ? context.l10n.pvConfirmOn
            : context.l10n.pvConfirmOff),
      ));
      _reload();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonFailedRetry)),
        );
      }
      return false;
    }
  }

  Future<void> _delete(PrivateEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          context.l10n.pvDeleteVault,
          style: GoogleFonts.geist(color: AppColors.text),
        ),
        content: Text(
          context.l10n.pvDeleteVaultBody(event.title),
          style: GoogleFonts.geist(color: AppColors.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.commonDelete,
              style: const TextStyle(color: Color(0xFFFF6B6B)),
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
        SnackBar(content: Text(context.l10n.commonDeleteFailed)),
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
          context.l10n.accountPrivateEvents,
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
                onAlbum: () => EventAlbumScreen.open(
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
                onToggleConfirmation: (on) => _toggleConfirmation(events[i], on),
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
          context.l10n.pvNewEvent,
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
              context.l10n.pvNone,
              style: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.pvNoneHint,
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
  final VoidCallback onAlbum;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowGuests;
  /// Bascule « Demander une confirmation » ; renvoie true si enregistre.
  final Future<bool> Function(bool enabled) onToggleConfirmation;

  const _EventTile({
    required this.event,
    required this.onShare,
    required this.onChat,
    required this.onAlbum,
    required this.onEdit,
    required this.onDelete,
    required this.onShowGuests,
    required this.onToggleConfirmation,
  });

  String _friendlyDate(BuildContext context, String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE d MMM', context.dateLocale).format(d);
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
                            _friendlyDate(context, event.date) +
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(date: event.date),
                    const SizedBox(height: 6),
                    _OpensBadge(open: event.openCount),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Pastilles sur UNE ligne : code, inscrits, confirmes ──
            // FittedBox : sur un ecran etroit, la ligne se reduit au lieu de
            // passer a la ligne.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Chip(
                  icon: Icons.key,
                  label: event.passcode,
                  mono: true,
                  color: AppColors.magenta,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onShowGuests,
                  child: _ParticipantsBadge(
                    count: event.rsvpCount,
                    max: event.maxParticipants,
                  ),
                ),
                if (event.confirmationRequise) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onShowGuests,
                    child: _Chip(
                      icon: Icons.verified,
                      label: '${event.confirmedCount} confirmé${event.confirmedCount > 1 ? 's' : ''}',
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ],
            ),
            ),
            const SizedBox(height: 10),

            // ── Confirmation des participants, basculable d'ici ──
            _ConfirmationToggle(
              value: event.confirmationRequise,
              onChanged: onToggleConfirmation,
            ),
            const SizedBox(height: 10),

            // ── Album photo, mis en avant (pleine largeur) ──
            AlbumButton(photoCount: event.photoCount, onTap: onAlbum),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 4),

            // ── Actions : pleine largeur, icone + libelle, jamais coupees ──
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (btnCtx) => _TileAction(
                      icon: Icons.share_outlined,
                      label: context.l10n.commonShare,
                      onTap: () => onShare(btnCtx),
                    ),
                  ),
                ),
                Expanded(
                  child: _TileAction(
                    icon: Icons.forum_outlined,
                    label: context.l10n.pvChat,
                    onTap: onChat,
                  ),
                ),

                Expanded(
                  child: _TileAction(
                    icon: Icons.edit_outlined,
                    label: context.l10n.commonEdit,
                    onTap: onEdit,
                  ),
                ),
                Expanded(
                  child: _TileAction(
                    icon: Icons.delete_outline,
                    label: context.l10n.commonDelete,
                    onTap: onDelete,
                    color: const Color(0xFFFF6B6B),
                  ),
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
  /// Liste ou reglages modifies depuis la feuille (carte a rafraichir).
  final VoidCallback? onChanged;

  const _GuestsSheet({
    required this.event,
    required this.hostDeviceUuid,
    this.onChanged,
  });

  @override
  State<_GuestsSheet> createState() => _GuestsSheetState();
}

class _GuestsSheetState extends State<_GuestsSheet> {
  final _service = PrivateEventService();
  Future<List<PrivateEventRsvp>>? _future;
  // Onglet « Confirmés » : seulement si l'hote a active la confirmation.
  Future<List<PrivateEventConfirmation>>? _confFuture;
  /// Onglet affiche : 0 = participants, 1 = vus (coffre ouvert), 2 = confirmes.
  int _tabIndex = 0;
  /// Personnes ayant ouvert le coffre (charge a la 1re ouverture de l'onglet).
  Future<List<PrivateEventOpener>>? _openersFuture;
  /// Inscrits dont le dernier message prive attend une reponse de l'hote.
  Set<String> _pendingDm = {};
  /// Nombre d'inscrits affiche dans le titre (baisse quand l'hote retire).
  late int _count = widget.event.rsvpCount;
  /// Confirmation activee (peut l'etre depuis le bouton PDF).
  late bool _confirmationOn = widget.event.confirmationRequise;

  @override
  void initState() {
    super.initState();
    _loadPendingDm();
    _future = _service.hostListEventRsvps(
      token: widget.event.accessToken,
      hostDeviceUuid: widget.hostDeviceUuid,
    );
    _loadConfirmations();
  }

  void _loadConfirmations() {
    if (_confirmationOn) {
      _confFuture = _service.hostListConfirmations(
        token: widget.event.accessToken,
        hostDeviceUuid: widget.hostDeviceUuid,
      );
    }
  }

  /// Retire un participant (meme confirme) apres confirmation. Il ne pourra
  /// plus se reinscrire ni acceder a la discussion de l'event.
  Future<void> _removeGuest(String userId, String? name) async {
    final label = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : context.l10n.pvThisPerson;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          context.l10n.pvRemoveGuest(label),
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          context.l10n.pvRemoveGuestBody,
          style: GoogleFonts.geist(fontSize: 14, color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: Text(context.l10n.commonRemove),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final updated = await _service.hostRemoveRsvp(
        token: widget.event.accessToken,
        hostDeviceUuid: widget.hostDeviceUuid,
        userId: userId,
      );
      if (!mounted) return;
      widget.onChanged?.call();
      setState(() {
        _future = Future.value(updated);
        _count = updated.length;
        _pendingDm = {..._pendingDm}..remove(userId);
        _loadConfirmations();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label a été retiré(e) de la liste')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pvRemoveFailed)),
      );
    }
  }

  bool _exporting = false;

  void _snack(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  /// Le PDF est genere depuis le formulaire de confirmation (nom, prenom...) :
  /// sans confirmation activee, on propose de l'activer.
  Future<void> _askEnableConfirmation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          context.l10n.pvEnableConfirmTitle,
          style: GoogleFonts.geist(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          context.l10n.pvEnableConfirmBody,
          style: GoogleFonts.geist(fontSize: 14, color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonActivate),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.setConfirmationRequired(
        token: widget.event.accessToken,
        hostDeviceUuid: widget.hostDeviceUuid,
        enabled: true,
      );
      if (!mounted) return;
      widget.onChanged?.call();
      setState(() {
        _confirmationOn = true;
        _loadConfirmations();
      });
      _snack(context.l10n.pvConfirmOnPdf);
    } catch (_) {
      if (mounted) _snack(context.l10n.commonFailedRetry);
    }
  }

  /// Export PDF des confirmes (nom, prenom, age, contact) puis partage.
  Future<void> _exportPdf(BuildContext btnCtx) async {
    if (_exporting) return;
    if (!_confirmationOn) {
      await _askEnableConfirmation();
      return;
    }
    setState(() => _exporting = true);
    try {
      final confirmations = await (_confFuture ??
          Future.value(<PrivateEventConfirmation>[]));
      if (!mounted || !btnCtx.mounted) return;
      if (confirmations.isEmpty) {
        _snack(context.l10n.pvNoConfirmYet);
        return;
      }
      await GuestListPdf.share(
        btnCtx,
        event: widget.event,
        confirmations: confirmations,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _loadPendingDm() async {
    final ids = await _service.hostPendingDmUserIds(
      token: widget.event.accessToken,
      hostDeviceUuid: widget.hostDeviceUuid,
    );
    if (mounted) setState(() => _pendingDm = ids);
  }

  /// Conversation privee avec un inscrit ; au retour, rafraichit les points.
  Future<void> _openDm(String userId, String? name) async {
    await PrivateEventChatScreen.openDm(
      context,
      token: widget.event.accessToken,
      eventTitle: widget.event.title,
      withUserId: userId,
      withName: name,
      isHost: true,
    );
    _loadPendingDm();
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.magenta : AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            // Une seule ligne : le libelle retrecit plutot que de passer a la
            // ligne (police agrandie du telephone, langues plus longues).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.text,
                ),
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

  /// Ont ouvert le coffre sans faire « Je viens » (derniere ouverture en haut).
  Widget _openersList() {
    return FutureBuilder<List<PrivateEventOpener>>(
      future: _openersFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.magenta),
          );
        }
        final list = (snap.data ?? []).where((o) => !o.going).toList();
        if (list.isEmpty) {
          return _empty(context.l10n.pvNoOpeners);
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _OpenerRow(opener: list[i]),
        );
      },
    );
  }

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
          return _empty(context.l10n.pvNoConfirmations);
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ConfirmedRow(
            rank: i + 1,
            c: list[i],
            pendingDm: _pendingDm.contains(list[i].userId),
            onMessage: list[i].userId == null
                ? null
                : () => _openDm(list[i].userId!, list[i].pseudo),
            onRemove: list[i].userId == null
                ? null
                : () => _removeGuest(
                      list[i].userId!,
                      list[i].pseudo ?? '${list[i].prenom} ${list[i].nom}',
                    ),
          ),
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
                  // Titre court sur la 1re ligne, nom de l'event en petit
                  // dessous : un nom long ne deborde plus de l'ecran.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.maxParticipants != null
                              ? context.l10n.pvSignedUpMax(
                                  _count, widget.event.maxParticipants!)
                              : context.l10n.pvSignedUp(_count),
                          style: GoogleFonts.geist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          widget.event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.geist(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Export PDF de la liste (WhatsApp, impression a l'entree).
                  Builder(
                    builder: (btnCtx) => TextButton.icon(
                      onPressed: _exporting ? null : () => _exportPdf(btnCtx),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.magenta,
                        backgroundColor: AppColors.magenta.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                      ),
                      icon: _exporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.magenta,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        'PDF',
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _tab(context.l10n.pvTabGuests, _tabIndex == 0,
                      () => setState(() => _tabIndex = 0)),
                  const SizedBox(width: 8),
                  _tab(context.l10n.pvTabSeen, _tabIndex == 1, () => setState(() {
                        _tabIndex = 1;
                        _openersFuture ??= _service.hostListOpeners(
                          token: widget.event.accessToken,
                          hostDeviceUuid: widget.hostDeviceUuid,
                        );
                      })),
                  if (_confFuture != null) ...[
                    const SizedBox(width: 8),
                    _tab(context.l10n.pvTabConfirmed, _tabIndex == 2,
                        () => setState(() => _tabIndex = 2)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (_tabIndex == 2 && _confFuture != null)
                Flexible(child: _confirmedList())
              else if (_tabIndex == 1)
                Flexible(child: _openersList())
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
                            context.l10n.pvNobodyYet,
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
                      itemBuilder: (_, i) => _GuestRow(
                        rsvp: rsvps[i],
                        pendingDm: _pendingDm.contains(rsvps[i].userId),
                        onMessage: () => _openDm(rsvps[i].userId, rsvps[i].prenom),
                        onRemove: () => _removeGuest(rsvps[i].userId, rsvps[i].prenom),
                      ),
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
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;
  final bool pendingDm;
  const _GuestRow({
    required this.rsvp,
    this.onMessage,
    this.onRemove,
    this.pendingDm = false,
  });

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
              rsvp.prenom ?? context.l10n.storyAnonymous,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          if (onMessage != null) ...[
            const SizedBox(width: 6),
            _DmButton(onTap: onMessage!, pending: pendingDm),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            _RemoveButton(onTap: onRemove!),
          ],
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

/// A ouvert le coffre sans s'inscrire : identite, nombre et date d'ouverture.
class _OpenerRow extends StatelessWidget {
  final PrivateEventOpener opener;
  const _OpenerRow({required this.opener});

  @override
  Widget build(BuildContext context) {
    final prenom = opener.prenom?.trim() ?? '';
    final hasPhoto = opener.avatarUrl != null && opener.avatarUrl!.isNotEmpty;
    final initial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
    final when = opener.lastOpenedAt == null
        ? ''
        : formatDayAtTime(context, opener.lastOpenedAt!.toLocal());
    final detail = [
      context.l10n.pvOpens(opener.opens),
      if (when.isNotEmpty) context.l10n.pvLastOn(when),
    ].join(' · ');
    Widget fallback() => Container(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: prenom.isEmpty
          ? null
          : () => ContributorProfileSheet.show(
                context,
                userId: opener.userId,
                fallbackPrenom: prenom,
                fallbackAvatarUrl: opener.avatarUrl,
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
                      imageUrl: opener.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => fallback(),
                      placeholder: (_, __) => fallback(),
                    )
                  : fallback(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prenom.isNotEmpty ? prenom : context.l10n.commonWithoutAccount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    detail,
                    style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            Icon(Icons.visibility_outlined, size: 16, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

/// Un participant confirme, vu par l'hote : rang, identite, age, contact.
/// Telephone et e-mail cliquables (appel / e-mail).
class _ConfirmedRow extends StatelessWidget {
  final int rank;
  final PrivateEventConfirmation c;
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;
  final bool pendingDm;
  const _ConfirmedRow({
    required this.rank,
    required this.c,
    this.onMessage,
    this.onRemove,
    this.pendingDm = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = '${c.prenom} ${c.nom.toUpperCase()}'.trim();
    final pseudo = c.pseudo?.trim() ?? '';
    final when = c.confirmedAt == null
        ? ''
        : formatDayAtTime(context, c.confirmedAt!.toLocal());
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
                  c.age != null
                      ? context.l10n.pvNameAge(fullName, c.age!)
                      : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                // Pseudo MaCity mis en avant (pastille de couleur) : c'est
                // lui que l'hote reconnait dans la liste des inscrits.
                if (pseudo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.magenta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.magenta.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '@$pseudo',
                      style: GoogleFonts.geist(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.magenta,
                      ),
                    ),
                  ),
                ],
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(context.l10n.pvConfirmedOn(when), style: small),
                ],
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
          if (onMessage != null) ...[
            const SizedBox(width: 6),
            _DmButton(onTap: onMessage!, pending: pendingDm),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            _RemoveButton(onTap: onRemove!),
          ],
        ],
      ),
    );
  }
}

/// Bouton « retirer de la liste » d'une ligne d'inscrit (hote uniquement).
class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.person_remove_outlined, size: 17, color: Color(0xFFFF3B30)),
        ),
      ),
    );
  }
}

/// Bouton « message prive » d'une ligne d'inscrit. Point rouge : l'inscrit a
/// ecrit et attend une reponse.
class _DmButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool pending;
  const _DmButton({required this.onTap, this.pending = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.magenta.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chat_bubble_outline, size: 17, color: AppColors.magenta),
            ),
          ),
        ),
        if (pending)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceHi, width: 1.5),
              ),
            ),
          ),
      ],
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
            max != null
                ? '$count / $max${full ? ' · ${context.l10n.pvFull}' : ''}'
                : context.l10n.pvSignedUpCount(count),
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

/// Pastille compacte (code secret, nombre de confirmes...).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool mono;
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (mono ? GoogleFonts.geistMono : GoogleFonts.geist)(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: mono ? 2 : 0,
      color: color,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: style),
        ],
      ),
    );
  }
}

/// Interrupteur « Confirmation des participants » sur la carte. Optimiste :
/// bascule tout de suite, revient en arriere si l'enregistrement echoue.
class _ConfirmationToggle extends StatefulWidget {
  final bool value;
  final Future<bool> Function(bool enabled) onChanged;
  const _ConfirmationToggle({required this.value, required this.onChanged});

  @override
  State<_ConfirmationToggle> createState() => _ConfirmationToggleState();
}

class _ConfirmationToggleState extends State<_ConfirmationToggle> {
  late bool _value = widget.value;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _ConfirmationToggle old) {
    super.didUpdateWidget(old);
    if (!_busy && old.value != widget.value) _value = widget.value;
  }

  Future<void> _set(bool v) async {
    setState(() {
      _value = v;
      _busy = true;
    });
    final ok = await widget.onChanged(v);
    if (!mounted) return;
    setState(() {
      if (!ok) _value = !v;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.how_to_reg, size: 18, color: Color(0xFF22C55E)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.pvGuestConfirmation,
                style: GoogleFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              Text(
                _value
                    ? context.l10n.pvGuestConfirmationOn
                    : context.l10n.pvOff,
                style: GoogleFonts.geist(fontSize: 11, color: AppColors.textDim),
              ),
            ],
          ),
        ),
        Switch(
          value: _value,
          onChanged: _busy ? null : _set,
          activeColor: const Color(0xFF22C55E),
        ),
      ],
    );
  }
}

/// Action de la carte : icone + libelle, pleine largeur partagee.
class _TileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _TileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.magenta,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Statut de l'event selon sa date : « Aujourd'hui », « À venir » ou
/// « Passé » (supprime automatiquement 7 jours apres la date).
class _StatusBadge extends StatelessWidget {
  final String date; // YYYY-MM-DD
  const _StatusBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = d == null ? null : DateTime(d.year, d.month, d.day);

    final String label;
    final Color color;
    if (day == null || day.isAfter(today)) {
      label = context.l10n.cultureCatUpcoming;
      color = const Color(0xFF22C55E);
    } else if (day == today) {
      label = context.l10n.commonToday;
      color = AppColors.magenta;
    } else {
      label = context.l10n.commonPast;
      color = AppColors.textFaint;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.geist(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
