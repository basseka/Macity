import 'package:flutter/material.dart';

/// Categories alignees sur les chips de filtre du Feed (slot 1 de la nav bar).
/// Garder cet ordre identique a `_feedCategories` dans `feed_screen.dart`.
const kEventCategories = <String>[
  'Concerts',
  'Soirée',
  'Spectacle',
  'Cinéma',
  'Food',
  'Sport',
  'Famille',
];

/// Types de lieu.
const kLieuTypes = <String>[
  'Salle',
  'Exterieur',
  'Studio',
  'En ligne',
];

/// Public cible.
const kPublicCible = <String>[
  'Enfants',
  'Ados',
  'Adultes',
  'Seniors',
  'Tous publics',
];

/// Niveaux.
const kNiveaux = <String>[
  'Debutant',
  'Intermediaire',
  'Avance',
  'Tous niveaux',
];

/// Types d'organisateur.
const kOrganisateurTypes = <String>[
  'Particulier',
  'Association',
  'Entreprise',
];

/// Types d'inscription.
const kInscriptionTypes = <String>[
  'Libre',
  'Validation',
  'Liste d\'attente',
];

/// Mapping categorie -> rubrique/hub. Determine dans quel hub l'event apparait
/// (day, night, food, culture, sport, family).
const categoryToMode = <String, String>{
  'Concerts': 'day',
  'Soirée': 'night',
  'Spectacle': 'culture',
  'Cinéma': 'culture',
  'Food': 'food',
  'Sport': 'sport',
  'Famille': 'family',
};

/// State du wizard de creation d'evenement (2 etapes : Essentiel + Optionnel).
class CreateEventState {
  // Mode edition
  final bool isEditing;
  final String? editingEventId;
  final String? existingPhotoUrl;

  /// Compteur incremente a chaque bulk-update exterieur (loadEvent, prefillFromScan).
  /// Utilise comme Key sur les TextFormField pour forcer leur recreation avec
  /// la nouvelle initialValue.
  final int prefillRevision;

  // Navigation
  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  // Essentiel
  final String? categorie;
  final String titre;
  final String? photoPath;
  final String? videoPath;
  final bool isVideo;
  final DateTime? dateDebut;
  final TimeOfDay? heureDebut;
  final String lieuAdresse;
  final String ville;
  final String pays;
  final bool estGratuit;
  final String prix;

  // Optionnel
  final String descriptionCourte;
  final DateTime? dateFin;
  final TimeOfDay? heureFin;
  final String? recurrenceType;
  final String? lieuType;
  final String? lieuNom;
  final String prixReduit;
  final String prixGroupe;
  final String prixEarlyBird;
  final String lienBilletterie;
  final String descriptionLongue;
  final String publicCible;
  final String niveau;
  final String organisateurType;
  final String organisateurNom;
  final String organisateurEmail;
  final String organisateurTelephone;
  final String organisateurSite;
  final String participantsMin;
  final String participantsMax;
  final String inscriptionType;
  final String priority;
  final Set<DateTime> boostDates;
  final List<String> galleryPaths;
  final String videoUrl;
  final List<String> tags;
  final List<ProgrammeSession> programme;
  final Set<String> accessibilite;
  final String ageMinimum;
  final String materielRequis;
  final String conditionsAnnulation;

  const CreateEventState({
    this.isEditing = false,
    this.editingEventId,
    this.existingPhotoUrl,
    this.prefillRevision = 0,
    this.currentStep = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.categorie,
    this.titre = '',
    this.photoPath,
    this.videoPath,
    this.isVideo = false,
    this.dateDebut,
    this.heureDebut,
    this.lieuAdresse = '',
    this.ville = '',
    this.pays = 'France',
    this.estGratuit = false,
    this.prix = '',
    this.descriptionCourte = '',
    this.dateFin,
    this.heureFin,
    this.recurrenceType,
    this.lieuType,
    this.lieuNom,
    this.prixReduit = '',
    this.prixGroupe = '',
    this.prixEarlyBird = '',
    this.lienBilletterie = '',
    this.descriptionLongue = '',
    this.publicCible = 'Tous publics',
    this.niveau = 'Tous niveaux',
    this.organisateurType = '',
    this.organisateurNom = '',
    this.organisateurEmail = '',
    this.organisateurTelephone = '',
    this.organisateurSite = '',
    this.participantsMin = '',
    this.participantsMax = '',
    this.inscriptionType = 'Libre',
    this.priority = 'P4',
    this.boostDates = const {},
    this.galleryPaths = const [],
    this.videoUrl = '',
    this.tags = const [],
    this.programme = const [],
    this.accessibilite = const {},
    this.ageMinimum = '',
    this.materielRequis = '',
    this.conditionsAnnulation = '',
  });

  CreateEventState copyWith({
    bool? isEditing,
    String? editingEventId,
    String? existingPhotoUrl,
    int? prefillRevision,
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    String? categorie,
    String? titre,
    String? photoPath,
    String? videoPath,
    bool? isVideo,
    DateTime? dateDebut,
    TimeOfDay? heureDebut,
    String? lieuAdresse,
    String? ville,
    String? pays,
    bool? estGratuit,
    String? prix,
    String? descriptionCourte,
    DateTime? dateFin,
    TimeOfDay? heureFin,
    String? recurrenceType,
    String? lieuType,
    String? lieuNom,
    String? prixReduit,
    String? prixGroupe,
    String? prixEarlyBird,
    String? lienBilletterie,
    String? descriptionLongue,
    String? publicCible,
    String? niveau,
    String? organisateurType,
    String? organisateurNom,
    String? organisateurEmail,
    String? organisateurTelephone,
    String? organisateurSite,
    String? participantsMin,
    String? participantsMax,
    String? inscriptionType,
    String? priority,
    Set<DateTime>? boostDates,
    List<String>? galleryPaths,
    String? videoUrl,
    List<String>? tags,
    List<ProgrammeSession>? programme,
    Set<String>? accessibilite,
    String? ageMinimum,
    String? materielRequis,
    String? conditionsAnnulation,
    bool clearError = false,
    bool clearRecurrence = false,
    bool clearDateFin = false,
    bool clearHeureFin = false,
  }) {
    return CreateEventState(
      isEditing: isEditing ?? this.isEditing,
      editingEventId: editingEventId ?? this.editingEventId,
      existingPhotoUrl: existingPhotoUrl ?? this.existingPhotoUrl,
      prefillRevision: prefillRevision ?? this.prefillRevision,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      categorie: categorie ?? this.categorie,
      titre: titre ?? this.titre,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      isVideo: isVideo ?? this.isVideo,
      dateDebut: dateDebut ?? this.dateDebut,
      heureDebut: heureDebut ?? this.heureDebut,
      lieuAdresse: lieuAdresse ?? this.lieuAdresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      estGratuit: estGratuit ?? this.estGratuit,
      prix: prix ?? this.prix,
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      dateFin: clearDateFin ? null : (dateFin ?? this.dateFin),
      heureFin: clearHeureFin ? null : (heureFin ?? this.heureFin),
      recurrenceType: clearRecurrence ? null : (recurrenceType ?? this.recurrenceType),
      lieuType: lieuType ?? this.lieuType,
      lieuNom: lieuNom ?? this.lieuNom,
      prixReduit: prixReduit ?? this.prixReduit,
      prixGroupe: prixGroupe ?? this.prixGroupe,
      prixEarlyBird: prixEarlyBird ?? this.prixEarlyBird,
      lienBilletterie: lienBilletterie ?? this.lienBilletterie,
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
      priority: priority ?? this.priority,
      boostDates: boostDates ?? this.boostDates,
      galleryPaths: galleryPaths ?? this.galleryPaths,
      videoUrl: videoUrl ?? this.videoUrl,
      tags: tags ?? this.tags,
      programme: programme ?? this.programme,
      accessibilite: accessibilite ?? this.accessibilite,
      ageMinimum: ageMinimum ?? this.ageMinimum,
      materielRequis: materielRequis ?? this.materielRequis,
      conditionsAnnulation: conditionsAnnulation ?? this.conditionsAnnulation,
    );
  }

  /// Valide l'etape courante. Retourne un message d'erreur ou null.
  /// Un seul step (Essentiel) : tout est obligatoire ici.
  String? validateCurrentStep() {
    if (categorie == null) return 'Choisis une catégorie';
    if (titre.trim().isEmpty) return 'Le titre est requis';
    if (photoPath == null && videoPath == null && existingPhotoUrl == null) {
      return 'Une photo ou vidéo est requise';
    }
    if (dateDebut == null) return 'La date de début est requise';
    if (heureDebut == null) return 'L\'heure de début est requise';
    if (lieuAdresse.trim().isEmpty) return 'Adresse du lieu requise';
    final url = lienBilletterie.trim();
    if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
      return 'Le lien doit commencer par http:// ou https://';
    }
    return null;
  }

  /// Nombre total d'etapes (form simplifie a 1 etape).
  static const int totalSteps = 1;

  /// Plus de step optionnelle : rien n'est passable.
  bool get isCurrentStepSkippable => false;
}

/// Session de programme (etape 2 - optionnel).
class ProgrammeSession {
  final String heure;
  final String activite;
  final String intervenant;

  const ProgrammeSession({
    this.heure = '',
    this.activite = '',
    this.intervenant = '',
  });

  Map<String, dynamic> toJson() => {
        'heure': heure,
        'activite': activite,
        'intervenant': intervenant,
      };
}
