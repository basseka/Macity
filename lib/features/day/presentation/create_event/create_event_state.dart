import 'package:flutter/material.dart';

/// Categories principales disponibles pour un evenement.
const kEventCategories = <String>[
  'Musique / Concert',
  'Culturel / Artistique',
  'Danse',
  'Sport / Fitness',
  'Formation / Atelier',
  'Business / Professionnel',
  'Loisirs / Gaming',
  'Gastronomie',
  'Fete / Communautaire',
  'Bien-etre / Sante',
  'Nuit / Soiree',
  'Famille / Enfants',
];

/// Sous-categories dynamiques par categorie.
const kSubcategories = <String, List<String>>{
  'Musique / Concert': ['Concert', 'Festival', 'DJ set', 'Showcase', 'Opera', 'Karaoke'],
  'Culturel / Artistique': ['Expo', 'Vernissage', 'Theatre', 'Visite guidee', 'Musee', 'Cinema'],
  'Danse': ['Cours de danse', 'Spectacle', 'Bal', 'Battle', 'Stage'],
  'Sport / Fitness': ['Football', 'Rugby', 'Basketball', 'Handball', 'Tennis', 'Boxe', 'Natation', 'Courses a pied', 'Competition', 'Stage de danse', 'Course', 'Yoga', 'Fitness', 'Autre sport'],
  'Formation / Atelier': ['Atelier creatif', 'Formation pro', 'Cours de cuisine', 'Hackathon', 'Workshop'],
  'Business / Professionnel': ['Conference', 'Networking', 'Salon', 'Seminaire', 'Meetup'],
  'Loisirs / Gaming': ['Tournoi e-sport', 'Convention', 'Bar a jeux', 'LAN party', 'Escape game'],
  'Gastronomie': ['Restaurant', 'Degustation', 'Brunch', 'Marche', 'Food truck', 'Cours de cuisine'],
  'Nuit / Soiree': ['Soiree', 'Club', 'Bar', 'DJ set', 'Karaoke', 'After work', 'Soiree privee'],
  'Fete / Communautaire': ['Fete de quartier', 'Braderie', 'Vide-grenier', 'Carnaval', 'Feu d\'artifice'],
  'Bien-etre / Sante': ['Yoga', 'Meditation', 'Spa', 'Randonnee', 'Retraite bien-etre'],
  'Famille / Enfants': ['Spectacle enfant', 'Atelier enfant', 'Parc', 'Cinema', 'Bowling', 'Fete foraine'],
};

/// Formats d'evenement.
const kEventFormats = <String>[
  'Concert',
  'Atelier',
  'Stage',
  'Conference',
  'Spectacle',
  'Festival',
  'Meetup',
  'Formation',
  'Soiree',
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

/// Mapping categorie → mode/rubrique existant.
const categoryToMode = <String, String>{
  'Musique / Concert': 'day',
  'Culturel / Artistique': 'culture',
  'Danse': 'culture',
  'Sport / Fitness': 'sport',
  'Formation / Atelier': 'day',
  'Business / Professionnel': 'day',
  'Loisirs / Gaming': 'gaming',
  'Nuit / Soiree': 'night',
  'Gastronomie': 'food',
  'Fete / Communautaire': 'day',
  'Bien-etre / Sante': 'food',
  'Famille / Enfants': 'family',
};

/// State du wizard de creation d'evenement.
class CreateEventState {
  // Mode edition
  final bool isEditing;
  final String? editingEventId;
  final String? existingPhotoUrl;

  /// Compteur incremente a chaque bulk-update exterieur (loadEvent, prefillFromScan).
  /// Utilise comme Key sur les TextFormField pour forcer leur recreation avec
  /// la nouvelle initialValue (sinon les champs restent bloques sur la valeur
  /// initiale car ils sont controles par leur TextEditingController interne).
  final int prefillRevision;

  // Navigation
  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;

  // Etape 1
  final String? categorie;
  final String? sousCategorie;
  final String? format;
  final String titre;
  final String descriptionCourte;
  final String? photoPath;
  final String? videoPath;
  final bool isVideo;

  // Etape 2
  final DateTime? dateDebut;
  final TimeOfDay? heureDebut;
  final DateTime? dateFin;
  final TimeOfDay? heureFin;
  final String? recurrenceType; // null, 'quotidien', 'hebdomadaire', 'mensuel'
  final String? lieuType;
  final String? lieuNom;
  final String lieuAdresse;
  final String ville;
  final String pays;

  // Etape 3
  final bool estGratuit;
  final String prix;
  final String prixReduit;
  final String prixGroupe;
  final String prixEarlyBird;
  final String lienBilletterie;

  // Etape 4
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

  // Boost
  final String priority; // P1, P2, P3, P4
  final Set<DateTime> boostDates; // jours de boost sélectionnés

  // Etape 5
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
    this.sousCategorie,
    this.format,
    this.titre = '',
    this.descriptionCourte = '',
    this.photoPath,
    this.videoPath,
    this.isVideo = false,
    this.dateDebut,
    this.heureDebut,
    this.dateFin,
    this.heureFin,
    this.recurrenceType,
    this.lieuType,
    this.lieuNom,
    this.lieuAdresse = '',
    this.ville = '',
    this.pays = 'France',
    this.estGratuit = false,
    this.prix = '',
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
    String? sousCategorie,
    String? format,
    String? titre,
    String? descriptionCourte,
    String? photoPath,
    String? videoPath,
    bool? isVideo,
    DateTime? dateDebut,
    TimeOfDay? heureDebut,
    DateTime? dateFin,
    TimeOfDay? heureFin,
    String? recurrenceType,
    String? lieuType,
    String? lieuNom,
    String? lieuAdresse,
    String? ville,
    String? pays,
    bool? estGratuit,
    String? prix,
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
      sousCategorie: sousCategorie ?? this.sousCategorie,
      format: format ?? this.format,
      titre: titre ?? this.titre,
      descriptionCourte: descriptionCourte ?? this.descriptionCourte,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      isVideo: isVideo ?? this.isVideo,
      dateDebut: dateDebut ?? this.dateDebut,
      heureDebut: heureDebut ?? this.heureDebut,
      dateFin: clearDateFin ? null : (dateFin ?? this.dateFin),
      heureFin: clearHeureFin ? null : (heureFin ?? this.heureFin),
      recurrenceType: clearRecurrence ? null : (recurrenceType ?? this.recurrenceType),
      lieuType: lieuType ?? this.lieuType,
      lieuNom: lieuNom ?? this.lieuNom,
      lieuAdresse: lieuAdresse ?? this.lieuAdresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      estGratuit: estGratuit ?? this.estGratuit,
      prix: prix ?? this.prix,
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
  String? validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (categorie == null) return 'Choisissez une categorie';
        if (sousCategorie == null) return 'Choisissez une sous-categorie';
        if (titre.trim().isEmpty) return 'Le titre est requis';
        if (photoPath == null && videoPath == null && existingPhotoUrl == null) return 'Une photo ou video est requise';
        return null;
      case 1:
        if (dateDebut == null) return 'La date de debut est requise';
        if (heureDebut == null) return 'L\'heure de debut est requise';
        return null;
      case 2:
        final url = lienBilletterie.trim();
        if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
          return 'Le lien doit commencer par http:// ou https://';
        }
        return null;
      default:
        return null;
    }
  }

  /// Nombre total d'etapes.
  static const int totalSteps = 5;

  /// Est-ce que l'etape courante est skippable ?
  bool get isCurrentStepSkippable => currentStep >= 3;
}

/// Session de programme (etape 5).
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

