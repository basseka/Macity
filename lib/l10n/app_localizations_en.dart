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

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonFree => 'FREE';

  @override
  String get commonValidate => 'Confirm';

  @override
  String get commonEdit => 'Edit';

  @override
  String get catAll => 'All';

  @override
  String get catConcerts => 'Concerts';

  @override
  String get catParty => 'Parties';

  @override
  String get catShow => 'Shows';

  @override
  String get catDance => 'Dance';

  @override
  String get catCinema => 'Cinema';

  @override
  String get modeDay => 'Concerts & Shows';

  @override
  String get modeSport => 'Sport & sporting events';

  @override
  String get modeCulture => 'Culture & Arts';

  @override
  String get modeFamily => 'Family time';

  @override
  String get modeFood => 'Food & lifestyle';

  @override
  String get modeGaming => 'Gaming & pop culture';

  @override
  String get modeNight => 'Nightlife & going out';

  @override
  String get modeTourisme => 'Tourism & discoveries';

  @override
  String get feedEvents => 'Events';

  @override
  String feedDateRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String feedEventsInPeriod(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events in this period',
      one: '1 event in this period',
    );
    return '$_temp0';
  }

  @override
  String get feedNoEventsInPeriod => 'No events in this period';

  @override
  String feedNoEventsInPeriodForCategory(String category) {
    return 'No \"$category\" events in this period';
  }

  @override
  String get feedSearchPlaceholder => 'Search for a place, an event...';

  @override
  String get feedSearchPlaceholderAlt => 'Search for an event, a place...';

  @override
  String get feedSearchHint => 'Name, place, artist...';

  @override
  String get feedPickPeriod => 'Choose your dates';

  @override
  String get feedMenuOffers => 'Offers';

  @override
  String get feedMenuTownHalls => 'Town halls';

  @override
  String get feedMenuPreferences => 'Preferences';

  @override
  String get feedAllVenues => 'All venues';

  @override
  String get feedSearching => 'Searching...';

  @override
  String get feedForYou => 'FOR YOU';

  @override
  String get feedOtherResults => 'OTHER RESULTS';

  @override
  String get feedTypeAtLeast2 => 'Type at least 2 letters';

  @override
  String get feedNoResults => 'No results';

  @override
  String feedNoUpcomingEventsFor(String label) {
    return 'No upcoming $label events';
  }

  @override
  String get feedNoUpcomingEvents => 'No upcoming events';

  @override
  String get feedOpenOnMap => 'Open on the map';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonLearnMore => 'Learn more';

  @override
  String get homeFeaturedPrefix => 'In the';

  @override
  String get homeFeaturedAccent => 'spotlight';

  @override
  String get homeTopPrefix => 'Top';

  @override
  String get homeTopAccent => 'picks';

  @override
  String get homeBadgeFeatured => 'Featured';

  @override
  String get homeBadgeTop => 'Top pick';

  @override
  String get homeBadgeYourSelection => 'Your selection';

  @override
  String get homeBadgePinned => 'PINNED';

  @override
  String get homePillTop => 'Top';

  @override
  String get offersLoadError => 'Unable to load offers';

  @override
  String get offersNone => 'No offers available';

  @override
  String get offerClaim => 'Get the deal';

  @override
  String get offersSwipeHint => 'Swipe to explore';

  @override
  String get offerSoldOut => 'Sold out';

  @override
  String offerSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots',
      one: '1 spot',
    );
    return '$_temp0';
  }

  @override
  String get tonightTitle => 'Best picks';

  @override
  String get tonightWhatToDo => 'What to do tonight';

  @override
  String get tonightNothingToday => 'Nothing today? Check tomorrow';

  @override
  String tonightOutingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count OUTINGS',
      one: '1 OUTING',
    );
    return '$_temp0';
  }

  @override
  String get tonightOutingsMany => '99+ OUTINGS';

  @override
  String tonightA11yEmpty(String city) {
    return 'Nothing today in $city, check tomorrow, button';
  }

  @override
  String tonightA11yCount(int count, String city) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Best picks in $city, $count outings, button',
      one: 'Best picks in $city, 1 outing, button',
    );
    return '$_temp0';
  }

  @override
  String tonightA11y(String city) {
    return 'Best picks in $city, button';
  }

  @override
  String get tonightLoadError => 'Unable to load the best picks.';

  @override
  String get tonightNothingTonight => 'Nothing tonight in this city.';

  @override
  String get tonightNothingTodayCity => 'No picks today in this city.';

  @override
  String get tonightSectionConcerts => 'Concerts';

  @override
  String get tonightSectionParties => 'Parties';

  @override
  String get tonightSectionShows => 'Shows';

  @override
  String get tonightSectionOther => 'Other outings';

  @override
  String get priceFree => 'Free';

  @override
  String get priceUnknown => 'Price not specified';

  @override
  String get priceFreeEntry => 'free entry';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String get feedMoreSearch => 'Want more? Check the feed';

  @override
  String get commonPartner => 'PARTNER';

  @override
  String get favoritesRemove => 'Remove from favorites';

  @override
  String get favoritesAdd => 'Add to favorites';

  @override
  String get modeShortDay => 'Concert';

  @override
  String get modeShortGaming => 'Gaming';

  @override
  String get modeShortNight => 'Night';

  @override
  String get modeShortTourisme => 'Tourism';

  @override
  String get rubriqueEyebrow => 'SECTION';

  @override
  String get commonToDiscover => 'To discover';

  @override
  String get commonDiscover => 'Discover';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonCall => 'Call';

  @override
  String get commonShare => 'Share';

  @override
  String get commonTickets => 'TICKETS';

  @override
  String get commonTicketOffice => 'TICKETS';

  @override
  String get shareFooter => 'Discover it on MaCity';

  @override
  String get filterByVenue => 'Filter by venue';

  @override
  String get refineAll => 'All';

  @override
  String get landingPartners => 'Our partners';

  @override
  String get landingRefine => 'Refine your search';

  @override
  String get landingNoPlaceForSelection => 'No places for this selection.';

  @override
  String get landingUnavailable => 'Content unavailable.';

  @override
  String get landingNoPlaceForFilter => 'No places for this filter.';

  @override
  String get landingInspirations => 'Current inspirations';

  @override
  String get cultureEyebrowRight => 'CITY';

  @override
  String get cultureTitle => 'Culture.';

  @override
  String get cultureSubtitle =>
      'Museums, monuments, exhibitions: the cultural calendar.';

  @override
  String get cultureChipMuseums => 'Museums';

  @override
  String get cultureChipMonuments => 'Monuments';

  @override
  String get cultureChipLibraries => 'Libraries';

  @override
  String get cultureChipGalleries => 'Galleries';

  @override
  String get cultureBannerTitle => 'The city tells its story.';

  @override
  String get cultureBannerSubtitle =>
      'Museums, exhibitions and heritage await you.';

  @override
  String get cultureMapTitle => 'Cultural venues';

  @override
  String get cultureKickerHome => 'Section · City';

  @override
  String get cultureBlurb =>
      'Cinema, theatre, exhibitions, dance: the cultural calendar.';

  @override
  String get cultureCatMuseum => 'Museums';

  @override
  String get cultureCatTheatre => 'Theatre';

  @override
  String get cultureCatGallery => 'Art galleries';

  @override
  String get cultureCatMonument => 'Historic monuments';

  @override
  String get cultureCatLibrary => 'Libraries';

  @override
  String get cultureCatGuidedTours => 'Guided tours';

  @override
  String get cultureCatExhibition => 'Exhibitions';

  @override
  String get cultureCatUpcoming => 'Upcoming';

  @override
  String get cultureNoMuseum => 'No museums found';

  @override
  String get cultureMuseumError => 'Error loading museums';

  @override
  String get cultureNoTheatreEvent => 'No upcoming theatre events';

  @override
  String get cultureNoEventForFilter => 'No events for this filter';

  @override
  String get cultureNoScreening => 'No upcoming screenings';

  @override
  String get cultureNoScreeningForFilter => 'No screenings for this filter';

  @override
  String get cultureNoDance => 'No dance studios found';

  @override
  String get cultureDanceError => 'Error loading dance studios';

  @override
  String get cultureNoGallery => 'No galleries found';

  @override
  String get cultureGalleryError => 'Error loading galleries';

  @override
  String get cultureNoLibrary => 'No libraries found';

  @override
  String get cultureLibraryError => 'Error loading libraries';

  @override
  String get cultureNoMonument => 'No monuments found';

  @override
  String get cultureMonumentError => 'Error loading monuments';

  @override
  String get cultureNoGuidedTour => 'No upcoming guided tours';

  @override
  String get cultureGuidedTourError => 'Error loading guided tours';

  @override
  String get cultureNoExhibition => 'No upcoming exhibitions';

  @override
  String get cultureExhibitionError => 'Error loading exhibitions';

  @override
  String get cultureNoEvent => 'No upcoming cultural events';

  @override
  String get cultureEventError => 'Error loading cultural events';

  @override
  String get cultureNoVenueForCategory =>
      'No cultural venues found for this category';

  @override
  String get cultureVenueError => 'Error loading cultural venues';

  @override
  String get museumCatArt => 'Art';

  @override
  String get museumCatHistory => 'History';

  @override
  String get museumCatScience => 'Science';

  @override
  String get danceGroupGeneral => 'General school';

  @override
  String get danceGroupSpecialisation => 'Specialisation & style';

  @override
  String get danceGroupPro => 'Professional training';

  @override
  String get danceGroupOther => 'Dance school';

  @override
  String theatreUpcomingShows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming shows',
      one: '1 upcoming show',
      zero: 'No upcoming shows',
    );
    return '$_temp0';
  }

  @override
  String get commonClosed => 'Closed';

  @override
  String get commonLoadError => 'Loading error';

  @override
  String get commonMap => 'Map';

  @override
  String get commonList => 'List';

  @override
  String get commonCategories => 'Categories';

  @override
  String get commonView => 'View';

  @override
  String get commonNoSubcategory => 'No subcategories';

  @override
  String get commonNoPlaceForCategory => 'No places found for this category';

  @override
  String get commonPlacesLoadError => 'Error loading places';

  @override
  String get commonNoEventYetAdd => 'No events yet.\nAdd one with the + button';

  @override
  String get mapNearestBar => 'Nearest bar';

  @override
  String get mapNearestClub => 'Nearest club';

  @override
  String get mapNearestPlace => 'Nearest place';

  @override
  String get nightTitle => 'Night.';

  @override
  String get nightSubtitle =>
      'Clubs, bars, parties: the city shows another face.';

  @override
  String get nightSectionTitle => 'Where to go out';

  @override
  String get nightChipClub => 'Nightclub';

  @override
  String get nightChipNightBar => 'Night bar';

  @override
  String get nightChipCocktails => 'Cocktails';

  @override
  String get nightChipShisha => 'Shisha';

  @override
  String get nightBannerTitle => 'The night is yours.';

  @override
  String get nightBannerSubtitle => 'The best night spots await you.';

  @override
  String get nightUntil2 => 'Until 2am';

  @override
  String get nightAfter2 => 'After 2am';

  @override
  String get nightAfter6 => 'After 6am';

  @override
  String get nightAllNight => '24/7';

  @override
  String get nightMapTitle => 'Out tonight';

  @override
  String get nightCatClub => 'Nightclubs';

  @override
  String get nightCatNightBar => 'Night bars';

  @override
  String get nightCatCocktails => 'Cocktail bars';

  @override
  String get nightCatShisha => 'Shisha bars';

  @override
  String get nightCatPub => 'Pubs';

  @override
  String get sosAperoOne => 'One shop delivers when everything is closed';

  @override
  String sosAperoMany(int count) {
    return '$count shops deliver when everything is closed';
  }

  @override
  String get nightPlanTitle => 'Plan your night';

  @override
  String get nightPlanSubtitle => 'Dinner · concert · bar · club';

  @override
  String get nightPlanDinner => 'Dinner';

  @override
  String get nightPlanDinnerHint => 'Before the show';

  @override
  String get nightPlanDrink => 'A drink';

  @override
  String get nightPlanDrinkHint => 'To keep the night going';

  @override
  String get nightPlanClub => 'Clubbing';

  @override
  String get nightPlanClubHint => 'To end the night';

  @override
  String get nightPlanYourEvent => 'YOUR EVENT';

  @override
  String get nightPlanGoFurther => 'Go even further: a nightclub';

  @override
  String get nightPlanGo => 'Go';

  @override
  String get nightPlanPartner => '⭐ Partner';

  @override
  String get nightPlanEmptyTitle => 'No suggestions yet';

  @override
  String nightPlanEmptyBody(String city) {
    return 'We couldn\'t find places in $city to plan your night. Come back once the city has more listings!';
  }
}
