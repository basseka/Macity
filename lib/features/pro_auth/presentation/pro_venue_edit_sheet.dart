import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/pro_auth/data/pro_venue_service.dart';

/// Sheet d'edition de la fiche pro : 6 photos + URL video teaser.
/// Accessible depuis AccountMenu en tapant sur le bouton "Mon compte pro".
class ProVenueEditSheet extends ConsumerStatefulWidget {
  const ProVenueEditSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProVenueEditSheet(),
    );
  }

  @override
  ConsumerState<ProVenueEditSheet> createState() => _ProVenueEditSheetState();
}

class _ProVenueEditSheetState extends ConsumerState<ProVenueEditSheet> {
  static const _primaryColor = Color(0xFF7B2D8E);
  static const _slotCount = 6;

  final _service = ProVenueService();

  ProVenueRecord? _record;
  bool _loading = true;
  String? _error;
  final Set<int> _uploadingSlots = {};
  bool _uploadingVideo = false;
  String _videoStatus = '';
  double _videoProgress = 0.0;
  bool _uploadingCover = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rec = await _service.fetchMyVenue();
      if (!mounted) return;
      setState(() {
        _record = rec;
        _loading = false;
        if (rec == null) {
          _error = 'Aucune fiche associee a votre compte pro.\n'
              'Reclamez votre etablissement depuis sa fiche pour pouvoir l\'editer.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  Future<void> _pickAndUpload(int slot) async {
    final rec = _record;
    if (rec == null) return;
    final source = await _pickSource();
    if (source == null) return;

    setState(() => _uploadingSlots.add(slot));
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 2000);
      if (xFile == null) {
        if (mounted) setState(() => _uploadingSlots.remove(slot));
        return;
      }
      final url = await _service.uploadPhoto(
        tableName: rec.tableName,
        rowId: rec.rowId,
        slotIndex: slot,
        localPath: xFile.path,
      );
      // Reconstruire la liste avec exactement _slotCount entrees, vide = ''.
      final next = List<String>.filled(_slotCount, '');
      for (var i = 0; i < _slotCount && i < rec.photos.length; i++) {
        next[i] = rec.photos[i];
      }
      next[slot] = url;
      final cleaned = next.where((s) => s.isNotEmpty).toList();
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        photos: cleaned,
      );
      if (!mounted) return;
      setState(() {
        _record = rec.copyWith(photos: cleaned);
        _uploadingSlots.remove(slot);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingSlots.remove(slot));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec upload : $e')),
      );
    }
  }

  Future<void> _deletePhoto(int slot) async {
    final rec = _record;
    if (rec == null) return;
    if (slot >= rec.photos.length) return;
    final next = List<String>.from(rec.photos)..removeAt(slot);
    try {
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        photos: next,
      );
      if (!mounted) return;
      setState(() => _record = rec.copyWith(photos: next));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec suppression : $e')),
      );
    }
  }

  Future<ImageSource?> _pickSource({String label = 'photo'}) async {
    final isVideo = label == 'video';
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isVideo ? Icons.videocam : Icons.photo_camera,
                color: _primaryColor,
              ),
              title: Text(
                isVideo ? 'Filmer maintenant' : 'Prendre une photo',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primaryColor),
              title: Text(
                isVideo
                    ? 'Choisir une video dans la galerie'
                    : 'Choisir dans la galerie',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadCover() async {
    final rec = _record;
    if (rec == null) return;
    final source = await _pickSource();
    if (source == null) return;

    setState(() => _uploadingCover = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 2000);
      if (xFile == null) {
        if (mounted) setState(() => _uploadingCover = false);
        return;
      }
      final url = await _service.uploadCover(
        tableName: rec.tableName,
        rowId: rec.rowId,
        localPath: xFile.path,
      );
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        coverPhoto: url,
      );
      if (!mounted) return;
      setState(() {
        _record = rec.copyWith(mainPhoto: url);
        _uploadingCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pochette mise a jour'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec upload pochette : $e')),
      );
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final rec = _record;
    if (rec == null) return;
    final source = await _pickSource(label: 'video');
    if (source == null) return;

    setState(() {
      _uploadingVideo = true;
      _videoStatus = 'Compression...';
      _videoProgress = 0.0;
    });
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (xFile == null) {
        if (mounted) setState(() => _uploadingVideo = false);
        return;
      }
      final url = await _service.uploadVideo(
        tableName: rec.tableName,
        rowId: rec.rowId,
        localPath: xFile.path,
        onCompressed: (kb) {
          if (!mounted) return;
          setState(() {
            _videoStatus = 'Compressee : ${(kb / 1024).toStringAsFixed(1)} MB';
          });
        },
        onProgress: (pct) {
          if (!mounted) return;
          setState(() {
            _videoStatus = 'Upload ${(pct * 100).round()} %';
            _videoProgress = pct;
          });
        },
      );
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        videoUrl: url,
      );
      if (!mounted) return;
      setState(() {
        _record = rec.copyWith(videoUrl: url);
        _uploadingVideo = false;
        _videoStatus = '';
        _videoProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploadee avec succes'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } on ProVenueUploadError catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingVideo = false;
        _videoStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingVideo = false;
        _videoStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec upload : $e')),
      );
    }
  }

  Future<void> _deleteVideo() async {
    final rec = _record;
    if (rec == null || rec.videoUrl == null || rec.videoUrl!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer la video ?',
            style: TextStyle(color: AppColors.text, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFE91E8C))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        videoUrl: '',
      );
      if (!mounted) return;
      setState(() => _record = rec.copyWith(videoUrl: ''));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }
    final rec = _record;
    if (rec == null) {
      return _buildError(_error ?? 'Erreur inconnue');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          const SizedBox(height: 12),
          _header(rec),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.cloud_done_outlined,
                    size: 14, color: Color(0xFF4CAF50)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vos modifications sont enregistrees automatiquement.',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionTitle('Pochette (visible dans la liste)'),
          const SizedBox(height: 4),
          Text(
            'Image principale affichee sur la carte de votre etablissement '
            'dans les listes.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _coverTile(rec),
          const SizedBox(height: 22),
          _sectionTitle('Photos de la fiche detail'),
          const SizedBox(height: 4),
          Text(
            'Jusqu\'a 6 photos. Apparaissent dans l\'ordre sur la fiche detail.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _photoGrid(rec),
          const SizedBox(height: 22),
          _sectionTitle('Video teaser'),
          const SizedBox(height: 4),
          Text(
            'Filmez avec le telephone ou choisissez dans la galerie. '
            'Max 30 sec — 50 MB apres compression auto.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _videoTile(rec),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Termine',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.lineStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(ProVenueRecord rec) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2D8E), Color(0xFF9B4DCA)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rec.category} · ${rec.ville}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _coverTile(ProVenueRecord rec) {
    final cover = rec.mainPhoto ?? '';
    final hasCover = cover.isNotEmpty && cover.startsWith('http');
    return GestureDetector(
      onTap: _uploadingCover ? null : _pickAndUploadCover,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 140),
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasCover)
                  Image.network(cover, fit: BoxFit.cover)
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined,
                            color: AppColors.textFaint, size: 32),
                        SizedBox(height: 4),
                        Text(
                          'Pochette',
                          style: TextStyle(
                              color: AppColors.textFaint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
                if (_uploadingCover)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoTile(ProVenueRecord rec) {
    final hasVideo = rec.videoUrl != null && rec.videoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _uploadingVideo ? null : _pickAndUploadVideo,
      onLongPress: hasVideo ? _deleteVideo : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasVideo) ...[
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          color: Colors.white24, size: 56),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 56),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Appui long pour supprimer · Tap pour remplacer',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ] else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_call_outlined,
                            color: AppColors.textFaint, size: 40),
                        SizedBox(height: 6),
                        Text(
                          'Ajouter une video',
                          style: TextStyle(
                              color: AppColors.textFaint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (_uploadingVideo)
                  Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                              value: _videoProgress > 0 ? _videoProgress : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _videoStatus.isEmpty
                                ? 'Preparation...'
                                : _videoStatus,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoGrid(ProVenueRecord rec) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _slotCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final hasPhoto = i < rec.photos.length && rec.photos[i].isNotEmpty;
        final uploading = _uploadingSlots.contains(i);
        return GestureDetector(
          onTap: uploading ? null : () => _pickAndUpload(i),
          onLongPress: hasPhoto ? () => _confirmDelete(i) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHi,
                border: Border.all(color: AppColors.lineStrong),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    Image.network(rec.photos[i], fit: BoxFit.cover)
                  else
                    Center(
                      child: Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textFaint),
                    ),
                  if (uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(int slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer cette photo ?',
            style: TextStyle(color: AppColors.text, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFE91E8C))),
          ),
        ],
      ),
    );
    if (ok == true) await _deletePhoto(slot);
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          const SizedBox(height: 20),
          Icon(Icons.info_outline, color: AppColors.textFaint, size: 32),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
}
