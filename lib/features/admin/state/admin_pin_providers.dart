import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/admin/data/admin_pin_service.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Email hardcode pour l'admin actuel (MaCity-France).
/// Future: remplacer par une colonne `is_admin` sur pro_profiles.
const String kAdminEmail = 'basseka@yahoo.fr';

/// True si le pro connecte est l'admin MaCity.
/// NB : on accepte tous les status (approved, pendingApproval) tant que
/// l'email correspond. Si approved=false, le pin echouera cote serveur de
/// toute facon (RLS), on n'a pas besoin de bloquer l'UI.
final isAdminProvider = Provider<bool>((ref) {
  final auth = ref.watch(proAuthProvider);
  final email = auth.profile?.email.toLowerCase();
  if (email == null) return false;
  return email == kAdminEmail.toLowerCase();
});

final adminPinServiceProvider =
    Provider<AdminPinService>((ref) => AdminPinService());

/// Tous les pins actifs (pinned_until > now). Refresh manuel via invalidation.
final activeAdminPinsProvider =
    FutureProvider<List<AdminPin>>((ref) async {
  final svc = ref.watch(adminPinServiceProvider);
  return svc.fetchActivePins();
});

/// Helper : lookup d'un pin pour un event donne (permet d'afficher le badge
/// "epingle" sur les cards).
///
/// Match par `identifiant` uniquement, pas par `source`. Le feed insere
/// historiquement avec un mauvais `source` (cf bug feed_screen.dart) — le
/// service auto-detecte le bon source desormais, mais des rows orphelines
/// existent encore en DB. Le match laxe permet de voir le pin existant
/// quoiqu'il arrive.
final pinForEventProvider = Provider.family<AdminPin?, ({AdminPinSource source, String identifiant})>((ref, key) {
  final pins = ref.watch(activeAdminPinsProvider).maybeWhen(
        data: (d) => d,
        orElse: () => const <AdminPin>[],
      );
  for (final p in pins) {
    if (p.identifiant == key.identifiant) return p;
  }
  return null;
});

/// Liste des identifiants de pins "featured" actifs (pour merge dans Weekend Picks).
final featuredPinIdsProvider =
    Provider<Set<({AdminPinSource source, String identifiant})>>((ref) {
  final pins = ref.watch(activeAdminPinsProvider).maybeWhen(
        data: (d) => d,
        orElse: () => const <AdminPin>[],
      );
  return {
    for (final p in pins)
      if (p.pinType == AdminPinType.featured)
        (source: p.source, identifiant: p.identifiant),
  };
});

/// Liste des identifiants de pins "top" actifs.
final topPinIdsProvider =
    Provider<Set<({AdminPinSource source, String identifiant})>>((ref) {
  final pins = ref.watch(activeAdminPinsProvider).maybeWhen(
        data: (d) => d,
        orElse: () => const <AdminPin>[],
      );
  return {
    for (final p in pins)
      if (p.pinType == AdminPinType.top)
        (source: p.source, identifiant: p.identifiant),
  };
});
