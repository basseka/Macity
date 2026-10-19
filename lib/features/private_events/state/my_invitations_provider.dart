import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/private_events/data/private_event_service.dart';

/// Nombre de soirees privees a venir auxquelles ce device a confirme sa
/// venue ("Je viens"). Sert a l'indicateur discret sur l'avatar de Home
/// (petit point) : 0 = rien affiche, >0 = au moins une invitation en cours.
final myInvitationsCountProvider = FutureProvider<int>((ref) async {
  try {
    final uuid = await UserIdentityService.getUserId();
    final invitations =
        await PrivateEventService().listMyInvitations(userId: uuid);
    // Les soirees passees restent dans la liste (album, discussion) : le
    // point ne compte que celles a venir.
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return invitations.where((e) {
      final d = DateTime.tryParse(e.date);
      return d == null || !d.isBefore(todayDate);
    }).length;
  } catch (_) {
    return 0;
  }
});
