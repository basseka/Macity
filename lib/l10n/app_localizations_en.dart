// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navFeed => 'Feed';

  @override
  String get navPublish => 'Post';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navMyCity => 'My City';

  @override
  String get publishWhatTitle => 'What do you want to post?';

  @override
  String get publishStoryTitle => 'Map Live story';

  @override
  String get publishStorySubtitle =>
      'Photo or video of an event happening near you';

  @override
  String get publishEventTitle => 'Post an event';

  @override
  String get publishEventSubtitle => 'Concert, party, exhibition, workshop…';

  @override
  String get eventTypeTitle => 'What kind of event?';

  @override
  String get eventPrivateTitle => 'Private event';

  @override
  String get eventPrivateSubtitle =>
      'With friends, access code, not in the public feed';

  @override
  String get eventPublicTitle => 'Public event';

  @override
  String get eventPublicSubtitle => 'Visible to everyone, plans from €1.99';

  @override
  String get proAccessTitle => 'Pro access';

  @override
  String get proAccessSubtitle => 'Pro account: free and unlimited posting';

  @override
  String get proMenuTitle => 'What would you like to do?';

  @override
  String get proAddEvent => 'Add an event';

  @override
  String get proAddEventSubtitle => 'Post a new event';

  @override
  String get proScanFlyer => 'Scan a flyer (AI)';

  @override
  String get proScanFlyerSubtitle => 'Pre-fills the event from a photo';

  @override
  String get proCreatePromoOffer => 'Create a promotional offer';

  @override
  String get myPreferences => 'My preferences';

  @override
  String get accountTitle => 'My account';

  @override
  String accountHello(String name) {
    return 'Hi, $name';
  }

  @override
  String get accountProSpace => 'Pro space';

  @override
  String get accountCreate => 'Create my account';

  @override
  String get accountCreateSubtitle => 'Unlock stories, favorites and rewards';

  @override
  String get accountPublishSubtitle => 'Private, public or pro';

  @override
  String get accountMyPosts => 'My posts';

  @override
  String get accountMyPostsSubtitle => 'Events I created';

  @override
  String get accountFavorites => 'My favorites';

  @override
  String get accountFavoritesSubtitle => 'Places and events I liked';

  @override
  String get accountPrivateEvents => 'My private events';

  @override
  String get accountPrivateEventsSubtitle =>
      'Secret vaults, by invitation only';

  @override
  String get accountOpenVault => 'Open a vault';

  @override
  String get accountOpenVaultSubtitle => 'I got a link + code';

  @override
  String get accountInvitations => 'My invitations';

  @override
  String get accountInvitationsSubtitle => 'Parties where I said \"I\'m in\"';

  @override
  String get accountMemories => 'My memories';

  @override
  String get accountMemoriesSubtitle => 'Photo albums from my past parties';

  @override
  String get accountProfile => 'My profile';

  @override
  String get accountProfileSubtitle => 'City, interests';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountProApproved => 'Account approved';

  @override
  String get accountProPending => 'Pending approval';

  @override
  String get accountProEditListing => 'Edit my listing (photos, video)';

  @override
  String get accountCreateOffer => 'Create an offer';

  @override
  String get accountCreateOfferSubtitle => 'Post a promotional offer';

  @override
  String get accountMyOffers => 'My offers';

  @override
  String get accountMyOffersSubtitle => 'View, edit or delete';

  @override
  String get accountLogout => 'Log out';

  @override
  String get accountLogoutSubtitle => 'Log out of the pro account';

  @override
  String get accountProAccessSubtitle => 'Business area';

  @override
  String get accountDelete => 'Delete my account';

  @override
  String get accountDeleteSubtitle => 'Permanent and cannot be undone';

  @override
  String get accountDeleteDialogTitle => 'Delete your account?';

  @override
  String get accountDeleteProDialogBody =>
      'This cannot be undone. Your pro data will be deleted and you will no longer be able to log in with this email. You can create a new account later if needed.';

  @override
  String get accountDeleteUserDialogBody =>
      'This cannot be undone. Your profile, posts, stories and City-Miles will be deleted. You can create a new account later if needed.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get accountDeleteFailed => 'Deletion failed, please try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get languageSheetTitle => 'App language';

  @override
  String get languageSystem => 'Automatic (phone language)';

  @override
  String get languageContentNote =>
      'Listings and events stay in their original language for now.';

  @override
  String get rubriqueFood => 'Food';

  @override
  String get rubriqueCulture => 'Culture';

  @override
  String get rubriqueFamily => 'Family';

  @override
  String get rubriqueNight => 'Night';

  @override
  String get rubriqueSport => 'Sport';

  @override
  String get rubriqueEvasion => 'Getaways';

  @override
  String get onboardingWelcome => 'Welcome to MaCity';

  @override
  String get onboardingWelcomeBack => 'Good to see you again!';

  @override
  String get onboardingSignUpSubtitle => 'Create your account in seconds';

  @override
  String get onboardingLoginSubtitle => 'Log in with your details';

  @override
  String get onboardingExploreWithoutAccount => 'Explore without an account';

  @override
  String get onboardingTabSignUp => 'Sign up';

  @override
  String get onboardingTabLogin => 'Log in';

  @override
  String get onboardingSubmitSignUp => 'Let\'s go!';

  @override
  String get onboardingSubmitLogin => 'Log in';

  @override
  String get onboardingAlreadyRegistered => 'Already have an account? ';

  @override
  String get onboardingNoAccountYet => 'Don\'t have an account yet? ';

  @override
  String get onboardingSwitchToSignUp => 'Sign up';

  @override
  String get onboardingFieldName => 'First name or nickname';

  @override
  String get onboardingFieldNameError => 'Enter your first name or nickname';

  @override
  String get onboardingFieldEmail => 'Email';

  @override
  String get onboardingFieldEmailEmpty => 'Enter your email';

  @override
  String get onboardingFieldEmailInvalid => 'Invalid email';

  @override
  String get onboardingFieldPhone => 'Phone';

  @override
  String get onboardingFieldPhoneEmpty => 'Enter your number';

  @override
  String get onboardingFieldPhoneTooShort => 'Number too short';

  @override
  String get onboardingFieldCity => 'City or town';

  @override
  String get onboardingFieldCityError => 'Select your city';

  @override
  String get onboardingInterestsTitle => 'What are you into?';

  @override
  String get onboardingInterestsSubtitle =>
      'Pick your categories to get relevant notifications.';

  @override
  String get onboardingLoginHint =>
      'Enter your email and phone number\nto find your account';

  @override
  String get onboardingLoginNotFound => 'No account found with these details';

  @override
  String get onboardingLoginError => 'Connection error, please try again';

  @override
  String get onboardingTakePhoto => 'Take a photo';

  @override
  String get onboardingChooseFromGallery => 'Choose from gallery';

  @override
  String get onboardingRemovePhoto => 'Remove photo';

  @override
  String get onboardingImageError => 'Unable to select this image';

  @override
  String get emailVerifyTitle => 'Confirm your email';

  @override
  String emailVerifySent(String email) {
    return 'A 6-digit code was sent to\n$email';
  }

  @override
  String get emailVerifySpamHint =>
      'Nothing yet? Check your spam or junk folder.';

  @override
  String get emailVerifyEnterCode => 'Enter the 6-digit code';

  @override
  String get emailVerifyWrongCode => 'Incorrect or expired code';

  @override
  String get emailVerifyError => 'Verification error, please try again';

  @override
  String get emailVerifyCodeResent => 'New code sent';

  @override
  String get emailVerifyResendFailed => 'Unable to resend the code';

  @override
  String get emailVerifyConfirm => 'Confirm';

  @override
  String get emailVerifySending => 'Sending…';

  @override
  String get emailVerifyResend => 'Resend the code';
}
