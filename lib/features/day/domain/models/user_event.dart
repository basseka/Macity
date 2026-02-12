import 'package:pulz_app/features/day/domain/models/event.dart';

class UserEvent {
  final String id;
  final String titre;
  final String description;
  final String categorie;
  final String rubrique;
  final String date;
  final String heure;
  final String lieuNom;
  final String lieuAdresse;
  final String? photoPath;
  final String? photoUrl;
  final String ville;
  final DateTime createdAt;

  UserEvent({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.rubrique,
    required this.date,
    required this.heure,
    this.lieuNom = '',
    this.lieuAdresse = '',
    this.photoPath,
    this.photoUrl,
    required this.ville,
    required this.createdAt,
  });

  /// Copie avec modifications.
  UserEvent copyWith({
    String? photoUrl,
  }) {
    return UserEvent(
      id: id,
      titre: titre,
      description: description,
      categorie: categorie,
      rubrique: rubrique,
      date: date,
      heure: heure,
      lieuNom: lieuNom,
      lieuAdresse: lieuAdresse,
      photoPath: photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      ville: ville,
      createdAt: createdAt,
    );
  }

  // ─────────────────────────────────────────
  // Sérialisation locale (SharedPreferences)
  // ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'rubrique': rubrique,
        'date': date,
        'heure': heure,
        'lieuNom': lieuNom,
        'lieuAdresse': lieuAdresse,
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'ville': ville,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserEvent.fromJson(Map<String, dynamic> json) => UserEvent(
        id: json['id'] as String,
        titre: json['titre'] as String,
        description: json['description'] as String,
        categorie: json['categorie'] as String,
        rubrique: json['rubrique'] as String,
        date: json['date'] as String,
        heure: json['heure'] as String,
        lieuNom: json['lieuNom'] as String? ?? '',
        lieuAdresse: json['lieuAdresse'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
        photoUrl: json['photoUrl'] as String?,
        ville: json['ville'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  // ─────────────────────────────────────────
  // Sérialisation Supabase (snake_case)
  // ─────────────────────────────────────────

  /// JSON pour insertion PostgREST (table `user_events`).
  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'rubrique': rubrique,
        'date': date,
        'heure': heure,
        'lieu_nom': lieuNom,
        'lieu_adresse': lieuAdresse,
        'photo_url': photoUrl,
        'ville': ville,
        'created_at': createdAt.toIso8601String(),
      };

  /// Depuis une ligne PostgREST.
  factory UserEvent.fromSupabaseJson(Map<String, dynamic> json) => UserEvent(
        id: json['id'] as String,
        titre: json['titre'] as String? ?? '',
        description: json['description'] as String? ?? '',
        categorie: json['categorie'] as String? ?? '',
        rubrique: json['rubrique'] as String? ?? '',
        date: json['date'] as String? ?? '',
        heure: json['heure'] as String? ?? '',
        lieuNom: json['lieu_nom'] as String? ?? '',
        lieuAdresse: json['lieu_adresse'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        ville: json['ville'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  // ─────────────────────────────────────────
  // Conversion vers Event unifié
  // ─────────────────────────────────────────

  /// Retourne l'image à utiliser : URL distante prioritaire, sinon chemin local.
  String? get resolvedPhoto => photoUrl ?? photoPath;

  /// Convert to [Event] for unified display in the events list.
  Event toEvent() => Event(
        identifiant: id,
        titre: titre,
        descriptifCourt: description,
        descriptifLong: description,
        dateDebut: date,
        dateFin: date,
        horaires: heure,
        lieuNom: lieuNom,
        lieuAdresse: lieuAdresse,
        commune: ville,
        categorie: categorie,
        type: categorie,
        photoPath: resolvedPhoto,
      );
}
