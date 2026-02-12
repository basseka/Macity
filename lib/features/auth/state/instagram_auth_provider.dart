import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/auth/data/instagram_auth_service.dart';

class InstagramAuthNotifier extends StateNotifier<InstagramAuthState> {
  final InstagramAuthService _service;

  InstagramAuthNotifier(this._service) : super(const InstagramAuthState()) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final connected = await _service.isConnected();
    final username = await _service.getConnectedUsername();
    state = InstagramAuthState(isConnected: connected, username: username);
  }

  Future<String?> startAuth() async {
    return _service.getAuthUrl();
  }

  Future<void> handleCallback(String code) async {
    state = state.copyWith(isLoading: true);
    final result = await _service.exchangeCode(code);
    if (result.success) {
      state = InstagramAuthState(
        isConnected: true,
        username: result.username,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = const InstagramAuthState();
  }
}

class InstagramAuthState {
  final bool isConnected;
  final String? username;
  final bool isLoading;
  final String? error;

  const InstagramAuthState({
    this.isConnected = false,
    this.username,
    this.isLoading = false,
    this.error,
  });

  InstagramAuthState copyWith({
    bool? isConnected,
    String? username,
    bool? isLoading,
    String? error,
  }) {
    return InstagramAuthState(
      isConnected: isConnected ?? this.isConnected,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final instagramAuthProvider =
    StateNotifierProvider<InstagramAuthNotifier, InstagramAuthState>(
  (ref) => InstagramAuthNotifier(InstagramAuthService()),
);
