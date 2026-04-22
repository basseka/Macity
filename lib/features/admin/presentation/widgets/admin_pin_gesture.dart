import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';
import 'package:pulz_app/features/admin/state/admin_pin_providers.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/pro_auth/data/pro_session_service.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

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
    // Parse date_fin (YYYY-MM-DD) ; fallback sur dateDebutFallback + 7 jours ;
    // ultime fallback : now + 30 jours.
    DateTime? base;
    for (final candidate in [dateFin, dateDebutFallback]) {
      if (candidate != null && candidate.isNotEmpty) {
        try {
          base = DateTime.parse(candidate);
          break;
        } catch (_) {}
      }
    }
    base ??= DateTime.now().add(const Duration(days: 30));
    // Fin de journee (23:59:59) pour que l'event reste visible tout son dernier jour.
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
                  onTap: () => _doUnpin(ctx, ref, existing.pinType),
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
    final token = await ProSessionService().getAccessToken();
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
  ) async {
    final navigator = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    final service = ref.read(adminPinServiceProvider);
    final token = await ProSessionService().getAccessToken();
    if (token == null) {
      navigator.pop();
      return;
    }
    final ok = await service.unpin(
      source: source,
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
