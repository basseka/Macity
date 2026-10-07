import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/router/app_router.dart' show isDeviceRegistered;
import 'package:pulz_app/core/widgets/account_gate.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/photo_slideshow_screen.dart';
import 'package:pulz_app/features/private_events/presentation/private_event_chat_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/services/analytics_service.dart';

/// Album d'un event prive : toutes les photos partagees dans la discussion
/// de GROUPE, en grille. Diaporama, enregistrement d'une ou de toutes les
/// photos. Acces verifie cote serveur (comme la discussion).
class EventAlbumScreen extends StatefulWidget {
  final String token;
  final String title;
  final String? passcode;
  final bool isHost;

  /// Lance directement le diaporama une fois les photos chargees.
  final bool startSlideshow;

  /// Plus de publication possible (J+7) : pas d'invitation a ajouter des photos.
  final bool archived;

  const EventAlbumScreen({
    super.key,
    required this.token,
    required this.title,
    this.passcode,
    this.isHost = false,
    this.startSlideshow = false,
    this.archived = false,
  });

  static Future<void> open(
    BuildContext context, {
    required String token,
    required String title,
    String? passcode,
    bool isHost = false,
    bool startSlideshow = false,
    bool archived = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => EventAlbumScreen(
          token: token,
          title: title,
          passcode: passcode,
          isHost: isHost,
          startSlideshow: startSlideshow,
          archived: archived,
        ),
      ),
    );
  }

  @override
  State<EventAlbumScreen> createState() => _EventAlbumScreenState();
}

class _EventAlbumScreenState extends State<EventAlbumScreen> {
  final _service = PrivateEventService();
  List<PrivateEventPhoto>? _photos;
  String? _error;
  bool _savingAll = false;
  String? _userId;

  /// Organisateur : ouvert depuis ses events, ou auteur d'une photo marquee
  /// is_host (ouverture depuis une notification / un souvenir).
  bool get _iAmHost =>
      widget.isHost ||
      (_userId != null && (_photos ?? const []).any((p) => p.isHost && p.userId == _userId));

  /// L'organisateur peut retirer n'importe quelle photo (hors sujet...), chacun
  /// peut retirer les siennes. Le serveur reverifie (delete_private_event_message).
  bool _canDelete(PrivateEventPhoto p) => _iAmHost || p.userId == _userId;

  /// Supprime une photo de l'album (= son message dans la discussion).
  /// Renvoie true si supprimee.
  Future<bool> _deletePhoto(PrivateEventPhoto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette photo ?'),
        content: Text(
          _iAmHost && p.userId != _userId
              ? 'Elle sera retirée de l\'album et de la discussion pour tout le monde.'
              : 'Elle sera retirée de l\'album et de la discussion.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || _userId == null || !mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await _service.deleteMessage(
        messageId: p.id,
        token: widget.token,
        userId: _userId!,
      );
      if (!deleted) {
        messenger.showSnackBar(const SnackBar(content: Text('Tu ne peux pas retirer cette photo')));
        return false;
      }
      if (mounted) setState(() => _photos = [...?_photos]..removeWhere((x) => x.id == p.id));
      messenger.showSnackBar(const SnackBar(content: Text('Photo retirée de l\'album')));
      return true;
    } on PrivateEventException {
      messenger.showSnackBar(const SnackBar(content: Text('Échec, réessaie')));
      return false;
    }
  }

  /// Ajout de photos en cours : « 2 / 5 ».
  int _uploadDone = 0;
  int _uploadTotal = 0;
  bool get _uploading => _uploadTotal > 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('/event-prive/album');
    _load(autoStart: widget.startSlideshow);
  }

  Future<void> _load({bool autoStart = false}) async {
    try {
      final uid = await UserIdentityService.getUserId();
      _userId = uid;
      final photos = await _service.listPhotos(
        token: widget.token,
        userId: uid,
        passcode: widget.passcode,
      );
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _error = null;
      });
      if (autoStart && photos.isNotEmpty) _slideshow(0, autoplay: true);
    } on PrivateEventException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code == PrivateEventError.network
          ? 'Impossible de charger l\'album. Vérifie ta connexion.'
          : 'Cet album n\'est pas accessible.');
    }
  }

  /// Ajoute des photos a l'album SANS ouvrir la discussion : chaque photo
  /// est publiee comme un message (sans texte) de la discussion de groupe,
  /// exactement comme depuis le chat, donc visible des deux cotes.
  /// Galerie : plusieurs photos d'un coup (20 max) ; ou appareil photo.
  Future<void> _addPhotos() async {
    if (_uploading) return;
    if (!isDeviceRegistered()) {
      AccountGate.showNudge(context, action: 'ajouter des photos');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.text),
              title: Text('Choisir dans la galerie (plusieurs)',
                  style: GoogleFonts.geist(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.text),
              title: Text('Prendre une photo', style: GoogleFonts.geist(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final List<XFile> picked = source == ImageSource.gallery
        ? await picker.pickMultiImage(imageQuality: 85, limit: 20)
        : [if (await picker.pickImage(source: source, imageQuality: 85) case final f?) f];
    if (picked.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _uploadDone = 0;
      _uploadTotal = picked.length;
    });
    var ok = 0;
    String? stopReason;
    try {
      final uid = await UserIdentityService.getUserId();
      for (final file in picked) {
        try {
          // Nom aleatoire : l'URL publique n'est pas devinable.
          final url = await UserEventSupabaseService().uploadPhoto(
            file.path,
            objectName: 'private_chat/${const Uuid().v4()}.jpg',
          );
          await _service.postMessage(
            token: widget.token,
            userId: uid,
            content: '',
            passcode: widget.passcode,
            imageUrl: url,
          );
          ok++;
        } on PrivateEventException catch (e) {
          // Refus definitif (album fige, profil manquant, acces) : on arrete.
          if (e.code != PrivateEventError.network) {
            stopReason = e.code == PrivateEventError.profileRequired
                ? 'Complète ton profil pour ajouter des photos'
                : (e.message ?? 'Ajout refusé');
            break;
          }
        } catch (_) {/* echec d'upload d'une photo : on passe a la suivante */}
        if (mounted) setState(() => _uploadDone++);
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadDone = 0;
          _uploadTotal = 0;
        });
      }
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(stopReason ??
          (ok == picked.length
              ? '$ok photo${ok > 1 ? 's' : ''} ajoutée${ok > 1 ? 's' : ''} à l\'album'
              : '$ok / ${picked.length} photos ajoutées, réessaie pour les autres')),
    ));
    if (ok > 0) _load();
  }

  void _slideshow(int index, {bool autoplay = false}) {
    final photos = _photos;
    if (photos == null || photos.isEmpty) return;
    PhotoSlideshowScreen.open(
      context,
      photos: photos,
      eventTitle: widget.title,
      initialIndex: index,
      autoplay: autoplay,
      canDelete: _canDelete,
      onDelete: _deletePhoto,
    );
  }

  /// Toutes les photos en une fois via la feuille de partage (Enregistrer
  /// les images, Drive, WhatsApp...). Plafond pour ne pas saturer le partage.
  Future<void> _saveAll(BuildContext btnCtx) async {
    final photos = _photos;
    if (photos == null || photos.isEmpty || _savingAll) return;
    setState(() => _savingAll = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Rect? origin;
    final box = btnCtx.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    const max = 30;
    try {
      final files = <XFile>[];
      for (final p in photos.take(max)) {
        try {
          final f = await DefaultCacheManager().getSingleFile(p.imageUrl);
          files.add(XFile(f.path, mimeType: 'image/jpeg'));
        } catch (_) {/* photo indisponible : on passe a la suivante */}
      }
      if (files.isEmpty) throw Exception('aucune photo telechargee');
      await Share.shareXFiles(files, text: widget.title, sharePositionOrigin: origin);
      if (photos.length > max) {
        messenger?.showSnackBar(SnackBar(
          content: Text('Les $max premières photos ont été proposées. '
              'Enregistre les autres une par une depuis le diaporama.'),
        ));
      }
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Impossible d\'enregistrer les photos')),
      );
    } finally {
      if (mounted) setState(() => _savingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📸 Album',
              style: GoogleFonts.geist(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.geist(fontSize: 11, color: AppColors.textDim),
            ),
          ],
        ),
        actions: [
          if (photos != null && photos.isNotEmpty)
            Builder(
              builder: (btnCtx) => IconButton(
                tooltip: 'Tout enregistrer',
                onPressed: _savingAll ? null : () => _saveAll(btnCtx),
                icon: _savingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magenta),
                      )
                    : const Icon(Icons.download_rounded, color: AppColors.magenta),
              ),
            ),
        ],
      ),
      body: _buildBody(photos),
      floatingActionButton: (photos == null || _error != null)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.archived)
                  FloatingActionButton.extended(
                    heroTag: 'album_add',
                    onPressed: _uploading ? null : _addPhotos,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.magenta,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magenta),
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _uploading ? 'Envoi $_uploadDone / $_uploadTotal' : 'Ajouter',
                      style: GoogleFonts.geist(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (photos.length > 1) ...[
                  const SizedBox(height: 10),
                  FloatingActionButton.extended(
                    heroTag: 'album_play',
                    onPressed: () => _slideshow(0, autoplay: true),
                    backgroundColor: AppColors.magenta,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Diaporama', style: GoogleFonts.geist(fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildBody(List<PrivateEventPhoto>? photos) {
    if (_error != null) {
      return _centered(Icons.lock_outline, _error!);
    }
    if (photos == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.magenta));
    }
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.magenta),
              const SizedBox(height: 12),
              Text(
                'Pas encore de photo',
                style: GoogleFonts.geist(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                widget.archived
                    ? 'Personne n\'a partagé de photo pendant cette soirée.'
                    : 'Ajoute tes photos ici, ou partage-les dans la discussion : '
                        'elles apparaissent automatiquement dans l\'album.',
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(fontSize: 13, color: AppColors.textDim),
              ),
              if (!widget.archived) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _addPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('Ajouter des photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.magenta,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => PrivateEventChatScreen.open(
                    context,
                    token: widget.token,
                    title: widget.title,
                    passcode: widget.passcode,
                    isHost: widget.isHost,
                  ).then((_) => _load()),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text('Ouvrir la discussion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.magenta,
                    side: const BorderSide(color: AppColors.magenta),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.magenta,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                '${photos.length} photo${photos.length > 1 ? 's' : ''}'
                '${widget.archived ? ' · album figé' : ''}'
                '${_iAmHost ? ' · appui long sur une photo pour la retirer' : ''}',
                style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 96),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => GestureDetector(
                  onTap: () => _slideshow(i),
                  // Appui long : retirer la photo (organisateur, ou son auteur).
                  onLongPress: _canDelete(photos[i]) ? () => _deletePhoto(photos[i]) : null,
                  child: CachedNetworkImage(
                      imageUrl: photos[i].imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (_, __) => Container(color: AppColors.surfaceHi),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceHi,
                        child: Icon(Icons.broken_image_outlined, color: AppColors.textFaint),
                      ),
                  ),
                ),
                childCount: photos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.textFaint),
              const SizedBox(height: 10),
              Text(text, textAlign: TextAlign.center,
                  style: GoogleFonts.geist(fontSize: 13, color: AppColors.textDim)),
            ],
          ),
        ),
      );
}
