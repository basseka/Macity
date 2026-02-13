import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/notifications/data/notification_prefs_service.dart';

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  final NotificationPrefsService _service;

  NotificationPrefsNotifier(this._service)
      : super(const NotificationPrefs()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _service.fetch();
    } catch (e) {
      debugPrint('[NotifPrefs] fetch failed: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _save();
  }

  Future<void> setRemind15d(bool value) async {
    state = state.copyWith(remind15d: value);
    await _save();
  }

  Future<void> setRemind1d(bool value) async {
    state = state.copyWith(remind1d: value);
    await _save();
  }

  Future<void> setRemind1h(bool value) async {
    state = state.copyWith(remind1h: value);
    await _save();
  }

  Future<void> _save() async {
    try {
      await _service.upsert(state);
    } catch (e) {
      debugPrint('[NotifPrefs] save failed: $e');
    }
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  (ref) => NotificationPrefsNotifier(NotificationPrefsService()),
);
