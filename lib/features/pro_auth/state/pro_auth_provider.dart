import 'package:dio/dio.dart';
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
    debugPrint('[ProAuth] _loadSession: isConnected=$connected');
    if (!connected) {
      state = const ProAuthState(status: ProAuthStatus.notConnected);
      return;
    }
    final profile = await _sessionService.getProfile();
    debugPrint('[ProAuth] _loadSession: profile=${profile?.nom ?? "null"} approved=${profile?.approved}');
    if (profile == null) {
      state = const ProAuthState(status: ProAuthStatus.notConnected);
      return;
    }

    // Toujours rafraichir le profil depuis Supabase pour avoir le statut a jour
    state = ProAuthState(
      status: profile.approved
          ? ProAuthStatus.approved
          : ProAuthStatus.pendingApproval,
      profile: profile,
    );
    // Rafraichir en arriere-plan sans bloquer l'UI
    refreshStatus();
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
      debugPrint(
        '[ProAuth] refreshStatus reads: profile=${profile != null} '
        'accessToken=${accessToken != null} refreshToken=${refreshTokenStr != null}',
      );

      // Si un des reads secure storage renvoie null, on NE VIRE PAS la
      // session. Ca peut arriver sur iOS avant "first unlock" complet apres
      // un reboot, ou lors d'une race condition au cold start. On laisse la
      // session telle que chargee par _loadSession (base sur le cache local).
      // Un vrai logout ne passe que par l'action "Se deconnecter".
      if (profile == null || accessToken == null || refreshTokenStr == null) {
        debugPrint(
          '[ProAuth] refreshStatus: partial null reads, keeping cached session '
          '(do NOT clear — probably transient keychain hiccup)',
        );
        return;
      }

      // Rafraichir le token. Si ca rate (reseau, timeout, etc.), on garde
      // l'ancien access token pour tenter fetchProfile quand meme, MAIS on
      // n'efface rien : au pire la session reste telle quelle jusqu'a la
      // prochaine fois ou le reseau marche.
      final newTokens = await _authService.refreshToken(refreshTokenStr);
      final token = newTokens?.accessToken ?? accessToken;
      if (newTokens != null) {
        await _sessionService.updateTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken,
        );
      }

      // fetchProfile peut renvoyer null pour plusieurs raisons :
      //   1. Reseau indisponible (glitch, sortie de tunnel, Wi-Fi qui switch)
      //   2. Token expire (401) — rare ici car on vient de le refresh
      //   3. Profil supprime cote DB (legitime)
      // Impossible de distinguer 1 de 3 depuis le catch actuel. On prefere
      // garder la session locale pour ne PAS logout l'user a chaque glitch
      // reseau. Si le profil a vraiment ete supprime, un appel API en echec
      // le forcera a se reconnecter plus tard de lui-meme.
      final updated = await _authService.fetchProfile(profile.userId, token);
      if (updated == null) {
        debugPrint(
          '[ProAuth] fetchProfile returned null — keeping cached session '
          '(probably network error, not a real logout)',
        );
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
      // Ici aussi : ne pas clearSession. Les erreurs imprevues ne doivent pas
      // deconnecter l'user ; le state reste celui charge depuis le cache local.
      debugPrint('[ProAuth] refreshStatus error: $e');
    }
  }

  /// Verifie le code 6-chiffres recu par mail. Si match, passe en approved.
  /// Retourne true si verifie, false si code incorrect.
  Future<bool> verifyCode(String code) async {
    final accessToken = await _sessionService.getAccessToken();
    if (accessToken == null) return false;

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final ok = await _authService.verifyApprovalCode(
        code: code,
        accessToken: accessToken,
      );
      if (!ok) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Code incorrect',
        );
        return false;
      }
      // Refresh pour recuperer approved=true + mettre a jour le state
      await refreshStatus();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('[ProAuth] verifyCode error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  /// Demande le renvoi d'un nouveau code par mail.
  Future<void> resendCode() async {
    final accessToken = await _sessionService.getAccessToken();
    if (accessToken == null) return;
    try {
      await _authService.resendApprovalCode(accessToken: accessToken);
    } catch (e) {
      debugPrint('[ProAuth] resendCode error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _sessionService.clearSession();
    state = const ProAuthState(status: ProAuthStatus.notConnected);
  }

  String _parseError(Object e) {
    // Extraire le vrai message Supabase depuis DioException
    String msg = e.toString().toLowerCase();
    if (e is DioException && e.response?.data is Map) {
      final body = e.response!.data as Map;
      final supaMsg = (body['error_description'] ??
              body['msg'] ??
              body['message'] ??
              body['error'] ??
              '')
          .toString()
          .toLowerCase();
      if (supaMsg.isNotEmpty) msg = supaMsg;
    }

    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Un compte existe deja avec cet email';
    }
    if (msg.contains('invalid login') ||
        msg.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Veuillez confirmer votre email. Verifiez votre boite de reception.';
    }
    if (msg.contains('password') && (msg.contains('6') || msg.contains('short') || msg.contains('weak'))) {
      return 'Le mot de passe doit contenir au moins 6 caracteres';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erreur de connexion. Verifiez votre internet.';
    }

    debugPrint('[ProAuth] Erreur non mappee: $msg');
    return 'Une erreur est survenue. Veuillez reessayer.';
  }
}

final proAuthProvider =
    StateNotifierProvider<ProAuthNotifier, ProAuthState>(
  (ref) => ProAuthNotifier(ProAuthService(), ProSessionService()),
);
