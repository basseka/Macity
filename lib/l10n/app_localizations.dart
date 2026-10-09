import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFeed.
  ///
  /// In fr, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get navPublish;

  /// No description provided for @navFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get navFavorites;

  /// No description provided for @navMyCity.
  ///
  /// In fr, this message translates to:
  /// **'Ma Ville'**
  String get navMyCity;

  /// No description provided for @publishWhatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que veux-tu publier ?'**
  String get publishWhatTitle;

  /// No description provided for @publishStoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Story Map Live'**
  String get publishStoryTitle;

  /// No description provided for @publishStorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo / vidéo d\'un évent en cours autour de toi'**
  String get publishStorySubtitle;

  /// No description provided for @publishEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier un event'**
  String get publishEventTitle;

  /// No description provided for @publishEventSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Concert, soirée, expo, atelier…'**
  String get publishEventSubtitle;

  /// No description provided for @eventTypeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel type d\'event ?'**
  String get eventTypeTitle;

  /// No description provided for @eventPrivateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Event privé'**
  String get eventPrivateTitle;

  /// No description provided for @eventPrivateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre amis, code d\'accès, pas dans le feed public'**
  String get eventPrivateSubtitle;

  /// No description provided for @eventPublicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Event public'**
  String get eventPublicTitle;

  /// No description provided for @eventPublicSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Visible par tous, formules à partir de 1,99 €'**
  String get eventPublicSubtitle;

  /// No description provided for @proAccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès pro'**
  String get proAccessTitle;

  /// No description provided for @proAccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte pro : publication gratuite et illimitée'**
  String get proAccessSubtitle;

  /// No description provided for @proMenuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que souhaitez-vous faire ?'**
  String get proMenuTitle;

  /// No description provided for @proAddEvent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un événement'**
  String get proAddEvent;

  /// No description provided for @proAddEventSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier un nouvel event'**
  String get proAddEventSubtitle;

  /// No description provided for @proScanFlyer.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un flyer (IA)'**
  String get proScanFlyer;

  /// No description provided for @proScanFlyerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pré-remplit l\'event à partir d\'une photo'**
  String get proScanFlyerSubtitle;

  /// No description provided for @proCreatePromoOffer.
  ///
  /// In fr, this message translates to:
  /// **'Créer une offre promotionnelle'**
  String get proCreatePromoOffer;

  /// No description provided for @myPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Mes préférences'**
  String get myPreferences;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get accountTitle;

  /// Titre du menu compte
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String accountHello(String name);

  /// No description provided for @accountProSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace pro'**
  String get accountProSpace;

  /// No description provided for @accountCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get accountCreate;

  /// No description provided for @accountCreateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloque stories, favoris et récompenses'**
  String get accountCreateSubtitle;

  /// No description provided for @accountPublishSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Privé, public ou pro'**
  String get accountPublishSubtitle;

  /// No description provided for @accountMyPosts.
  ///
  /// In fr, this message translates to:
  /// **'Mes publications'**
  String get accountMyPosts;

  /// No description provided for @accountMyPostsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements créés'**
  String get accountMyPostsSubtitle;

  /// No description provided for @accountFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get accountFavorites;

  /// No description provided for @accountFavoritesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieux et events aimés'**
  String get accountFavoritesSubtitle;

  /// No description provided for @accountPrivateEvents.
  ///
  /// In fr, this message translates to:
  /// **'Mes events privés'**
  String get accountPrivateEvents;

  /// No description provided for @accountPrivateEventsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Coffres secrets sur invitation'**
  String get accountPrivateEventsSubtitle;

  /// No description provided for @accountOpenVault.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir un coffre'**
  String get accountOpenVault;

  /// No description provided for @accountOpenVaultSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu un lien + code'**
  String get accountOpenVaultSubtitle;

  /// No description provided for @accountInvitations.
  ///
  /// In fr, this message translates to:
  /// **'Mes invitations'**
  String get accountInvitations;

  /// No description provided for @accountInvitationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Soirées où j\'ai dit \"Je viens\"'**
  String get accountInvitationsSubtitle;

  /// No description provided for @accountMemories.
  ///
  /// In fr, this message translates to:
  /// **'Mes souvenirs'**
  String get accountMemories;

  /// No description provided for @accountMemoriesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Albums photo de mes soirées passées'**
  String get accountMemoriesSubtitle;

  /// No description provided for @accountProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get accountProfile;

  /// No description provided for @accountProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ville, centres d\'intérêt'**
  String get accountProfileSubtitle;

  /// No description provided for @accountLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get accountLanguage;

  /// No description provided for @accountProApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte validé'**
  String get accountProApproved;

  /// No description provided for @accountProPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get accountProPending;

  /// No description provided for @accountProEditListing.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma fiche (photos, vidéo)'**
  String get accountProEditListing;

  /// No description provided for @accountCreateOffer.
  ///
  /// In fr, this message translates to:
  /// **'Créer une offre'**
  String get accountCreateOffer;

  /// No description provided for @accountCreateOfferSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier une offre promotionnelle'**
  String get accountCreateOfferSubtitle;

  /// No description provided for @accountMyOffers.
  ///
  /// In fr, this message translates to:
  /// **'Mes offres'**
  String get accountMyOffers;

  /// No description provided for @accountMyOffersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir, modifier ou supprimer'**
  String get accountMyOffersSubtitle;

  /// No description provided for @accountLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get accountLogout;

  /// No description provided for @accountLogoutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter du compte pro'**
  String get accountLogoutSubtitle;

  /// No description provided for @accountProAccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace professionnel'**
  String get accountProAccessSubtitle;

  /// No description provided for @accountDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get accountDelete;

  /// No description provided for @accountDeleteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Action définitive et irréversible'**
  String get accountDeleteSubtitle;

  /// No description provided for @accountDeleteDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer votre compte ?'**
  String get accountDeleteDialogTitle;

  /// No description provided for @accountDeleteProDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Vos données pro seront supprimées et vous ne pourrez plus vous connecter avec cet email. Vous pourrez créer un nouveau compte plus tard si besoin.'**
  String get accountDeleteProDialogBody;

  /// No description provided for @accountDeleteUserDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Ton profil, tes publications, tes stories et tes City-Miles seront supprimés. Tu pourras créer un nouveau compte plus tard si besoin.'**
  String get accountDeleteUserDialogBody;

  /// No description provided for @accountDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get accountDeleted;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression, réessayez'**
  String get accountDeleteFailed;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @languageSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languageSheetTitle;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (langue du téléphone)'**
  String get languageSystem;

  /// No description provided for @languageContentNote.
  ///
  /// In fr, this message translates to:
  /// **'Les fiches et les événements restent pour l\'instant dans leur langue d\'origine.'**
  String get languageContentNote;

  /// No description provided for @rubriqueFood.
  ///
  /// In fr, this message translates to:
  /// **'Food'**
  String get rubriqueFood;

  /// No description provided for @rubriqueCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get rubriqueCulture;

  /// No description provided for @rubriqueFamily.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get rubriqueFamily;

  /// No description provided for @rubriqueNight.
  ///
  /// In fr, this message translates to:
  /// **'Night'**
  String get rubriqueNight;

  /// No description provided for @rubriqueSport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get rubriqueSport;

  /// No description provided for @rubriqueEvasion.
  ///
  /// In fr, this message translates to:
  /// **'Évasion'**
  String get rubriqueEvasion;

  /// No description provided for @onboardingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur MaCity'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWelcomeBack.
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir !'**
  String get onboardingWelcomeBack;

  /// No description provided for @onboardingSignUpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte en quelques secondes'**
  String get onboardingSignUpSubtitle;

  /// No description provided for @onboardingLoginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi avec tes identifiants'**
  String get onboardingLoginSubtitle;

  /// No description provided for @onboardingExploreWithoutAccount.
  ///
  /// In fr, this message translates to:
  /// **'Explorer sans compte'**
  String get onboardingExploreWithoutAccount;

  /// No description provided for @onboardingTabSignUp.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get onboardingTabSignUp;

  /// No description provided for @onboardingTabLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get onboardingTabLogin;

  /// No description provided for @onboardingSubmitSignUp.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get onboardingSubmitSignUp;

  /// No description provided for @onboardingSubmitLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get onboardingSubmitLogin;

  /// No description provided for @onboardingAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Déjà inscrit ? '**
  String get onboardingAlreadyRegistered;

  /// No description provided for @onboardingNoAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get onboardingNoAccountYet;

  /// No description provided for @onboardingSwitchToSignUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get onboardingSwitchToSignUp;

  /// No description provided for @onboardingFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom ou pseudo'**
  String get onboardingFieldName;

  /// No description provided for @onboardingFieldNameError.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre prénom ou pseudo'**
  String get onboardingFieldNameError;

  /// No description provided for @onboardingFieldEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get onboardingFieldEmail;

  /// No description provided for @onboardingFieldEmailEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email'**
  String get onboardingFieldEmailEmpty;

  /// No description provided for @onboardingFieldEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get onboardingFieldEmailInvalid;

  /// No description provided for @onboardingFieldPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get onboardingFieldPhone;

  /// No description provided for @onboardingFieldPhoneEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre numéro'**
  String get onboardingFieldPhoneEmpty;

  /// No description provided for @onboardingFieldPhoneTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop court'**
  String get onboardingFieldPhoneTooShort;

  /// No description provided for @onboardingFieldCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville ou village'**
  String get onboardingFieldCity;

  /// No description provided for @onboardingFieldCityError.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre ville'**
  String get onboardingFieldCityError;

  /// No description provided for @onboardingInterestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelles activités t\'intéressent ?'**
  String get onboardingInterestsTitle;

  /// No description provided for @onboardingInterestsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne tes rubriques pour des notifications pertinentes.'**
  String get onboardingInterestsSubtitle;

  /// No description provided for @onboardingLoginHint.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton email et ton numéro de téléphone\npour retrouver ton compte'**
  String get onboardingLoginHint;

  /// No description provided for @onboardingLoginNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte trouvé avec ces identifiants'**
  String get onboardingLoginNotFound;

  /// No description provided for @onboardingLoginError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion, réessayez'**
  String get onboardingLoginError;

  /// No description provided for @onboardingTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get onboardingTakePhoto;

  /// No description provided for @onboardingChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get onboardingChooseFromGallery;

  /// No description provided for @onboardingRemovePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get onboardingRemovePhoto;

  /// No description provided for @onboardingImageError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de sélectionner cette image'**
  String get onboardingImageError;

  /// No description provided for @emailVerifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre email'**
  String get emailVerifyTitle;

  /// Sous-titre de la verification email
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé à\n{email}'**
  String emailVerifySent(String email);

  /// No description provided for @emailVerifySpamHint.
  ///
  /// In fr, this message translates to:
  /// **'Pas reçu ? Pensez à vérifier vos spams / courriers indésirables.'**
  String get emailVerifySpamHint;

  /// No description provided for @emailVerifyEnterCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code à 6 chiffres'**
  String get emailVerifyEnterCode;

  /// No description provided for @emailVerifyWrongCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré'**
  String get emailVerifyWrongCode;

  /// No description provided for @emailVerifyError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de vérification, réessayez'**
  String get emailVerifyError;

  /// No description provided for @emailVerifyCodeResent.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé'**
  String get emailVerifyCodeResent;

  /// No description provided for @emailVerifyResendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de renvoyer le code'**
  String get emailVerifyResendFailed;

  /// No description provided for @emailVerifyConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get emailVerifyConfirm;

  /// No description provided for @emailVerifySending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get emailVerifySending;

  /// No description provided for @emailVerifyResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get emailVerifyResend;

  /// No description provided for @commonToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get commonTomorrow;

  /// No description provided for @commonFree.
  ///
  /// In fr, this message translates to:
  /// **'GRATUIT'**
  String get commonFree;

  /// No description provided for @commonValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commonValidate;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @catAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get catAll;

  /// No description provided for @catConcerts.
  ///
  /// In fr, this message translates to:
  /// **'Concerts'**
  String get catConcerts;

  /// No description provided for @catParty.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get catParty;

  /// No description provided for @catShow.
  ///
  /// In fr, this message translates to:
  /// **'Spectacle'**
  String get catShow;

  /// No description provided for @catDance.
  ///
  /// In fr, this message translates to:
  /// **'Danse'**
  String get catDance;

  /// No description provided for @catCinema.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get catCinema;

  /// No description provided for @modeDay.
  ///
  /// In fr, this message translates to:
  /// **'Concerts & Spectacles'**
  String get modeDay;

  /// No description provided for @modeSport.
  ///
  /// In fr, this message translates to:
  /// **'Sport & événements sportifs'**
  String get modeSport;

  /// No description provided for @modeCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture & Arts'**
  String get modeCulture;

  /// No description provided for @modeFamily.
  ///
  /// In fr, this message translates to:
  /// **'En Famille'**
  String get modeFamily;

  /// No description provided for @modeFood.
  ///
  /// In fr, this message translates to:
  /// **'Food & lifestyle'**
  String get modeFood;

  /// No description provided for @modeGaming.
  ///
  /// In fr, this message translates to:
  /// **'Gaming & pop culture'**
  String get modeGaming;

  /// No description provided for @modeNight.
  ///
  /// In fr, this message translates to:
  /// **'Nuit & sorties'**
  String get modeNight;

  /// No description provided for @modeTourisme.
  ///
  /// In fr, this message translates to:
  /// **'Tourisme & découvertes'**
  String get modeTourisme;

  /// No description provided for @feedEvents.
  ///
  /// In fr, this message translates to:
  /// **'Évènements'**
  String get feedEvents;

  /// Titre de la recherche par dates
  ///
  /// In fr, this message translates to:
  /// **'Du {start} au {end}'**
  String feedDateRange(String start, String end);

  /// Nombre de resultats de la recherche par dates
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 évènement sur la période} other{{count} évènements sur la période}}'**
  String feedEventsInPeriod(int count);

  /// No description provided for @feedNoEventsInPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucun évènement sur cette période'**
  String get feedNoEventsInPeriod;

  /// Recherche par dates filtree vide
  ///
  /// In fr, this message translates to:
  /// **'Aucun évènement « {category} » sur cette période'**
  String feedNoEventsInPeriodForCategory(String category);

  /// No description provided for @feedSearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un lieu, un event...'**
  String get feedSearchPlaceholder;

  /// No description provided for @feedSearchPlaceholderAlt.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un événement, un lieu...'**
  String get feedSearchPlaceholderAlt;

  /// No description provided for @feedSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom, lieu, artiste...'**
  String get feedSearchHint;

  /// No description provided for @feedPickPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une période'**
  String get feedPickPeriod;

  /// No description provided for @feedMenuOffers.
  ///
  /// In fr, this message translates to:
  /// **'Offres'**
  String get feedMenuOffers;

  /// No description provided for @feedMenuTownHalls.
  ///
  /// In fr, this message translates to:
  /// **'Mairies'**
  String get feedMenuTownHalls;

  /// No description provided for @feedMenuPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get feedMenuPreferences;

  /// No description provided for @feedAllVenues.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les salles'**
  String get feedAllVenues;

  /// No description provided for @feedSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours...'**
  String get feedSearching;

  /// No description provided for @feedForYou.
  ///
  /// In fr, this message translates to:
  /// **'POUR TOI'**
  String get feedForYou;

  /// No description provided for @feedOtherResults.
  ///
  /// In fr, this message translates to:
  /// **'AUTRES RÉSULTATS'**
  String get feedOtherResults;

  /// No description provided for @feedTypeAtLeast2.
  ///
  /// In fr, this message translates to:
  /// **'Tape au moins 2 lettres'**
  String get feedTypeAtLeast2;

  /// No description provided for @feedNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get feedNoResults;

  /// Liste vide d'une categorie
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement {label} à venir'**
  String feedNoUpcomingEventsFor(String label);

  /// No description provided for @feedNoUpcomingEvents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement à venir'**
  String get feedNoUpcomingEvents;

  /// No description provided for @feedOpenOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir sur la carte'**
  String get feedOpenOnMap;

  /// No description provided for @commonSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get commonSeeAll;

  /// No description provided for @commonLearnMore.
  ///
  /// In fr, this message translates to:
  /// **'En savoir plus'**
  String get commonLearnMore;

  /// No description provided for @homeFeaturedPrefix.
  ///
  /// In fr, this message translates to:
  /// **'À la'**
  String get homeFeaturedPrefix;

  /// No description provided for @homeFeaturedAccent.
  ///
  /// In fr, this message translates to:
  /// **'une'**
  String get homeFeaturedAccent;

  /// No description provided for @homeTopPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get homeTopPrefix;

  /// No description provided for @homeTopAccent.
  ///
  /// In fr, this message translates to:
  /// **'top'**
  String get homeTopAccent;

  /// No description provided for @homeBadgeFeatured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get homeBadgeFeatured;

  /// No description provided for @homeBadgeTop.
  ///
  /// In fr, this message translates to:
  /// **'Au top'**
  String get homeBadgeTop;

  /// No description provided for @homeBadgeYourSelection.
  ///
  /// In fr, this message translates to:
  /// **'Ta sélection'**
  String get homeBadgeYourSelection;

  /// No description provided for @homeBadgePinned.
  ///
  /// In fr, this message translates to:
  /// **'ÉPINGLÉ'**
  String get homeBadgePinned;

  /// No description provided for @homePillTop.
  ///
  /// In fr, this message translates to:
  /// **'Top'**
  String get homePillTop;

  /// No description provided for @offersLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les offres'**
  String get offersLoadError;

  /// No description provided for @offersNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre disponible'**
  String get offersNone;

  /// No description provided for @offerClaim.
  ///
  /// In fr, this message translates to:
  /// **'J\'en profite'**
  String get offerClaim;

  /// No description provided for @offersSwipeHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisse pour découvrir'**
  String get offersSwipeHint;

  /// No description provided for @offerSoldOut.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get offerSoldOut;

  /// Places restantes sur une offre
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String offerSpotsLeft(int count);

  /// No description provided for @tonightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les bons plans'**
  String get tonightTitle;

  /// No description provided for @tonightWhatToDo.
  ///
  /// In fr, this message translates to:
  /// **'Quoi faire ce soir'**
  String get tonightWhatToDo;

  /// No description provided for @tonightNothingToday.
  ///
  /// In fr, this message translates to:
  /// **'Rien aujourd\'hui ? Regarde demain'**
  String get tonightNothingToday;

  /// Pastille compteur du bandeau bons plans
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 SORTIE} other{{count} SORTIES}}'**
  String tonightOutingsCount(int count);

  /// No description provided for @tonightOutingsMany.
  ///
  /// In fr, this message translates to:
  /// **'99+ SORTIES'**
  String get tonightOutingsMany;

  /// Accessibilite
  ///
  /// In fr, this message translates to:
  /// **'Rien aujourd\'hui à {city}, regarde demain, bouton'**
  String tonightA11yEmpty(String city);

  /// Accessibilite
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Les bons plans à {city}, 1 sortie, bouton} other{Les bons plans à {city}, {count} sorties, bouton}}'**
  String tonightA11yCount(int count, String city);

  /// Accessibilite
  ///
  /// In fr, this message translates to:
  /// **'Les bons plans à {city}, bouton'**
  String tonightA11y(String city);

  /// No description provided for @tonightLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les bons plans.'**
  String get tonightLoadError;

  /// No description provided for @tonightNothingTonight.
  ///
  /// In fr, this message translates to:
  /// **'Rien ce soir dans cette ville.'**
  String get tonightNothingTonight;

  /// No description provided for @tonightNothingTodayCity.
  ///
  /// In fr, this message translates to:
  /// **'Aucun bon plan aujourd\'hui dans cette ville.'**
  String get tonightNothingTodayCity;

  /// No description provided for @tonightSectionConcerts.
  ///
  /// In fr, this message translates to:
  /// **'Concerts'**
  String get tonightSectionConcerts;

  /// No description provided for @tonightSectionParties.
  ///
  /// In fr, this message translates to:
  /// **'Soirées'**
  String get tonightSectionParties;

  /// No description provided for @tonightSectionShows.
  ///
  /// In fr, this message translates to:
  /// **'Spectacles'**
  String get tonightSectionShows;

  /// No description provided for @tonightSectionOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres sorties'**
  String get tonightSectionOther;

  /// No description provided for @priceFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get priceFree;

  /// No description provided for @priceUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Tarif non communiqué'**
  String get priceUnknown;

  /// No description provided for @priceFreeEntry.
  ///
  /// In fr, this message translates to:
  /// **'entrée libre'**
  String get priceFreeEntry;

  /// Horaire du jour
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui à {time}'**
  String todayAt(String time);

  /// No description provided for @feedMoreSearch.
  ///
  /// In fr, this message translates to:
  /// **'Plus de recherche ? Regarde le feed'**
  String get feedMoreSearch;

  /// No description provided for @commonPartner.
  ///
  /// In fr, this message translates to:
  /// **'PARTENAIRE'**
  String get commonPartner;

  /// No description provided for @favoritesRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get favoritesRemove;

  /// No description provided for @favoritesAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get favoritesAdd;

  /// No description provided for @modeShortDay.
  ///
  /// In fr, this message translates to:
  /// **'Concert'**
  String get modeShortDay;

  /// No description provided for @modeShortGaming.
  ///
  /// In fr, this message translates to:
  /// **'Gaming'**
  String get modeShortGaming;

  /// No description provided for @modeShortNight.
  ///
  /// In fr, this message translates to:
  /// **'Nuit'**
  String get modeShortNight;

  /// No description provided for @modeShortTourisme.
  ///
  /// In fr, this message translates to:
  /// **'Tourisme'**
  String get modeShortTourisme;

  /// No description provided for @rubriqueEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'RUBRIQUE'**
  String get rubriqueEyebrow;

  /// No description provided for @commonToDiscover.
  ///
  /// In fr, this message translates to:
  /// **'À découvrir'**
  String get commonToDiscover;

  /// No description provided for @commonDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get commonDiscover;

  /// No description provided for @commonClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get commonClear;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get commonLoading;

  /// No description provided for @commonOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get commonOpen;

  /// No description provided for @commonCall.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get commonCall;

  /// No description provided for @commonShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get commonShare;

  /// No description provided for @commonTickets.
  ///
  /// In fr, this message translates to:
  /// **'BILLETS'**
  String get commonTickets;

  /// No description provided for @commonTicketOffice.
  ///
  /// In fr, this message translates to:
  /// **'BILLETTERIE'**
  String get commonTicketOffice;

  /// No description provided for @shareFooter.
  ///
  /// In fr, this message translates to:
  /// **'Découvre sur MaCity'**
  String get shareFooter;

  /// No description provided for @filterByVenue.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par salle'**
  String get filterByVenue;

  /// No description provided for @refineAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get refineAll;

  /// No description provided for @landingPartners.
  ///
  /// In fr, this message translates to:
  /// **'Nos partenaires'**
  String get landingPartners;

  /// No description provided for @landingRefine.
  ///
  /// In fr, this message translates to:
  /// **'Affinez votre recherche'**
  String get landingRefine;

  /// No description provided for @landingNoPlaceForSelection.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse pour cette sélection.'**
  String get landingNoPlaceForSelection;

  /// No description provided for @landingUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Contenu indisponible.'**
  String get landingUnavailable;

  /// No description provided for @landingNoPlaceForFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu pour ce filtre.'**
  String get landingNoPlaceForFilter;

  /// No description provided for @landingInspirations.
  ///
  /// In fr, this message translates to:
  /// **'Inspirations du moment'**
  String get landingInspirations;

  /// No description provided for @cultureEyebrowRight.
  ///
  /// In fr, this message translates to:
  /// **'CITÉ'**
  String get cultureEyebrowRight;

  /// No description provided for @cultureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Culture.'**
  String get cultureTitle;

  /// No description provided for @cultureSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Musées, monuments, expos : l\'agenda culturel.'**
  String get cultureSubtitle;

  /// No description provided for @cultureChipMuseums.
  ///
  /// In fr, this message translates to:
  /// **'Musées'**
  String get cultureChipMuseums;

  /// No description provided for @cultureChipMonuments.
  ///
  /// In fr, this message translates to:
  /// **'Monuments'**
  String get cultureChipMonuments;

  /// No description provided for @cultureChipLibraries.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèques'**
  String get cultureChipLibraries;

  /// No description provided for @cultureChipGalleries.
  ///
  /// In fr, this message translates to:
  /// **'Galeries'**
  String get cultureChipGalleries;

  /// No description provided for @cultureBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'La ville se raconte.'**
  String get cultureBannerTitle;

  /// No description provided for @cultureBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Musées, expos et patrimoine vous attendent.'**
  String get cultureBannerSubtitle;

  /// No description provided for @cultureMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieux culturels'**
  String get cultureMapTitle;

  /// No description provided for @cultureKickerHome.
  ///
  /// In fr, this message translates to:
  /// **'Rubrique · Cité'**
  String get cultureKickerHome;

  /// No description provided for @cultureBlurb.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma, théâtre, expositions, danse : l\'agenda culturel.'**
  String get cultureBlurb;

  /// No description provided for @cultureCatMuseum.
  ///
  /// In fr, this message translates to:
  /// **'Musée'**
  String get cultureCatMuseum;

  /// No description provided for @cultureCatTheatre.
  ///
  /// In fr, this message translates to:
  /// **'Théâtre'**
  String get cultureCatTheatre;

  /// No description provided for @cultureCatGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie d\'art'**
  String get cultureCatGallery;

  /// No description provided for @cultureCatMonument.
  ///
  /// In fr, this message translates to:
  /// **'Monument historique'**
  String get cultureCatMonument;

  /// No description provided for @cultureCatLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get cultureCatLibrary;

  /// No description provided for @cultureCatGuidedTours.
  ///
  /// In fr, this message translates to:
  /// **'Visites guidées'**
  String get cultureCatGuidedTours;

  /// No description provided for @cultureCatExhibition.
  ///
  /// In fr, this message translates to:
  /// **'Exposition'**
  String get cultureCatExhibition;

  /// No description provided for @cultureCatUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get cultureCatUpcoming;

  /// No description provided for @cultureNoMuseum.
  ///
  /// In fr, this message translates to:
  /// **'Aucun musée trouvé'**
  String get cultureNoMuseum;

  /// No description provided for @cultureMuseumError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des musées'**
  String get cultureMuseumError;

  /// No description provided for @cultureNoTheatreEvent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement théâtre à venir'**
  String get cultureNoTheatreEvent;

  /// No description provided for @cultureNoEventForFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement pour ce filtre'**
  String get cultureNoEventForFilter;

  /// No description provided for @cultureNoScreening.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance de cinéma à venir'**
  String get cultureNoScreening;

  /// No description provided for @cultureNoScreeningForFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance pour ce filtre'**
  String get cultureNoScreeningForFilter;

  /// No description provided for @cultureNoDance.
  ///
  /// In fr, this message translates to:
  /// **'Aucune salle de danse trouvée'**
  String get cultureNoDance;

  /// No description provided for @cultureDanceError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des salles de danse'**
  String get cultureDanceError;

  /// No description provided for @cultureNoGallery.
  ///
  /// In fr, this message translates to:
  /// **'Aucune galerie trouvée'**
  String get cultureNoGallery;

  /// No description provided for @cultureGalleryError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des galeries'**
  String get cultureGalleryError;

  /// No description provided for @cultureNoLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Aucune bibliothèque trouvée'**
  String get cultureNoLibrary;

  /// No description provided for @cultureLibraryError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des bibliothèques'**
  String get cultureLibraryError;

  /// No description provided for @cultureNoMonument.
  ///
  /// In fr, this message translates to:
  /// **'Aucun monument trouvé'**
  String get cultureNoMonument;

  /// No description provided for @cultureMonumentError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des monuments'**
  String get cultureMonumentError;

  /// No description provided for @cultureNoGuidedTour.
  ///
  /// In fr, this message translates to:
  /// **'Aucune visite guidée à venir'**
  String get cultureNoGuidedTour;

  /// No description provided for @cultureGuidedTourError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des visites guidées'**
  String get cultureGuidedTourError;

  /// No description provided for @cultureNoExhibition.
  ///
  /// In fr, this message translates to:
  /// **'Aucune exposition à venir'**
  String get cultureNoExhibition;

  /// No description provided for @cultureExhibitionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des expositions'**
  String get cultureExhibitionError;

  /// No description provided for @cultureNoEvent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement culturel à venir'**
  String get cultureNoEvent;

  /// No description provided for @cultureEventError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des événements culturels'**
  String get cultureEventError;

  /// No description provided for @cultureNoVenueForCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu culturel trouvé pour cette catégorie'**
  String get cultureNoVenueForCategory;

  /// No description provided for @cultureVenueError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des lieux culturels'**
  String get cultureVenueError;

  /// No description provided for @museumCatArt.
  ///
  /// In fr, this message translates to:
  /// **'Art'**
  String get museumCatArt;

  /// No description provided for @museumCatHistory.
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get museumCatHistory;

  /// No description provided for @museumCatScience.
  ///
  /// In fr, this message translates to:
  /// **'Science'**
  String get museumCatScience;

  /// No description provided for @danceGroupGeneral.
  ///
  /// In fr, this message translates to:
  /// **'École générale'**
  String get danceGroupGeneral;

  /// No description provided for @danceGroupSpecialisation.
  ///
  /// In fr, this message translates to:
  /// **'Spécialisation & style'**
  String get danceGroupSpecialisation;

  /// No description provided for @danceGroupPro.
  ///
  /// In fr, this message translates to:
  /// **'Formation professionnelle'**
  String get danceGroupPro;

  /// No description provided for @danceGroupOther.
  ///
  /// In fr, this message translates to:
  /// **'École de danse'**
  String get danceGroupOther;

  /// Nombre de spectacles a venir d'une salle
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun spectacle à venir} =1{1 spectacle à venir} other{{count} spectacles à venir}}'**
  String theatreUpcomingShows(int count);

  /// No description provided for @commonClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get commonClosed;

  /// No description provided for @commonLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get commonLoadError;

  /// No description provided for @commonMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get commonMap;

  /// No description provided for @commonList.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get commonList;

  /// No description provided for @commonCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get commonCategories;

  /// No description provided for @commonView.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get commonView;

  /// No description provided for @commonNoSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sous-catégorie'**
  String get commonNoSubcategory;

  /// No description provided for @commonNoPlaceForCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun commerce trouvé pour cette catégorie'**
  String get commonNoPlaceForCategory;

  /// No description provided for @commonPlacesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des commerces'**
  String get commonPlacesLoadError;

  /// No description provided for @commonNoEventYetAdd.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement pour le moment.\nAjoute un événement avec le bouton +'**
  String get commonNoEventYetAdd;

  /// No description provided for @mapNearestBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar le plus proche'**
  String get mapNearestBar;

  /// No description provided for @mapNearestClub.
  ///
  /// In fr, this message translates to:
  /// **'Club le plus proche'**
  String get mapNearestClub;

  /// No description provided for @mapNearestPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu le plus proche'**
  String get mapNearestPlace;

  /// No description provided for @nightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nuit.'**
  String get nightTitle;

  /// No description provided for @nightSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Clubs, bars, soirées : la ville change de visage.'**
  String get nightSubtitle;

  /// No description provided for @nightSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où sortir'**
  String get nightSectionTitle;

  /// No description provided for @nightChipClub.
  ///
  /// In fr, this message translates to:
  /// **'Discothèque'**
  String get nightChipClub;

  /// No description provided for @nightChipNightBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar de nuit'**
  String get nightChipNightBar;

  /// No description provided for @nightChipCocktails.
  ///
  /// In fr, this message translates to:
  /// **'Cocktails'**
  String get nightChipCocktails;

  /// No description provided for @nightChipShisha.
  ///
  /// In fr, this message translates to:
  /// **'Chicha'**
  String get nightChipShisha;

  /// No description provided for @nightBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'La nuit t\'appartient.'**
  String get nightBannerTitle;

  /// No description provided for @nightBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleurs spots nocturnes vous attendent.'**
  String get nightBannerSubtitle;

  /// No description provided for @nightUntil2.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 2h'**
  String get nightUntil2;

  /// No description provided for @nightAfter2.
  ///
  /// In fr, this message translates to:
  /// **'Après 2h'**
  String get nightAfter2;

  /// No description provided for @nightAfter6.
  ///
  /// In fr, this message translates to:
  /// **'Après 6h'**
  String get nightAfter6;

  /// No description provided for @nightAllNight.
  ///
  /// In fr, this message translates to:
  /// **'24h/24'**
  String get nightAllNight;

  /// No description provided for @nightMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sortir ce soir'**
  String get nightMapTitle;

  /// No description provided for @nightCatClub.
  ///
  /// In fr, this message translates to:
  /// **'Club disco'**
  String get nightCatClub;

  /// No description provided for @nightCatNightBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar de nuit'**
  String get nightCatNightBar;

  /// No description provided for @nightCatCocktails.
  ///
  /// In fr, this message translates to:
  /// **'Cocktails'**
  String get nightCatCocktails;

  /// No description provided for @nightCatShisha.
  ///
  /// In fr, this message translates to:
  /// **'Chicha'**
  String get nightCatShisha;

  /// No description provided for @nightCatPub.
  ///
  /// In fr, this message translates to:
  /// **'Pub'**
  String get nightCatPub;

  /// No description provided for @sosAperoOne.
  ///
  /// In fr, this message translates to:
  /// **'Une enseigne livre quand tout est fermé'**
  String get sosAperoOne;

  /// Bandeau SOS Apero
  ///
  /// In fr, this message translates to:
  /// **'{count} enseignes livrent quand tout est fermé'**
  String sosAperoMany(int count);

  /// No description provided for @nightPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compose ta soirée'**
  String get nightPlanTitle;

  /// No description provided for @nightPlanSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Dîner · concert · bar · boîte'**
  String get nightPlanSubtitle;

  /// No description provided for @nightPlanDinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get nightPlanDinner;

  /// No description provided for @nightPlanDinnerHint.
  ///
  /// In fr, this message translates to:
  /// **'Avant le show'**
  String get nightPlanDinnerHint;

  /// No description provided for @nightPlanDrink.
  ///
  /// In fr, this message translates to:
  /// **'Un verre'**
  String get nightPlanDrink;

  /// No description provided for @nightPlanDrinkHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour prolonger la soirée'**
  String get nightPlanDrinkHint;

  /// No description provided for @nightPlanClub.
  ///
  /// In fr, this message translates to:
  /// **'En boîte'**
  String get nightPlanClub;

  /// No description provided for @nightPlanClubHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour finir la nuit'**
  String get nightPlanClubHint;

  /// No description provided for @nightPlanYourEvent.
  ///
  /// In fr, this message translates to:
  /// **'TON ÉVÉNEMENT'**
  String get nightPlanYourEvent;

  /// No description provided for @nightPlanGoFurther.
  ///
  /// In fr, this message translates to:
  /// **'Aller encore plus loin : une boîte de nuit'**
  String get nightPlanGoFurther;

  /// No description provided for @nightPlanGo.
  ///
  /// In fr, this message translates to:
  /// **'Y aller'**
  String get nightPlanGo;

  /// No description provided for @nightPlanPartner.
  ///
  /// In fr, this message translates to:
  /// **'⭐ Partenaire'**
  String get nightPlanPartner;

  /// No description provided for @nightPlanEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de suggestions'**
  String get nightPlanEmptyTitle;

  /// Compose ta soiree vide
  ///
  /// In fr, this message translates to:
  /// **'On n\'a pas trouvé de lieux à {city} pour composer ta soirée. Reviens quand la ville sera plus fournie !'**
  String nightPlanEmptyBody(String city);

  /// No description provided for @ticketsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Billetterie'**
  String get ticketsLabel;

  /// No description provided for @ticketsShort.
  ///
  /// In fr, this message translates to:
  /// **'Billets'**
  String get ticketsShort;

  /// No description provided for @websiteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get websiteLabel;

  /// Texte de partage
  ///
  /// In fr, this message translates to:
  /// **'Date : {date}'**
  String shareDate(String date);

  /// Texte de partage
  ///
  /// In fr, this message translates to:
  /// **'Lieu : {venue}'**
  String shareVenue(String venue);

  /// No description provided for @countdownToday.
  ///
  /// In fr, this message translates to:
  /// **'AUJOURD\'HUI'**
  String get countdownToday;

  /// No description provided for @countdownTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'DEMAIN'**
  String get countdownTomorrow;

  /// Compte a rebours avant un match
  ///
  /// In fr, this message translates to:
  /// **'J-{count}'**
  String countdownDays(int count);

  /// No description provided for @commonNoEventFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement trouvé'**
  String get commonNoEventFound;

  /// No description provided for @mapNearest.
  ///
  /// In fr, this message translates to:
  /// **'Le plus proche'**
  String get mapNearest;

  /// No description provided for @mapDirections.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get mapDirections;

  /// No description provided for @mapMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get mapMyLocation;

  /// Distance au lieu le plus proche
  ///
  /// In fr, this message translates to:
  /// **'à {distance} de vous'**
  String mapDistanceAway(String distance);

  /// No description provided for @mapLocationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Active la localisation dans les paramètres'**
  String get mapLocationDisabled;

  /// No description provided for @mapLocationNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Autorise la localisation dans les paramètres de l\'appli'**
  String get mapLocationNotAllowed;

  /// No description provided for @mapPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée'**
  String get mapPermissionDenied;

  /// Erreur de geolocalisation
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'obtenir la position : {error}'**
  String mapLocationError(String error);

  /// No description provided for @sportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sport.'**
  String get sportTitle;

  /// No description provided for @sportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Salles, terrains, piscines : bouger près de chez toi.'**
  String get sportSubtitle;

  /// No description provided for @sportSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où pratiquer'**
  String get sportSectionTitle;

  /// No description provided for @sportChipGroupClasses.
  ///
  /// In fr, this message translates to:
  /// **'Cours Co'**
  String get sportChipGroupClasses;

  /// No description provided for @sportChipWeights.
  ///
  /// In fr, this message translates to:
  /// **'Muscu'**
  String get sportChipWeights;

  /// No description provided for @sportChipGentle.
  ///
  /// In fr, this message translates to:
  /// **'Gym Douce'**
  String get sportChipGentle;

  /// No description provided for @sportChipBasket.
  ///
  /// In fr, this message translates to:
  /// **'Basket'**
  String get sportChipBasket;

  /// No description provided for @sportChipPool.
  ///
  /// In fr, this message translates to:
  /// **'Piscine'**
  String get sportChipPool;

  /// No description provided for @sportBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passe à l\'action.'**
  String get sportBannerTitle;

  /// No description provided for @sportBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleurs spots sportifs vous attendent.'**
  String get sportBannerSubtitle;

  /// No description provided for @sportMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieux de sport'**
  String get sportMapTitle;

  /// Nombre de salles d'une chaine
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 salle} other{{count} salles}}'**
  String sportGymCount(int count);

  /// No description provided for @sportKickerHome.
  ///
  /// In fr, this message translates to:
  /// **'Rubrique · Active'**
  String get sportKickerHome;

  /// No description provided for @sportBlurb.
  ///
  /// In fr, this message translates to:
  /// **'Matchs, courses, entraînement : l\'agenda sportif de la ville.'**
  String get sportBlurb;

  /// No description provided for @sportNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match trouvé pour cette catégorie'**
  String get sportNoMatch;

  /// No description provided for @sportMatchError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des matchs'**
  String get sportMatchError;

  /// No description provided for @sportNews.
  ///
  /// In fr, this message translates to:
  /// **'Actu sport'**
  String get sportNews;

  /// No description provided for @sportReadArticle.
  ///
  /// In fr, this message translates to:
  /// **'Lire l\'article'**
  String get sportReadArticle;

  /// Lien vers un article
  ///
  /// In fr, this message translates to:
  /// **'Lire sur {source}'**
  String sportReadOn(String source);

  /// No description provided for @sportCatMatches.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get sportCatMatches;

  /// No description provided for @sportCatEvents.
  ///
  /// In fr, this message translates to:
  /// **'Events'**
  String get sportCatEvents;

  /// No description provided for @sportCatComplex.
  ///
  /// In fr, this message translates to:
  /// **'Complexe sportif'**
  String get sportCatComplex;

  /// No description provided for @sportCatMarathon.
  ///
  /// In fr, this message translates to:
  /// **'Marathon'**
  String get sportCatMarathon;

  /// No description provided for @sportCatRacket.
  ///
  /// In fr, this message translates to:
  /// **'Raquette'**
  String get sportCatRacket;

  /// No description provided for @sportCatBoxing.
  ///
  /// In fr, this message translates to:
  /// **'Boxe'**
  String get sportCatBoxing;

  /// No description provided for @sportCatSwimming.
  ///
  /// In fr, this message translates to:
  /// **'Natation'**
  String get sportCatSwimming;

  /// No description provided for @sportCatRunning.
  ///
  /// In fr, this message translates to:
  /// **'Courses à pied'**
  String get sportCatRunning;

  /// No description provided for @sportCatCompetition.
  ///
  /// In fr, this message translates to:
  /// **'Compétition'**
  String get sportCatCompetition;

  /// No description provided for @sportCatDanceWorkshop.
  ///
  /// In fr, this message translates to:
  /// **'Stage de danse'**
  String get sportCatDanceWorkshop;

  /// No description provided for @sportCatGym.
  ///
  /// In fr, this message translates to:
  /// **'Salle de fitness'**
  String get sportCatGym;

  /// No description provided for @sportCatBoxingGym.
  ///
  /// In fr, this message translates to:
  /// **'Salles de boxe'**
  String get sportCatBoxingGym;

  /// No description provided for @sportCatFootballPitch.
  ///
  /// In fr, this message translates to:
  /// **'Terrain de football'**
  String get sportCatFootballPitch;

  /// No description provided for @sportCatBasketCourt.
  ///
  /// In fr, this message translates to:
  /// **'Terrain de basketball'**
  String get sportCatBasketCourt;

  /// No description provided for @sportCatPool.
  ///
  /// In fr, this message translates to:
  /// **'Piscine'**
  String get sportCatPool;

  /// No description provided for @sportCatPadel.
  ///
  /// In fr, this message translates to:
  /// **'Padel'**
  String get sportCatPadel;

  /// No description provided for @sportCatTableTennis.
  ///
  /// In fr, this message translates to:
  /// **'Ping-pong'**
  String get sportCatTableTennis;

  /// No description provided for @sportCatBadminton.
  ///
  /// In fr, this message translates to:
  /// **'Badminton'**
  String get sportCatBadminton;

  /// No description provided for @sportCatFootball.
  ///
  /// In fr, this message translates to:
  /// **'Football'**
  String get sportCatFootball;

  /// No description provided for @sportCatBasketball.
  ///
  /// In fr, this message translates to:
  /// **'Basketball'**
  String get sportCatBasketball;

  /// No description provided for @sportCatHandball.
  ///
  /// In fr, this message translates to:
  /// **'Handball'**
  String get sportCatHandball;

  /// No description provided for @sportCatGala.
  ///
  /// In fr, this message translates to:
  /// **'Gala / Matchs'**
  String get sportCatGala;

  /// No description provided for @sportCatOlympics.
  ///
  /// In fr, this message translates to:
  /// **'JO 2028'**
  String get sportCatOlympics;

  /// No description provided for @familyEyebrowRight.
  ///
  /// In fr, this message translates to:
  /// **'EN TRIBU'**
  String get familyEyebrowRight;

  /// No description provided for @familyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Famille.'**
  String get familyTitle;

  /// No description provided for @familySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma, parcs, ateliers : sortir avec les enfants.'**
  String get familySubtitle;

  /// No description provided for @familySectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'À faire en famille'**
  String get familySectionTitle;

  /// No description provided for @familyBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Des souvenirs à créer en tribu.'**
  String get familyBannerTitle;

  /// No description provided for @familyBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleures sorties enfants vous attendent.'**
  String get familyBannerSubtitle;

  /// No description provided for @familyMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieux famille'**
  String get familyMapTitle;

  /// No description provided for @familyAllAges.
  ///
  /// In fr, this message translates to:
  /// **'Pour tous'**
  String get familyAllAges;

  /// No description provided for @familyAge0to3.
  ///
  /// In fr, this message translates to:
  /// **'0-3 ans'**
  String get familyAge0to3;

  /// Filtre d'age
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à {max} ans'**
  String familyUpToAge(int max);

  /// No description provided for @familyKickerHome.
  ///
  /// In fr, this message translates to:
  /// **'Rubrique · En tribu'**
  String get familyKickerHome;

  /// No description provided for @familyNoEvent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement famille pour le moment'**
  String get familyNoEvent;

  /// No description provided for @familySessions.
  ///
  /// In fr, this message translates to:
  /// **'SÉANCES'**
  String get familySessions;

  /// Tarif d'un lieu
  ///
  /// In fr, this message translates to:
  /// **'Tarif : {price}'**
  String priceLabel(String price);

  /// No description provided for @shareFooterPointing.
  ///
  /// In fr, this message translates to:
  /// **'Découvre sur MaCity 👉'**
  String get shareFooterPointing;

  /// No description provided for @familyGroupEntertainment.
  ///
  /// In fr, this message translates to:
  /// **'Divertissements'**
  String get familyGroupEntertainment;

  /// No description provided for @familyGroupKidsPlay.
  ///
  /// In fr, this message translates to:
  /// **'Jeux d\'enfants'**
  String get familyGroupKidsPlay;

  /// No description provided for @familyGroupAnimals.
  ///
  /// In fr, this message translates to:
  /// **'Animaux et Nature'**
  String get familyGroupAnimals;

  /// No description provided for @familyGroupWater.
  ///
  /// In fr, this message translates to:
  /// **'Activité aquatique'**
  String get familyGroupWater;

  /// No description provided for @familyGroupOutdoor.
  ///
  /// In fr, this message translates to:
  /// **'Sortie en plein air'**
  String get familyGroupOutdoor;

  /// No description provided for @familyGroupDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get familyGroupDiscover;

  /// No description provided for @familyCatCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get familyCatCalendar;

  /// No description provided for @familyCatThemePark.
  ///
  /// In fr, this message translates to:
  /// **'Parc d\'attractions'**
  String get familyCatThemePark;

  /// No description provided for @familyCatLaserGame.
  ///
  /// In fr, this message translates to:
  /// **'Laser game'**
  String get familyCatLaserGame;

  /// No description provided for @familyCatEscapeGame.
  ///
  /// In fr, this message translates to:
  /// **'Escape game'**
  String get familyCatEscapeGame;

  /// No description provided for @familyCatBowling.
  ///
  /// In fr, this message translates to:
  /// **'Bowling'**
  String get familyCatBowling;

  /// No description provided for @familyCatIceRink.
  ///
  /// In fr, this message translates to:
  /// **'Patinoire'**
  String get familyCatIceRink;

  /// No description provided for @familyCatPlayground.
  ///
  /// In fr, this message translates to:
  /// **'Aire de jeux'**
  String get familyCatPlayground;

  /// No description provided for @familyCatLeisurePark.
  ///
  /// In fr, this message translates to:
  /// **'Parc de loisirs'**
  String get familyCatLeisurePark;

  /// No description provided for @familyCatWildlifePark.
  ///
  /// In fr, this message translates to:
  /// **'Parc animalier'**
  String get familyCatWildlifePark;

  /// No description provided for @familyCatFarm.
  ///
  /// In fr, this message translates to:
  /// **'Ferme pédagogique'**
  String get familyCatFarm;

  /// No description provided for @familyCatAquarium.
  ///
  /// In fr, this message translates to:
  /// **'Aquarium'**
  String get familyCatAquarium;

  /// No description provided for @familyCatZoo.
  ///
  /// In fr, this message translates to:
  /// **'Zoo'**
  String get familyCatZoo;

  /// No description provided for @familyCatBotanicGarden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin botanique'**
  String get familyCatBotanicGarden;

  /// No description provided for @familyCatWaterPark.
  ///
  /// In fr, this message translates to:
  /// **'Centre aquatique'**
  String get familyCatWaterPark;

  /// No description provided for @familyCatParks.
  ///
  /// In fr, this message translates to:
  /// **'Parcs'**
  String get familyCatParks;

  /// No description provided for @familyCatWalks.
  ///
  /// In fr, this message translates to:
  /// **'Balades familiales'**
  String get familyCatWalks;

  /// No description provided for @familyCatTreetop.
  ///
  /// In fr, this message translates to:
  /// **'Accrobranche'**
  String get familyCatTreetop;

  /// No description provided for @familyCatMiniGolf.
  ///
  /// In fr, this message translates to:
  /// **'Mini golf'**
  String get familyCatMiniGolf;

  /// No description provided for @familyCatLeisureBase.
  ///
  /// In fr, this message translates to:
  /// **'Base de loisirs'**
  String get familyCatLeisureBase;

  /// No description provided for @familyCatKidsMuseum.
  ///
  /// In fr, this message translates to:
  /// **'Musée pour enfants'**
  String get familyCatKidsMuseum;

  /// No description provided for @familyCatPlanetarium.
  ///
  /// In fr, this message translates to:
  /// **'Planétarium'**
  String get familyCatPlanetarium;

  /// No description provided for @familyCatWorkshop.
  ///
  /// In fr, this message translates to:
  /// **'Atelier créatif'**
  String get familyCatWorkshop;

  /// No description provided for @familyCatRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant familial'**
  String get familyCatRestaurant;

  /// No description provided for @evasionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évasion.'**
  String get evasionTitle;

  /// No description provided for @evasionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Escapades et week-ends autour de chez vous.'**
  String get evasionSubtitle;

  /// Temps de trajet
  ///
  /// In fr, this message translates to:
  /// **'À {hours}h'**
  String evasionWithinHours(int hours);

  /// No description provided for @evasionNoPlaceForFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucune adresse pour ce filtre.'**
  String get evasionNoPlaceForFilter;

  /// No description provided for @tourismeKickerHome.
  ///
  /// In fr, this message translates to:
  /// **'Rubrique · Visite'**
  String get tourismeKickerHome;

  /// No description provided for @tourismeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tourisme'**
  String get tourismeTitle;

  /// No description provided for @tourismeBlurb.
  ///
  /// In fr, this message translates to:
  /// **'Monuments, transports, incontournables : la ville pour les visiteurs.'**
  String get tourismeBlurb;

  /// No description provided for @tourismeTopMustSee.
  ///
  /// In fr, this message translates to:
  /// **'Top incontournables'**
  String get tourismeTopMustSee;

  /// No description provided for @tourismeVisit.
  ///
  /// In fr, this message translates to:
  /// **'Visiter'**
  String get tourismeVisit;

  /// No description provided for @tourismeGetAround.
  ///
  /// In fr, this message translates to:
  /// **'Se déplacer'**
  String get tourismeGetAround;

  /// No description provided for @tourismeNoPlace.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu à visiter'**
  String get tourismeNoPlace;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get commonError;

  /// No description provided for @tourismeCatMonument.
  ///
  /// In fr, this message translates to:
  /// **'Monuments'**
  String get tourismeCatMonument;

  /// No description provided for @tourismeCatMuseum.
  ///
  /// In fr, this message translates to:
  /// **'Musées'**
  String get tourismeCatMuseum;

  /// No description provided for @tourismeCatAttraction.
  ///
  /// In fr, this message translates to:
  /// **'Attractions'**
  String get tourismeCatAttraction;

  /// No description provided for @tourismeCatNature.
  ///
  /// In fr, this message translates to:
  /// **'Sites naturels'**
  String get tourismeCatNature;

  /// No description provided for @tourismeCatSquare.
  ///
  /// In fr, this message translates to:
  /// **'Places'**
  String get tourismeCatSquare;

  /// No description provided for @tourismeCatCultural.
  ///
  /// In fr, this message translates to:
  /// **'Lieux culturels'**
  String get tourismeCatCultural;

  /// No description provided for @tourismeCatTouristOffice.
  ///
  /// In fr, this message translates to:
  /// **'Office de tourisme'**
  String get tourismeCatTouristOffice;

  /// No description provided for @tourismeCatDistrict.
  ///
  /// In fr, this message translates to:
  /// **'Quartiers'**
  String get tourismeCatDistrict;

  /// No description provided for @tourismeTipTodo.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get tourismeTipTodo;

  /// No description provided for @tourismeTipFood.
  ///
  /// In fr, this message translates to:
  /// **'Gastronomie'**
  String get tourismeTipFood;

  /// No description provided for @tourismeTipExcursion.
  ///
  /// In fr, this message translates to:
  /// **'Excursions'**
  String get tourismeTipExcursion;

  /// No description provided for @tourismeTipDeals.
  ///
  /// In fr, this message translates to:
  /// **'Bons plans'**
  String get tourismeTipDeals;

  /// Transport pas encore renseigne
  ///
  /// In fr, this message translates to:
  /// **'Infos transport pour {city}\nbientôt disponibles'**
  String transportComingSoon(String city);

  /// No description provided for @transportMetro.
  ///
  /// In fr, this message translates to:
  /// **'Métro'**
  String get transportMetro;

  /// No description provided for @transportTram.
  ///
  /// In fr, this message translates to:
  /// **'Tramway'**
  String get transportTram;

  /// No description provided for @transportBike.
  ///
  /// In fr, this message translates to:
  /// **'Vélo en libre-service'**
  String get transportBike;

  /// No description provided for @transportBikeShort.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get transportBikeShort;

  /// Nombre de stations
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 station} other{{count} stations}}'**
  String transportStations(int count);

  /// Nombre d'arrets
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arrêt} other{{count} arrêts}}'**
  String transportStops(int count);

  /// No description provided for @detailPartner.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire'**
  String get detailPartner;

  /// No description provided for @detailPartnerEstate.
  ///
  /// In fr, this message translates to:
  /// **'Domaine partenaire'**
  String get detailPartnerEstate;

  /// No description provided for @detailClaim.
  ///
  /// In fr, this message translates to:
  /// **'Revendiquer'**
  String get detailClaim;

  /// No description provided for @detailLiked.
  ///
  /// In fr, this message translates to:
  /// **'Aimé'**
  String get detailLiked;

  /// No description provided for @detailLike.
  ///
  /// In fr, this message translates to:
  /// **'Aimer'**
  String get detailLike;

  /// Texte de partage
  ///
  /// In fr, this message translates to:
  /// **'Horaires : {hours}'**
  String detailOpeningHours(String hours);

  /// No description provided for @reviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviewsTitle;

  /// No description provided for @reviewsGive.
  ///
  /// In fr, this message translates to:
  /// **'Donner mon avis'**
  String get reviewsGive;

  /// No description provided for @reviewsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon avis'**
  String get reviewsEdit;

  /// No description provided for @reviewsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour le moment. Sois le premier !'**
  String get reviewsNone;

  /// No description provided for @reviewsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les avis'**
  String get reviewsLoadError;

  /// No description provided for @reviewsNotRated.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore noté'**
  String get reviewsNotRated;

  /// No description provided for @reviewsYou.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get reviewsYou;

  /// No description provided for @reviewsPickRating.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une note avant de publier'**
  String get reviewsPickRating;

  /// No description provided for @reviewsPostFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec : réessaie dans un instant'**
  String get reviewsPostFailed;

  /// No description provided for @reviewsDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression'**
  String get reviewsDeleteFailed;

  /// No description provided for @reviewsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton ressenti, en quelques mots...'**
  String get reviewsHint;

  /// No description provided for @commonPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get commonPublish;

  /// No description provided for @eventMyNight.
  ///
  /// In fr, this message translates to:
  /// **'Ma soirée'**
  String get eventMyNight;

  /// No description provided for @eventInfo.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get eventInfo;

  /// Organisateur d'un evenement
  ///
  /// In fr, this message translates to:
  /// **'Par {name}'**
  String eventBy(String name);

  /// Nombre de seances
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Séance} other{{count} séances}}'**
  String eventSessions(int count);

  /// No description provided for @eventPreviousStory.
  ///
  /// In fr, this message translates to:
  /// **'Story précédente'**
  String get eventPreviousStory;

  /// No description provided for @eventSwipeNext.
  ///
  /// In fr, this message translates to:
  /// **'Swipe pour la suivante'**
  String get eventSwipeNext;

  /// No description provided for @eventMore.
  ///
  /// In fr, this message translates to:
  /// **'plus'**
  String get eventMore;

  /// No description provided for @eventAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get eventAbout;

  /// No description provided for @eventNoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description fournie pour cet évènement.'**
  String get eventNoDescription;

  /// No description provided for @eventShareCaption.
  ///
  /// In fr, this message translates to:
  /// **'Découvre cet évènement sur MaCity 👇'**
  String get eventShareCaption;

  /// No description provided for @updateRequiredDefault.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version est requise pour continuer à utiliser l\'application.'**
  String get updateRequiredDefault;

  /// No description provided for @updateTitlePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Mise à '**
  String get updateTitlePrefix;

  /// No description provided for @updateTitleAccent.
  ///
  /// In fr, this message translates to:
  /// **'jour'**
  String get updateTitleAccent;

  /// Version disponible
  ///
  /// In fr, this message translates to:
  /// **'v{version} disponible'**
  String updateVersionAvailable(String version);

  /// No description provided for @updateNow.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateNow;

  /// No description provided for @updateOpenAppStore.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'App Store'**
  String get updateOpenAppStore;

  /// No description provided for @updateLatestFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Pour profiter des dernières fonctionnalités'**
  String get updateLatestFeatures;

  /// No description provided for @updateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version disponible'**
  String get updateAvailable;

  /// No description provided for @commonLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get commonLater;

  /// Incitation a creer un compte
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte pour {action}'**
  String gateTitle(String action);

  /// No description provided for @gateBody.
  ///
  /// In fr, this message translates to:
  /// **'Ça prend 30 secondes. Tu débloques aussi tes favoris et tes récompenses.'**
  String get gateBody;

  /// No description provided for @gateActionPublishEvent.
  ///
  /// In fr, this message translates to:
  /// **'publier un event'**
  String get gateActionPublishEvent;

  /// No description provided for @gateActionPostStory.
  ///
  /// In fr, this message translates to:
  /// **'poster une story'**
  String get gateActionPostStory;

  /// No description provided for @gateActionChat.
  ///
  /// In fr, this message translates to:
  /// **'participer à la discussion'**
  String get gateActionChat;

  /// No description provided for @gateActionConfirm.
  ///
  /// In fr, this message translates to:
  /// **'confirmer ta venue'**
  String get gateActionConfirm;

  /// No description provided for @gateActionAddPhotos.
  ///
  /// In fr, this message translates to:
  /// **'ajouter des photos'**
  String get gateActionAddPhotos;

  /// No description provided for @verifiedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verifiedLabel;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @dateFilter7Days.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get dateFilter7Days;

  /// No description provided for @dateFilter30Days.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get dateFilter30Days;

  /// No description provided for @dateFilterDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateFilterDate;

  /// No description provided for @liveTitle.
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get liveTitle;

  /// No description provided for @liveAroundYou.
  ///
  /// In fr, this message translates to:
  /// **'autour de vous'**
  String get liveAroundYou;

  /// No description provided for @liveStoryFallback.
  ///
  /// In fr, this message translates to:
  /// **'Story Map Live'**
  String get liveStoryFallback;

  /// No description provided for @timeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeJustNow;

  /// Temps relatif
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String timeMinutesAgo(int count);

  /// Temps relatif
  ///
  /// In fr, this message translates to:
  /// **'il y a {count}h'**
  String timeHoursAgo(int count);

  /// Temps relatif
  ///
  /// In fr, this message translates to:
  /// **'il y a {count}j'**
  String timeDaysAgo(int count);

  /// No description provided for @ofDayFood.
  ///
  /// In fr, this message translates to:
  /// **'Le restaurant du jour'**
  String get ofDayFood;

  /// No description provided for @ofDayFamily.
  ///
  /// In fr, this message translates to:
  /// **'L\'activité du jour'**
  String get ofDayFamily;

  /// No description provided for @ofDayCulture.
  ///
  /// In fr, this message translates to:
  /// **'Le point culture'**
  String get ofDayCulture;

  /// No description provided for @ofDaySport.
  ///
  /// In fr, this message translates to:
  /// **'Le moment Sport'**
  String get ofDaySport;

  /// No description provided for @ofDayNight.
  ///
  /// In fr, this message translates to:
  /// **'Le club du jour'**
  String get ofDayNight;

  /// No description provided for @ofDayEvasion.
  ///
  /// In fr, this message translates to:
  /// **'Le moment évasion'**
  String get ofDayEvasion;

  /// No description provided for @cityPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une ville'**
  String get cityPickerTitle;

  /// No description provided for @cityPickerHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une ville...'**
  String get cityPickerHint;

  /// No description provided for @cityPickerNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ville trouvée'**
  String get cityPickerNone;

  /// No description provided for @cityPickerError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de recherche'**
  String get cityPickerError;

  /// No description provided for @storyCatConcert.
  ///
  /// In fr, this message translates to:
  /// **'Concert'**
  String get storyCatConcert;

  /// No description provided for @storyCatParty.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get storyCatParty;

  /// No description provided for @storyCatCelebration.
  ///
  /// In fr, this message translates to:
  /// **'Fête'**
  String get storyCatCelebration;

  /// No description provided for @storyCatFestival.
  ///
  /// In fr, this message translates to:
  /// **'Festival'**
  String get storyCatFestival;

  /// No description provided for @storyCatMarket.
  ///
  /// In fr, this message translates to:
  /// **'Marché'**
  String get storyCatMarket;

  /// No description provided for @storyCatExpo.
  ///
  /// In fr, this message translates to:
  /// **'Expo'**
  String get storyCatExpo;

  /// No description provided for @storyCatFair.
  ///
  /// In fr, this message translates to:
  /// **'Salon'**
  String get storyCatFair;

  /// No description provided for @storyCatOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get storyCatOther;

  /// No description provided for @cameraHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuie = photo  ·  Maintiens = vidéo'**
  String get cameraHint;

  /// No description provided for @storyPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Signalé ! L\'affiche se prépare...'**
  String get storyPreparing;

  /// No description provided for @storyLocating.
  ///
  /// In fr, this message translates to:
  /// **'Localisation...'**
  String get storyLocating;

  /// No description provided for @storyPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get storyPlace;

  /// No description provided for @storyPlaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Bar, rue, place...'**
  String get storyPlaceHint;

  /// No description provided for @storyTestOnlyMe.
  ///
  /// In fr, this message translates to:
  /// **'Story de test (visible que par moi)'**
  String get storyTestOnlyMe;

  /// No description provided for @storyTest.
  ///
  /// In fr, this message translates to:
  /// **'Story de test'**
  String get storyTest;

  /// Recherche de ville Map Live
  ///
  /// In fr, this message translates to:
  /// **'Impossible de trouver « {query} »'**
  String mapCityNotFound(String query);

  /// No description provided for @storyCommunity.
  ///
  /// In fr, this message translates to:
  /// **'La commu'**
  String get storyCommunity;

  /// No description provided for @storyChatShort.
  ///
  /// In fr, this message translates to:
  /// **'discu'**
  String get storyChatShort;

  /// No description provided for @storyVideo.
  ///
  /// In fr, this message translates to:
  /// **'vidéo'**
  String get storyVideo;

  /// No description provided for @storyAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get storyAnonymous;

  /// No description provided for @storyPostedBy.
  ///
  /// In fr, this message translates to:
  /// **'Signalé par '**
  String get storyPostedBy;

  /// No description provided for @storyDiscuss.
  ///
  /// In fr, this message translates to:
  /// **'Discuter'**
  String get storyDiscuss;

  /// No description provided for @storyAiGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération IA...'**
  String get storyAiGenerating;

  /// No description provided for @storyNobodyYet.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a encore signalé par ici. Sois le premier !'**
  String get storyNobodyYet;

  /// No description provided for @memberNoBio.
  ///
  /// In fr, this message translates to:
  /// **'Ce membre n\'a pas encore de bio.'**
  String get memberNoBio;

  /// No description provided for @chatRejected.
  ///
  /// In fr, this message translates to:
  /// **'Message refusé : langage inapproprié'**
  String get chatRejected;

  /// No description provided for @chatReportInfo.
  ///
  /// In fr, this message translates to:
  /// **'Si plusieurs personnes signalent ce message, il sera masqué automatiquement.'**
  String get chatReportInfo;

  /// No description provided for @chatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Discussion'**
  String get chatTitle;

  /// No description provided for @chatLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la discussion'**
  String get chatLoadError;

  /// No description provided for @chatBeFirst.
  ///
  /// In fr, this message translates to:
  /// **'Sois le premier à poser une question !'**
  String get chatBeFirst;

  /// No description provided for @chatFinishSignup.
  ///
  /// In fr, this message translates to:
  /// **'Termine ton inscription pour participer à la discussion.'**
  String get chatFinishSignup;

  /// No description provided for @chatHint.
  ///
  /// In fr, this message translates to:
  /// **'Pose une question...'**
  String get chatHint;

  /// No description provided for @chatReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get chatReport;

  /// No description provided for @optVenueIndoor.
  ///
  /// In fr, this message translates to:
  /// **'Salle'**
  String get optVenueIndoor;

  /// No description provided for @optVenueOutdoor.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get optVenueOutdoor;

  /// No description provided for @optVenueStudio.
  ///
  /// In fr, this message translates to:
  /// **'Studio'**
  String get optVenueStudio;

  /// No description provided for @optVenueOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get optVenueOnline;

  /// No description provided for @optKids.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get optKids;

  /// No description provided for @optTeens.
  ///
  /// In fr, this message translates to:
  /// **'Ados'**
  String get optTeens;

  /// No description provided for @optAdults.
  ///
  /// In fr, this message translates to:
  /// **'Adultes'**
  String get optAdults;

  /// No description provided for @optSeniors.
  ///
  /// In fr, this message translates to:
  /// **'Seniors'**
  String get optSeniors;

  /// No description provided for @optAllAudiences.
  ///
  /// In fr, this message translates to:
  /// **'Tous publics'**
  String get optAllAudiences;

  /// No description provided for @optBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get optBeginner;

  /// No description provided for @optIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get optIntermediate;

  /// No description provided for @optAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get optAdvanced;

  /// No description provided for @optAllLevels.
  ///
  /// In fr, this message translates to:
  /// **'Tous niveaux'**
  String get optAllLevels;

  /// No description provided for @optIndividual.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get optIndividual;

  /// No description provided for @optNonProfit.
  ///
  /// In fr, this message translates to:
  /// **'Association'**
  String get optNonProfit;

  /// No description provided for @optCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get optCompany;

  /// No description provided for @optOpenEntry.
  ///
  /// In fr, this message translates to:
  /// **'Libre'**
  String get optOpenEntry;

  /// No description provided for @optApproval.
  ///
  /// In fr, this message translates to:
  /// **'Sur validation'**
  String get optApproval;

  /// No description provided for @optWaitingList.
  ///
  /// In fr, this message translates to:
  /// **'Liste d\'attente'**
  String get optWaitingList;

  /// No description provided for @optDaily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get optDaily;

  /// No description provided for @optWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get optWeekly;

  /// No description provided for @optMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get optMonthly;

  /// No description provided for @errPickCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une catégorie'**
  String get errPickCategory;

  /// No description provided for @errTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le titre est requis'**
  String get errTitleRequired;

  /// No description provided for @errMediaRequired.
  ///
  /// In fr, this message translates to:
  /// **'Une photo ou vidéo est requise'**
  String get errMediaRequired;

  /// No description provided for @errStartDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date de début est requise'**
  String get errStartDateRequired;

  /// No description provided for @errStartTimeRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de début est requise'**
  String get errStartTimeRequired;

  /// No description provided for @errAddressRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du lieu requise'**
  String get errAddressRequired;

  /// No description provided for @errLinkFormat.
  ///
  /// In fr, this message translates to:
  /// **'Le lien doit commencer par http:// ou https://'**
  String get errLinkFormat;

  /// No description provided for @errDateTimeBeforePublish.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne la date et l\'heure avant de publier.'**
  String get errDateTimeBeforePublish;

  /// No description provided for @errInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides (400). Vérifie les champs.'**
  String get errInvalidData;

  /// Erreur HTTP
  ///
  /// In fr, this message translates to:
  /// **'Authentification requise ({code}).'**
  String errAuthRequired(String code);

  /// No description provided for @errConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit (409). Évènement déjà existant ?'**
  String get errConflict;

  /// No description provided for @errFileTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux.'**
  String get errFileTooLarge;

  /// Erreur HTTP
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur ({code}). Réessaye dans un instant.'**
  String errServer(String code);

  /// Erreur HTTP
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau ({code}).'**
  String errNetworkCode(String code);

  /// No description provided for @errSlowConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion trop lente. Vérifie ton réseau.'**
  String get errSlowConnection;

  /// No description provided for @errNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau. Vérifie ta connexion.'**
  String get errNetwork;

  /// No description provided for @errNoInternet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get errNoInternet;

  /// No description provided for @errCheckFields.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie les champs'**
  String get errCheckFields;

  /// No description provided for @errPublishFailed.
  ///
  /// In fr, this message translates to:
  /// **'Publication échouée'**
  String get errPublishFailed;

  /// No description provided for @ceEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'évènement'**
  String get ceEditTitle;

  /// No description provided for @ceCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un évènement'**
  String get ceCreateTitle;

  /// No description provided for @commonPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get commonPrevious;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @ceUploadingVideo.
  ///
  /// In fr, this message translates to:
  /// **'Publication de la vidéo...'**
  String get ceUploadingVideo;

  /// No description provided for @ceUploading.
  ///
  /// In fr, this message translates to:
  /// **'Publication en cours...'**
  String get ceUploading;

  /// No description provided for @ceAlmostDone.
  ///
  /// In fr, this message translates to:
  /// **'Presque terminé'**
  String get ceAlmostDone;

  /// No description provided for @ceBoostPending.
  ///
  /// In fr, this message translates to:
  /// **'Event créé ! Le boost sera actif après validation du paiement.'**
  String get ceBoostPending;

  /// No description provided for @ceEdited.
  ///
  /// In fr, this message translates to:
  /// **'Évènement modifié\navec succès !'**
  String get ceEdited;

  /// No description provided for @ceAdded.
  ///
  /// In fr, this message translates to:
  /// **'Évènement ajouté\navec succès !'**
  String get ceAdded;

  /// No description provided for @ceVisibleInRubrique.
  ///
  /// In fr, this message translates to:
  /// **'Il sera visible dans la rubrique correspondante.'**
  String get ceVisibleInRubrique;

  /// No description provided for @ceCreated.
  ///
  /// In fr, this message translates to:
  /// **'Évènement créé !'**
  String get ceCreated;

  /// No description provided for @ceBoostActiveAfterPayment.
  ///
  /// In fr, this message translates to:
  /// **'Le boost sera actif dès que le paiement sera confirmé.'**
  String get ceBoostActiveAfterPayment;

  /// No description provided for @ceQuitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ?'**
  String get ceQuitTitle;

  /// No description provided for @ceQuitBody.
  ///
  /// In fr, this message translates to:
  /// **'Les informations saisies seront perdues.'**
  String get ceQuitBody;

  /// No description provided for @ceQuit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get ceQuit;

  /// No description provided for @ceCompressing.
  ///
  /// In fr, this message translates to:
  /// **'Compression de la vidéo...'**
  String get ceCompressing;

  /// No description provided for @ceUploadInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Upload en cours...'**
  String get ceUploadInProgress;

  /// No description provided for @ceFinalizing.
  ///
  /// In fr, this message translates to:
  /// **'Finalisation...'**
  String get ceFinalizing;

  /// No description provided for @ceEssentials.
  ///
  /// In fr, this message translates to:
  /// **'L\'essentiel'**
  String get ceEssentials;

  /// No description provided for @ceEssentialsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le minimum pour publier ton event.'**
  String get ceEssentialsSubtitle;

  /// No description provided for @ceScanFlyerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplit tout automatiquement'**
  String get ceScanFlyerSubtitle;

  /// No description provided for @ceCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get ceCategory;

  /// No description provided for @ceEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'évènement *'**
  String get ceEventTitle;

  /// No description provided for @ceDescriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get ceDescriptionOptional;

  /// No description provided for @ceTicketLinkOptional.
  ///
  /// In fr, this message translates to:
  /// **'Lien billetterie ou site web (optionnel)'**
  String get ceTicketLinkOptional;

  /// No description provided for @ceTeaserVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo teaser (recommandée, 30s max)'**
  String get ceTeaserVideo;

  /// No description provided for @cePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo *'**
  String get cePhoto;

  /// No description provided for @ceDate.
  ///
  /// In fr, this message translates to:
  /// **'Date *'**
  String get ceDate;

  /// No description provided for @ceTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure *'**
  String get ceTime;

  /// No description provided for @ceAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse *'**
  String get ceAddress;

  /// No description provided for @ceFreeEvent.
  ///
  /// In fr, this message translates to:
  /// **'Évènement gratuit'**
  String get ceFreeEvent;

  /// No description provided for @cePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix (€)'**
  String get cePrice;

  /// No description provided for @ceTapToAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour ajouter une photo'**
  String get ceTapToAddPhoto;

  /// No description provided for @commonCamera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get commonGallery;

  /// No description provided for @commonVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get commonVideo;

  /// No description provided for @ceAddVideo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter\n(30 sec max)'**
  String get ceAddVideo;

  /// No description provided for @commonDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get commonTime;

  /// No description provided for @ceMoreInfo.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'infos'**
  String get ceMoreInfo;

  /// No description provided for @ceOptional.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get ceOptional;

  /// No description provided for @ceDetailsHint.
  ///
  /// In fr, this message translates to:
  /// **'Affine ton event ou clique \"Publier\" maintenant.'**
  String get ceDetailsHint;

  /// No description provided for @ceDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get ceDescription;

  /// No description provided for @ceShortDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description courte (1-2 lignes)'**
  String get ceShortDescription;

  /// No description provided for @ceLongDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description longue'**
  String get ceLongDescription;

  /// No description provided for @ceDatesRecurrence.
  ///
  /// In fr, this message translates to:
  /// **'Dates et récurrence'**
  String get ceDatesRecurrence;

  /// No description provided for @ceEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date fin'**
  String get ceEndDate;

  /// No description provided for @ceEndTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure fin'**
  String get ceEndTime;

  /// No description provided for @ceVenueDetails.
  ///
  /// In fr, this message translates to:
  /// **'Lieu détaillé'**
  String get ceVenueDetails;

  /// No description provided for @ceVenueName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du lieu (ex. salle des fêtes)'**
  String get ceVenueName;

  /// No description provided for @cePricingTickets.
  ///
  /// In fr, this message translates to:
  /// **'Tarification & billetterie'**
  String get cePricingTickets;

  /// No description provided for @ceReducedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Tarif réduit'**
  String get ceReducedPrice;

  /// No description provided for @ceGroupPrice.
  ///
  /// In fr, this message translates to:
  /// **'Tarif groupe'**
  String get ceGroupPrice;

  /// No description provided for @ceEarlyBird.
  ///
  /// In fr, this message translates to:
  /// **'Early bird'**
  String get ceEarlyBird;

  /// No description provided for @ceOrganizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get ceOrganizer;

  /// No description provided for @ceName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get ceName;

  /// No description provided for @ceAudience.
  ///
  /// In fr, this message translates to:
  /// **'Public & participants'**
  String get ceAudience;

  /// No description provided for @ceTargetAudience.
  ///
  /// In fr, this message translates to:
  /// **'Public cible'**
  String get ceTargetAudience;

  /// No description provided for @ceLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get ceLevel;

  /// No description provided for @ceRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get ceRegistration;

  /// No description provided for @ceTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get ceTags;

  /// No description provided for @ceAddTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un tag'**
  String get ceAddTag;

  /// No description provided for @ceBoostTitle.
  ///
  /// In fr, this message translates to:
  /// **'Booster ton event'**
  String get ceBoostTitle;

  /// No description provided for @ceBoostOptional.
  ///
  /// In fr, this message translates to:
  /// **'OPTIONNEL'**
  String get ceBoostOptional;

  /// No description provided for @ceBoostSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Augmente la visibilité de ton event'**
  String get ceBoostSubtitle;

  /// No description provided for @cePriceLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement prix'**
  String get cePriceLoadError;

  /// No description provided for @ceTapDays.
  ///
  /// In fr, this message translates to:
  /// **'Touche les jours souhaités'**
  String get ceTapDays;

  /// No description provided for @publishChooseType.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le type de publication'**
  String get publishChooseType;

  /// No description provided for @publishPrivateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Coffre secret sur invitation, gratuit'**
  String get publishPrivateSubtitle;

  /// No description provided for @publishAsPro.
  ///
  /// In fr, this message translates to:
  /// **'Publier en tant que pro'**
  String get publishAsPro;

  /// No description provided for @publishProUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Publication illimitée (compte pro validé)'**
  String get publishProUnlimited;

  /// No description provided for @publishProSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace professionnel (inscription / connexion)'**
  String get publishProSpace;

  /// No description provided for @tierPremium.
  ///
  /// In fr, this message translates to:
  /// **'💎 Abonnement Premium'**
  String get tierPremium;

  /// No description provided for @tierPremiumEffect.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos events passent à la une du feed.'**
  String get tierPremiumEffect;

  /// No description provided for @tierGold.
  ///
  /// In fr, this message translates to:
  /// **'🥇 Abonnement Gold'**
  String get tierGold;

  /// No description provided for @tierGoldEffect.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos events sont mis au top du feed.'**
  String get tierGoldEffect;

  /// No description provided for @tierNormal.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement Normal'**
  String get tierNormal;

  /// No description provided for @tierNormalEffect.
  ///
  /// In fr, this message translates to:
  /// **'Vos events apparaissent dans le feed standard.'**
  String get tierNormalEffect;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @pubMyEvents.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements'**
  String get pubMyEvents;

  /// No description provided for @pubMyStories.
  ///
  /// In fr, this message translates to:
  /// **'Mes stories'**
  String get pubMyStories;

  /// No description provided for @pubStoriesKept.
  ///
  /// In fr, this message translates to:
  /// **'Conservées un temps limité. Supprimables à tout moment.'**
  String get pubStoriesKept;

  /// No description provided for @pubNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune publication'**
  String get pubNone;

  /// No description provided for @pubNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Tes événements créés apparaîtront ici'**
  String get pubNoneHint;

  /// Stories en file d'attente
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 story en attente de réseau} other{{count} stories en attente de réseau}}'**
  String pubStoriesPending(int count);

  /// No description provided for @commonSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get commonSend;

  /// Confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {title} » ?'**
  String pubDeleteConfirm(String title);

  /// No description provided for @pubDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Publication supprimée'**
  String get pubDeleted;

  /// No description provided for @pubDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible, réessaie'**
  String get pubDeleteFailed;

  /// No description provided for @pubThisStory.
  ///
  /// In fr, this message translates to:
  /// **'cette story'**
  String get pubThisStory;

  /// No description provided for @pubDeleteStory.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la story'**
  String get pubDeleteStory;

  /// Confirmation de suppression
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {title} » ? Cette action est définitive.'**
  String pubDeleteStoryConfirm(String title);

  /// No description provided for @pubStoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Story supprimée'**
  String get pubStoryDeleted;

  /// No description provided for @pubStatusGenerating.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get pubStatusGenerating;

  /// No description provided for @pubStatusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get pubStatusExpired;

  /// No description provided for @pubStatusOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get pubStatusOnline;

  /// Date et heure
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String dateAtTime(String date, String time);

  /// No description provided for @commonFailedRetry.
  ///
  /// In fr, this message translates to:
  /// **'Échec, réessaie'**
  String get commonFailedRetry;

  /// No description provided for @commonDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression'**
  String get commonDeleteFailed;

  /// No description provided for @commonActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get commonActivate;

  /// No description provided for @commonRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get commonRemove;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié dans le presse-papiers'**
  String get commonCopied;

  /// No description provided for @commonWithoutAccount.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte'**
  String get commonWithoutAccount;

  /// No description provided for @commonPast.
  ///
  /// In fr, this message translates to:
  /// **'Passé'**
  String get commonPast;

  /// No description provided for @pvConfirmOn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation activée : tes participants peuvent confirmer'**
  String get pvConfirmOn;

  /// No description provided for @pvConfirmOff.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation désactivée'**
  String get pvConfirmOff;

  /// No description provided for @pvDeleteVault.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce coffre ?'**
  String get pvDeleteVault;

  /// Suppression coffre
  ///
  /// In fr, this message translates to:
  /// **'L\'event « {title} » ne sera plus accessible aux invités.'**
  String pvDeleteVaultBody(String title);

  /// No description provided for @pvNewEvent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel event'**
  String get pvNewEvent;

  /// No description provided for @pvNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun event privé'**
  String get pvNone;

  /// No description provided for @pvNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée un coffre secret et invite tes amis avec un lien + code.'**
  String get pvNoneHint;

  /// No description provided for @pvChat.
  ///
  /// In fr, this message translates to:
  /// **'Discussion'**
  String get pvChat;

  /// No description provided for @pvThisPerson.
  ///
  /// In fr, this message translates to:
  /// **'cette personne'**
  String get pvThisPerson;

  /// Retrait invite
  ///
  /// In fr, this message translates to:
  /// **'Retirer {name} ?'**
  String pvRemoveGuest(String name);

  /// No description provided for @pvRemoveGuestBody.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera supprimée de la liste des participants (et des confirmés), ne pourra plus se réinscrire et n\'aura plus accès à la discussion de la soirée.'**
  String get pvRemoveGuestBody;

  /// No description provided for @pvRemoveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du retrait, réessaie'**
  String get pvRemoveFailed;

  /// No description provided for @pvEnableConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la confirmation ?'**
  String get pvEnableConfirmTitle;

  /// No description provided for @pvEnableConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Le PDF liste les participants qui ont confirmé leur venue avec leur nom et prénom. Active la confirmation : tes participants pourront remplir le formulaire depuis « Mes invitations ».'**
  String get pvEnableConfirmBody;

  /// No description provided for @pvConfirmOnPdf.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation activée : le PDF sera prêt dès la 1re confirmation'**
  String get pvConfirmOnPdf;

  /// No description provided for @pvNoConfirmYet.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a encore confirmé : le PDF liste les confirmés avec leur nom et prénom'**
  String get pvNoConfirmYet;

  /// No description provided for @pvNoOpeners.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a ouvert le coffre sans s\'inscrire.\nLes ouvertures sont visibles avec la dernière version de l\'app.'**
  String get pvNoOpeners;

  /// No description provided for @pvNoConfirmations.
  ///
  /// In fr, this message translates to:
  /// **'Aucune confirmation pour l\'instant.\nLes participants confirment depuis « Mes invitations ».'**
  String get pvNoConfirmations;

  /// Compteur inscrits
  ///
  /// In fr, this message translates to:
  /// **'Inscrits {count} / {max}'**
  String pvSignedUpMax(int count, int max);

  /// Compteur inscrits
  ///
  /// In fr, this message translates to:
  /// **'Inscrits ({count})'**
  String pvSignedUp(int count);

  /// No description provided for @pvTabGuests.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get pvTabGuests;

  /// No description provided for @pvTabSeen.
  ///
  /// In fr, this message translates to:
  /// **'👀 Vus'**
  String get pvTabSeen;

  /// No description provided for @pvTabConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'✅ Confirmés'**
  String get pvTabConfirmed;

  /// No description provided for @pvNobodyYet.
  ///
  /// In fr, this message translates to:
  /// **'Personne pour l\'instant'**
  String get pvNobodyYet;

  /// Ouvertures du coffre
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ouverture} other{{count} ouvertures}}'**
  String pvOpens(int count);

  /// Derniere ouverture
  ///
  /// In fr, this message translates to:
  /// **'dernière le {when}'**
  String pvLastOn(String when);

  /// Date de confirmation
  ///
  /// In fr, this message translates to:
  /// **'confirmé le {when}'**
  String pvConfirmedOn(String when);

  /// No description provided for @pvFull.
  ///
  /// In fr, this message translates to:
  /// **'complet'**
  String get pvFull;

  /// Nombre d'inscrits
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 inscrit} other{{count} inscrits}}'**
  String pvSignedUpCount(int count);

  /// No description provided for @pvGuestConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation des participants'**
  String get pvGuestConfirmation;

  /// No description provided for @pvGuestConfirmationOn.
  ///
  /// In fr, this message translates to:
  /// **'Activée : nom, âge, téléphone demandés'**
  String get pvGuestConfirmationOn;

  /// No description provided for @pvOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get pvOff;

  /// No description provided for @pvPhotoUploadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi de la photo'**
  String get pvPhotoUploadFailed;

  /// No description provided for @pvErrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Donne un titre à ton event'**
  String get pvErrTitle;

  /// No description provided for @pvErrDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une date'**
  String get pvErrDate;

  /// No description provided for @pvErrCode.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit faire 4 chiffres'**
  String get pvErrCode;

  /// No description provided for @pvErrSeats.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de places : entre 1 et 1000 (ou vide)'**
  String get pvErrSeats;

  /// No description provided for @pvErrInvalidField.
  ///
  /// In fr, this message translates to:
  /// **'Champ invalide'**
  String get pvErrInvalidField;

  /// No description provided for @pvErrEditFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la modification, réessaie'**
  String get pvErrEditFailed;

  /// No description provided for @pvErrCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la création, réessaie'**
  String get pvErrCreateFailed;

  /// No description provided for @pvEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'event privé'**
  String get pvEditTitle;

  /// No description provided for @pvCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un event privé'**
  String get pvCreateTitle;

  /// No description provided for @pvEditSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le lien et le code déjà envoyés restent valables'**
  String get pvEditSubtitle;

  /// No description provided for @pvCreateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Coffre secret partagé par lien + code'**
  String get pvCreateSubtitle;

  /// No description provided for @pvAddPoster.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une affiche (optionnel)'**
  String get pvAddPoster;

  /// No description provided for @pvTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get pvTitle;

  /// No description provided for @pvTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Anniv de ...'**
  String get pvTitleHint;

  /// No description provided for @pvPlaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Chez moi, club...'**
  String get pvPlaceHint;

  /// No description provided for @pvAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get pvAddress;

  /// No description provided for @pvAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'5 rue X, Toulouse'**
  String get pvAddressHint;

  /// No description provided for @pvDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'BYOB, dress code...'**
  String get pvDescriptionHint;

  /// No description provided for @pvSecretCode.
  ///
  /// In fr, this message translates to:
  /// **'Code secret à partager (4 chiffres)'**
  String get pvSecretCode;

  /// No description provided for @pvSeats.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de places'**
  String get pvSeats;

  /// Places deja prises
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 déjà inscrit. Vide = illimité.} other{{count} déjà inscrits. Vide = illimité.}}'**
  String pvSeatsAlready(int count);

  /// No description provided for @pvSeatsHint.
  ///
  /// In fr, this message translates to:
  /// **'Vide = illimité. « Complet » une fois atteint.'**
  String get pvSeatsHint;

  /// No description provided for @pvEnableConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Activer la confirmation'**
  String get pvEnableConfirmation;

  /// No description provided for @pvEnableConfirmationHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque participant confirme sa venue avec nom, prénom, e-mail, âge et téléphone. Toi seul vois ces infos.'**
  String get pvEnableConfirmationHint;

  /// No description provided for @pvCreateMine.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon event'**
  String get pvCreateMine;

  /// No description provided for @pvPickDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get pvPickDate;

  /// No description provided for @pvShareOnList.
  ///
  /// In fr, this message translates to:
  /// **'🤫 Tu es sur la liste.'**
  String get pvShareOnList;

  /// No description provided for @pvShareTeaser.
  ///
  /// In fr, this message translates to:
  /// **'Un événement privé t\'attend… Ouvre le coffre pour découvrir où, quand et tous les détails 👀'**
  String get pvShareTeaser;

  /// Code du coffre
  ///
  /// In fr, this message translates to:
  /// **'🔑 Code : {code}'**
  String pvShareCode(String code);

  /// No description provided for @pvSharePreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation du partage…'**
  String get pvSharePreparing;

  /// No description provided for @pvShareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Partage impossible, réessaie'**
  String get pvShareFailed;

  /// No description provided for @pvVaultCreated.
  ///
  /// In fr, this message translates to:
  /// **'Coffre créé !'**
  String get pvVaultCreated;

  /// No description provided for @pvShareSeparately.
  ///
  /// In fr, this message translates to:
  /// **'Partage le lien et le code séparément, par message ou WhatsApp.'**
  String get pvShareSeparately;

  /// No description provided for @vaultErrLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien invalide (format UUID attendu)'**
  String get vaultErrLink;

  /// No description provided for @vaultErrNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun coffre trouvé avec ce lien'**
  String get vaultErrNotFound;

  /// No description provided for @vaultErrWrongCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get vaultErrWrongCode;

  /// No description provided for @vaultErrPast.
  ///
  /// In fr, this message translates to:
  /// **'Cet event est passé'**
  String get vaultErrPast;

  /// No description provided for @vaultErrOpenLimit.
  ///
  /// In fr, this message translates to:
  /// **'Ce coffre a atteint sa limite d\'ouvertures'**
  String get vaultErrOpenLimit;

  /// No description provided for @vaultErrInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Donnée invalide'**
  String get vaultErrInvalidData;

  /// No description provided for @vaultErrProfile.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil MaCity pour continuer'**
  String get vaultErrProfile;

  /// No description provided for @vaultErrDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get vaultErrDenied;

  /// No description provided for @vaultErrFull.
  ///
  /// In fr, this message translates to:
  /// **'C\'est complet, plus de place'**
  String get vaultErrFull;

  /// No description provided for @vaultErrEnded.
  ///
  /// In fr, this message translates to:
  /// **'Soirée terminée : consultation seule'**
  String get vaultErrEnded;

  /// No description provided for @vaultErrComeFirst.
  ///
  /// In fr, this message translates to:
  /// **'Indique d\'abord que tu viens à la soirée'**
  String get vaultErrComeFirst;

  /// No description provided for @vaultErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau, réessaie'**
  String get vaultErrNetwork;

  /// No description provided for @vaultOpened.
  ///
  /// In fr, this message translates to:
  /// **'Coffre ouvert'**
  String get vaultOpened;

  /// No description provided for @vaultTypeLinkCode.
  ///
  /// In fr, this message translates to:
  /// **'Tape le lien et le code reçus'**
  String get vaultTypeLinkCode;

  /// No description provided for @vaultHostShared.
  ///
  /// In fr, this message translates to:
  /// **'L\'organisateur t\'a partagé un token + un code à 4 chiffres.'**
  String get vaultHostShared;

  /// No description provided for @vaultLinkToken.
  ///
  /// In fr, this message translates to:
  /// **'Lien (token)'**
  String get vaultLinkToken;

  /// No description provided for @vaultPaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller'**
  String get vaultPaste;

  /// No description provided for @vaultCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get vaultCode;

  /// No description provided for @vaultOpening.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture...'**
  String get vaultOpening;

  /// No description provided for @vaultOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le coffre'**
  String get vaultOpen;

  /// No description provided for @vaultAttendanceConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Venue confirmée, l\'organisateur est prévenu'**
  String get vaultAttendanceConfirmed;

  /// No description provided for @vaultFullShort.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get vaultFullShort;

  /// Places restantes
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 place restante} other{{count} places restantes}}'**
  String vaultSpotsLeft(int count);

  /// No description provided for @vaultOpenedBadge.
  ///
  /// In fr, this message translates to:
  /// **'COFFRE OUVERT'**
  String get vaultOpenedBadge;

  /// Nombre de venues
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 personne vient} other{{count} personnes viennent}}'**
  String vaultPeopleComing(int count);

  /// No description provided for @vaultCancelMine.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ma venue'**
  String get vaultCancelMine;

  /// No description provided for @vaultImComing.
  ///
  /// In fr, this message translates to:
  /// **'Je viens'**
  String get vaultImComing;

  /// No description provided for @vaultConfirmedEdit.
  ///
  /// In fr, this message translates to:
  /// **'Venue confirmée · modifier'**
  String get vaultConfirmedEdit;

  /// No description provided for @vaultConfirmMine.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ma venue'**
  String get vaultConfirmMine;

  /// No description provided for @vaultHostAsksConfirm.
  ///
  /// In fr, this message translates to:
  /// **'L\'organisateur demande de confirmer ta venue (nom, âge, téléphone…).'**
  String get vaultHostAsksConfirm;

  /// No description provided for @invNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune invitation'**
  String get invNone;

  /// No description provided for @invNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Quand tu cliqueras « Je viens » sur un coffre, l\'event apparaîtra ici.'**
  String get invNoneHint;

  /// No description provided for @invImComingBadge.
  ///
  /// In fr, this message translates to:
  /// **'JE VIENS'**
  String get invImComingBadge;

  /// No description provided for @invCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ta venue ?'**
  String get invCancelTitle;

  /// No description provided for @invCancelBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras toujours revenir en cliquant « Je viens » depuis le coffre.'**
  String get invCancelBody;

  /// No description provided for @invKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get invKeep;

  /// No description provided for @invCancelFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'annulation'**
  String get invCancelFailed;

  /// No description provided for @invAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get invAlbum;

  /// No description provided for @invSeeGuests.
  ///
  /// In fr, this message translates to:
  /// **'Glisse vers le haut pour voir les participants ({count})'**
  String invSeeGuests(int count);

  /// No description provided for @invWriteHost.
  ///
  /// In fr, this message translates to:
  /// **'Écrire à l\'organisateur'**
  String get invWriteHost;

  /// No description provided for @invCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Venue annulée'**
  String get invCancelled;

  /// No description provided for @invNobodyElse.
  ///
  /// In fr, this message translates to:
  /// **'Personne d\'autre n\'a encore confirmé.'**
  String get invNobodyElse;

  /// Liste des presents
  ///
  /// In fr, this message translates to:
  /// **'Présents ({count} / {max})'**
  String invPresentMax(int count, int max);

  /// Liste des presents
  ///
  /// In fr, this message translates to:
  /// **'Présents ({count})'**
  String invPresent(int count);

  /// No description provided for @invConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get invConfirmed;

  /// No description provided for @invConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get invConfirm;

  /// Soi-meme dans la liste
  ///
  /// In fr, this message translates to:
  /// **'{name} (moi)'**
  String invMe(String name);

  /// No description provided for @cfErrName.
  ///
  /// In fr, this message translates to:
  /// **'Nom et prénom obligatoires'**
  String get cfErrName;

  /// No description provided for @cfErrEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get cfErrEmail;

  /// No description provided for @cfErrAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge invalide'**
  String get cfErrAge;

  /// No description provided for @cfErrPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get cfErrPhone;

  /// No description provided for @cfSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi, réessaie'**
  String get cfSendFailed;

  /// No description provided for @cfEditMine.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ma confirmation'**
  String get cfEditMine;

  /// Mention de confidentialite
  ///
  /// In fr, this message translates to:
  /// **'Pour « {title} ». Ces infos sont envoyées uniquement à l\'organisateur et supprimées après la soirée.'**
  String cfPrivacy(String title);

  /// No description provided for @cfFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get cfFirstName;

  /// No description provided for @cfLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get cfLastName;

  /// No description provided for @cfEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get cfEmail;

  /// No description provided for @cfAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get cfAge;

  /// No description provided for @pcErrGuestLeft.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne n\'est plus inscrite à l\'event : la conversation privée n\'est plus possible.'**
  String get pcErrGuestLeft;

  /// No description provided for @pcErrYouAreHost.
  ///
  /// In fr, this message translates to:
  /// **'Tu es l\'organisateur de cet event : écris à tes participants depuis « Mes events privés », bouton 💬 à côté de chacun.'**
  String get pcErrYouAreHost;

  /// No description provided for @pcErrNotGoing.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'es plus inscrit à cet event : fais « Je viens » pour écrire à l\'organisateur.'**
  String get pcErrNotGoing;

  /// No description provided for @pcErrGone.
  ///
  /// In fr, this message translates to:
  /// **'Cet event n\'existe plus (supprimé ou passé depuis plus de 7 jours).'**
  String get pcErrGone;

  /// No description provided for @pcErrNoAccess.
  ///
  /// In fr, this message translates to:
  /// **'Cette discussion n\'est plus accessible.'**
  String get pcErrNoAccess;

  /// No description provided for @pcErrLoad.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la discussion. Vérifie ta connexion et réessaie.'**
  String get pcErrLoad;

  /// No description provided for @pcPhotoSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi de la photo'**
  String get pcPhotoSendFailed;

  /// No description provided for @pcDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce message ?'**
  String get pcDeleteMessage;

  /// No description provided for @pcCannotDelete.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas supprimer ce message'**
  String get pcCannotDelete;

  /// No description provided for @pcAlbumTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Album photos'**
  String get pcAlbumTooltip;

  /// No description provided for @pcGuest.
  ///
  /// In fr, this message translates to:
  /// **'Participant'**
  String get pcGuest;

  /// No description provided for @pcHost.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get pcHost;

  /// Sous-titre DM
  ///
  /// In fr, this message translates to:
  /// **'Message privé · {title}'**
  String pcPrivateMessage(String title);

  /// No description provided for @pcPrivateChat.
  ///
  /// In fr, this message translates to:
  /// **'Discussion privée'**
  String get pcPrivateChat;

  /// No description provided for @pcEmptyDmToGuest.
  ///
  /// In fr, this message translates to:
  /// **'Écris en privé à ce participant : lui seul verra tes messages.'**
  String get pcEmptyDmToGuest;

  /// No description provided for @pcEmptyDmToHost.
  ///
  /// In fr, this message translates to:
  /// **'Écris en privé à l\'organisateur : lui seul verra tes messages.'**
  String get pcEmptyDmToHost;

  /// No description provided for @pcEmptyGroup.
  ///
  /// In fr, this message translates to:
  /// **'Pose une question à l\'organisateur ou dis bonjour aux autres invités !'**
  String get pcEmptyGroup;

  /// No description provided for @pcPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get pcPhoto;

  /// No description provided for @pcCaptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une légende...'**
  String get pcCaptionHint;

  /// No description provided for @pcMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris un message...'**
  String get pcMessageHint;

  /// No description provided for @pcMe.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get pcMe;

  /// No description provided for @alRemovePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette photo ?'**
  String get alRemovePhoto;

  /// No description provided for @alRemoveAll.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera retirée de l\'album et de la discussion pour tout le monde.'**
  String get alRemoveAll;

  /// No description provided for @alRemoveMine.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera retirée de l\'album et de la discussion.'**
  String get alRemoveMine;

  /// No description provided for @alCannotRemove.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne peux pas retirer cette photo'**
  String get alCannotRemove;

  /// No description provided for @alRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Photo retirée de l\'album'**
  String get alRemoved;

  /// No description provided for @alLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'album. Vérifie ta connexion.'**
  String get alLoadError;

  /// No description provided for @alNoAccess.
  ///
  /// In fr, this message translates to:
  /// **'Cet album n\'est pas accessible.'**
  String get alNoAccess;

  /// No description provided for @alPickMany.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie (plusieurs)'**
  String get alPickMany;

  /// No description provided for @alProfileRequired.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil pour ajouter des photos'**
  String get alProfileRequired;

  /// No description provided for @alAddRefused.
  ///
  /// In fr, this message translates to:
  /// **'Ajout refusé'**
  String get alAddRefused;

  /// Photos ajoutees
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo ajoutée à l\'album} other{{count} photos ajoutées à l\'album}}'**
  String alAdded(int count);

  /// Ajout partiel
  ///
  /// In fr, this message translates to:
  /// **'{ok} / {total} photos ajoutées, réessaie pour les autres'**
  String alAddedPartial(int ok, int total);

  /// Enregistrement limite
  ///
  /// In fr, this message translates to:
  /// **'Les {max} premières photos ont été proposées. Enregistre les autres une par une depuis le diaporama.'**
  String alFirstProposed(int max);

  /// No description provided for @alSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer les photos'**
  String get alSaveFailed;

  /// No description provided for @alTitle.
  ///
  /// In fr, this message translates to:
  /// **'📸 Album'**
  String get alTitle;

  /// No description provided for @alSaveAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout enregistrer'**
  String get alSaveAll;

  /// Progression envoi
  ///
  /// In fr, this message translates to:
  /// **'Envoi {done} / {total}'**
  String alSending(int done, int total);

  /// No description provided for @alAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get alAdd;

  /// No description provided for @alNoPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de photo'**
  String get alNoPhoto;

  /// No description provided for @alNoPhotoArchived.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a partagé de photo pendant cette soirée.'**
  String get alNoPhotoArchived;

  /// No description provided for @alNoPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes photos ici, ou partage-les dans la discussion : elles apparaissent automatiquement dans l\'album.'**
  String get alNoPhotoHint;

  /// No description provided for @alAddPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get alAddPhotos;

  /// No description provided for @alOpenChat.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la discussion'**
  String get alOpenChat;

  /// Nombre de photos
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String alPhotoCount(int count);

  /// No description provided for @alFrozen.
  ///
  /// In fr, this message translates to:
  /// **'album figé'**
  String get alFrozen;

  /// No description provided for @alLongPressHint.
  ///
  /// In fr, this message translates to:
  /// **'appui long sur une photo pour la retirer'**
  String get alLongPressHint;

  /// No description provided for @memNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de souvenirs'**
  String get memNone;

  /// No description provided for @memNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Tes soirées privées passées (organisées ou où tu étais inscrit) apparaîtront ici avec leurs photos.'**
  String get memNoneHint;

  /// No description provided for @memGuestRole.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get memGuestRole;

  /// Participants
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 participant} other{{count} participants}}'**
  String memParticipants(int count);

  /// Fin d'ajout de photos
  ///
  /// In fr, this message translates to:
  /// **'ajout de photos jusqu\'au {date}'**
  String memAddUntil(String date);

  /// No description provided for @memSlideshow.
  ///
  /// In fr, this message translates to:
  /// **'Diaporama'**
  String get memSlideshow;

  /// No description provided for @ssSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer cette photo'**
  String get ssSaveFailed;

  /// No description provided for @ssPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get ssPause;

  /// No description provided for @ssPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get ssPlay;

  /// No description provided for @ssRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'album'**
  String get ssRemove;

  /// No description provided for @ssSaveShare.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer / partager'**
  String get ssSaveShare;

  /// No description provided for @abAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album photo'**
  String get abAlbum;

  /// No description provided for @abSeeAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'album'**
  String get abSeeAlbum;

  /// No description provided for @abFirstPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les premières photos de la soirée'**
  String get abFirstPhotos;

  /// Bouton album
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo · diaporama} other{{count} photos · diaporama}}'**
  String abSlideshowCount(int count);

  /// No description provided for @hostOrganizedBy.
  ///
  /// In fr, this message translates to:
  /// **'ORGANISÉ PAR'**
  String get hostOrganizedBy;

  /// No description provided for @pdfGuestList.
  ///
  /// In fr, this message translates to:
  /// **'Liste des invités'**
  String get pdfGuestList;

  /// Resume PDF
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 confirmé / {max} places} other{{count} confirmés / {max} places}}'**
  String pdfSummaryMax(int count, int max);

  /// Resume PDF
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 confirmé} other{{count} confirmés}}'**
  String pdfSummary(int count);

  /// Pied de titre PDF
  ///
  /// In fr, this message translates to:
  /// **'Généré le {date} avec MaCity'**
  String pdfGenerated(String date);

  /// No description provided for @pdfConfidential.
  ///
  /// In fr, this message translates to:
  /// **'Document confidentiel : données personnelles, à ne pas diffuser au-delà de l\'organisation de la soirée.'**
  String get pdfConfidential;

  /// Section PDF
  ///
  /// In fr, this message translates to:
  /// **'Confirmés ({count})  ·  ordre de confirmation'**
  String pdfConfirmedSection(int count);

  /// No description provided for @pdfNoConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Aucune confirmation pour le moment.'**
  String get pdfNoConfirm;

  /// No description provided for @pdfColNumber.
  ///
  /// In fr, this message translates to:
  /// **'N°'**
  String get pdfColNumber;

  /// No description provided for @pdfColConfirmedOn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé le'**
  String get pdfColConfirmedOn;

  /// Texte de partage PDF
  ///
  /// In fr, this message translates to:
  /// **'Liste des invités : {title}'**
  String pdfShareText(String title);

  /// No description provided for @pdfExportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Export PDF impossible, réessaie'**
  String get pdfExportFailed;

  /// No description provided for @interestConcert.
  ///
  /// In fr, this message translates to:
  /// **'Concerts'**
  String get interestConcert;

  /// No description provided for @interestFestival.
  ///
  /// In fr, this message translates to:
  /// **'Festivals'**
  String get interestFestival;

  /// No description provided for @interestSpectacle.
  ///
  /// In fr, this message translates to:
  /// **'Spectacles vivants'**
  String get interestSpectacle;

  /// No description provided for @interestStandup.
  ///
  /// In fr, this message translates to:
  /// **'Stand-up / Humour'**
  String get interestStandup;

  /// No description provided for @interestOpera.
  ///
  /// In fr, this message translates to:
  /// **'Opéra / Classique'**
  String get interestOpera;

  /// No description provided for @interestDj.
  ///
  /// In fr, this message translates to:
  /// **'DJ set / Électro'**
  String get interestDj;

  /// No description provided for @interestConference.
  ///
  /// In fr, this message translates to:
  /// **'Conférences / Talks'**
  String get interestConference;

  /// No description provided for @interestAtelier.
  ///
  /// In fr, this message translates to:
  /// **'Ateliers / Workshops'**
  String get interestAtelier;

  /// No description provided for @interestFootball.
  ///
  /// In fr, this message translates to:
  /// **'Football'**
  String get interestFootball;

  /// No description provided for @interestRugby.
  ///
  /// In fr, this message translates to:
  /// **'Rugby'**
  String get interestRugby;

  /// No description provided for @interestBasketball.
  ///
  /// In fr, this message translates to:
  /// **'Basketball'**
  String get interestBasketball;

  /// No description provided for @interestTennis.
  ///
  /// In fr, this message translates to:
  /// **'Tennis'**
  String get interestTennis;

  /// No description provided for @interestHandball.
  ///
  /// In fr, this message translates to:
  /// **'Handball'**
  String get interestHandball;

  /// No description provided for @interestCourse.
  ///
  /// In fr, this message translates to:
  /// **'Course / Running'**
  String get interestCourse;

  /// No description provided for @interestFitness.
  ///
  /// In fr, this message translates to:
  /// **'Fitness / Musculation'**
  String get interestFitness;

  /// No description provided for @interestYoga.
  ///
  /// In fr, this message translates to:
  /// **'Yoga / Pilates'**
  String get interestYoga;

  /// No description provided for @interestNatation.
  ///
  /// In fr, this message translates to:
  /// **'Natation'**
  String get interestNatation;

  /// No description provided for @interestCyclisme.
  ///
  /// In fr, this message translates to:
  /// **'Cyclisme'**
  String get interestCyclisme;

  /// No description provided for @interestArtsMartiaux.
  ///
  /// In fr, this message translates to:
  /// **'Arts martiaux / Combat'**
  String get interestArtsMartiaux;

  /// No description provided for @interestExpo.
  ///
  /// In fr, this message translates to:
  /// **'Expositions'**
  String get interestExpo;

  /// No description provided for @interestTheatre.
  ///
  /// In fr, this message translates to:
  /// **'Théâtre'**
  String get interestTheatre;

  /// No description provided for @interestMusee.
  ///
  /// In fr, this message translates to:
  /// **'Musées'**
  String get interestMusee;

  /// No description provided for @interestCinema.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get interestCinema;

  /// No description provided for @interestDanse.
  ///
  /// In fr, this message translates to:
  /// **'Danse'**
  String get interestDanse;

  /// No description provided for @interestVisite.
  ///
  /// In fr, this message translates to:
  /// **'Visites guidées'**
  String get interestVisite;

  /// No description provided for @interestLecture.
  ///
  /// In fr, this message translates to:
  /// **'Lecture / Littérature'**
  String get interestLecture;

  /// No description provided for @interestPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photographie'**
  String get interestPhoto;

  /// No description provided for @interestSpectacleEnfant.
  ///
  /// In fr, this message translates to:
  /// **'Spectacles enfants'**
  String get interestSpectacleEnfant;

  /// No description provided for @interestParc.
  ///
  /// In fr, this message translates to:
  /// **'Parcs / Jardins'**
  String get interestParc;

  /// No description provided for @interestCinemaFamille.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get interestCinemaFamille;

  /// No description provided for @interestBowling.
  ///
  /// In fr, this message translates to:
  /// **'Bowling / Laser game'**
  String get interestBowling;

  /// No description provided for @interestAtelierEnfant.
  ///
  /// In fr, this message translates to:
  /// **'Ateliers créatifs'**
  String get interestAtelierEnfant;

  /// No description provided for @interestFeteForaine.
  ///
  /// In fr, this message translates to:
  /// **'Fêtes foraines'**
  String get interestFeteForaine;

  /// No description provided for @interestZoo.
  ///
  /// In fr, this message translates to:
  /// **'Zoo / Aquarium'**
  String get interestZoo;

  /// No description provided for @interestRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants'**
  String get interestRestaurant;

  /// No description provided for @interestBrunch.
  ///
  /// In fr, this message translates to:
  /// **'Brunchs'**
  String get interestBrunch;

  /// No description provided for @interestCafe.
  ///
  /// In fr, this message translates to:
  /// **'Cafés / Salons de thé'**
  String get interestCafe;

  /// No description provided for @interestMarche.
  ///
  /// In fr, this message translates to:
  /// **'Marchés / Food markets'**
  String get interestMarche;

  /// No description provided for @interestDegustation.
  ///
  /// In fr, this message translates to:
  /// **'Dégustations / Vin'**
  String get interestDegustation;

  /// No description provided for @interestFoodTruck.
  ///
  /// In fr, this message translates to:
  /// **'Food trucks'**
  String get interestFoodTruck;

  /// No description provided for @interestCoursCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cours de cuisine'**
  String get interestCoursCuisine;

  /// No description provided for @interestBienetre.
  ///
  /// In fr, this message translates to:
  /// **'Bien-être / Spa'**
  String get interestBienetre;

  /// No description provided for @interestEsport.
  ///
  /// In fr, this message translates to:
  /// **'E-sport / Tournois'**
  String get interestEsport;

  /// No description provided for @interestConvention.
  ///
  /// In fr, this message translates to:
  /// **'Conventions / Salons'**
  String get interestConvention;

  /// No description provided for @interestBarJeux.
  ///
  /// In fr, this message translates to:
  /// **'Bar à jeux'**
  String get interestBarJeux;

  /// No description provided for @interestLan.
  ///
  /// In fr, this message translates to:
  /// **'LAN party'**
  String get interestLan;

  /// No description provided for @interestManga.
  ///
  /// In fr, this message translates to:
  /// **'Manga / Anime'**
  String get interestManga;

  /// No description provided for @interestVr.
  ///
  /// In fr, this message translates to:
  /// **'Réalité virtuelle'**
  String get interestVr;

  /// No description provided for @interestEscapeGame.
  ///
  /// In fr, this message translates to:
  /// **'Escape games'**
  String get interestEscapeGame;

  /// No description provided for @interestBar.
  ///
  /// In fr, this message translates to:
  /// **'Bars / Pubs'**
  String get interestBar;

  /// No description provided for @interestClub.
  ///
  /// In fr, this message translates to:
  /// **'Clubs / Discothèques'**
  String get interestClub;

  /// No description provided for @interestSoiree.
  ///
  /// In fr, this message translates to:
  /// **'Soirées thématiques'**
  String get interestSoiree;

  /// No description provided for @interestConcertLive.
  ///
  /// In fr, this message translates to:
  /// **'Concerts live / Showcase'**
  String get interestConcertLive;

  /// No description provided for @interestKaraoke.
  ///
  /// In fr, this message translates to:
  /// **'Karaoké'**
  String get interestKaraoke;

  /// No description provided for @interestAfterwork.
  ///
  /// In fr, this message translates to:
  /// **'Afterwork'**
  String get interestAfterwork;

  /// No description provided for @interestVisiteGuidee.
  ///
  /// In fr, this message translates to:
  /// **'Visites guidées'**
  String get interestVisiteGuidee;

  /// No description provided for @interestBalade.
  ///
  /// In fr, this message translates to:
  /// **'Balades / Randonnées'**
  String get interestBalade;

  /// No description provided for @interestPatrimoine.
  ///
  /// In fr, this message translates to:
  /// **'Patrimoine / Monuments'**
  String get interestPatrimoine;

  /// No description provided for @interestNature.
  ///
  /// In fr, this message translates to:
  /// **'Nature / Plein air'**
  String get interestNature;

  /// No description provided for @interestCroisiere.
  ///
  /// In fr, this message translates to:
  /// **'Croisières fluviales'**
  String get interestCroisiere;

  /// No description provided for @interestOenotourisme.
  ///
  /// In fr, this message translates to:
  /// **'Œnotourisme'**
  String get interestOenotourisme;

  /// No description provided for @prefsUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Préférences mises à jour'**
  String get prefsUpdated;

  /// No description provided for @commonErrorRetry.
  ///
  /// In fr, this message translates to:
  /// **'Erreur, réessayez'**
  String get commonErrorRetry;

  /// No description provided for @prefsProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifie ton prénom/pseudo et ta photo'**
  String get prefsProfileSubtitle;

  /// No description provided for @prefsMyTownHalls.
  ///
  /// In fr, this message translates to:
  /// **'Mes mairies'**
  String get prefsMyTownHalls;

  /// No description provided for @prefsMyTownHallsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevez les notifications de plusieurs mairies'**
  String get prefsMyTownHallsSubtitle;

  /// No description provided for @prefsMyHub.
  ///
  /// In fr, this message translates to:
  /// **'Mon Hub'**
  String get prefsMyHub;

  /// No description provided for @prefsMyHubSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre ville principale pour les événements'**
  String get prefsMyHubSubtitle;

  /// No description provided for @prefsInterests.
  ///
  /// In fr, this message translates to:
  /// **'Centres d\'intérêt'**
  String get prefsInterests;

  /// No description provided for @prefsInterestsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez vos activités pour des notifications pertinentes. Appuyez sur une catégorie pour affiner vos choix.'**
  String get prefsInterestsSubtitle;

  /// No description provided for @prefsNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Carlos'**
  String get prefsNameHint;

  /// No description provided for @prefsBio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get prefsBio;

  /// No description provided for @prefsBioHint.
  ///
  /// In fr, this message translates to:
  /// **'Quelques mots sur toi (visible sur tes stories)'**
  String get prefsBioHint;

  /// No description provided for @prefsAddCity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une ville...'**
  String get prefsAddCity;

  /// No description provided for @mairieLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des actus...'**
  String get mairieLoading;

  /// No description provided for @mairieOffline.
  ///
  /// In fr, this message translates to:
  /// **'Oups, pas de connexion'**
  String get mairieOffline;

  /// No description provided for @mairieLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les notifications'**
  String get mairieLoadError;

  /// No description provided for @mairieMyCities.
  ///
  /// In fr, this message translates to:
  /// **'Mes Villes'**
  String get mairieMyCities;

  /// No description provided for @mairieNoCity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ville'**
  String get mairieNoCity;

  /// Nombre d'actus
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{actu} other{actus}}'**
  String mairieNewsCount(int count);

  /// No description provided for @mairieAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get mairieAll;

  /// No description provided for @mairieNoNewsForCity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune actu pour cette mairie'**
  String get mairieNoNewsForCity;

  /// No description provided for @mairieNothingNew.
  ///
  /// In fr, this message translates to:
  /// **'Rien de neuf !'**
  String get mairieNothingNew;

  /// Mairie sans actu
  ///
  /// In fr, this message translates to:
  /// **'{city} n\'a pas encore publié d\'actualité'**
  String mairieCityNoNews(String city);

  /// No description provided for @mairieNoNews.
  ///
  /// In fr, this message translates to:
  /// **'Aucune actualité pour le moment'**
  String get mairieNoNews;

  /// No description provided for @mairieWillNotify.
  ///
  /// In fr, this message translates to:
  /// **'Tu seras notifié des nouveautés'**
  String get mairieWillNotify;

  /// No description provided for @mairieNew.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get mairieNew;

  /// No description provided for @timeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get timeYesterday;

  /// No description provided for @mairieUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mairies mises à jour'**
  String get mairieUpdated;

  /// No description provided for @mairieManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes mairies'**
  String get mairieManage;

  /// No description provided for @mairieManageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez ou retirez les villes suivies'**
  String get mairieManageSubtitle;

  /// No description provided for @mairieNoneFollowed.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mairie suivie pour le moment'**
  String get mairieNoneFollowed;

  /// No description provided for @offerAt.
  ///
  /// In fr, this message translates to:
  /// **'Chez'**
  String get offerAt;

  /// No description provided for @offerValid.
  ///
  /// In fr, this message translates to:
  /// **'Valable'**
  String get offerValid;

  /// No description provided for @offerNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Sans date limite'**
  String get offerNoExpiry;

  /// Fin de validite
  ///
  /// In fr, this message translates to:
  /// **'jusqu\'au {date}'**
  String offerUntil(String date);

  /// No description provided for @offerAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get offerAvailability;

  /// No description provided for @offerUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimitées'**
  String get offerUnlimited;

  /// No description provided for @offerUnlimitedShort.
  ///
  /// In fr, this message translates to:
  /// **'∞ Illimité'**
  String get offerUnlimitedShort;

  /// No description provided for @offerValidateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de valider l\'offre'**
  String get offerValidateFailed;

  /// No description provided for @offerGeneratingCode.
  ///
  /// In fr, this message translates to:
  /// **'Génération du code...'**
  String get offerGeneratingCode;

  /// No description provided for @offerAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'DÉJÀ UTILISÉ'**
  String get offerAlreadyUsed;

  /// No description provided for @offerShowMerchant.
  ///
  /// In fr, this message translates to:
  /// **'À PRÉSENTER AU COMMERÇANT'**
  String get offerShowMerchant;

  /// No description provided for @offerCodeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié !'**
  String get offerCodeCopied;

  /// No description provided for @offerTapToCopy.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour copier'**
  String get offerTapToCopy;

  /// No description provided for @offerShowCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Présentez ce code au commerçant pour bénéficier de l\'offre'**
  String get offerShowCodeHint;

  /// No description provided for @premiumRestos.
  ///
  /// In fr, this message translates to:
  /// **'Restos'**
  String get premiumRestos;

  /// No description provided for @premiumBars.
  ///
  /// In fr, this message translates to:
  /// **'Bars'**
  String get premiumBars;

  /// No description provided for @premiumWellness.
  ///
  /// In fr, this message translates to:
  /// **'Bien-être'**
  String get premiumWellness;

  /// No description provided for @premiumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Offres premium'**
  String get premiumTitle;

  /// No description provided for @premiumPitch.
  ///
  /// In fr, this message translates to:
  /// **'3 offres exclusives de plus chaque mois, dans tes catégories préférées.'**
  String get premiumPitch;

  /// No description provided for @premiumUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer · 5,90 €/mois'**
  String get premiumUnlock;

  /// No description provided for @proTypeAssociation.
  ///
  /// In fr, this message translates to:
  /// **'Association'**
  String get proTypeAssociation;

  /// No description provided for @proTypePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Établissement privé'**
  String get proTypePrivate;

  /// No description provided for @proTypeLegalEntity.
  ///
  /// In fr, this message translates to:
  /// **'Personne morale approuvée'**
  String get proTypeLegalEntity;

  /// No description provided for @pwdRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get pwdRequired;

  /// No description provided for @pwdMin10.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 10 caractères'**
  String get pwdMin10;

  /// No description provided for @pwdUppercase.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 1 majuscule'**
  String get pwdUppercase;

  /// No description provided for @pwdDigit.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 1 chiffre'**
  String get pwdDigit;

  /// No description provided for @pwdHint10.
  ///
  /// In fr, this message translates to:
  /// **'10+ caractères'**
  String get pwdHint10;

  /// No description provided for @pwdHintUpper.
  ///
  /// In fr, this message translates to:
  /// **'1 majuscule'**
  String get pwdHintUpper;

  /// No description provided for @pwdHintDigit.
  ///
  /// In fr, this message translates to:
  /// **'1 chiffre'**
  String get pwdHintDigit;

  /// No description provided for @proSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace Professionnel'**
  String get proSpaceTitle;

  /// No description provided for @proLoginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get proLoginSubtitle;

  /// No description provided for @proSignupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-vous pour publier des événements'**
  String get proSignupSubtitle;

  /// No description provided for @proEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get proEmailRequired;

  /// No description provided for @proPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get proPassword;

  /// No description provided for @proSendingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get proSendingInProgress;

  /// No description provided for @proForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get proForgotPassword;

  /// No description provided for @proStructureName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la structure'**
  String get proStructureName;

  /// No description provided for @proNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get proNameRequired;

  /// No description provided for @proStructureType.
  ///
  /// In fr, this message translates to:
  /// **'Type de structure'**
  String get proStructureType;

  /// No description provided for @proPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est requis'**
  String get proPhoneRequired;

  /// No description provided for @proSubmitSignup.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'inscription'**
  String get proSubmitSignup;

  /// No description provided for @proEnterEmailFirst.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email d\'abord'**
  String get proEnterEmailFirst;

  /// No description provided for @proResetSent.
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé !'**
  String get proResetSent;

  /// No description provided for @proResetFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi. Vérifiez votre email.'**
  String get proResetFailed;

  /// No description provided for @proLoginSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie !'**
  String get proLoginSuccess;

  /// No description provided for @proEnter6Digits.
  ///
  /// In fr, this message translates to:
  /// **'Entrez les 6 chiffres du code'**
  String get proEnter6Digits;

  /// No description provided for @proNewCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé par mail'**
  String get proNewCodeSent;

  /// No description provided for @proResendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du renvoi du code'**
  String get proResendFailed;

  /// No description provided for @proApproved.
  ///
  /// In fr, this message translates to:
  /// **'Compte approuvé ! Bienvenue sur MaCity'**
  String get proApproved;

  /// No description provided for @proEmailVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification par email'**
  String get proEmailVerification;

  /// No description provided for @proCodeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé à\n'**
  String get proCodeSentTo;

  /// No description provided for @proLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get proLogout;

  /// No description provided for @proEmailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié !'**
  String get proEmailVerified;

  /// No description provided for @proPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte en cours de validation'**
  String get proPendingTitle;

  /// No description provided for @proPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe va t\'appeler très bientôt au numéro que tu as renseigné pour finaliser la validation de ton compte.\n\nUne fois ton compte approuvé, tu pourras publier des offres et accéder à toutes les fonctionnalités pro.'**
  String get proPendingBody;

  /// No description provided for @proWaitCall.
  ///
  /// In fr, this message translates to:
  /// **'OK, j\'attends l\'appel'**
  String get proWaitCall;

  /// No description provided for @pveNoListing.
  ///
  /// In fr, this message translates to:
  /// **'Aucune fiche associée à votre compte pro.\nRéclamez votre établissement depuis sa fiche pour pouvoir l\'éditer.'**
  String get pveNoListing;

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement : {error}'**
  String pveLoadError(String error);

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi : {error}'**
  String pveUploadFailed(String error);

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression : {error}'**
  String pveDeleteFailed(String error);

  /// No description provided for @pveFilmNow.
  ///
  /// In fr, this message translates to:
  /// **'Filmer maintenant'**
  String get pveFilmNow;

  /// No description provided for @pvePickVideo.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une vidéo dans la galerie'**
  String get pvePickVideo;

  /// No description provided for @pveCoverUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Pochette mise à jour'**
  String get pveCoverUpdated;

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi de la pochette : {error}'**
  String pveCoverUploadFailed(String error);

  /// No description provided for @pveCompressing.
  ///
  /// In fr, this message translates to:
  /// **'Compression...'**
  String get pveCompressing;

  /// Taille video
  ///
  /// In fr, this message translates to:
  /// **'Compressée : {size} MB'**
  String pveCompressed(String size);

  /// Progression
  ///
  /// In fr, this message translates to:
  /// **'Envoi {pct} %'**
  String pveUploadPct(int pct);

  /// No description provided for @pveVideoUploaded.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo envoyée avec succès'**
  String get pveVideoUploaded;

  /// No description provided for @pveDeleteVideo.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la vidéo ?'**
  String get pveDeleteVideo;

  /// No description provided for @pveUnknownError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get pveUnknownError;

  /// No description provided for @pveAutoSaved.
  ///
  /// In fr, this message translates to:
  /// **'Vos modifications sont enregistrées automatiquement.'**
  String get pveAutoSaved;

  /// No description provided for @pveCoverSection.
  ///
  /// In fr, this message translates to:
  /// **'Pochette (visible dans la liste)'**
  String get pveCoverSection;

  /// No description provided for @pveCoverHint.
  ///
  /// In fr, this message translates to:
  /// **'Image principale affichée sur la carte de votre établissement dans les listes.'**
  String get pveCoverHint;

  /// No description provided for @pvePhotosSection.
  ///
  /// In fr, this message translates to:
  /// **'Photos de la fiche détail'**
  String get pvePhotosSection;

  /// No description provided for @pvePhotosHint.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 6 photos. Apparaissent dans l\'ordre sur la fiche détail.'**
  String get pvePhotosHint;

  /// No description provided for @pveVideoSection.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo teaser'**
  String get pveVideoSection;

  /// No description provided for @pveVideoHint.
  ///
  /// In fr, this message translates to:
  /// **'Filmez avec le téléphone ou choisissez dans la galerie. Max 30 s, 50 MB après compression automatique.'**
  String get pveVideoHint;

  /// No description provided for @pveDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get pveDone;

  /// No description provided for @pveCover.
  ///
  /// In fr, this message translates to:
  /// **'Pochette'**
  String get pveCover;

  /// No description provided for @pvePhotoGridHint.
  ///
  /// In fr, this message translates to:
  /// **'Appui long pour supprimer · Tap pour remplacer'**
  String get pvePhotoGridHint;

  /// No description provided for @pveAddVideo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une vidéo'**
  String get pveAddVideo;

  /// No description provided for @pvePreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation...'**
  String get pvePreparing;

  /// No description provided for @pveDeletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get pveDeletePhoto;

  /// No description provided for @aoEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'offre'**
  String get aoEditTitle;

  /// No description provided for @aoBusinessName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'établissement'**
  String get aoBusinessName;

  /// No description provided for @aoBusinessNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom de l\'établissement est requis'**
  String get aoBusinessNameRequired;

  /// No description provided for @aoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'offre (ex : massage offert)'**
  String get aoTitle;

  /// No description provided for @aoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (ex : 30 min offertes pour toute réservation)'**
  String get aoDescription;

  /// No description provided for @aoEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Emoji (1 seul)'**
  String get aoEmoji;

  /// No description provided for @aoAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get aoAddPhoto;

  /// No description provided for @aoSpotsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nombre de places est requis'**
  String get aoSpotsRequired;

  /// No description provided for @aoValidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un nombre valide'**
  String get aoValidNumber;

  /// No description provided for @aoUnlimitedSpots.
  ///
  /// In fr, this message translates to:
  /// **'Places illimitées'**
  String get aoUnlimitedSpots;

  /// No description provided for @aoExpiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get aoExpiryDate;

  /// No description provided for @aoExpiryRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date d\'expiration est requise'**
  String get aoExpiryRequired;

  /// No description provided for @aoNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Sans date d\'expiration'**
  String get aoNoExpiry;

  /// No description provided for @aoEditing.
  ///
  /// In fr, this message translates to:
  /// **'Modification en cours...'**
  String get aoEditing;

  /// No description provided for @aoFixFields.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie les champs en rouge avant de publier'**
  String get aoFixFields;

  /// No description provided for @aoEdited.
  ///
  /// In fr, this message translates to:
  /// **'Offre modifiée avec succès !'**
  String get aoEdited;

  /// No description provided for @aoPublished.
  ///
  /// In fr, this message translates to:
  /// **'Offre publiée avec succès !'**
  String get aoPublished;

  /// Erreur
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String commonErrorWith(String error);

  /// No description provided for @aoProRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion pro requise'**
  String get aoProRequired;

  /// No description provided for @aoPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte pro est bien créé. Notre équipe va t\'appeler très bientôt au numéro renseigné pour valider ton inscription. Tu pourras publier des offres dès que ton compte sera approuvé.'**
  String get aoPendingBody;

  /// No description provided for @aoProRequiredBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu dois être connecté avec un compte pro approuvé pour publier une offre.'**
  String get aoProRequiredBody;

  /// No description provided for @commonOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @moDeleteOffer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette offre ?'**
  String get moDeleteOffer;

  /// No description provided for @moDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Offre supprimée'**
  String get moDeleted;

  /// No description provided for @moNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Sans expiration'**
  String get moNoExpiry;

  /// No description provided for @moExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get moExpired;

  /// No description provided for @moFull.
  ///
  /// In fr, this message translates to:
  /// **'Complète'**
  String get moFull;

  /// No description provided for @moLive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get moLive;

  /// No description provided for @moInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactive'**
  String get moInactive;

  /// No description provided for @moNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre encore'**
  String get moNone;

  /// No description provided for @moNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée ta première offre promotionnelle pour attirer plus de clients.'**
  String get moNoneHint;

  /// No description provided for @subAllPremium.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les offres premium débloquées'**
  String get subAllPremium;

  /// No description provided for @subAllPremiumSub.
  ///
  /// In fr, this message translates to:
  /// **'Café offert, réductions, places de concert, expériences...'**
  String get subAllPremiumSub;

  /// No description provided for @subWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles offres chaque semaine'**
  String get subWeekly;

  /// No description provided for @subWeeklySub.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnées chez les meilleurs commerces.'**
  String get subWeeklySub;

  /// No description provided for @subCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annulable à tout moment'**
  String get subCancel;

  /// No description provided for @subCancelSub.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement. Tu arrêtes quand tu veux.'**
  String get subCancelSub;

  /// No description provided for @subHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Profite des meilleures\noffres de ta ville.'**
  String get subHeadline;

  /// No description provided for @subPitch.
  ///
  /// In fr, this message translates to:
  /// **'Un abonnement, des centaines d\'offres premium\nsélectionnées chez les commerces partenaires.'**
  String get subPitch;

  /// No description provided for @subPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'par mois'**
  String get subPerMonth;

  /// No description provided for @subAutoRenew.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique. Annulable à tout moment depuis les réglages.'**
  String get subAutoRenew;

  /// No description provided for @subPaymentSoon.
  ///
  /// In fr, this message translates to:
  /// **'Paiement bientôt disponible'**
  String get subPaymentSoon;

  /// No description provided for @subSubscribe.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner pour 5,90 €/mois'**
  String get subSubscribe;

  /// No description provided for @foodChipRestaurants.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants'**
  String get foodChipRestaurants;

  /// No description provided for @foodChipGuinguette.
  ///
  /// In fr, this message translates to:
  /// **'Guinguette'**
  String get foodChipGuinguette;

  /// No description provided for @foodChipBuffets.
  ///
  /// In fr, this message translates to:
  /// **'Buffets'**
  String get foodChipBuffets;

  /// No description provided for @foodChipTeaRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salon de Thé'**
  String get foodChipTeaRoom;

  /// No description provided for @foodChipBrunch.
  ///
  /// In fr, this message translates to:
  /// **'Brunch'**
  String get foodChipBrunch;

  /// No description provided for @foodChipTapas.
  ///
  /// In fr, this message translates to:
  /// **'Tapas'**
  String get foodChipTapas;

  /// No description provided for @foodChipPintxos.
  ///
  /// In fr, this message translates to:
  /// **'Pintxos'**
  String get foodChipPintxos;

  /// No description provided for @foodChipFish.
  ///
  /// In fr, this message translates to:
  /// **'Poisson'**
  String get foodChipFish;

  /// No description provided for @foodChipMeat.
  ///
  /// In fr, this message translates to:
  /// **'Viande'**
  String get foodChipMeat;

  /// No description provided for @foodLocateToSort.
  ///
  /// In fr, this message translates to:
  /// **'Active la localisation pour trier par proximité.'**
  String get foodLocateToSort;

  /// No description provided for @foodNearestToMe.
  ///
  /// In fr, this message translates to:
  /// **'Plus proche de moi'**
  String get foodNearestToMe;

  /// No description provided for @foodPartners.
  ///
  /// In fr, this message translates to:
  /// **'Nos restaurants partenaires'**
  String get foodPartners;

  /// No description provided for @foodBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez, découvrez, régalez-vous.'**
  String get foodBannerTitle;

  /// No description provided for @foodBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les meilleures tables vous attendent.'**
  String get foodBannerSubtitle;

  /// No description provided for @foodTitle.
  ///
  /// In fr, this message translates to:
  /// **'Food.'**
  String get foodTitle;

  /// No description provided for @foodSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Des restaurants, des saveurs à partager.'**
  String get foodSubtitle;

  /// No description provided for @foodAroundMe.
  ///
  /// In fr, this message translates to:
  /// **'Autour de moi'**
  String get foodAroundMe;

  /// No description provided for @foodFavourite.
  ///
  /// In fr, this message translates to:
  /// **'COUP DE CŒUR'**
  String get foodFavourite;

  /// No description provided for @foodKickerHome.
  ///
  /// In fr, this message translates to:
  /// **'Rubrique · Plaisirs'**
  String get foodKickerHome;

  /// No description provided for @foodBlurb.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants, brunchs, marchés : la carte gourmande de la ville.'**
  String get foodBlurb;

  /// No description provided for @foodNoRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Aucun restaurant'**
  String get foodNoRestaurant;

  /// No description provided for @mapNearestRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant le plus proche'**
  String get mapNearestRestaurant;

  /// No description provided for @resErrDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une date'**
  String get resErrDate;

  /// No description provided for @resErrTime.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une heure'**
  String get resErrTime;

  /// No description provided for @resErrSignup.
  ///
  /// In fr, this message translates to:
  /// **'Termine ton inscription (prénom requis)'**
  String get resErrSignup;

  /// No description provided for @resSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée. Tu seras notifié dès la réponse.'**
  String get resSent;

  /// No description provided for @resBook.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get resBook;

  /// No description provided for @resPeople.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de personnes'**
  String get resPeople;

  /// No description provided for @resPhoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get resPhoneOptional;

  /// No description provided for @resComment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire (allergies, occasion...)'**
  String get resComment;

  /// No description provided for @resSendRequest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get resSendRequest;

  /// No description provided for @tripPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Organiser mon trip'**
  String get tripPlanTitle;

  /// No description provided for @tripPlanSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Repas et activités, jour par jour, selon votre groupe.'**
  String get tripPlanSubtitle;

  /// Nom et age d'un confirme
  ///
  /// In fr, this message translates to:
  /// **'{name} · {age} ans'**
  String pvNameAge(String name, int age);

  /// No description provided for @tripNoAlternative.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'autre lieu disponible pour cette étape'**
  String get tripNoAlternative;

  /// No description provided for @tripQWho.
  ///
  /// In fr, this message translates to:
  /// **'Vous partez avec qui ?'**
  String get tripQWho;

  /// No description provided for @tripQWhoSub.
  ///
  /// In fr, this message translates to:
  /// **'On adapte les adresses à votre groupe.'**
  String get tripQWhoSub;

  /// No description provided for @tripCouple.
  ///
  /// In fr, this message translates to:
  /// **'En couple'**
  String get tripCouple;

  /// No description provided for @tripCoupleSub.
  ///
  /// In fr, this message translates to:
  /// **'Tables romantiques, sorties à deux'**
  String get tripCoupleSub;

  /// No description provided for @tripFamilyKids.
  ///
  /// In fr, this message translates to:
  /// **'En famille avec enfants'**
  String get tripFamilyKids;

  /// No description provided for @tripFamilyKidsSub.
  ///
  /// In fr, this message translates to:
  /// **'Adresses et activités adaptées aux enfants'**
  String get tripFamilyKidsSub;

  /// No description provided for @tripFamily.
  ///
  /// In fr, this message translates to:
  /// **'En famille'**
  String get tripFamily;

  /// No description provided for @tripFriends.
  ///
  /// In fr, this message translates to:
  /// **'Entre amis'**
  String get tripFriends;

  /// No description provided for @tripFriendsSub.
  ///
  /// In fr, this message translates to:
  /// **'Tables à partager, activités fun, un verre le soir'**
  String get tripFriendsSub;

  /// No description provided for @tripQHowMany.
  ///
  /// In fr, this message translates to:
  /// **'Combien êtes-vous ?'**
  String get tripQHowMany;

  /// No description provided for @tripKidsIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Enfants compris.'**
  String get tripKidsIncluded;

  /// No description provided for @tripYouIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Vous compris.'**
  String get tripYouIncluded;

  /// No description provided for @tripPeople.
  ///
  /// In fr, this message translates to:
  /// **'{count} personnes'**
  String tripPeople(int count);

  /// No description provided for @tripQDuration.
  ///
  /// In fr, this message translates to:
  /// **'Vous restez combien de temps ?'**
  String get tripQDuration;

  /// No description provided for @tripQDurationSub.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille de route par jour.'**
  String get tripQDurationSub;

  /// No description provided for @tripOneDay.
  ///
  /// In fr, this message translates to:
  /// **'1 journée'**
  String get tripOneDay;

  /// No description provided for @tripOneWeek.
  ///
  /// In fr, this message translates to:
  /// **'1 semaine'**
  String get tripOneWeek;

  /// No description provided for @tripDays.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String tripDays(int count);

  /// No description provided for @tripWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Le week-end'**
  String get tripWeekend;

  /// No description provided for @tripQMeals.
  ///
  /// In fr, this message translates to:
  /// **'Vous mangez dehors quand ?'**
  String get tripQMeals;

  /// No description provided for @tripQMealsSub.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour cocher ou décocher.'**
  String get tripQMealsSub;

  /// No description provided for @tripMorning.
  ///
  /// In fr, this message translates to:
  /// **'Le matin'**
  String get tripMorning;

  /// No description provided for @tripMorningSub.
  ///
  /// In fr, this message translates to:
  /// **'Brunch, salon de thé'**
  String get tripMorningSub;

  /// No description provided for @tripNoon.
  ///
  /// In fr, this message translates to:
  /// **'Le midi'**
  String get tripNoon;

  /// No description provided for @tripNoonSub.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get tripNoonSub;

  /// No description provided for @tripEvening.
  ///
  /// In fr, this message translates to:
  /// **'Le soir'**
  String get tripEvening;

  /// No description provided for @tripEveningSub.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get tripEveningSub;

  /// No description provided for @tripQActivities.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous des activités ?'**
  String get tripQActivities;

  /// No description provided for @tripQActivitiesSubKids.
  ///
  /// In fr, this message translates to:
  /// **'Sorties pour petits et grands entre les repas.'**
  String get tripQActivitiesSubKids;

  /// No description provided for @tripQActivitiesSub.
  ///
  /// In fr, this message translates to:
  /// **'Sorties et visites entre les repas.'**
  String get tripQActivitiesSub;

  /// No description provided for @tripYesActivities.
  ///
  /// In fr, this message translates to:
  /// **'Oui, des activités'**
  String get tripYesActivities;

  /// No description provided for @tripYesActivitiesSub.
  ///
  /// In fr, this message translates to:
  /// **'Une le matin, une l\'après-midi'**
  String get tripYesActivitiesSub;

  /// No description provided for @tripNoActivities.
  ///
  /// In fr, this message translates to:
  /// **'Non, juste les repas'**
  String get tripNoActivities;

  /// No description provided for @tripQNight.
  ///
  /// In fr, this message translates to:
  /// **'Et la soirée ?'**
  String get tripQNight;

  /// No description provided for @tripQNightSub.
  ///
  /// In fr, this message translates to:
  /// **'Après le dîner, dans le même quartier.'**
  String get tripQNightSub;

  /// No description provided for @tripNightBar.
  ///
  /// In fr, this message translates to:
  /// **'Un verre en bar'**
  String get tripNightBar;

  /// No description provided for @tripNightBarSub.
  ///
  /// In fr, this message translates to:
  /// **'Bar à cocktails, pub, bar de nuit'**
  String get tripNightBarSub;

  /// No description provided for @tripNightClub.
  ///
  /// In fr, this message translates to:
  /// **'Bar puis discothèque'**
  String get tripNightClub;

  /// No description provided for @tripNightClubSub.
  ///
  /// In fr, this message translates to:
  /// **'Pour finir la nuit en club'**
  String get tripNightClubSub;

  /// No description provided for @tripNightNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas de sortie'**
  String get tripNightNone;

  /// No description provided for @tripQMusic.
  ///
  /// In fr, this message translates to:
  /// **'Quelle musique en discothèque ?'**
  String get tripQMusic;

  /// No description provided for @tripQMusicSub.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs choix possibles. On choisit le club selon vos goûts.'**
  String get tripQMusicSub;

  /// No description provided for @tripMusicElectro.
  ///
  /// In fr, this message translates to:
  /// **'Électro / Techno'**
  String get tripMusicElectro;

  /// No description provided for @tripMusicElectroSub.
  ///
  /// In fr, this message translates to:
  /// **'House, techno, électro'**
  String get tripMusicElectroSub;

  /// No description provided for @tripMusicHiphop.
  ///
  /// In fr, this message translates to:
  /// **'Hip-hop / R&B / Afro'**
  String get tripMusicHiphop;

  /// No description provided for @tripMusicHiphopSub.
  ///
  /// In fr, this message translates to:
  /// **'Rap, R&B, afrobeats, dancehall'**
  String get tripMusicHiphopSub;

  /// No description provided for @tripMusicLatino.
  ///
  /// In fr, this message translates to:
  /// **'Latino / Reggaeton'**
  String get tripMusicLatino;

  /// No description provided for @tripMusicLatinoSub.
  ///
  /// In fr, this message translates to:
  /// **'Reggaeton, salsa, bachata'**
  String get tripMusicLatinoSub;

  /// No description provided for @tripMusicGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Généraliste / Hits'**
  String get tripMusicGeneral;

  /// No description provided for @tripMusicGeneralSub.
  ///
  /// In fr, this message translates to:
  /// **'Tubes du moment, années 80 à 2000'**
  String get tripMusicGeneralSub;

  /// No description provided for @tripMusicRock.
  ///
  /// In fr, this message translates to:
  /// **'Rock / Indie'**
  String get tripMusicRock;

  /// No description provided for @tripMusicRockSub.
  ///
  /// In fr, this message translates to:
  /// **'Rock, indie, pop-rock'**
  String get tripMusicRockSub;

  /// No description provided for @tripPickOne.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un repas, une activité ou une sortie.'**
  String get tripPickOne;

  /// No description provided for @tripSeePlan.
  ///
  /// In fr, this message translates to:
  /// **'Voir ma feuille de route'**
  String get tripSeePlan;

  /// No description provided for @tripNotEnough.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore assez d\'adresses à {ville} pour composer un trip. Revenez bientôt !'**
  String tripNotEnough(String ville);

  /// No description provided for @tripYourTrip.
  ///
  /// In fr, this message translates to:
  /// **'Votre trip à {ville}'**
  String tripYourTrip(String ville);

  /// No description provided for @tripSummary.
  ///
  /// In fr, this message translates to:
  /// **'{group} · {people} pers. · {duration}'**
  String tripSummary(String group, int people, String duration);

  /// No description provided for @tripTapHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez « Infos » pour voir ce qu\'il y a à voir et à faire.'**
  String get tripTapHint;

  /// No description provided for @tripOtherProposal.
  ///
  /// In fr, this message translates to:
  /// **'Autre proposition'**
  String get tripOtherProposal;

  /// No description provided for @tripYourDay.
  ///
  /// In fr, this message translates to:
  /// **'Votre journée'**
  String get tripYourDay;

  /// No description provided for @tripDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour {n}'**
  String tripDay(int n);

  /// No description provided for @tripDayRoute.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire du jour'**
  String get tripDayRoute;

  /// No description provided for @tripNoMoreForDay.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'adresses disponibles pour ce jour.'**
  String get tripNoMoreForDay;

  /// No description provided for @tripWalkMinutes.
  ///
  /// In fr, this message translates to:
  /// **'à {min} min à pied de l\'étape précédente'**
  String tripWalkMinutes(int min);

  /// No description provided for @tripKmFrom.
  ///
  /// In fr, this message translates to:
  /// **'à {km} km de l\'étape précédente'**
  String tripKmFrom(String km);

  /// No description provided for @tripPartner.
  ///
  /// In fr, this message translates to:
  /// **'⭐ Partenaire'**
  String get tripPartner;

  /// No description provided for @tripBookingAdvised.
  ///
  /// In fr, this message translates to:
  /// **'Réservation conseillée pour {count}'**
  String tripBookingAdvised(int count);

  /// No description provided for @tripInfos.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get tripInfos;

  /// No description provided for @tripChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get tripChange;

  /// No description provided for @tripSlotBreakfast.
  ///
  /// In fr, this message translates to:
  /// **'Petit-déjeuner'**
  String get tripSlotBreakfast;

  /// No description provided for @tripSlotMorning.
  ///
  /// In fr, this message translates to:
  /// **'Activité du matin'**
  String get tripSlotMorning;

  /// No description provided for @tripSlotLunch.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get tripSlotLunch;

  /// No description provided for @tripSlotAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Activité de l\'après-midi'**
  String get tripSlotAfternoon;

  /// No description provided for @tripSlotDinner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get tripSlotDinner;

  /// No description provided for @tripSlotDrink.
  ///
  /// In fr, this message translates to:
  /// **'Un verre en bar'**
  String get tripSlotDrink;

  /// No description provided for @tripSlotClub.
  ///
  /// In fr, this message translates to:
  /// **'Fin de soirée en discothèque'**
  String get tripSlotClub;

  /// No description provided for @tripMusicAny.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get tripMusicAny;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
