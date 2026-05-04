// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'private_event.freezed.dart';
part 'private_event.g.dart';

/// Soiree privee creee par un hote (vue complete : retourne par
/// create_private_event et list_my_private_events).
/// Inclut access_token + passcode pour permettre a l'hote de re-partager.
@freezed
class PrivateEvent with _$PrivateEvent {
  const factory PrivateEvent({
    required String id,
    @JsonKey(name: 'host_device_uuid') required String hostDeviceUuid,
    required String title,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @Default('') String lieu,
    @Default('') String adresse,
    required String date, // YYYY-MM-DD
    @Default('') String heure,
    @Default('') String description,
    @JsonKey(name: 'access_token') required String accessToken,
    required String passcode,
    @JsonKey(name: 'max_opens') @Default(50) int maxOpens,
    @JsonKey(name: 'open_count') @Default(0) int openCount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _PrivateEvent;

  factory PrivateEvent.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventFromJson(json);
}

/// Vue invite : retournee par open_private_event. Pas de passcode, pas de
/// host_device_uuid (on ne revele pas l'hote a l'invite). [accessToken] est
/// rempli uniquement par list_my_invitations (l'invite a deja prouve qu'il
/// connait token+passcode au moment du RSVP) ; null pour open_private_event
/// qui ne le renvoie pas (le caller le possede deja).
@freezed
class PrivateEventReveal with _$PrivateEventReveal {
  const factory PrivateEventReveal({
    required String id,
    required String title,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @Default('') String lieu,
    @Default('') String adresse,
    required String date,
    @Default('') String heure,
    @Default('') String description,
    @JsonKey(name: 'open_count') @Default(0) int openCount,
    @JsonKey(name: 'max_opens') @Default(0) int maxOpens,
    @Default([]) List<PrivateEventRsvp> rsvps,
    @JsonKey(name: 'access_token') String? accessToken,
  }) = _PrivateEventReveal;

  factory PrivateEventReveal.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventRevealFromJson(json);
}

/// Un acceptant ("Je viens") d'une soiree privee. prenom + avatar_url joints
/// depuis user_profiles cote SQL. Peuvent etre null si l'utilisateur n'a pas
/// rempli son onboarding.
@freezed
class PrivateEventRsvp with _$PrivateEventRsvp {
  const factory PrivateEventRsvp({
    @JsonKey(name: 'user_id') required String userId,
    String? prenom,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PrivateEventRsvp;

  factory PrivateEventRsvp.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventRsvpFromJson(json);
}
