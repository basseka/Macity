import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/day/presentation/create_event/create_event_state.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/home/state/paginated_feed_provider.dart';
import 'package:pulz_app/features/pro_auth/state/pro_auth_provider.dart';

final createEventProvider =
    StateNotifierProvider.autoDispose<CreateEventNotifier, CreateEventState>(
  (ref) => CreateEventNotifier(ref),
);


class CreateEventNotifier extends StateNotifier<CreateEventState> {
  final Ref _ref;

  CreateEventNotifier(this._ref) : super(const CreateEventState()) {
    // Pre-remplir le nom de l'organisateur si pro connecte
    final proState = _ref.read(proAuthProvider);
    if (proState.status == ProAuthStatus.approved && proState.profile != null) {
      state = state.copyWith(organisateurNom: proState.profile!.nom);
    }
  }

  /// Charge un événement existant dans le state pour l'édition.
  void loadEvent(UserEvent e) {
    // Parser la date
    DateTime? dateDebut;
    TimeOfDay? heureDebut;
    DateTime? dateFin;
    TimeOfDay? heureFin;

    if (e.date.isNotEmpty) {
      try { dateDebut = DateTime.parse(e.date); } catch (_) {}
    }
    if (e.heure.isNotEmpty) {
      final parts = e.heure.split(':');
      if (parts.length >= 2) {
        heureDebut = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (e.dateFin.isNotEmpty) {
      try { dateFin = DateTime.parse(e.dateFin); } catch (_) {}
    }
    if (e.heureFin.isNotEmpty) {
      final parts = e.heureFin.split(':');
      if (parts.length >= 2) {
        heureFin = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    // Trouver la catégorie parente à partir de la sous-catégorie
    String? categorie;
    for (final entry in kSubcategories.entries) {
      if (entry.value.contains(e.categorie)) {
        categorie = entry.key;
        break;
      }
    }

    // Extraire accessibilité
    Set<String> accessibilite = {};
    if (e.accessibilite != null && e.accessibilite!['options'] is List) {
      accessibilite = Set<String>.from(e.accessibilite!['options'] as List);
    }

    // Extraire règles
    String ageMinimum = '';
    String materielRequis = '';
    String conditionsAnnulation = '';
    if (e.regles != null) {
      ageMinimum = e.regles!['age_minimum'] as String? ?? '';
      materielRequis = e.regles!['materiel_requis'] as String? ?? '';
      conditionsAnnulation = e.regles!['conditions_annulation'] as String? ?? '';
    }

    state = CreateEventState(
      isEditing: true,
      editingEventId: e.id,
      existingPhotoUrl: e.photoUrl,
      categorie: categorie,
      sousCategorie: e.categorie,
      format: e.format.isNotEmpty ? e.format : null,
      titre: e.titre,
      descriptionCourte: e.descriptionCourte,
      dateDebut: dateDebut,
      heureDebut: heureDebut,
      dateFin: dateFin,
      heureFin: heureFin,
      recurrenceType: e.recurrence?['type'] as String?,
      lieuType: e.lieuType.isNotEmpty ? e.lieuType : null,
      lieuNom: e.lieuNom.isNotEmpty ? e.lieuNom : null,
      lieuAdresse: e.lieuAdresse,
      ville: e.ville,
      pays: e.pays,
      estGratuit: e.estGratuit,
      prix: e.prix != null ? e.prix.toString() : '',
      prixReduit: e.prixReduit != null ? e.prixReduit.toString() : '',
      prixGroupe: e.prixGroupe != null ? e.prixGroupe.toString() : '',
      prixEarlyBird: e.prixEarlyBird != null ? e.prixEarlyBird.toString() : '',
      lienBilletterie: e.lienBilletterie,
      descriptionLongue: e.descriptionLongue,
      publicCible: e.publicCible,
      niveau: e.niveau,
      organisateurType: e.organisateurType,
      organisateurNom: e.organisateurNom,
      organisateurEmail: e.organisateurEmail,
      organisateurTelephone: e.organisateurTelephone,
      organisateurSite: e.organisateurSite,
      participantsMin: e.participantsMin?.toString() ?? '',
      participantsMax: e.participantsMax?.toString() ?? '',
      inscriptionType: e.inscriptionType,
      priority: e.priority,
      videoUrl: e.videoUrl,
      tags: e.tags,
      programme: e.programme
              ?.map((p) => ProgrammeSession(
                    heure: p['heure'] as String? ?? '',
                    activite: p['activite'] as String? ?? '',
                    intervenant: p['intervenant'] as String? ?? '',
                  ))
              .toList() ??
          [],
      accessibilite: accessibilite,
      ageMinimum: ageMinimum,
      materielRequis: materielRequis,
      conditionsAnnulation: conditionsAnnulation,
    );
  }

  void updateCategorie(String value) {
    state = state.copyWith(
      categorie: value,
      sousCategorie: null,
      clearError: true,
    );
  }

  void updateSousCategorie(String value) {
    state = state.copyWith(sousCategorie: value, clearError: true);
  }

  void updateFormat(String value) {
    state = state.copyWith(format: value, clearError: true);
  }

  void updateTitre(String value) {
    state = state.copyWith(titre: value, clearError: true);
  }

  void updateDescriptionCourte(String value) {
    state = state.copyWith(descriptionCourte: value, clearError: true);
  }

  void updatePhotoPath(String value) {
    state = state.copyWith(photoPath: value, clearError: true);
  }

  void updateVideoPath(String value) {
    state = state.copyWith(videoPath: value, clearError: true);
  }

  void updateIsVideo(bool value) {
    state = state.copyWith(isVideo: value, clearError: true);
  }

  void updateDateDebut(DateTime value) {
    state = state.copyWith(dateDebut: value, clearError: true);
  }

  void updateHeureDebut(TimeOfDay value) {
    state = state.copyWith(heureDebut: value, clearError: true);
  }

  void updateDateFin(DateTime? value) {
    if (value == null) {
      state = state.copyWith(clearDateFin: true, clearError: true);
    } else {
      state = state.copyWith(dateFin: value, clearError: true);
    }
  }

  void updateHeureFin(TimeOfDay? value) {
    if (value == null) {
      state = state.copyWith(clearHeureFin: true, clearError: true);
    } else {
      state = state.copyWith(heureFin: value, clearError: true);
    }
  }

  void updateRecurrenceType(String? value) {
    if (value == null) {
      state = state.copyWith(clearRecurrence: true, clearError: true);
    } else {
      state = state.copyWith(recurrenceType: value, clearError: true);
    }
  }

  void updateLieuType(String value) {
    state = state.copyWith(lieuType: value, clearError: true);
  }

  void updateLieuNom(String value) {
    state = state.copyWith(lieuNom: value, clearError: true);
  }

  void updateLieuAdresse(String value) {
    state = state.copyWith(lieuAdresse: value, clearError: true);
  }

  void updateVille(String value) {
    state = state.copyWith(ville: value, clearError: true);
  }

  void updatePays(String value) {
    state = state.copyWith(pays: value, clearError: true);
  }

  void updateEstGratuit(bool value) {
    state = state.copyWith(estGratuit: value, clearError: true);
  }

  void updatePrix(String value) {
    state = state.copyWith(prix: value, clearError: true);
  }

  void updatePrixReduit(String value) {
    state = state.copyWith(prixReduit: value, clearError: true);
  }

  void updatePrixGroupe(String value) {
    state = state.copyWith(prixGroupe: value, clearError: true);
  }

  void updatePrixEarlyBird(String value) {
    state = state.copyWith(prixEarlyBird: value, clearError: true);
  }

  void updateLienBilletterie(String value) {
    state = state.copyWith(lienBilletterie: value, clearError: true);
  }

  void updatePriority(String value) {
    state = state.copyWith(priority: value, clearError: true);
  }

  void toggleBoostDate(DateTime date) {
    final current = Set<DateTime>.from(state.boostDates);
    final normalized = DateTime(date.year, date.month, date.day);
    if (current.any((d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day)) {
      current.removeWhere((d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day);
    } else if (current.length < 30) {
      current.add(normalized);
    }
    state = state.copyWith(boostDates: current, clearError: true);
  }

  void setBoostDates(Set<DateTime> dates) {
    state = state.copyWith(boostDates: dates, clearError: true);
  }

  void clearBoostDates() {
    state = state.copyWith(boostDates: {}, clearError: true);
  }

  void updateDescriptionLongue(String value) {
    state = state.copyWith(descriptionLongue: value, clearError: true);
  }

  void updatePublicCible(String value) {
    state = state.copyWith(publicCible: value, clearError: true);
  }

  void updateNiveau(String value) {
    state = state.copyWith(niveau: value, clearError: true);
  }

  void updateOrganisateurType(String value) {
    state = state.copyWith(organisateurType: value, clearError: true);
  }

  void updateOrganisateurNom(String value) {
    state = state.copyWith(organisateurNom: value, clearError: true);
  }

  void updateOrganisateurEmail(String value) {
    state = state.copyWith(organisateurEmail: value, clearError: true);
  }

  void updateOrganisateurTelephone(String value) {
    state = state.copyWith(organisateurTelephone: value, clearError: true);
  }

  void updateOrganisateurSite(String value) {
    state = state.copyWith(organisateurSite: value, clearError: true);
  }

  void updateParticipantsMin(String value) {
    state = state.copyWith(participantsMin: value, clearError: true);
  }

  void updateParticipantsMax(String value) {
    state = state.copyWith(participantsMax: value, clearError: true);
  }

  void updateInscriptionType(String value) {
    state = state.copyWith(inscriptionType: value, clearError: true);
  }

  void updateGalleryPaths(List<String> value) {
    state = state.copyWith(galleryPaths: value, clearError: true);
  }

  void updateVideoUrl(String value) {
    state = state.copyWith(videoUrl: value, clearError: true);
  }

  void updateTags(List<String> value) {
    state = state.copyWith(tags: value, clearError: true);
  }

  void updateProgramme(List<ProgrammeSession> value) {
    state = state.copyWith(programme: value, clearError: true);
  }

  void toggleAccessibilite(String key) {
    final current = Set<String>.from(state.accessibilite);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    state = state.copyWith(accessibilite: current, clearError: true);
  }

  void updateAgeMinimum(String value) {
    state = state.copyWith(ageMinimum: value, clearError: true);
  }

  void updateMaterielRequis(String value) {
    state = state.copyWith(materielRequis: value, clearError: true);
  }

  void updateConditionsAnnulation(String value) {
    state = state.copyWith(conditionsAnnulation: value, clearError: true);
  }

  /// Tente d'avancer a l'etape suivante.
  /// Retourne true si la navigation a reussi.
  bool nextStep() {
    final error = state.validateCurrentStep();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }
    if (state.currentStep < CreateEventState.totalSteps - 1) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
    return true;
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  /// Skip l'etape courante (etapes 4-5 uniquement).
  void skipStep() {
    if (state.isCurrentStepSkippable &&
        state.currentStep < CreateEventState.totalSteps - 1) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  /// Soumet l'evenement.
  Future<bool> submit() async {
    // Valider l'etape courante d'abord
    final error = state.validateCurrentStep();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final s = state;
      final id = s.isEditing ? s.editingEventId! : '${DateTime.now().millisecondsSinceEpoch}';
      final dateStr = s.dateDebut != null
          ? DateFormat('yyyy-MM-dd').format(s.dateDebut!)
          : '';
      final timeStr = s.heureDebut != null
          ? '${s.heureDebut!.hour.toString().padLeft(2, '0')}:${s.heureDebut!.minute.toString().padLeft(2, '0')}'
          : '';
      final dateFinStr = s.dateFin != null
          ? DateFormat('yyyy-MM-dd').format(s.dateFin!)
          : '';
      final heureFinStr = s.heureFin != null
          ? '${s.heureFin!.hour.toString().padLeft(2, '0')}:${s.heureFin!.minute.toString().padLeft(2, '0')}'
          : '';

      final rubrique = categoryToMode[s.categorie] ?? 'day';

      // Upload video si present
      String? uploadedVideoUrl;
      final svc = UserEventSupabaseService();
      if (s.videoPath != null && s.videoPath!.isNotEmpty) {
        try {
          uploadedVideoUrl = await svc.uploadVideo(s.videoPath!);
          debugPrint('[CreateEvent] video uploaded: $uploadedVideoUrl');
        } catch (e) {
          debugPrint('[CreateEvent] video upload failed: $e');
        }
      }

      // Upload gallery photos if any
      List<String> galleryUrls = [];
      if (s.galleryPaths.isNotEmpty) {
        try {
          galleryUrls = await svc.uploadGallery(s.galleryPaths);
        } catch (e) {
          debugPrint('[CreateEvent] gallery upload failed: $e');
        }
      }

      // En mode edition, garder l'ancienne photo si pas de nouvelle
      final photoUrl = s.isEditing && s.photoPath == null ? s.existingPhotoUrl : null;

      final event = UserEvent(
        id: id,
        titre: s.titre.trim(),
        description: s.descriptionCourte.trim(),
        categorie: s.sousCategorie ?? '',
        rubrique: rubrique,
        date: dateStr,
        heure: timeStr,
        lieuNom: s.lieuNom ?? '',
        lieuAdresse: s.lieuAdresse.trim(),
        photoPath: s.photoPath,
        photoUrl: photoUrl,
        videoUrl: uploadedVideoUrl ?? s.videoUrl,
        ville: s.ville,
        lienBilletterie: s.lienBilletterie.trim(),
        createdAt: DateTime.now(),
        format: s.format ?? '',
        descriptionCourte: s.descriptionCourte.trim(),
        dateFin: dateFinStr,
        heureFin: heureFinStr,
        recurrence: s.recurrenceType != null
            ? {'type': s.recurrenceType}
            : null,
        lieuType: s.lieuType ?? '',
        pays: s.pays,
        estGratuit: s.estGratuit,
        prix: _parseDouble(s.prix),
        prixReduit: _parseDouble(s.prixReduit),
        prixGroupe: _parseDouble(s.prixGroupe),
        prixEarlyBird: _parseDouble(s.prixEarlyBird),
        descriptionLongue: s.descriptionLongue.trim(),
        publicCible: s.publicCible,
        niveau: s.niveau,
        organisateurType: s.organisateurType,
        organisateurNom: s.organisateurNom.trim(),
        organisateurEmail: s.organisateurEmail.trim(),
        organisateurTelephone: s.organisateurTelephone.trim(),
        organisateurSite: s.organisateurSite.trim(),
        participantsMin: int.tryParse(s.participantsMin),
        participantsMax: int.tryParse(s.participantsMax),
        inscriptionType: s.inscriptionType.toLowerCase(),
        galleryUrls: galleryUrls,
        tags: s.tags,
        programme: s.programme.isNotEmpty
            ? s.programme.map((p) => p.toJson()).toList()
            : null,
        accessibilite: s.accessibilite.isNotEmpty
            ? {'options': s.accessibilite.toList()}
            : null,
        regles: (s.ageMinimum.isNotEmpty ||
                s.materielRequis.isNotEmpty ||
                s.conditionsAnnulation.isNotEmpty)
            ? {
                'age_minimum': s.ageMinimum,
                'materiel_requis': s.materielRequis,
                'conditions_annulation': s.conditionsAnnulation,
              }
            : null,
        priority: s.priority,
      );

      if (s.isEditing) {
        // Mode édition : update
        await _ref
            .read(userEventsProvider.notifier)
            .updateEvent(event);
      } else {
        // Mode création
        String? establishmentId;
        final proState = _ref.read(proAuthProvider);
        if (proState.status == ProAuthStatus.approved &&
            proState.profile != null) {
          establishmentId = proState.profile!.id;
        }

        await _ref
            .read(userEventsProvider.notifier)
            .addEvent(event, establishmentId: establishmentId);

        ActivityService.instance.eventCreated(
          eventId: event.id,
          titre: event.titre,
          categorie: event.categorie,
          rubrique: event.rubrique,
          ville: event.ville,
        );
      }

      // Rafraichir le feed pour inclure le nouvel event
      _ref.invalidate(paginatedFeedProvider);

      lastCreatedEventId = event.id;
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erreur : $e',
      );
      return false;
    }
  }

  /// ID du dernier event créé (pour le paiement Stripe).
  String? lastCreatedEventId;

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }
}
