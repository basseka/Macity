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
    /// L'hote demande aux participants de confirmer leur venue (formulaire
    /// nom, prenom, e-mail, age, telephone).
    @JsonKey(name: 'confirmation_requise') @Default(false) bool confirmationRequise,
    /// Nombre maximum de participants ; null = illimite.
    @JsonKey(name: 'max_participants') int? maxParticipants,
    /// Nombre d'inscrits (« Je viens »), renvoye par list_my_private_events.
    @JsonKey(name: 'rsvp_count') @Default(0) int rsvpCount,
    /// Participants ayant confirme leur venue (list_my_private_events).
    @JsonKey(name: 'confirmed_count') @Default(0) int confirmedCount,
    /// Photos de l'album (discussion de groupe), list_my_private_events.
    @JsonKey(name: 'photo_count') @Default(0) int photoCount,
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
    PrivateEventHost? host,
    @JsonKey(name: 'confirmation_requise') @Default(false) bool confirmationRequise,
    @JsonKey(name: 'max_participants') int? maxParticipants,
    @JsonKey(name: 'photo_count') @Default(0) int photoCount,
  }) = _PrivateEventReveal;

  factory PrivateEventReveal.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventRevealFromJson(json);
}

/// Profil PUBLIC de l'organisateur montre aux invites (pas d'identifiant ni
/// de coordonnees). Null si l'hote n'a pas de profil.
@freezed
class PrivateEventHost with _$PrivateEventHost {
  const factory PrivateEventHost({
    String? prenom,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? ville,
    String? bio,
  }) = _PrivateEventHost;

  factory PrivateEventHost.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventHostFromJson(json);
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
    /// A rempli le formulaire de confirmation (seul ce booleen est public :
    /// les infos personnelles ne sont lisibles que par l'hote).
    @Default(false) bool confirmed,
  }) = _PrivateEventRsvp;

  factory PrivateEventRsvp.fromJson(Map<String, dynamic> json) =>
      _$PrivateEventRsvpFromJson(json);
}

/// Infos de confirmation de venue d'un participant. Lues par l'hote
/// (host_list_event_confirmations, avec [pseudo]) ou par le participant
/// lui-meme pour pre-remplir le formulaire (get_my_private_event_confirmation).
class PrivateEventConfirmation {
  final String? userId;
  final String? pseudo;
  final String? avatarUrl;
  final String nom;
  final String prenom;
  final String email;
  final int? age;
  final String tel;
  final DateTime? confirmedAt;

  const PrivateEventConfirmation({
    this.userId,
    this.pseudo,
    this.avatarUrl,
    this.nom = '',
    this.prenom = '',
    this.email = '',
    this.age,
    this.tel = '',
    this.confirmedAt,
  });

  bool get isConfirmed => confirmedAt != null;

  factory PrivateEventConfirmation.fromJson(Map<String, dynamic> json) =>
      PrivateEventConfirmation(
        userId: json['user_id'] as String?,
        pseudo: json['pseudo'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        email: json['email'] as String? ?? '',
        age: (json['age'] as num?)?.toInt(),
        tel: json['tel'] as String? ?? '',
        confirmedAt: json['confirmed_at'] == null
            ? null
            : DateTime.tryParse(json['confirmed_at'] as String),
      );
}

/// Photo de l'album d'un event (discussion de groupe uniquement).
class PrivateEventPhoto {
  final String id;
  final String imageUrl;
  final String caption;
  final String userId;
  final String? prenom;
  final String? avatarUrl;
  final bool isHost;
  final DateTime createdAt;

  const PrivateEventPhoto({
    required this.id,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    this.caption = '',
    this.prenom,
    this.avatarUrl,
    this.isHost = false,
  });

  factory PrivateEventPhoto.fromJson(Map<String, dynamic> json) => PrivateEventPhoto(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        caption: json['caption'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        prenom: json['prenom'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isHost: json['is_host'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Event passe dans « Mes souvenirs » (organise ou inscrit).
class PrivateEventMemory {
  final String id;
  final String accessToken;
  final String title;
  final String? photoUrl;
  final String date; // YYYY-MM-DD
  final String heure;
  final String lieu;
  final bool isHost;
  /// Plus de publication possible (J+7 depasse) : album fige.
  final bool archived;
  final int participants;
  final int photoCount;
  /// Jusqu'a 4 dernieres photos de l'album (mosaique de couverture).
  final List<String> preview;

  const PrivateEventMemory({
    required this.id,
    required this.accessToken,
    required this.title,
    required this.date,
    this.photoUrl,
    this.heure = '',
    this.lieu = '',
    this.isHost = false,
    this.archived = false,
    this.participants = 0,
    this.photoCount = 0,
    this.preview = const [],
  });

  factory PrivateEventMemory.fromJson(Map<String, dynamic> json) => PrivateEventMemory(
        id: json['id'] as String,
        accessToken: json['access_token'] as String,
        title: json['title'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        date: json['date'] as String? ?? '',
        heure: json['heure'] as String? ?? '',
        lieu: json['lieu'] as String? ?? '',
        isHost: json['is_host'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        participants: (json['participants'] as num?)?.toInt() ?? 0,
        photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
        preview: (json['preview'] as List?)?.whereType<String>().toList() ?? const [],
      );
}

/// Personne ayant ouvert le coffre (bon code saisi), vue par l'hote.
/// [going] = a aussi fait « Je viens ». Lue via host_list_event_openers.
class PrivateEventOpener {
  final String userId;
  final String? prenom;
  final String? avatarUrl;
  final int opens;
  final DateTime? lastOpenedAt;
  final bool going;

  const PrivateEventOpener({
    required this.userId,
    this.prenom,
    this.avatarUrl,
    this.opens = 1,
    this.lastOpenedAt,
    this.going = false,
  });

  factory PrivateEventOpener.fromJson(Map<String, dynamic> json) => PrivateEventOpener(
        userId: json['user_id'] as String,
        prenom: json['prenom'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        opens: (json['opens'] as num?)?.toInt() ?? 1,
        lastOpenedAt: DateTime.tryParse(json['last_opened_at'] as String? ?? ''),
        going: json['going'] as bool? ?? false,
      );
}
