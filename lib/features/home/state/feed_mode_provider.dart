import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'affichage du feed principal.
/// - [classic] : feed standard avec "À la une" + "Au top" en haut
/// - [feed2]   : feed alternatif sans les carrousels boostés
enum FeedMode { classic, feed2 }

final feedModeProvider = StateProvider<FeedMode>((ref) => FeedMode.classic);
