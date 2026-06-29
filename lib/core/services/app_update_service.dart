import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Lit `app_versions` (Supabase) et compare avec la version locale (package_info_plus)
/// pour produire un [AppUpdateStatus]. Le call site decide ensuite quoi afficher
/// (ForceUpdateScreen vs UpdatePromptBanner) — ce service ne gere pas de UI.
///
/// Sur Android, declenche aussi le flow natif `in_app_update` (FLEXIBLE pour
/// suggere, IMMEDIATE pour force) qui offre l'UX Play Store integree.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// URL App Store de secours, utilisee si `app_versions.ios.store_url` est
  /// absent : evite que le bouton de l'ecran de forcage iOS (bloquant, sans
  /// bouton fermer) reste sans effet et piege l'utilisateur. (Apple ID 6778110272.)
  static const iosStoreFallbackUrl = 'https://apps.apple.com/app/id6778110272';

  AppUpdateStatus? _lastStatus;
  AppUpdateStatus? get lastStatus => _lastStatus;

  /// Lit la version locale + la row `app_versions` correspondant a la plateforme
  /// courante. Renvoie un statut consolide. En cas d'erreur reseau ou table
  /// vide, renvoie [AppUpdateStatus.uptoDate] pour ne jamais bloquer le user.
  ///
  /// Skip total si l'app n'est PAS installee depuis le Play Store (Android) ou
  /// l'App Store (iOS) — i.e. en `flutter run`, sideload APK ou TestFlight :
  /// inutile (et bloquant) de proposer une MAJ vers une version Play Store
  /// que le user n'a pas installee.
  Future<AppUpdateStatus> check() async {
    try {
      final platform = _platformKey();
      if (platform == null) {
        _lastStatus = const AppUpdateStatus.uptoDate();
        return _lastStatus!;
      }

      final pkg = await PackageInfo.fromPlatform();
      final local = pkg.version; // ex: "1.0.71"

      // Bypass si l'install ne vient pas du store officiel — evite la popup
      // sur tous les builds de dev / sideload / preview.
      if (!_isFromOfficialStore(pkg.installerStore)) {
        debugPrint(
          '[AppUpdate] skip check : installerStore="${pkg.installerStore}" '
          '(local=$local) — pas du Play Store/App Store',
        );
        _lastStatus = AppUpdateStatus.uptoDate(localVersion: local);
        return _lastStatus!;
      }

      final row = await _fetchRow(platform);
      if (row == null) {
        _lastStatus = AppUpdateStatus.uptoDate(localVersion: local);
        return _lastStatus!;
      }

      final latest = row['latest_version'] as String? ?? local;
      final min = row['min_version'] as String? ?? local;
      final force = row['force_update'] as bool? ?? false;
      final storeUrl = row['store_url'] as String?;
      final message = row['message'] as String?;

      final cmpMin = _compareSemver(local, min);
      final cmpLatest = _compareSemver(local, latest);

      AppUpdateStatus status;
      // Force update si :
      // - version locale < min_version (toujours, indep du flag)
      // - OU `force_update=true` ET version locale < latest_version (flag
      //   d'urgence qui upgrade un "update available" en "force update"
      //   sans avoir a bumper min_version).
      // Si local >= latest, on ne force JAMAIS (eviter de bloquer un user
      // qui vient juste d'installer la derniere version).
      if (cmpMin < 0 || (force && cmpLatest < 0)) {
        status = AppUpdateStatus.forceUpdate(
          localVersion: local,
          latestVersion: latest,
          storeUrl: storeUrl,
          message: message,
        );
      } else if (cmpLatest < 0) {
        status = AppUpdateStatus.updateAvailable(
          localVersion: local,
          latestVersion: latest,
          storeUrl: storeUrl,
          message: message,
        );
      } else {
        status = AppUpdateStatus.uptoDate(localVersion: local);
      }

      _lastStatus = status;
      return status;
    } catch (e) {
      debugPrint('[AppUpdate] check failed: $e');
      _lastStatus = const AppUpdateStatus.uptoDate();
      return _lastStatus!;
    }
  }

  /// Tente le flow natif Play Store (Android only). Returns true si l'UX
  /// native a pris le relai (caller peut sortir de l'ecran/banner). En cas
  /// d'echec ou plateforme non supportee, renvoie false → caller fallback
  /// sur url_launcher vers store_url.
  Future<bool> tryNativeFlow({required bool immediate}) async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (immediate) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
      return true;
    } catch (e) {
      debugPrint('[AppUpdate] native flow failed: $e');
      return false;
    }
  }

  String? _platformKey() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  /// True si l'app a ete installee depuis le Play Store (Android) ou
  /// l'App Store (iOS). Sinon : dev build, sideload, TestFlight, etc.
  ///
  /// `installerStore` est null en debug/flutter run et contient :
  /// - `com.android.vending` : Play Store
  /// - `com.apple.AppStore`  : App Store iOS (peut aussi etre null en
  ///   TestFlight selon la version d'iOS)
  bool _isFromOfficialStore(String? installerStore) {
    // Android : on exige le Play Store (le flow natif in-app-update en depend).
    if (Platform.isAndroid) return installerStore == 'com.android.vending';
    // iOS : `installerStore` est NON FIABLE (null/`com.apple.testflight` en
    // TestFlight, souvent null meme depuis l'App Store) -> s'y fier sautait le
    // check et cassait le forcage iOS. On se base sur le mode release : un
    // build release = distribue (TestFlight/App Store), le forcage doit donc
    // s'appliquer. En debug (flutter run) on skip pour ne pas bloquer le dev.
    if (Platform.isIOS) return kReleaseMode;
    return false;
  }

  Future<Map<String, dynamic>?> _fetchRow(String platform) async {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final response = await dio.get(
      'app_versions',
      queryParameters: {
        'select': 'latest_version,min_version,force_update,store_url,message',
        'platform': 'eq.$platform',
        'limit': '1',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return null;
    return data.first as Map<String, dynamic>;
  }

  /// Compare deux versions semver simples (`major.minor.patch`, sans suffixe).
  /// Retourne <0 si a<b, 0 si egal, >0 si a>b. Tolere les chaines partielles.
  static int _compareSemver(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final av = i < pa.length ? pa[i] : 0;
      final bv = i < pb.length ? pb[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }
}

/// Statut consolide produit par [AppUpdateService.check].
sealed class AppUpdateStatus {
  const AppUpdateStatus();

  const factory AppUpdateStatus.uptoDate({String? localVersion}) = _UptoDate;
  const factory AppUpdateStatus.updateAvailable({
    required String localVersion,
    required String latestVersion,
    String? storeUrl,
    String? message,
  }) = _UpdateAvailable;
  const factory AppUpdateStatus.forceUpdate({
    required String localVersion,
    required String latestVersion,
    String? storeUrl,
    String? message,
  }) = _ForceUpdate;

  bool get isForceUpdate => this is _ForceUpdate;
  bool get isUpdateAvailable => this is _UpdateAvailable;
}

class _UptoDate extends AppUpdateStatus {
  final String? localVersion;
  const _UptoDate({this.localVersion});
}

class _UpdateAvailable extends AppUpdateStatus {
  final String localVersion;
  final String latestVersion;
  final String? storeUrl;
  final String? message;
  const _UpdateAvailable({
    required this.localVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
  });
}

class _ForceUpdate extends AppUpdateStatus {
  final String localVersion;
  final String latestVersion;
  final String? storeUrl;
  final String? message;
  const _ForceUpdate({
    required this.localVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
  });
}

/// Helpers d'extraction sur le statut (sortie type-safe sans pattern matching).
extension AppUpdateStatusFields on AppUpdateStatus {
  String? get latestVersion {
    final s = this;
    if (s is _UpdateAvailable) return s.latestVersion;
    if (s is _ForceUpdate) return s.latestVersion;
    return null;
  }

  String? get storeUrl {
    final s = this;
    if (s is _UpdateAvailable) return s.storeUrl;
    if (s is _ForceUpdate) return s.storeUrl;
    return null;
  }

  /// URL store a ouvrir effectivement, avec fallback App Store sur iOS si la
  /// base ne fournit pas de store_url (sinon l'ecran de forcage iOS — bloquant
  /// — aurait un bouton sans effet => cul-de-sac). Android : pas de fallback
  /// (le flow natif in-app-update prend le relai, et store_url est attendu).
  String? get effectiveStoreUrl {
    final url = storeUrl;
    if (url != null && url.isNotEmpty) return url;
    if (Platform.isIOS) return AppUpdateService.iosStoreFallbackUrl;
    return null;
  }

  String? get message {
    final s = this;
    if (s is _UpdateAvailable) return s.message;
    if (s is _ForceUpdate) return s.message;
    return null;
  }
}
