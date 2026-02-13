import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/pro_auth/data/pro_auth_service.dart';
import 'package:pulz_app/features/pro_auth/data/pro_session_service.dart';
import 'package:pulz_app/features/pro_auth/domain/models/pro_profile.dart';

enum ProAuthStatus { notConnected, pendingApproval, approved, loading }

class ProAuthState {
  final ProAuthStatus status;
  final ProProfile? profile;
  final bool isSubmitting;
  final String? error;

  const ProAuthState({
    this.status = ProAuthStatus.loading,
    this.profile,
    this.isSubmitting = false,
    this.error,
  });

  ProAuthState copyWith({
    ProAuthStatus? status,
    ProProfile? profile,
    bool? isSubmitting,
    String? error,
  }) {
    return ProAuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ProAuthNotifier extends StateNotifier<ProAuthState> {
  final ProAuthService _authService;
  final ProSessionService _sessionService;

  ProAuthNotifier(this._authService, this._sessionService)
      : super(const ProAuthState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final connected = await _sessionService.isConnected();
    if (!connected) {
      state = const ProAuthState(status: ProAuthStatus.notConnected);
      return;
    }
    final profile = await _sessionService.getProfile();
    if (profile == null) {
      state = const ProAuthState(status: ProAuthStatus.notConnected);
      return;
    }
    state = ProAuthState(
      status: profile.approved
          ? ProAuthStatus.approved
          : ProAuthStatus.pendingApproval,
      profile: profile,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String nom,
    required String type,
    required String telephone,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        nom: nom,
        type: type,
        telephone: telephone,
      );

      await _sessionService.saveSession(
        profile: result.profile,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      state = ProAuthState(
        status: ProAuthStatus.pendingApproval,
        profile: result.profile,
      );
    } catch (e) {
      debugPrint('[ProAuth] register error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: _parseError(e),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Email ou mot de passe incorrect',
        );
        return;
      }

      await _sessionService.saveSession(
        profile: result.profile,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      state = ProAuthState(
        status: result.profile.approved
            ? ProAuthStatus.approved
            : ProAuthStatus.pendingApproval,
        profile: result.profile,
      );
    } catch (e) {
      debugPrint('[ProAuth] login error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: _parseError(e),
      );
    }
  }

  Future<void> refreshStatus() async {
    try {
      final profile = await _sessionService.getProfile();
      final accessToken = await _sessionService.getAccessToken();
      final refreshTokenStr = await _sessionService.getRefreshToken();

      if (profile == null || accessToken == null || refreshTokenStr == null) {
        state = const ProAuthState(status: ProAuthStatus.notConnected);
        await _sessionService.clearSession();
        return;
      }

      // Rafraichir le token avant de fetch
      final newTokens = await _authService.refreshToken(refreshTokenStr);
      final token = newTokens?.accessToken ?? accessToken;
      if (newTokens != null) {
        await _sessionService.updateTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken,
        );
      }

      final updated = await _authService.fetchProfile(profile.userId, token);
      if (updated == null) {
        state = const ProAuthState(status: ProAuthStatus.notConnected);
        await _sessionService.clearSession();
        return;
      }

      await _sessionService.updateProfile(updated);

      state = ProAuthState(
        status: updated.approved
            ? ProAuthStatus.approved
            : ProAuthStatus.pendingApproval,
        profile: updated,
      );
    } catch (e) {
      debugPrint('[ProAuth] refreshStatus error: $e');
    }
  }

  Future<void> disconnect() async {
    await _sessionService.clearSession();
    state = const ProAuthState(status: ProAuthStatus.notConnected);
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user already registered')) {
      return 'Un compte existe deja avec cet email';
    }
    if (msg.contains('invalid login')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('password') && msg.contains('6')) {
      return 'Le mot de passe doit contenir au moins 6 caracteres';
    }
    return 'Une erreur est survenue. Veuillez reessayer.';
  }
}

final proAuthProvider =
    StateNotifierProvider<ProAuthNotifier, ProAuthState>(
  (ref) => ProAuthNotifier(ProAuthService(), ProSessionService()),
);
