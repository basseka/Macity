class ModeSearchCache {
  final Map<String, List<dynamic>> _cache = {};

  void put(String key, List<dynamic> results) {
    _cache[key] = results;
  }

  List<dynamic>? get(String key) => _cache[key];

  void clear() => _cache.clear();

  void clearForMode(String mode) {
    _cache.removeWhere((key, _) => key.startsWith(mode));
  }

  bool has(String key) => _cache.containsKey(key);
}
