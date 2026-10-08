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
