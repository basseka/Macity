import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/router/app_router.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/core/utils/bad_words_filter.dart';
import 'package:pulz_app/core/widgets/account_gate.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event_message.dart';
import 'package:uuid/uuid.dart';
import 'package:pulz_app/features/reported_events/presentation/widgets/contributor_profile_sheet.dart';

/// Palette fixe sombre, alignee sur le coffre et "Mes invitations".
class _ChatColors {
  static const bg = Color(0xFF0A0514);
  static const surface = Color(0xFF1A0F2E);
  static const surfaceHi = Color(0xFF241640);
  static const text = Color(0xFFF5F0FF);
  static const textDim = Color(0xFFB5A8D0);
  static const textFaint = Color(0xFF7A6E95);
  static const line = Color(0x12FFFFFF);
  // Accent organisateur : or, distinct du magenta de "Moi".
  static const host = Color(0xFFFFC857);
}

/// Chat d'une soiree privee : l'organisateur et les invites posent des
/// questions et discutent. Acces verifie cote serveur (hote, invite
/// "Je viens", deja auteur, ou [passcode] du coffre).
class PrivateEventChatScreen extends StatefulWidget {
  final String token;
  final String? passcode;
  final String title;

  /// Ouvert depuis "Mes events prives" : l'organisateur peut supprimer
  /// n'importe quel message (le serveur le reverifie).
  final bool isHost;

  const PrivateEventChatScreen({
    super.key,
    required this.token,
    required this.title,
    this.passcode,
    this.isHost = false,
  });

  static Future<void> open(
    BuildContext context, {
    required String token,
    required String title,
    String? passcode,
    bool isHost = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivateEventChatScreen(
          token: token,
          title: title,
          passcode: passcode,
          isHost: isHost,
        ),
      ),
    );
  }

  @override
  State<PrivateEventChatScreen> createState() => _PrivateEventChatScreenState();
}

class _PrivateEventChatScreenState extends State<PrivateEventChatScreen> {
  static const _pollInterval = Duration(seconds: 5);

  final _service = PrivateEventService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<PrivateEventMessage> _messages = [];
  Timer? _pollTimer;
  String? _userId;
  bool _loading = true;
  bool _sending = false;
  bool _polling = false;
  // Photo jointe au prochain message : apercu local + URL une fois uploadee.
  String? _pendingPhotoPath;
  String? _pendingPhotoUrl;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await UserIdentityService.getUserId();
    await _refresh(initial: true);
    if (!mounted || _error != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Chargement initial puis delta (messages plus recents que le dernier).
  Future<void> _refresh({bool initial = false}) async {
    if (_polling || _userId == null) return;
    _polling = true;
    try {
      final fresh = await _service.listMessages(
        token: widget.token,
        userId: _userId!,
        passcode: widget.passcode,
        since: initial || _messages.isEmpty ? null : _messages.last.createdAt,
      );
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final added = fresh.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _loading = false;
        _error = null;
        _messages.addAll(added);
      });
      if (added.isNotEmpty) _scrollToBottom();
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      // Erreur reseau pendant le polling : on garde les messages affiches.
      if (!initial && e.code == PrivateEventError.network) return;
      setState(() {
        _loading = false;
        _error = e.code == PrivateEventError.forbidden ||
                e.code == PrivateEventError.notFound
            ? 'Cette discussion n\'est plus accessible.'
            : 'Impossible de charger la discussion.';
      });
    } finally {
      _polling = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _askSignup() {
    AccountGate.showNudge(context, action: 'participer a la discussion');
  }

  Future<void> _pickPhoto() async {
    if (!isDeviceRegistered()) {
      _askSignup();
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _ChatColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: _ChatColors.text),
              title: Text('Prendre une photo',
                  style: GoogleFonts.geist(color: _ChatColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: _ChatColors.text),
              title: Text('Choisir dans la galerie',
                  style: GoogleFonts.geist(color: _ChatColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _pendingPhotoPath = picked.path;
      _pendingPhotoUrl = null;
      _uploadingPhoto = true;
    });
    try {
      // Nom aleatoire : l'URL publique n'est pas devinable.
      final url = await UserEventSupabaseService().uploadPhoto(
        picked.path,
        objectName: 'private_chat/${const Uuid().v4()}.jpg',
      );
      if (!mounted || _pendingPhotoPath != picked.path) return;
      setState(() {
        _pendingPhotoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingPhotoPath = null;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de l\'envoi de la photo')),
      );
    }
  }

  void _removePendingPhoto() {
    setState(() {
      _pendingPhotoPath = null;
      _pendingPhotoUrl = null;
      _uploadingPhoto = false;
    });
  }

  Future<void> _send() async {
    final raw = _controller.text.trim();
    final photoUrl = _pendingPhotoUrl;
    if ((raw.isEmpty && photoUrl == null) ||
        _sending ||
        _uploadingPhoto ||
        _userId == null) {
      return;
    }
    if (!isDeviceRegistered()) {
      _askSignup();
      return;
    }
    if (raw.isNotEmpty && BadWordsFilter.contains(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message refuse : langage inapproprie'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _service.postMessage(
        token: widget.token,
        userId: _userId!,
        content: raw,
        passcode: widget.passcode,
        imageUrl: photoUrl,
      );
      _controller.clear();
      _removePendingPhoto();
      await _refresh();
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      if (e.code == PrivateEventError.profileRequired) {
        _askSignup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Echec de l\'envoi, reessaie')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelete(PrivateEventMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || _userId == null) return;
    try {
      final deleted = await _service.deleteMessage(
        messageId: msg.id,
        token: widget.token,
        userId: _userId!,
      );
      if (!mounted) return;
      if (deleted) {
        setState(() => _messages.removeWhere((m) => m.id == msg.id));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu ne peux pas supprimer ce message')),
        );
      }
    } on PrivateEventException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de la suppression')),
      );
    }
  }

  /// Hote : ouvert depuis ses events, ou auteur d'un message marque isHost
  /// (cas d'une ouverture via notification).
  bool get _iAmHost =>
      widget.isHost || _messages.any((m) => m.isHost && m.userId == _userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ChatColors.bg,
      appBar: AppBar(
        backgroundColor: _ChatColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ChatColors.text),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ChatColors.text,
              ),
            ),
            Text(
              'Discussion privee',
              style: GoogleFonts.geist(
                fontSize: 11,
                color: _ChatColors.textFaint,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (_error == null) _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.magenta,
          ),
        ),
      );
    }
    if (_error != null) {
      return _centerText(_error!);
    }
    if (_messages.isEmpty) {
      return _centerText(
        'Pose une question a l\'organisateur ou dis bonjour aux autres invites !',
      );
    }
    final iAmHost = _iAmHost;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMine = msg.userId == _userId;
        return _MessageBubble(
          msg: msg,
          isMine: isMine,
          onLongPress: isMine || iAmHost ? () => _confirmDelete(msg) : null,
        );
      },
    );
  }

  Widget _centerText(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.geist(fontSize: 13, color: _ChatColors.textDim),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
      decoration: const BoxDecoration(
        color: _ChatColors.surface,
        border: Border(top: BorderSide(color: _ChatColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingPhotoPath != null) _buildPendingPhoto(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _sending || _uploadingPhoto ? null : _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                color: _ChatColors.textDim,
                tooltip: 'Photo',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 500,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style:
                      GoogleFonts.geist(fontSize: 14, color: _ChatColors.text),
                  cursorColor: AppColors.magenta,
                  decoration: InputDecoration(
                    hintText: _pendingPhotoPath != null
                        ? 'Ajoute une legende...'
                        : 'Ecris un message...',
                    hintStyle: GoogleFonts.geist(
                      fontSize: 13,
                      color: _ChatColors.textFaint,
                    ),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: _ChatColors.surfaceHi,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: AppColors.magenta,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _sending ? null : _send,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPhoto() {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_pendingPhotoPath!),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          if (_uploadingPhoto)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: _removePendingPhoto,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final PrivateEventMessage msg;
  final bool isMine;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.msg,
    required this.isMine,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: msg.isHost
              ? _ChatColors.host.withValues(alpha: 0.14)
              : isMine
                  ? AppColors.magenta.withValues(alpha: 0.22)
                  : _ChatColors.surfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: msg.isHost
              ? Border.all(color: _ChatColors.host, width: 1.5)
              : Border.all(color: _ChatColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auteur sur CHAQUE message (y compris les siens : "Moi"),
            // couleur propre a chaque personne comme dans un groupe WhatsApp.
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        isMine ? 'Moi' : msg.prenom,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.geist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: msg.isHost
                              ? _ChatColors.host
                              : isMine
                                  ? AppColors.magenta
                                  : _nameColor(msg.userId),
                        ),
                      ),
                    ),
                  ),
                  if (msg.isHost) ...[
                    const SizedBox(width: 6),
                    const _HostBadge(),
                  ],
                ],
              ),
            ),
            if (msg.imageUrl != null)
              Padding(
                padding: EdgeInsets.only(
                  top: 2,
                  bottom: msg.content.isNotEmpty ? 6 : 2,
                ),
                child: GestureDetector(
                  onTap: () => _PhotoViewer.open(
                    context,
                    url: msg.imageUrl!,
                    heroTag: 'private_chat_${msg.id}',
                  ),
                  child: Hero(
                    tag: 'private_chat_${msg.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 260,
                          minWidth: 140,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: msg.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.magenta,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const SizedBox(
                            width: 200,
                            height: 120,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: _ChatColors.textFaint,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (msg.content.isNotEmpty)
              Text(
                msg.content,
                style: GoogleFonts.geist(
                  fontSize: 14,
                  color: _ChatColors.text,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.createdAt),
              style: GoogleFonts.geist(
                fontSize: 9,
                color: _ChatColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            GestureDetector(
              onTap: () => _openProfile(context),
              child: _Avatar(msg: msg),
            ),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    ContributorProfileSheet.show(
      context,
      userId: msg.userId,
      fallbackPrenom: msg.prenom,
      fallbackAvatarUrl: msg.avatarUrl,
    );
  }

  // Couleurs lisibles sur fond sombre, attribuees de facon stable par user.
  static const _nameColors = [
    Color(0xFF4FC3F7),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
    Color(0xFF4DD0E1),
    Color(0xFFFFD54F),
    Color(0xFFA1887F),
  ];

  static Color _nameColor(String userId) {
    var h = 0;
    for (final c in userId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _nameColors[h % _nameColors.length];
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (diff.inHours < 24) return hm;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $hm';
  }
}

class _HostBadge extends StatelessWidget {
  const _HostBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _ChatColors.host,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 11, color: _ChatColors.bg),
          const SizedBox(width: 3),
          Text(
            'Organisateur',
            style: GoogleFonts.geist(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _ChatColors.bg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PrivateEventMessage msg;
  const _Avatar({required this.msg});

  @override
  Widget build(BuildContext context) {
    final initial = msg.prenom.isNotEmpty ? msg.prenom[0].toUpperCase() : '?';
    final fallback = Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.geist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            msg.isHost ? Border.all(color: _ChatColors.host, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: msg.avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: msg.avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => fallback,
              placeholder: (_, __) => fallback,
            )
          : fallback,
    );
  }
}

/// Photo du chat en plein ecran : fond noir, zoom a deux doigts, tap ou
/// bouton fermer pour revenir.
class _PhotoViewer extends StatelessWidget {
  final String url;
  final String heroTag;

  const _PhotoViewer({required this.url, required this.heroTag});

  static Future<void> open(
    BuildContext context, {
    required String url,
    required String heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _PhotoViewer(url: url, heroTag: heroTag),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: 'Fermer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
