import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';
import 'package:pulz_app/features/admin/state/admin_pin_providers.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/pro_auth/data/pro_auth_service.dart';
import 'package:pulz_app/features/pro_auth/data/pro_session_service.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

/// Rafraichit l'access_token Supabase Auth avant un appel admin (pin/unpin).
/// L'access_token dure ~1h ; sans refresh, un admin qui pinne apres avoir
/// laisse l'app ouverte plusieurs heures se prend un 401 → "Echec".
/// Si le refresh echoue, fallback sur le token stocke (potentiellement expire) :
/// le call renverra 401 avec un log clair plutot que rien.
Future<String?> _getFreshAdminToken() async {
  final session = ProSessionService();
  final refreshTok = await session.getRefreshToken();
  if (refreshTok != null) {
    try {
      final fresh = await ProAuthService().refreshToken(refreshTok);
      if (fresh != null) {
        await session.updateTokens(
          accessToken: fresh.accessToken,
          refreshToken: fresh.refreshToken,
        );
        return fresh.accessToken;
      }
    } catch (e) {
      debugPrint('[AdminPin] refreshToken failed, fallback: $e');
    }
  }
  return session.getAccessToken();
}

/// Wrapper qui ajoute un appui-long sur le [child] pour l'admin connecte.
/// Le menu propose "À la une" / "Au top" (ou "Dépingler" si deja pinne).
/// Si l'user n'est pas admin, retourne [child] tel quel (zero overhead).
class AdminPinGesture extends ConsumerWidget {
  final Widget child;
  final AdminPinSource source;
  final String identifiant;

  /// Nom de l'event (pour l'affichage dans le popup).
  final String eventName;

  /// Date de fin de l'event au format "YYYY-MM-DD". Si vide ou invalide,
  /// fallback a date_debut + 7 jours.
  final String dateFin;

  /// Fallback si dateFin est vide (ex: date de debut de l'event).
  final String? dateDebutFallback;

  const AdminPinGesture({
    super.key,
    required this.child,
    required this.source,
    required this.identifiant,
    required this.eventName,
    required this.dateFin,
    this.dateDebutFallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => _showMenu(context, ref),
      child: child,
    );
  }

  DateTime _computePinnedUntil() {
    // Parse date_debut et date_fin (YYYY-MM-DD).
    DateTime? debut;
    DateTime? fin;
    if (dateDebutFallback != null && dateDebutFallback!.isNotEmpty) {
      try { debut = DateTime.parse(dateDebutFallback!); } catch (_) {}
    }
    if (dateFin.isNotEmpty) {
      try { fin = DateTime.parse(dateFin); } catch (_) {}
    }
    // Soiree qui deborde sur le lendemain (date_fin > date_debut) :
    // disparait a 05h00 du matin de date_fin, qq soit heure_fin affichee.
    // Une soiree finie a 06h n'a plus de raison d'etre A la une a midi.
    if (debut != null && fin != null && fin.isAfter(debut)) {
      return DateTime(fin.year, fin.month, fin.day, 5, 0, 0);
    }
    // Event single-day (ou pas de date_fin) : fin de journee de date_fin (ou
    // date_debut en fallback) pour rester visible tout son dernier jour.
    final base = fin ?? debut ?? DateTime.now().add(const Duration(days: 30));
    return DateTime(base.year, base.month, base.day, 23, 59, 59);
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final existing = ref.read(pinForEventProvider((source: source, identifiant: identifiant)));
    final pinnedUntil = _computePinnedUntil();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Épingler cet event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                eventName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Visible jusqu\'au ${_formatDate(pinnedUntil)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 12),
              _PinButton(
                label: 'À la une',
                subtitle: 'Carousel mis en avant du feed',
                icon: Icons.star_rounded,
                color: const Color(0xFFFFC107),
                active: existing?.pinType == AdminPinType.featured,
                onTap: () => _doPin(ctx, ref, AdminPinType.featured, pinnedUntil),
              ),
              const SizedBox(height: 6),
              _PinButton(
                label: 'Au top',
                subtitle: 'Haut de la liste chronologique',
                icon: Icons.vertical_align_top_rounded,
                color: const Color(0xFF4CAF50),
                active: existing?.pinType == AdminPinType.top,
                onTap: () => _doPin(ctx, ref, AdminPinType.top, pinnedUntil),
              ),
              if (existing != null) ...[
                const SizedBox(height: 6),
                _PinButton(
                  label: 'Dépingler',
                  subtitle: 'Retirer ce pin',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFF44336),
                  active: false,
                  onTap: () => _doUnpin(ctx, ref, existing.pinType, existing.source),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _doPin(
    BuildContext ctx,
    WidgetRef ref,
    AdminPinType type,
    DateTime until,
  ) async {
    final navigator = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    final service = ref.read(adminPinServiceProvider);
    final auth = ref.read(proAuthProvider);
    final token = await _getFreshAdminToken();
    if (token == null) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Session expirée')));
      return;
    }
    final ok = await service.pin(
      source: source,
      identifiant: identifiant,
      pinType: type,
      pinnedUntil: until,
      accessToken: token,
      adminEmail: auth.profile?.email,
    );
    if (!navigator.mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (type == AdminPinType.featured
                ? 'Épinglé à la une ✨'
                : 'Épinglé au top ⬆️')
            : 'Échec de l\'épinglage'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (ok) {
      ref.invalidate(activeAdminPinsProvider);
      ref.invalidate(boostedEventsProvider);
      ref.invalidate(boostedP2EventsProvider);
    }
  }

  Future<void> _doUnpin(
    BuildContext ctx,
    WidgetRef ref,
    AdminPinType type,
    AdminPinSource actualSource,
  ) async {
    final navigator = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    final service = ref.read(adminPinServiceProvider);
    final token = await _getFreshAdminToken();
    if (token == null) {
      navigator.pop();
      return;
    }
    // On utilise le source REEL de la row en DB (recupere via `existing`)
    // plutot que le `source` du widget : le feed peut hardcoder un source
    // different de celui sous lequel le pin est stocke.
    final ok = await service.unpin(
      source: actualSource,
      identifiant: identifiant,
      pinType: type,
      accessToken: token,
    );
    if (!navigator.mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Dépinglé' : 'Échec'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (ok) {
      ref.invalidate(activeAdminPinsProvider);
      ref.invalidate(boostedEventsProvider);
      ref.invalidate(boostedP2EventsProvider);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _PinButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _PinButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, color: color, size: 12),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
