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
  final _videoCtrl = TextEditingController();

  ProVenueRecord? _record;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final Set<int> _uploadingSlots = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    super.dispose();
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
        _videoCtrl.text = rec?.videoUrl ?? '';
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

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _primaryColor),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primaryColor),
              title: const Text('Choisir dans la galerie',
                  style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVideo() async {
    final rec = _record;
    if (rec == null) return;
    setState(() => _saving = true);
    try {
      final v = _videoCtrl.text.trim();
      await _service.updateMyVenue(
        tableName: rec.tableName,
        rowId: rec.rowId,
        videoUrl: v,
      );
      if (!mounted) return;
      setState(() {
        _record = rec.copyWith(videoUrl: v);
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video mise a jour')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec sauvegarde : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
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
          const SizedBox(height: 18),
          _sectionTitle('Photos de la fiche'),
          const SizedBox(height: 4),
          const Text(
            'Jusqu\'a 6 photos. Apparaissent dans l\'ordre sur la fiche detail.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _photoGrid(rec),
          const SizedBox(height: 22),
          _sectionTitle('Video teaser'),
          const SizedBox(height: 4),
          const Text(
            'Colle une URL MP4 publique (Cloudinary, Vimeo direct link, etc.).',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _videoCtrl,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: const TextStyle(color: AppColors.textFaint),
              filled: true,
              fillColor: AppColors.surfaceHi,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.lineStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.lineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Enregistrer la video',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

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
                    const Center(
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
        title: const Text('Supprimer cette photo ?',
            style: TextStyle(color: AppColors.text, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler',
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
          const Icon(Icons.info_outline, color: AppColors.textFaint, size: 32),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
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
