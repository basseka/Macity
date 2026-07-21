import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';

/// Une story en attente d'envoi (buffer offline). Persistee sur disque : ses
/// medias sont COPIES dans le dossier documents de l'app (les fichiers du
/// picker/camera vivent dans un cache que l'OS peut purger).
@immutable
class PendingStory {
  final String id; // clientId (UUID) — sert aussi de p_id cote RPC
  final String category;
  final String rawTitle;
  final double lat;
  final double lng;
  final String locationName;
  final String? osmId;
  final bool isPrivate;
  final List<String> photoPaths; // chemins PERSISTANTS (copies)
  final String? videoPath; // chemin PERSISTANT (copie)
  final DateTime createdAt;
  final int attempts;

  const PendingStory({
    required this.id,
    required this.category,
    required this.rawTitle,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.osmId,
    required this.isPrivate,
    required this.photoPaths,
    required this.videoPath,
    required this.createdAt,
    this.attempts = 0,
  });

  PendingStory copyWith({int? attempts}) => PendingStory(
        id: id,
        category: category,
        rawTitle: rawTitle,
        lat: lat,
        lng: lng,
        locationName: locationName,
        osmId: osmId,
        isPrivate: isPrivate,
        photoPaths: photoPaths,
        videoPath: videoPath,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'rawTitle': rawTitle,
        'lat': lat,
        'lng': lng,
        'locationName': locationName,
        'osmId': osmId,
        'isPrivate': isPrivate,
        'photoPaths': photoPaths,
        'videoPath': videoPath,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory PendingStory.fromJson(Map<String, dynamic> j) => PendingStory(
        id: j['id'] as String,
        category: (j['category'] as String?) ?? 'live',
        rawTitle: (j['rawTitle'] as String?) ?? 'Story Map Live',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        locationName: (j['locationName'] as String?) ?? '',
        osmId: j['osmId'] as String?,
        isPrivate: (j['isPrivate'] as bool?) ?? false,
        photoPaths:
            (j['photoPaths'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        videoPath: j['videoPath'] as String?,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );
}

/// File d'attente persistante des stories a envoyer des le retour du reseau.
///
/// - `enqueue` : copie les medias dans un dossier stable puis stocke l'entree.
/// - `flush`   : tente d'envoyer chaque entree via [ReportedEventsService].
/// - `remove`  : retire l'entree + supprime son dossier de medias.
class StoryOutboxService {
  StoryOutboxService(this._svc);

  final ReportedEventsService _svc;
  static const _prefsKey = 'story_outbox_v1';
  static const _uuid = Uuid();

  Future<Directory> _outboxDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'story_outbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<PendingStory>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => PendingStory.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('[Outbox] parse failed: $e');
      return const [];
    }
  }

  Future<void> _save(List<PendingStory> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Copie un fichier media dans le dossier stable de l'entree. Retourne le
  /// nouveau chemin, ou null si la source est introuvable.
  Future<String?> _persistMedia(String srcPath, Directory dstDir) async {
    try {
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final dst = p.join(dstDir.path, p.basename(srcPath));
      await src.copy(dst);
      return dst;
    } catch (e) {
      debugPrint('[Outbox] copy media failed ($srcPath): $e');
      return null;
    }
  }

  /// Met une story en file d'attente. Renvoie le [PendingStory] cree.
  Future<PendingStory> enqueue({
    required String category,
    required String rawTitle,
    required double lat,
    required double lng,
    required List<String> localPhotoPaths,
    required String? localVideoPath,
    required String locationName,
    required String? osmId,
    required bool isPrivate,
  }) async {
    final id = _uuid.v4();
    final dir = Directory(p.join((await _outboxDir()).path, id));
    await dir.create(recursive: true);

    final photoPaths = <String>[];
    for (final path in localPhotoPaths) {
      if (path.isEmpty) continue;
      final saved = await _persistMedia(path, dir);
      if (saved != null) photoPaths.add(saved);
    }
    String? videoPath;
    if (localVideoPath != null && localVideoPath.isNotEmpty) {
      videoPath = await _persistMedia(localVideoPath, dir);
    }

    final pending = PendingStory(
      id: id,
      category: category,
      rawTitle: rawTitle,
      lat: lat,
      lng: lng,
      locationName: locationName,
      osmId: osmId,
      isPrivate: isPrivate,
      photoPaths: photoPaths,
      videoPath: videoPath,
      createdAt: DateTime.now(),
    );

    final items = [...await list(), pending];
    await _save(items);
    debugPrint('[Outbox] enqueued $id (${photoPaths.length} photos, '
        'video=${videoPath != null})');
    return pending;
  }

  /// Supprime une entree + son dossier de medias.
  Future<void> remove(String id) async {
    final items = (await list()).where((e) => e.id != id).toList();
    await _save(items);
    try {
      final dir = Directory(p.join((await _outboxDir()).path, id));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('[Outbox] cleanup dir failed ($id): $e');
    }
  }

  /// Tente d'envoyer toutes les entrees. Renvoie le nombre envoye avec succes.
  /// Best-effort : une entree qui echoue reste en file (attempts++).
  /// Anti-boucle : re-entrance protegee par [_flushing].
  bool _flushing = false;
  Future<int> flush() async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      final items = await list();
      for (final s in items) {
        // Media disparu (cache purge avant copie) : on abandonne l'entree.
        final hasMedia = s.photoPaths.isNotEmpty || s.videoPath != null;
        if (!hasMedia) {
          await remove(s.id);
          continue;
        }
        try {
          await _svc.reportEvent(
            category: s.category,
            rawTitle: s.rawTitle,
            lat: s.lat,
            lng: s.lng,
            localPhotoPaths: s.photoPaths,
            localVideoPath: s.videoPath,
            locationName: s.locationName,
            osmId: s.osmId,
            isPrivate: s.isPrivate,
          );
          await remove(s.id);
          sent++;
          debugPrint('[Outbox] sent ${s.id}');
        } catch (e) {
          // Echec (reseau encore KO) : on garde, on incremente le compteur.
          debugPrint('[Outbox] send failed ${s.id}: $e');
          final updated = (await list())
              .map((e) => e.id == s.id ? e.copyWith(attempts: e.attempts + 1) : e)
              .toList();
          await _save(updated);
        }
      }
    } finally {
      _flushing = false;
    }
    return sent;
  }
}
