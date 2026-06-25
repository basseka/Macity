import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/core/utils/city_hub_resolver.dart';
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
    // Pre-remplit le nom de l'organisateur si pro connecte (utile pour l'etape
    // optionnelle).
    final proState = _ref.read(proAuthProvider);
    if (proState.status == ProAuthStatus.approved && proState.profile != null) {
      state = state.copyWith(organisateurNom: proState.profile!.nom);
    }
  }

  /// Mappe une categorie heritee (sous-cat libre ou ancienne taxonomie) vers
  /// l'une des 7 categories du feed. Best-effort par mots-cles.
  String? _mapLegacyToFeedCategory(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('concert') || s.contains('musique') || s.contains('festival')) {
      return 'Concerts';
    }
    if (s.contains('soir') || s.contains('club') || s.contains('dj') ||
        s.contains('party') || s.contains('bar') || s.contains('after')) {
      return 'Soirée';
    }
    if (s.contains('spectacle') || s.contains('theatre') || s.contains('théâtre') ||
        s.contains('humour') || s.contains('danse') || s.contains('opera') ||
        s.contains('comédie') || s.contains('comedie')) {
      return 'Spectacle';
    }
    if (s.contains('cinema') || s.contains('cinéma') || s.contains('film') ||
        s.contains('projection')) {
      return 'Cinéma';
    }
    if (s.contains('food') || s.contains('gastr') || s.contains('brunch') ||
        s.contains('restaurant') || s.contains('degustation') || s.contains('marche')) {
      return 'Food';
    }
    if (s.contains('sport') || s.contains('fitness') || s.contains('match') ||
        s.contains('running') || s.contains('course') || s.contains('tournoi')) {
      return 'Sport';
    }
    if (s.contains('famille') || s.contains('enfant') || s.contains('kids') ||
        s.contains('jeunesse')) {
      return 'Famille';
    }
    return null;
  }

  /// Charge un evenement existant dans le state pour l'edition.
  void loadEvent(UserEvent e, {int initialStep = 0}) {
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

    // Categorie : on accepte la valeur stockee si elle est dans la nouvelle
    // taxonomie ; sinon on mappe depuis la sous-cat legacy par mots-cles.
    String? categorie;
    if (kEventCategories.contains(e.categorie)) {
      categorie = e.categorie;
    } else if (e.categorie.isNotEmpty) {
      categorie = _mapLegacyToFeedCategory(e.categorie);
    }

    Set<String> accessibilite = {};
    if (e.accessibilite != null && e.accessibilite!['options'] is List) {
      accessibilite = Set<String>.from(e.accessibilite!['options'] as List);
    }

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
      currentStep: initialStep,
      categorie: categorie,
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

  /// Pre-remplit le state a partir des donnees extraites par l'IA sur un
  /// flyer scanne. L'user peut ensuite reviser chaque champ.
  void prefillFromScan({
    required Map<String, dynamic> data,
    required String photoUrl,
  }) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    DateTime? parseDate(dynamic v) {
      final s = str(v);
      if (s == null) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }

    TimeOfDay? parseTime(dynamic v) {
      final s = str(v);
      if (s == null) return null;
      final m = RegExp(r'^(\d{1,2})[:h](\d{2})').firstMatch(s);
      if (m == null) return null;
      final h = int.tryParse(m.group(1)!) ?? 0;
      final mn = int.tryParse(m.group(2)!) ?? 0;
      if (h > 23 || mn > 59) return null;
      return TimeOfDay(hour: h, minute: mn);
    }

    // L'IA peut renvoyer une categorie/sous-cat de l'ancienne taxonomie : on
    // mappe les deux par mots-cles vers les 7 categories du feed.
    String? cat;
    final rawCat = str(data['categorie']);
    final rawSub = str(data['sous_categorie']);
    if (rawCat != null) cat = _mapLegacyToFeedCategory(rawCat);
    if (cat == null && rawSub != null) cat = _mapLegacyToFeedCategory(rawSub);
    if (cat != null && !kEventCategories.contains(cat)) cat = null;

    final tags = data['tags'];
    final List<String> tagList = tags is List
        ? tags.whereType<String>().take(10).toList()
        : const [];

    // Form a 1 step : le scan IA pre-remplit et l'utilisateur peut publier
    // directement.
    state = state.copyWith(
      currentStep: 0,
      existingPhotoUrl: photoUrl,
      prefillRevision: state.prefillRevision + 1,
      categorie: cat,
      titre: str(data['titre']) ?? '',
      descriptionCourte: str(data['description_courte']) ?? '',
      descriptionLongue: str(data['description_longue']) ?? '',
      dateDebut: parseDate(data['date_debut']),
      heureDebut: parseTime(data['heure_debut']),
      dateFin: parseDate(data['date_fin']),
      heureFin: parseTime(data['heure_fin']),
      lieuNom: str(data['lieu_nom']),
      lieuAdresse: str(data['lieu_adresse']) ?? '',
      ville: str(data['ville']) != null
          ? CityHubResolver.resolveHub(
              str(data['ville']),
              str(data['code_postal']),
            )
          : state.ville,
      estGratuit: data['est_gratuit'] == true,
      prix: (str(data['prix']) ?? '').replaceAll(RegExp(r'[^\d.,]'), ''),
      lienBilletterie: str(data['lien_billetterie']) ?? '',
      tags: tagList,
      clearError: true,
    );
  }

  void updateCategorie(String value) {
    state = state.copyWith(categorie: value, clearError: true);
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

  /// Tente d'avancer a l'etape suivante. Retourne true si la nav a reussi.
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

  /// Skip l'etape Optionnel : passe direct au submit. La page gere l'appel.
  void skipStep() {
    if (state.isCurrentStepSkippable &&
        state.currentStep < CreateEventState.totalSteps - 1) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Soumet l'evenement.
  Future<bool> submit() async {
    debugPrint(
      '[CreateEvent] submit() step=${state.currentStep} '
      'isEditing=${state.isEditing} titre="${state.titre}" '
      'cat="${state.categorie}" date=${state.dateDebut} '
      'heure=${state.heureDebut} ville="${state.ville}"',
    );
    final error = state.validateCurrentStep();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }

    // Cas du fast-publish depuis Optionnel : on revalide l'essentiel.
    if (state.dateDebut == null || state.heureDebut == null) {
      state = state.copyWith(
        errorMessage: 'Renseigne la date et l\'heure avant de publier.',
        currentStep: 0,
      );
      return false;
    }
    if (state.categorie == null) {
      state = state.copyWith(
        errorMessage: 'Choisis une catégorie',
        currentStep: 0,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final event = await _assembleEvent();

      if (state.isEditing) {
        await _ref.read(userEventsProvider.notifier).updateEvent(event);
      } else {
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

      _ref.invalidate(paginatedFeedProvider);

      lastCreatedEventId = event.id;
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e, st) {
      debugPrint('[CreateEvent] submit FAILED: $e\n$st');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _friendlyError(e),
      );
      return false;
    }
  }

  /// Construit l'[UserEvent] depuis l'état courant et upload les médias,
  /// SANS l'insérer en base. Utilisé par [submit] (flux pro) et par la
  /// publication payante particulier (qui passe ensuite par l'écran Tarifs +
  /// Stripe avant que le webhook ne l'insère).
  Future<UserEvent?> assembleEventForPublication() async {
    final error = state.validateCurrentStep();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return null;
    }
    if (state.dateDebut == null || state.heureDebut == null) {
      state = state.copyWith(
        errorMessage: 'Renseigne la date et l\'heure avant de publier.',
        currentStep: 0,
      );
      return null;
    }
    if (state.categorie == null) {
      state = state.copyWith(errorMessage: 'Choisis une catégorie', currentStep: 0);
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final event = await _assembleEvent();
      state = state.copyWith(isSubmitting: false);
      return event;
    } catch (e, st) {
      debugPrint('[CreateEvent] assemble FAILED: $e\n$st');
      state = state.copyWith(isSubmitting: false, errorMessage: _friendlyError(e));
      return null;
    }
  }

  /// Cœur d'assemblage partagé : upload médias + construction de l'UserEvent.
  Future<UserEvent> _assembleEvent() async {
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

      String? uploadedVideoUrl;
      final svc = UserEventSupabaseService();
      if (s.videoPath != null && s.videoPath!.isNotEmpty) {
        try {
          uploadedVideoUrl = await svc.uploadVideo(s.videoPath!);
        } catch (e) {
          debugPrint('[CreateEvent] video upload failed: $e');
        }
      }

      List<String> galleryUrls = [];
      if (s.galleryPaths.isNotEmpty) {
        try {
          galleryUrls = await svc.uploadGallery(s.galleryPaths);
        } catch (e) {
          debugPrint('[CreateEvent] gallery upload failed: $e');
        }
      }

      final photoUrl = (s.photoPath == null || s.photoPath!.isEmpty)
          ? s.existingPhotoUrl
          : null;

      final event = UserEvent(
        id: id,
        titre: s.titre.trim(),
        description: s.descriptionCourte.trim(),
        // Categorie = celle choisie par l'user dans les 7 chips feed.
        // Le filtre feed matche par contains() lowercase, donc 'Concerts'
        // matche le keyword 'concert' du filtre.
        categorie: s.categorie ?? '',
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
        // Format n'existe plus dans le wizard simplifie. On l'envoie vide.
        format: '',
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

      return event;
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('DioException')) {
      final statusMatch = RegExp(r'status code of (\d{3})').firstMatch(s);
      if (statusMatch != null) {
        final code = statusMatch.group(1);
        if (code == '400') return 'Données invalides (400). Vérifie les champs.';
        if (code == '401' || code == '403') {
          return 'Authentification requise ($code).';
        }
        if (code == '409') return 'Conflit (409). Évènement déjà existant ?';
        if (code == '413') return 'Fichier trop volumineux.';
        if (code!.startsWith('5')) {
          return 'Erreur serveur ($code). Réessaye dans un instant.';
        }
        return 'Erreur réseau ($code).';
      }
      if (s.contains('timeout') || s.contains('Timeout')) {
        return 'Connexion trop lente. Vérifie ton réseau.';
      }
      return 'Erreur réseau. Vérifie ta connexion.';
    }
    if (s.contains('SocketException')) {
      return 'Pas de connexion internet.';
    }
    final raw = s.replaceFirst('Exception: ', '');
    return raw.length > 120 ? '${raw.substring(0, 117)}...' : raw;
  }

  String? lastCreatedEventId;

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }
}
