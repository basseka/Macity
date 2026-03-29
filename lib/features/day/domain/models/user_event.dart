import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

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
  final String lienBilletterie;
  final DateTime createdAt;

  // Etape 1 — Essentiel
  final String format;
  final String descriptionCourte;

  // Etape 2 — Quand & Ou
  final String dateFin;
  final String heureFin;
  final Map<String, dynamic>? recurrence;
  final String lieuType;
  final String pays;

  // Etape 3 — Tarifs
  final bool estGratuit;
  final double? prix;
  final double? prixReduit;
  final double? prixGroupe;
  final double? prixEarlyBird;

  // Etape 4 — Details
  final String descriptionLongue;
  final String publicCible;
  final String niveau;
  final String organisateurType;
  final String organisateurNom;
  final String organisateurEmail;
  final String organisateurTelephone;
  final String organisateurSite;
  final int? participantsMin;
  final int? participantsMax;
  final String inscriptionType;

  // Boost / Priorité
  final String priority; // P1, P2, P3, P4

  // Etape 5 — Extras
  final List<String> galleryUrls;
  final String videoUrl;
  final List<String> tags;
  final List<Map<String, dynamic>>? programme;
  final Map<String, dynamic>? accessibilite;
  final Map<String, dynamic>? regles;

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
    this.lienBilletterie = '',
    required this.createdAt,
    this.format = '',
    this.descriptionCourte = '',
    this.dateFin = '',
    this.heureFin = '',
    this.recurrence,
    this.lieuType = '',
    this.pays = 'France',
    this.estGratuit = false,
    this.prix,
    this.prixReduit,
    this.prixGroupe,
    this.prixEarlyBird,
    this.descriptionLongue = '',
    this.publicCible = 'tous publics',
    this.niveau = 'tous niveaux',
    this.organisateurType = '',
    this.organisateurNom = '',
    this.organisateurEmail = '',
    this.organisateurTelephone = '',
    this.organisateurSite = '',
    this.participantsMin,
    this.participantsMax,
    this.inscriptionType = 'libre',
    this.galleryUrls = const [],
    this.videoUrl = '',
    this.tags = const [],
    this.programme,
    this.accessibilite,
    this.regles,
    this.priority = 'P4',
  });

  UserEvent copyWith({
    String? id,
    String? titre,
    String? description,
    String? categorie,
    String? rubrique,
    String? date,
    String? heure,
    String? lieuNom,
    String? lieuAdresse,
    String? photoPath,
    String? photoUrl,
    String? ville,
    String? lienBilletterie,
    DateTime? createdAt,
    String? format,
    String? descriptionCourte,
    String? dateFin,
    String? heureFin,
    Map<String, dynamic>? recurrence,
    String? lieuType,
    String? pays,
    bool? estGratuit,
    double? prix,
    double? prixReduit,
    double? prixGroupe,
    double? prixEarlyBird,
    String? descriptionLongue,
    String? publicCible,
    String? niveau,
    String? organisateurType,
    String? organisateurNom,
    String? organisateurEmail,
    String? organisateurTelephone,
    String? organisateurSite,
    int? participantsMin,
    int? participantsMax,
    String? inscriptionType,
    List<String>? galleryUrls,
    String? videoUrl,
    List<String>? tags,
    List<Map<String, dynamic>>? programme,
    Map<String, dynamic>? accessibilite,
    Map<String, dynamic>? regles,
    String? priority,
  }) {
    return UserEvent(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      rubrique: rubrique ?? this.rubrique,
      date: date ?? this.date,
      heure: heure ?? this.heure,
      lieuNom: lieuNom ?? this.lieuNom,
      lieuAdresse: lieuAdresse ?? this.lieuAdresse,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      ville: ville ?? this.ville,
      lienBilletterie: lienBilletterie ?? this.lienBilletterie,
      createdAt: createdAt ?? this.createdAt,
      format: format ?? this.format,
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      dateFin: dateFin ?? this.dateFin,
      heureFin: heureFin ?? this.heureFin,
      recurrence: recurrence ?? this.recurrence,
      lieuType: lieuType ?? this.lieuType,
      pays: pays ?? this.pays,
      estGratuit: estGratuit ?? this.estGratuit,
      prix: prix ?? this.prix,
      prixReduit: prixReduit ?? this.prixReduit,
      prixGroupe: prixGroupe ?? this.prixGroupe,
      prixEarlyBird: prixEarlyBird ?? this.prixEarlyBird,
      descriptionLongue: descriptionLongue ?? this.descriptionLongue,
      publicCible: publicCible ?? this.publicCible,
      niveau: niveau ?? this.niveau,
      organisateurType: organisateurType ?? this.organisateurType,
      organisateurNom: organisateurNom ?? this.organisateurNom,
      organisateurEmail: organisateurEmail ?? this.organisateurEmail,
      organisateurTelephone: organisateurTelephone ?? this.organisateurTelephone,
      organisateurSite: organisateurSite ?? this.organisateurSite,
      participantsMin: participantsMin ?? this.participantsMin,
      participantsMax: participantsMax ?? this.participantsMax,
      inscriptionType: inscriptionType ?? this.inscriptionType,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      tags: tags ?? this.tags,
      programme: programme ?? this.programme,
      accessibilite: accessibilite ?? this.accessibilite,
      regles: regles ?? this.regles,
      priority: priority ?? this.priority,
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
        'lienBilletterie': lienBilletterie,
        'createdAt': createdAt.toIso8601String(),
        'format': format,
        'descriptionCourte': descriptionCourte,
        'dateFin': dateFin,
        'heureFin': heureFin,
        'recurrence': recurrence,
        'lieuType': lieuType,
        'pays': pays,
        'estGratuit': estGratuit,
        'prix': prix,
        'prixReduit': prixReduit,
        'prixGroupe': prixGroupe,
        'prixEarlyBird': prixEarlyBird,
        'descriptionLongue': descriptionLongue,
        'publicCible': publicCible,
        'niveau': niveau,
        'organisateurType': organisateurType,
        'organisateurNom': organisateurNom,
        'organisateurEmail': organisateurEmail,
        'organisateurTelephone': organisateurTelephone,
        'organisateurSite': organisateurSite,
        'participantsMin': participantsMin,
        'participantsMax': participantsMax,
        'inscriptionType': inscriptionType,
        'galleryUrls': galleryUrls,
        'videoUrl': videoUrl,
        'tags': tags,
        'programme': programme,
        'accessibilite': accessibilite,
        'regles': regles,
        'priority': priority,
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
        lienBilletterie: json['lienBilletterie'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        format: json['format'] as String? ?? '',
        descriptionCourte: json['descriptionCourte'] as String? ?? '',
        dateFin: json['dateFin'] as String? ?? '',
        heureFin: json['heureFin'] as String? ?? '',
        recurrence: json['recurrence'] as Map<String, dynamic>?,
        lieuType: json['lieuType'] as String? ?? '',
        pays: json['pays'] as String? ?? 'France',
        estGratuit: json['estGratuit'] as bool? ?? false,
        prix: (json['prix'] as num?)?.toDouble(),
        prixReduit: (json['prixReduit'] as num?)?.toDouble(),
        prixGroupe: (json['prixGroupe'] as num?)?.toDouble(),
        prixEarlyBird: (json['prixEarlyBird'] as num?)?.toDouble(),
        descriptionLongue: json['descriptionLongue'] as String? ?? '',
        publicCible: json['publicCible'] as String? ?? 'tous publics',
        niveau: json['niveau'] as String? ?? 'tous niveaux',
        organisateurType: json['organisateurType'] as String? ?? '',
        organisateurNom: json['organisateurNom'] as String? ?? '',
        organisateurEmail: json['organisateurEmail'] as String? ?? '',
        organisateurTelephone: json['organisateurTelephone'] as String? ?? '',
        organisateurSite: json['organisateurSite'] as String? ?? '',
        participantsMin: json['participantsMin'] as int?,
        participantsMax: json['participantsMax'] as int?,
        inscriptionType: json['inscriptionType'] as String? ?? 'libre',
        galleryUrls: (json['galleryUrls'] as List?)?.cast<String>() ?? [],
        videoUrl: json['videoUrl'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        programme: (json['programme'] as List?)
            ?.cast<Map<String, dynamic>>(),
        accessibilite: json['accessibilite'] as Map<String, dynamic>?,
        regles: json['regles'] as Map<String, dynamic>?,
        priority: json['priority'] as String? ?? 'P4',
      );

  // ─────────────────────────────────────────
  // Sérialisation Supabase (snake_case)
  // ─────────────────────────────────────────

  /// JSON pour insertion PostgREST (table `user_events`).
  /// Les nouveaux champs ne sont inclus que s'ils ont une valeur non-default,
  /// ce qui rend l'appel backward-compatible si la migration n'a pas ete appliquee.
  Map<String, dynamic> toSupabaseJson({String? userId}) {
    final json = <String, dynamic>{
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
      'lien_billetterie': lienBilletterie,
      'created_at': createdAt.toIso8601String(),
      if (userId != null) 'user_id': userId,
    };

    // Nouveaux champs — inclus uniquement si non-default
    if (format.isNotEmpty) json['format'] = format;
    if (descriptionCourte.isNotEmpty) json['description_courte'] = descriptionCourte;
    if (dateFin.isNotEmpty) json['date_fin'] = dateFin;
    if (heureFin.isNotEmpty) json['heure_fin'] = heureFin;
    if (recurrence != null) json['recurrence'] = recurrence;
    if (lieuType.isNotEmpty) json['lieu_type'] = lieuType;
    if (pays != 'France') json['pays'] = pays;
    if (estGratuit) json['est_gratuit'] = estGratuit;
    if (prix != null) json['prix'] = prix;
    if (prixReduit != null) json['prix_reduit'] = prixReduit;
    if (prixGroupe != null) json['prix_groupe'] = prixGroupe;
    if (prixEarlyBird != null) json['prix_early_bird'] = prixEarlyBird;
    if (descriptionLongue.isNotEmpty) json['description_longue'] = descriptionLongue;
    if (publicCible != 'tous publics') json['public_cible'] = publicCible;
    if (niveau != 'tous niveaux') json['niveau'] = niveau;
    if (organisateurType.isNotEmpty) json['organisateur_type'] = organisateurType;
    if (organisateurNom.isNotEmpty) json['organisateur_nom'] = organisateurNom;
    if (organisateurEmail.isNotEmpty) json['organisateur_email'] = organisateurEmail;
    if (organisateurTelephone.isNotEmpty) json['organisateur_telephone'] = organisateurTelephone;
    if (organisateurSite.isNotEmpty) json['organisateur_site'] = organisateurSite;
    if (participantsMin != null) json['participants_min'] = participantsMin;
    if (participantsMax != null) json['participants_max'] = participantsMax;
    if (inscriptionType != 'libre') json['inscription_type'] = inscriptionType;
    if (galleryUrls.isNotEmpty) json['gallery_urls'] = galleryUrls;
    if (videoUrl.isNotEmpty) json['video_url'] = videoUrl;
    if (tags.isNotEmpty) json['tags'] = tags;
    if (programme != null) json['programme'] = programme;
    if (accessibilite != null) json['accessibilite'] = accessibilite;
    if (regles != null) json['regles'] = regles;
    if (priority != 'P4') json['priority'] = priority;

    return json;
  }

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
        lienBilletterie: json['lien_billetterie'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        format: json['format'] as String? ?? '',
        descriptionCourte: json['description_courte'] as String? ?? '',
        dateFin: json['date_fin'] as String? ?? '',
        heureFin: json['heure_fin'] as String? ?? '',
        recurrence: json['recurrence'] as Map<String, dynamic>?,
        lieuType: json['lieu_type'] as String? ?? '',
        pays: json['pays'] as String? ?? 'France',
        estGratuit: json['est_gratuit'] as bool? ?? false,
        prix: (json['prix'] as num?)?.toDouble(),
        prixReduit: (json['prix_reduit'] as num?)?.toDouble(),
        prixGroupe: (json['prix_groupe'] as num?)?.toDouble(),
        prixEarlyBird: (json['prix_early_bird'] as num?)?.toDouble(),
        descriptionLongue: json['description_longue'] as String? ?? '',
        publicCible: json['public_cible'] as String? ?? 'tous publics',
        niveau: json['niveau'] as String? ?? 'tous niveaux',
        organisateurType: json['organisateur_type'] as String? ?? '',
        organisateurNom: json['organisateur_nom'] as String? ?? '',
        organisateurEmail: json['organisateur_email'] as String? ?? '',
        organisateurTelephone: json['organisateur_telephone'] as String? ?? '',
        organisateurSite: json['organisateur_site'] as String? ?? '',
        participantsMin: json['participants_min'] as int?,
        participantsMax: json['participants_max'] as int?,
        inscriptionType: json['inscription_type'] as String? ?? 'libre',
        galleryUrls: (json['gallery_urls'] as List?)?.cast<String>() ?? [],
        videoUrl: json['video_url'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        programme: (json['programme'] as List?)
            ?.cast<Map<String, dynamic>>(),
        accessibilite: json['accessibilite'] as Map<String, dynamic>?,
        regles: json['regles'] as Map<String, dynamic>?,
        priority: json['priority'] as String? ?? 'P4',
      );

  // ─────────────────────────────────────────
  // Conversion vers Event unifié
  // ─────────────────────────────────────────

  String? get resolvedPhoto => photoUrl ?? photoPath;

  SupabaseMatch toSupabaseMatch() => SupabaseMatch(
        id: createdAt.millisecondsSinceEpoch,
        sport: categorie,
        competition: '',
        equipe1: titre,
        equipe2: '',
        date: date,
        heure: heure,
        lieu: lieuNom,
        ville: ville,
        description: description,
        photoUrl: resolvedPhoto ?? '',
      );

  Event toEvent() => Event(
        identifiant: id,
        titre: titre,
        descriptifCourt: descriptionCourte.isNotEmpty ? descriptionCourte : description,
        descriptifLong: descriptionLongue.isNotEmpty ? descriptionLongue : description,
        dateDebut: date,
        dateFin: dateFin.isNotEmpty ? dateFin : date,
        horaires: heure,
        lieuNom: lieuNom,
        lieuAdresse: lieuAdresse,
        commune: ville,
        categorie: categorie,
        type: categorie,
        photoPath: resolvedPhoto,
        videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
        reservationUrl: lienBilletterie,
      );
}
