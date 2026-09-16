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
    return invitations.length;
  } catch (_) {
    return 0;
  }
});
