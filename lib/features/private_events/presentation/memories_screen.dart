import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';
import 'package:pulz_app/features/private_events/presentation/event_album_screen.dart';
import 'package:pulz_app/features/private_events/presentation/private_event_chat_screen.dart';

/// « Mes souvenirs » : les events prives passes que j'ai organises ou ou
/// j'etais inscrit, du plus recent au plus ancien, avec une mosaique des
/// photos de l'album. Ouvre l'album, le diaporama ou la discussion.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _service = PrivateEventService();
  late Future<List<PrivateEventMemory>> _future = _load();

  Future<List<PrivateEventMemory>> _load() async {
    final uid = await UserIdentityService.getUserId();
    return _service.listMemories(userId: uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        title: Text(
          'Mes souvenirs',
          style: GoogleFonts.geist(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
      ),
      body: FutureBuilder<List<PrivateEventMemory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.magenta));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) return _empty();
          return RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _MemoryCard(memory: list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 48, color: AppColors.magenta),
              const SizedBox(height: 12),
              Text('Pas encore de souvenirs',
                  style: GoogleFonts.geist(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              Text(
                'Tes soirées privées passées (organisées ou où tu étais inscrit) '
                'apparaîtront ici avec leurs photos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.geist(fontSize: 13, color: AppColors.textDim),
              ),
            ],
          ),
        ),
      );
}

class _MemoryCard extends StatelessWidget {
  final PrivateEventMemory memory;
  const _MemoryCard({required this.memory});

  String get _dateLabel {
    final d = DateTime.tryParse(memory.date);
    if (d == null) return memory.date;
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d);
  }

  /// Fin de la periode d'ajout de photos (J+7).
  String? get _openUntil {
    final d = DateTime.tryParse(memory.date);
    if (d == null || memory.archived) return null;
    return DateFormat('d MMM', 'fr_FR').format(d.add(const Duration(days: 7)));
  }

  void _openAlbum(BuildContext context, {bool slideshow = false}) => EventAlbumScreen.open(
        context,
        token: memory.accessToken,
        title: memory.title,
        isHost: memory.isHost,
        startSlideshow: slideshow,
        archived: memory.archived,
      );

  @override
  Widget build(BuildContext context) {
    final m = memory;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAlbum(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Mosaic(preview: m.preview, fallback: m.photoUrl, photoCount: m.photoCount),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.geist(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Tag(
                        m.isHost ? 'Organisateur' : 'Invité',
                        m.isHost ? AppColors.magenta : const Color(0xFF00B4D8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [_dateLabel, if (m.lieu.isNotEmpty) m.lieu].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.geist(fontSize: 12, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m.photoCount} photo${m.photoCount > 1 ? 's' : ''} · '
                    '${m.participants} participant${m.participants > 1 ? 's' : ''}'
                    '${_openUntil != null ? ' · ajout de photos jusqu\'au $_openUntil' : ''}',
                    style: GoogleFonts.geist(fontSize: 11, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _Action(
                  icon: Icons.play_circle_outline,
                  label: 'Diaporama',
                  enabled: m.photoCount > 0,
                  onTap: () => _openAlbum(context, slideshow: true),
                ),
                _Action(
                  icon: Icons.photo_library_outlined,
                  label: 'Album',
                  onTap: () => _openAlbum(context),
                ),
                _Action(
                  icon: Icons.forum_outlined,
                  label: 'Discussion',
                  onTap: () => PrivateEventChatScreen.open(
                    context,
                    token: m.accessToken,
                    title: m.title,
                    isHost: m.isHost,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Mosaique de couverture : 1 a 4 photos de l'album, sinon l'affiche de
/// l'event, sinon un fond degrade.
class _Mosaic extends StatelessWidget {
  final List<String> preview;
  final String? fallback;
  final int photoCount;
  const _Mosaic({required this.preview, required this.fallback, required this.photoCount});

  Widget _img(String url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        placeholder: (_, __) => Container(color: AppColors.surfaceHi),
        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceHi),
      );

  @override
  Widget build(BuildContext context) {
    final urls = preview.isNotEmpty
        ? preview
        : (fallback != null && fallback!.isNotEmpty ? [fallback!] : <String>[]);
    Widget content;
    if (urls.isEmpty) {
      content = Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: const Center(child: Icon(Icons.celebration, color: Colors.white, size: 40)),
      );
    } else if (urls.length == 1) {
      content = _img(urls[0]);
    } else if (urls.length == 2) {
      content = Row(children: [
        Expanded(child: _img(urls[0])),
        const SizedBox(width: 2),
        Expanded(child: _img(urls[1])),
      ]);
    } else {
      content = Row(children: [
        Expanded(flex: 2, child: _img(urls[0])),
        const SizedBox(width: 2),
        Expanded(
          child: Column(children: [
            Expanded(child: _img(urls[1])),
            const SizedBox(height: 2),
            Expanded(child: _img(urls[2])),
            if (urls.length > 3) ...[
              const SizedBox(height: 2),
              Expanded(child: _img(urls[3])),
            ],
          ]),
        ),
      ]);
    }
    return SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (photoCount > 0)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_camera_outlined, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('$photoCount',
                      style: GoogleFonts.geist(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.geist(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _Action({required this.icon, required this.label, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.magenta : AppColors.textFaint;
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.geist(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}
