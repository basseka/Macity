import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/mode/domain/models/mode_search_cache.dart';

final modeSearchCacheProvider = Provider<ModeSearchCache>(
  (ref) => ModeSearchCache(),
);
