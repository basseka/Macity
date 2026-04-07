import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un seul ID de video actif a la fois dans le feed.
/// Quand un nouveau tile video devient visible, l'ancien est pause.
final activeVideoProvider = StateProvider<String?>((ref) => null);
