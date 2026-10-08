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

  @override
  String get ticketsLabel => 'Tickets';

  @override
  String get ticketsShort => 'Tickets';

  @override
  String get websiteLabel => 'Website';

  @override
  String shareDate(String date) {
    return 'Date: $date';
  }

  @override
  String shareVenue(String venue) {
    return 'Venue: $venue';
  }

  @override
  String get countdownToday => 'TODAY';

  @override
  String get countdownTomorrow => 'TOMORROW';

  @override
  String countdownDays(int count) {
    return 'D-$count';
  }

  @override
  String get commonNoEventFound => 'No events found';

  @override
  String get mapNearest => 'Nearest';

  @override
  String get mapDirections => 'Directions';

  @override
  String get mapMyLocation => 'My location';

  @override
  String mapDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get mapLocationDisabled => 'Turn on location in your settings';

  @override
  String get mapLocationNotAllowed =>
      'Allow location access in the app settings';

  @override
  String get mapPermissionDenied => 'Permission denied';

  @override
  String mapLocationError(String error) {
    return 'Unable to get your location: $error';
  }

  @override
  String get sportTitle => 'Sport.';

  @override
  String get sportSubtitle => 'Gyms, pitches, pools: get moving near you.';

  @override
  String get sportSectionTitle => 'Where to train';

  @override
  String get sportChipGroupClasses => 'Group classes';

  @override
  String get sportChipWeights => 'Weights';

  @override
  String get sportChipGentle => 'Gentle exercise';

  @override
  String get sportChipBasket => 'Basketball';

  @override
  String get sportChipPool => 'Pool';

  @override
  String get sportBannerTitle => 'Take action.';

  @override
  String get sportBannerSubtitle => 'The best sports spots await you.';

  @override
  String get sportMapTitle => 'Sports venues';

  @override
  String sportGymCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gyms',
      one: '1 gym',
    );
    return '$_temp0';
  }

  @override
  String get sportKickerHome => 'Section · Active';

  @override
  String get sportBlurb =>
      'Matches, races, training: the city\'s sports calendar.';

  @override
  String get sportNoMatch => 'No matches found for this category';

  @override
  String get sportMatchError => 'Error loading matches';

  @override
  String get sportNews => 'Sports news';

  @override
  String get sportReadArticle => 'Read the article';

  @override
  String sportReadOn(String source) {
    return 'Read on $source';
  }

  @override
  String get sportCatMatches => 'Matches';

  @override
  String get sportCatEvents => 'Events';

  @override
  String get sportCatComplex => 'Sports centres';

  @override
  String get sportCatMarathon => 'Marathon';

  @override
  String get sportCatRacket => 'Racket sports';

  @override
  String get sportCatBoxing => 'Boxing';

  @override
  String get sportCatSwimming => 'Swimming';

  @override
  String get sportCatRunning => 'Running';

  @override
  String get sportCatCompetition => 'Competitions';

  @override
  String get sportCatDanceWorkshop => 'Dance workshops';

  @override
  String get sportCatGym => 'Gyms';

  @override
  String get sportCatBoxingGym => 'Boxing gyms';

  @override
  String get sportCatFootballPitch => 'Football pitches';

  @override
  String get sportCatBasketCourt => 'Basketball courts';

  @override
  String get sportCatPool => 'Swimming pools';

  @override
  String get sportCatPadel => 'Padel';

  @override
  String get sportCatTableTennis => 'Table tennis';

  @override
  String get sportCatBadminton => 'Badminton';

  @override
  String get sportCatFootball => 'Football';

  @override
  String get sportCatBasketball => 'Basketball';

  @override
  String get sportCatHandball => 'Handball';

  @override
  String get sportCatGala => 'Gala / Fights';

  @override
  String get sportCatOlympics => '2028 Olympics';

  @override
  String get familyEyebrowRight => 'TRIBE';

  @override
  String get familyTitle => 'Family.';

  @override
  String get familySubtitle =>
      'Cinema, parks, workshops: outings with the kids.';

  @override
  String get familySectionTitle => 'Family things to do';

  @override
  String get familyBannerTitle => 'Memories to make together.';

  @override
  String get familyBannerSubtitle => 'The best kids\' outings await you.';

  @override
  String get familyMapTitle => 'Family venues';

  @override
  String get familyAllAges => 'All ages';

  @override
  String get familyAge0to3 => '0-3 years';

  @override
  String familyUpToAge(int max) {
    return 'Up to $max years';
  }

  @override
  String get familyKickerHome => 'Section · Tribe';

  @override
  String get familyNoEvent => 'No family events yet';

  @override
  String get familySessions => 'SHOWTIMES';

  @override
  String priceLabel(String price) {
    return 'Price: $price';
  }

  @override
  String get shareFooterPointing => 'Discover it on MaCity 👉';

  @override
  String get familyGroupEntertainment => 'Entertainment';

  @override
  String get familyGroupKidsPlay => 'Kids play';

  @override
  String get familyGroupAnimals => 'Animals & nature';

  @override
  String get familyGroupWater => 'Water activities';

  @override
  String get familyGroupOutdoor => 'Outdoor outings';

  @override
  String get familyGroupDiscover => 'Learn & discover';

  @override
  String get familyCatCalendar => 'Calendar';

  @override
  String get familyCatThemePark => 'Theme parks';

  @override
  String get familyCatLaserGame => 'Laser tag';

  @override
  String get familyCatEscapeGame => 'Escape rooms';

  @override
  String get familyCatBowling => 'Bowling';

  @override
  String get familyCatIceRink => 'Ice rinks';

  @override
  String get familyCatPlayground => 'Playgrounds';

  @override
  String get familyCatLeisurePark => 'Leisure parks';

  @override
  String get familyCatWildlifePark => 'Wildlife parks';

  @override
  String get familyCatFarm => 'Educational farms';

  @override
  String get familyCatAquarium => 'Aquariums';

  @override
  String get familyCatZoo => 'Zoos';

  @override
  String get familyCatBotanicGarden => 'Botanical gardens';

  @override
  String get familyCatWaterPark => 'Water parks';

  @override
  String get familyCatParks => 'Parks';

  @override
  String get familyCatWalks => 'Family walks';

  @override
  String get familyCatTreetop => 'Treetop adventure';

  @override
  String get familyCatMiniGolf => 'Mini golf';

  @override
  String get familyCatLeisureBase => 'Outdoor leisure centres';

  @override
  String get familyCatKidsMuseum => 'Children\'s museums';

  @override
  String get familyCatPlanetarium => 'Planetariums';

  @override
  String get familyCatWorkshop => 'Creative workshops';

  @override
  String get familyCatRestaurant => 'Family restaurants';

  @override
  String get evasionTitle => 'Getaways.';

  @override
  String get evasionSubtitle => 'Getaways and weekends near you.';

  @override
  String evasionWithinHours(int hours) {
    return '${hours}h away';
  }

  @override
  String get evasionNoPlaceForFilter => 'No places for this filter.';

  @override
  String get tourismeKickerHome => 'Section · Visit';

  @override
  String get tourismeTitle => 'Tourism';

  @override
  String get tourismeBlurb =>
      'Monuments, transport, must-sees: the city for visitors.';

  @override
  String get tourismeTopMustSee => 'Top must-sees';

  @override
  String get tourismeVisit => 'Visit';

  @override
  String get tourismeGetAround => 'Getting around';

  @override
  String get tourismeNoPlace => 'No places to visit';

  @override
  String get commonError => 'Error';

  @override
  String get tourismeCatMonument => 'Monuments';

  @override
  String get tourismeCatMuseum => 'Museums';

  @override
  String get tourismeCatAttraction => 'Attractions';

  @override
  String get tourismeCatNature => 'Natural sites';

  @override
  String get tourismeCatSquare => 'Squares';

  @override
  String get tourismeCatCultural => 'Cultural venues';

  @override
  String get tourismeCatTouristOffice => 'Tourist office';

  @override
  String get tourismeCatDistrict => 'Neighbourhoods';

  @override
  String get tourismeTipTodo => 'Things to do';

  @override
  String get tourismeTipFood => 'Food & drink';

  @override
  String get tourismeTipExcursion => 'Day trips';

  @override
  String get tourismeTipDeals => 'Good deals';

  @override
  String transportComingSoon(String city) {
    return 'Transport info for $city\ncoming soon';
  }

  @override
  String get transportMetro => 'Metro';

  @override
  String get transportTram => 'Tram';

  @override
  String get transportBike => 'Bike sharing';

  @override
  String get transportBikeShort => 'Bike';

  @override
  String transportStations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String transportStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get detailPartner => 'Partner';

  @override
  String get detailPartnerEstate => 'Partner estate';

  @override
  String get detailClaim => 'Claim';

  @override
  String get detailLiked => 'Liked';

  @override
  String get detailLike => 'Like';

  @override
  String detailOpeningHours(String hours) {
    return 'Opening hours: $hours';
  }

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsGive => 'Write a review';

  @override
  String get reviewsEdit => 'Edit my review';

  @override
  String get reviewsNone => 'No reviews yet. Be the first!';

  @override
  String get reviewsLoadError => 'Unable to load reviews';

  @override
  String get reviewsNotRated => 'Not rated yet';

  @override
  String get reviewsYou => 'You';

  @override
  String get reviewsPickRating => 'Pick a rating before posting';

  @override
  String get reviewsPostFailed => 'Failed: try again in a moment';

  @override
  String get reviewsDeleteFailed => 'Deletion failed';

  @override
  String get reviewsHint => 'Your thoughts, in a few words...';

  @override
  String get commonPublish => 'Post';

  @override
  String get eventMyNight => 'My night';

  @override
  String get eventInfo => 'Info';

  @override
  String eventBy(String name) {
    return 'By $name';
  }

  @override
  String eventSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count showtimes',
      one: 'Showtime',
    );
    return '$_temp0';
  }

  @override
  String get eventPreviousStory => 'Previous story';

  @override
  String get eventSwipeNext => 'Swipe for the next one';

  @override
  String get eventMore => 'more';

  @override
  String get eventAbout => 'About';

  @override
  String get eventNoDescription => 'No description provided for this event.';

  @override
  String get eventShareCaption => 'Check out this event on MaCity 👇';

  @override
  String get updateRequiredDefault =>
      'A new version is required to keep using the app.';

  @override
  String get updateTitlePrefix => 'Update ';

  @override
  String get updateTitleAccent => 'required';

  @override
  String updateVersionAvailable(String version) {
    return 'v$version available';
  }

  @override
  String get updateNow => 'Update';

  @override
  String get updateOpenAppStore => 'Open the App Store';

  @override
  String get updateLatestFeatures => 'To enjoy the latest features';

  @override
  String get updateAvailable => 'New version available';

  @override
  String get commonLater => 'Later';

  @override
  String gateTitle(String action) {
    return 'Create your account to $action';
  }

  @override
  String get gateBody =>
      'It takes 30 seconds. You also unlock your favorites and rewards.';

  @override
  String get gateActionPublishEvent => 'post an event';

  @override
  String get gateActionPostStory => 'post a story';

  @override
  String get gateActionChat => 'join the conversation';

  @override
  String get gateActionConfirm => 'confirm you are coming';

  @override
  String get gateActionAddPhotos => 'add photos';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get commonRetry => 'Try again';

  @override
  String get dateFilter7Days => '7 days';

  @override
  String get dateFilter30Days => '30 days';

  @override
  String get dateFilterDate => 'Date';

  @override
  String get liveTitle => 'Live';

  @override
  String get liveAroundYou => 'around you';

  @override
  String get liveStoryFallback => 'Map Live story';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get ofDayFood => 'Restaurant of the day';

  @override
  String get ofDayFamily => 'Activity of the day';

  @override
  String get ofDayCulture => 'Culture spotlight';

  @override
  String get ofDaySport => 'Sport moment';

  @override
  String get ofDayNight => 'Club of the day';

  @override
  String get ofDayEvasion => 'Getaway moment';

  @override
  String get cityPickerTitle => 'Choose a city';

  @override
  String get cityPickerHint => 'Search for a city...';

  @override
  String get cityPickerNone => 'No city found';

  @override
  String get cityPickerError => 'Search error';

  @override
  String get storyCatConcert => 'Concert';

  @override
  String get storyCatParty => 'Party';

  @override
  String get storyCatCelebration => 'Celebration';

  @override
  String get storyCatFestival => 'Festival';

  @override
  String get storyCatMarket => 'Market';

  @override
  String get storyCatExpo => 'Exhibition';

  @override
  String get storyCatFair => 'Fair';

  @override
  String get storyCatOther => 'Other';

  @override
  String get cameraHint => 'Tap = photo  ·  Hold = video';

  @override
  String get storyPreparing => 'Posted! Your poster is being prepared...';

  @override
  String get storyLocating => 'Locating...';

  @override
  String get storyPlace => 'Place';

  @override
  String get storyPlaceHint => 'Bar, street, square...';

  @override
  String get storyTestOnlyMe => 'Test story (only visible to me)';

  @override
  String get storyTest => 'Test story';

  @override
  String mapCityNotFound(String query) {
    return 'Unable to find \"$query\"';
  }

  @override
  String get storyCommunity => 'The community';

  @override
  String get storyChatShort => 'chat';

  @override
  String get storyVideo => 'video';

  @override
  String get storyAnonymous => 'Anonymous';

  @override
  String get storyPostedBy => 'Posted by ';

  @override
  String get storyDiscuss => 'Chat';

  @override
  String get storyAiGenerating => 'AI generating...';

  @override
  String get storyNobodyYet =>
      'Nobody has posted around here yet. Be the first!';

  @override
  String get memberNoBio => 'This member hasn\'t written a bio yet.';

  @override
  String get chatRejected => 'Message rejected: inappropriate language';

  @override
  String get chatReportInfo =>
      'If several people report this message, it will be hidden automatically.';

  @override
  String get chatTitle => 'Discussion';

  @override
  String get chatLoadError => 'Unable to load the discussion';

  @override
  String get chatBeFirst => 'Be the first to ask a question!';

  @override
  String get chatFinishSignup => 'Finish signing up to join the conversation.';

  @override
  String get chatHint => 'Ask a question...';

  @override
  String get chatReport => 'Report';

  @override
  String get optVenueIndoor => 'Indoor venue';

  @override
  String get optVenueOutdoor => 'Outdoor';

  @override
  String get optVenueStudio => 'Studio';

  @override
  String get optVenueOnline => 'Online';

  @override
  String get optKids => 'Kids';

  @override
  String get optTeens => 'Teens';

  @override
  String get optAdults => 'Adults';

  @override
  String get optSeniors => 'Seniors';

  @override
  String get optAllAudiences => 'All audiences';

  @override
  String get optBeginner => 'Beginner';

  @override
  String get optIntermediate => 'Intermediate';

  @override
  String get optAdvanced => 'Advanced';

  @override
  String get optAllLevels => 'All levels';

  @override
  String get optIndividual => 'Individual';

  @override
  String get optNonProfit => 'Non-profit';

  @override
  String get optCompany => 'Company';

  @override
  String get optOpenEntry => 'Open';

  @override
  String get optApproval => 'Approval required';

  @override
  String get optWaitingList => 'Waiting list';

  @override
  String get optDaily => 'Daily';

  @override
  String get optWeekly => 'Weekly';

  @override
  String get optMonthly => 'Monthly';

  @override
  String get errPickCategory => 'Pick a category';

  @override
  String get errTitleRequired => 'A title is required';

  @override
  String get errMediaRequired => 'A photo or video is required';

  @override
  String get errStartDateRequired => 'A start date is required';

  @override
  String get errStartTimeRequired => 'A start time is required';

  @override
  String get errAddressRequired => 'The venue address is required';

  @override
  String get errLinkFormat => 'The link must start with http:// or https://';

  @override
  String get errDateTimeBeforePublish =>
      'Fill in the date and time before posting.';

  @override
  String get errInvalidData => 'Invalid data (400). Check the fields.';

  @override
  String errAuthRequired(String code) {
    return 'Authentication required ($code).';
  }

  @override
  String get errConflict => 'Conflict (409). Does this event already exist?';

  @override
  String get errFileTooLarge => 'File too large.';

  @override
  String errServer(String code) {
    return 'Server error ($code). Try again in a moment.';
  }

  @override
  String errNetworkCode(String code) {
    return 'Network error ($code).';
  }

  @override
  String get errSlowConnection => 'Connection too slow. Check your network.';

  @override
  String get errNetwork => 'Network error. Check your connection.';

  @override
  String get errNoInternet => 'No internet connection.';

  @override
  String get errCheckFields => 'Check the fields';

  @override
  String get errPublishFailed => 'Posting failed';

  @override
  String get ceEditTitle => 'Edit event';

  @override
  String get ceCreateTitle => 'Create an event';

  @override
  String get commonPrevious => 'Back';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonNext => 'Next';

  @override
  String get commonClose => 'Close';

  @override
  String get ceUploadingVideo => 'Uploading the video...';

  @override
  String get ceUploading => 'Posting...';

  @override
  String get ceAlmostDone => 'Almost done';

  @override
  String get ceBoostPending =>
      'Event created! The boost will start once payment is confirmed.';

  @override
  String get ceEdited => 'Event updated\nsuccessfully!';

  @override
  String get ceAdded => 'Event added\nsuccessfully!';

  @override
  String get ceVisibleInRubrique => 'It will show up in the matching section.';

  @override
  String get ceCreated => 'Event created!';

  @override
  String get ceBoostActiveAfterPayment =>
      'The boost will start as soon as payment is confirmed.';

  @override
  String get ceQuitTitle => 'Leave?';

  @override
  String get ceQuitBody => 'What you entered will be lost.';

  @override
  String get ceQuit => 'Leave';

  @override
  String get ceCompressing => 'Compressing the video...';

  @override
  String get ceUploadInProgress => 'Uploading...';

  @override
  String get ceFinalizing => 'Finishing...';

  @override
  String get ceEssentials => 'The essentials';

  @override
  String get ceEssentialsSubtitle => 'The minimum to post your event.';

  @override
  String get ceScanFlyerSubtitle => 'Fills everything in automatically';

  @override
  String get ceCategory => 'Category *';

  @override
  String get ceEventTitle => 'Event title *';

  @override
  String get ceDescriptionOptional => 'Description (optional)';

  @override
  String get ceTicketLinkOptional => 'Ticket link or website (optional)';

  @override
  String get ceTeaserVideo => 'Teaser video (recommended, 30s max)';

  @override
  String get cePhoto => 'Photo *';

  @override
  String get ceDate => 'Date *';

  @override
  String get ceTime => 'Time *';

  @override
  String get ceAddress => 'Address *';

  @override
  String get ceFreeEvent => 'Free event';

  @override
  String get cePrice => 'Price (€)';

  @override
  String get ceTapToAddPhoto => 'Tap to add a photo';

  @override
  String get commonCamera => 'Camera';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonVideo => 'Video';

  @override
  String get ceAddVideo => 'Add\n(30 sec max)';

  @override
  String get commonDate => 'Date';

  @override
  String get commonTime => 'Time';

  @override
  String get ceMoreInfo => 'More info';

  @override
  String get ceOptional => 'Optional';

  @override
  String get ceDetailsHint => 'Fine-tune your event or tap \"Post\" now.';

  @override
  String get ceDescription => 'Description';

  @override
  String get ceShortDescription => 'Short description (1-2 lines)';

  @override
  String get ceLongDescription => 'Long description';

  @override
  String get ceDatesRecurrence => 'Dates & recurrence';

  @override
  String get ceEndDate => 'End date';

  @override
  String get ceEndTime => 'End time';

  @override
  String get ceVenueDetails => 'Venue details';

  @override
  String get ceVenueName => 'Venue name (e.g. village hall)';

  @override
  String get cePricingTickets => 'Pricing & tickets';

  @override
  String get ceReducedPrice => 'Reduced price';

  @override
  String get ceGroupPrice => 'Group price';

  @override
  String get ceEarlyBird => 'Early bird';

  @override
  String get ceOrganizer => 'Organizer';

  @override
  String get ceName => 'Name';

  @override
  String get ceAudience => 'Audience & participants';

  @override
  String get ceTargetAudience => 'Target audience';

  @override
  String get ceLevel => 'Level';

  @override
  String get ceRegistration => 'Registration';

  @override
  String get ceTags => 'Tags';

  @override
  String get ceAddTag => 'Add a tag';

  @override
  String get ceBoostTitle => 'Boost your event';

  @override
  String get ceBoostOptional => 'OPTIONAL';

  @override
  String get ceBoostSubtitle => 'Increase your event\'s visibility';

  @override
  String get cePriceLoadError => 'Error loading prices';

  @override
  String get ceTapDays => 'Tap the days you want';

  @override
  String get publishChooseType => 'Choose how to post';

  @override
  String get publishPrivateSubtitle => 'Secret vault by invitation, free';

  @override
  String get publishAsPro => 'Post as a pro';

  @override
  String get publishProUnlimited => 'Unlimited posting (approved pro account)';

  @override
  String get publishProSpace => 'Business area (sign up / log in)';

  @override
  String get tierPremium => '💎 Premium plan';

  @override
  String get tierPremiumEffect => 'All your events are featured in the feed.';

  @override
  String get tierGold => '🥇 Gold plan';

  @override
  String get tierGoldEffect =>
      'All your events are boosted to the top of the feed.';

  @override
  String get tierNormal => 'Standard plan';

  @override
  String get tierNormalEffect => 'Your events appear in the standard feed.';

  @override
  String get commonBack => 'Back';

  @override
  String get pubMyEvents => 'My events';

  @override
  String get pubMyStories => 'My stories';

  @override
  String get pubStoriesKept =>
      'Kept for a limited time. You can delete them at any time.';

  @override
  String get pubNone => 'No posts yet';

  @override
  String get pubNoneHint => 'Events you create will show up here';

  @override
  String pubStoriesPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stories waiting for network',
      one: '1 story waiting for network',
    );
    return '$_temp0';
  }

  @override
  String get commonSend => 'Send';

  @override
  String pubDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get pubDeleted => 'Post deleted';

  @override
  String get pubDeleteFailed => 'Unable to delete, try again';

  @override
  String get pubThisStory => 'this story';

  @override
  String get pubDeleteStory => 'Delete story';

  @override
  String pubDeleteStoryConfirm(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String get pubStoryDeleted => 'Story deleted';

  @override
  String get pubStatusGenerating => 'Processing';

  @override
  String get pubStatusExpired => 'Expired';

  @override
  String get pubStatusOnline => 'Live';

  @override
  String dateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get commonFailedRetry => 'Failed, try again';

  @override
  String get commonDeleteFailed => 'Deletion failed';

  @override
  String get commonActivate => 'Turn on';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get commonWithoutAccount => 'No account';

  @override
  String get commonPast => 'Past';

  @override
  String get pvConfirmOn => 'Confirmation on: your guests can now confirm';

  @override
  String get pvConfirmOff => 'Confirmation off';

  @override
  String get pvDeleteVault => 'Delete this vault?';

  @override
  String pvDeleteVaultBody(String title) {
    return 'Guests will no longer be able to access \"$title\".';
  }

  @override
  String get pvNewEvent => 'New event';

  @override
  String get pvNone => 'No private events';

  @override
  String get pvNoneHint =>
      'Create a secret vault and invite your friends with a link + code.';

  @override
  String get pvChat => 'Chat';

  @override
  String get pvThisPerson => 'this person';

  @override
  String pvRemoveGuest(String name) {
    return 'Remove $name?';
  }

  @override
  String get pvRemoveGuestBody =>
      'They will be removed from the guest list (and confirmed list), won\'t be able to sign up again and will lose access to the event chat.';

  @override
  String get pvRemoveFailed => 'Removal failed, try again';

  @override
  String get pvEnableConfirmTitle => 'Turn on confirmation?';

  @override
  String get pvEnableConfirmBody =>
      'The PDF lists guests who confirmed they are coming, with their first and last name. Turn on confirmation so your guests can fill in the form from \"My invitations\".';

  @override
  String get pvConfirmOnPdf =>
      'Confirmation on: the PDF will be ready after the first confirmation';

  @override
  String get pvNoConfirmYet =>
      'Nobody has confirmed yet: the PDF lists confirmed guests with their full name';

  @override
  String get pvNoOpeners =>
      'Nobody opened the vault without signing up.\nOpens are visible with the latest version of the app.';

  @override
  String get pvNoConfirmations =>
      'No confirmations yet.\nGuests confirm from \"My invitations\".';

  @override
  String pvSignedUpMax(int count, int max) {
    return 'Signed up $count / $max';
  }

  @override
  String pvSignedUp(int count) {
    return 'Signed up ($count)';
  }

  @override
  String get pvTabGuests => 'Guests';

  @override
  String get pvTabSeen => '👀 Seen';

  @override
  String get pvTabConfirmed => '✅ Confirmed';

  @override
  String get pvNobodyYet => 'Nobody yet';

  @override
  String pvOpens(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opens',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String pvLastOn(String when) {
    return 'last on $when';
  }

  @override
  String pvConfirmedOn(String when) {
    return 'confirmed on $when';
  }

  @override
  String get pvFull => 'full';

  @override
  String pvSignedUpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signed up',
      one: '1 signed up',
    );
    return '$_temp0';
  }

  @override
  String get pvGuestConfirmation => 'Guest confirmation';

  @override
  String get pvGuestConfirmationOn => 'On: name, age and phone requested';

  @override
  String get pvOff => 'Off';

  @override
  String get pvPhotoUploadFailed => 'Photo upload failed';

  @override
  String get pvErrTitle => 'Give your event a title';

  @override
  String get pvErrDate => 'Pick a date';

  @override
  String get pvErrCode => 'The code must be 4 digits';

  @override
  String get pvErrSeats => 'Number of spots: between 1 and 1000 (or empty)';

  @override
  String get pvErrInvalidField => 'Invalid field';

  @override
  String get pvErrEditFailed => 'Update failed, try again';

  @override
  String get pvErrCreateFailed => 'Creation failed, try again';

  @override
  String get pvEditTitle => 'Edit private event';

  @override
  String get pvCreateTitle => 'Create a private event';

  @override
  String get pvEditSubtitle => 'The link and code already sent stay valid';

  @override
  String get pvCreateSubtitle => 'Secret vault shared with a link + code';

  @override
  String get pvAddPoster => 'Add a poster (optional)';

  @override
  String get pvTitle => 'Title';

  @override
  String get pvTitleHint => '...\'s birthday';

  @override
  String get pvPlaceHint => 'My place, club...';

  @override
  String get pvAddress => 'Address';

  @override
  String get pvAddressHint => '5 X Street, London';

  @override
  String get pvDescriptionHint => 'BYOB, dress code...';

  @override
  String get pvSecretCode => 'Secret code to share (4 digits)';

  @override
  String get pvSeats => 'Number of spots';

  @override
  String pvSeatsAlready(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already signed up. Empty = unlimited.',
      one: '1 already signed up. Empty = unlimited.',
    );
    return '$_temp0';
  }

  @override
  String get pvSeatsHint => 'Empty = unlimited. \"Full\" once reached.';

  @override
  String get pvEnableConfirmation => 'Turn on confirmation';

  @override
  String get pvEnableConfirmationHint =>
      'Each guest confirms with first name, last name, email, age and phone. Only you can see this info.';

  @override
  String get pvCreateMine => 'Create my event';

  @override
  String get pvPickDate => 'Pick a date';

  @override
  String get pvShareOnList => '🤫 You\'re on the list.';

  @override
  String get pvShareTeaser =>
      'A private event is waiting for you… Open the vault to find out where, when and all the details 👀';

  @override
  String pvShareCode(String code) {
    return '🔑 Code: $code';
  }

  @override
  String get pvSharePreparing => 'Preparing to share…';

  @override
  String get pvShareFailed => 'Unable to share, try again';

  @override
  String get pvVaultCreated => 'Vault created!';

  @override
  String get pvShareSeparately =>
      'Share the link and code separately, by message or WhatsApp.';

  @override
  String get vaultErrLink => 'Invalid link (UUID format expected)';

  @override
  String get vaultErrNotFound => 'No vault found with this link';

  @override
  String get vaultErrWrongCode => 'Wrong code';

  @override
  String get vaultErrPast => 'This event is over';

  @override
  String get vaultErrOpenLimit => 'This vault has reached its open limit';

  @override
  String get vaultErrInvalidData => 'Invalid data';

  @override
  String get vaultErrProfile => 'Complete your MaCity profile to continue';

  @override
  String get vaultErrDenied => 'Access denied';

  @override
  String get vaultErrFull => 'It\'s full, no spots left';

  @override
  String get vaultErrEnded => 'Event over: view only';

  @override
  String get vaultErrComeFirst => 'First say you\'re coming to the event';

  @override
  String get vaultErrNetwork => 'Network error, try again';

  @override
  String get vaultOpened => 'Vault opened';

  @override
  String get vaultTypeLinkCode => 'Enter the link and code you received';

  @override
  String get vaultHostShared =>
      'The host shared a token + a 4-digit code with you.';

  @override
  String get vaultLinkToken => 'Link (token)';

  @override
  String get vaultPaste => 'Paste';

  @override
  String get vaultCode => 'Code';

  @override
  String get vaultOpening => 'Opening...';

  @override
  String get vaultOpen => 'Open the vault';

  @override
  String get vaultAttendanceConfirmed =>
      'Confirmed, the host has been notified';

  @override
  String get vaultFullShort => 'Full';

  @override
  String vaultSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots left',
      one: '1 spot left',
    );
    return '$_temp0';
  }

  @override
  String get vaultOpenedBadge => 'VAULT OPENED';

  @override
  String vaultPeopleComing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people are coming',
      one: '1 person is coming',
    );
    return '$_temp0';
  }

  @override
  String get vaultCancelMine => 'I\'m not coming anymore';

  @override
  String get vaultImComing => 'I\'m in';

  @override
  String get vaultConfirmedEdit => 'Confirmed · edit';

  @override
  String get vaultConfirmMine => 'Confirm I am coming';

  @override
  String get vaultHostAsksConfirm =>
      'The host asks you to confirm (name, age, phone…).';

  @override
  String get invNone => 'No invitations';

  @override
  String get invNoneHint =>
      'When you tap \"I\'m in\" on a vault, the event will show up here.';

  @override
  String get invImComingBadge => 'I\'M IN';

  @override
  String get invCancelTitle => 'Not coming anymore?';

  @override
  String get invCancelBody =>
      'You can always come back by tapping \"I\'m in\" from the vault.';

  @override
  String get invKeep => 'Keep';

  @override
  String get invCancelFailed => 'Cancellation failed';

  @override
  String get invAlbum => 'Album';

  @override
  String get invWriteHost => 'Message the host';

  @override
  String get invCancelled => 'Cancelled';

  @override
  String get invNobodyElse => 'Nobody else has confirmed yet.';

  @override
  String invPresentMax(int count, int max) {
    return 'Attending ($count / $max)';
  }

  @override
  String invPresent(int count) {
    return 'Attending ($count)';
  }

  @override
  String get invConfirmed => 'Confirmed';

  @override
  String get invConfirm => 'Confirm';

  @override
  String invMe(String name) {
    return '$name (me)';
  }

  @override
  String get cfErrName => 'First and last name required';

  @override
  String get cfErrEmail => 'Invalid email address';

  @override
  String get cfErrAge => 'Invalid age';

  @override
  String get cfErrPhone => 'Invalid phone number';

  @override
  String get cfSendFailed => 'Sending failed, try again';

  @override
  String get cfEditMine => 'Edit my confirmation';

  @override
  String cfPrivacy(String title) {
    return 'For \"$title\". This info is only sent to the host and deleted after the event.';
  }

  @override
  String get cfFirstName => 'First name';

  @override
  String get cfLastName => 'Last name';

  @override
  String get cfEmail => 'Email';

  @override
  String get cfAge => 'Age';

  @override
  String get pcErrGuestLeft =>
      'This person is no longer signed up: private messaging is no longer possible.';

  @override
  String get pcErrYouAreHost =>
      'You are the host of this event: message your guests from \"My private events\", 💬 button next to each one.';

  @override
  String get pcErrNotGoing =>
      'You are no longer signed up: tap \"I\'m in\" to message the host.';

  @override
  String get pcErrGone =>
      'This event no longer exists (deleted or over for more than 7 days).';

  @override
  String get pcErrNoAccess => 'This chat is no longer accessible.';

  @override
  String get pcErrLoad =>
      'Unable to load the chat. Check your connection and try again.';

  @override
  String get pcPhotoSendFailed => 'Photo sending failed';

  @override
  String get pcDeleteMessage => 'Delete this message?';

  @override
  String get pcCannotDelete => 'You can\'t delete this message';

  @override
  String get pcAlbumTooltip => 'Photo album';

  @override
  String get pcGuest => 'Guest';

  @override
  String get pcHost => 'Host';

  @override
  String pcPrivateMessage(String title) {
    return 'Private message · $title';
  }

  @override
  String get pcPrivateChat => 'Private chat';

  @override
  String get pcEmptyDmToGuest =>
      'Message this guest privately: only they will see your messages.';

  @override
  String get pcEmptyDmToHost =>
      'Message the host privately: only they will see your messages.';

  @override
  String get pcEmptyGroup =>
      'Ask the host a question or say hi to the other guests!';

  @override
  String get pcPhoto => 'Photo';

  @override
  String get pcCaptionHint => 'Add a caption...';

  @override
  String get pcMessageHint => 'Write a message...';

  @override
  String get pcMe => 'Me';

  @override
  String get alRemovePhoto => 'Remove this photo?';

  @override
  String get alRemoveAll =>
      'It will be removed from the album and the chat for everyone.';

  @override
  String get alRemoveMine => 'It will be removed from the album and the chat.';

  @override
  String get alCannotRemove => 'You can\'t remove this photo';

  @override
  String get alRemoved => 'Photo removed from the album';

  @override
  String get alLoadError => 'Unable to load the album. Check your connection.';

  @override
  String get alNoAccess => 'This album is not accessible.';

  @override
  String get alPickMany => 'Choose from gallery (several)';

  @override
  String get alProfileRequired => 'Complete your profile to add photos';

  @override
  String get alAddRefused => 'Upload refused';

  @override
  String alAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos added to the album',
      one: '1 photo added to the album',
    );
    return '$_temp0';
  }

  @override
  String alAddedPartial(int ok, int total) {
    return '$ok / $total photos added, try again for the others';
  }

  @override
  String alFirstProposed(int max) {
    return 'The first $max photos were offered. Save the others one by one from the slideshow.';
  }

  @override
  String get alSaveFailed => 'Unable to save the photos';

  @override
  String get alTitle => '📸 Album';

  @override
  String get alSaveAll => 'Save all';

  @override
  String alSending(int done, int total) {
    return 'Sending $done / $total';
  }

  @override
  String get alAdd => 'Add';

  @override
  String get alNoPhoto => 'No photos yet';

  @override
  String get alNoPhotoArchived => 'Nobody shared any photos during this event.';

  @override
  String get alNoPhotoHint =>
      'Add your photos here, or share them in the chat: they show up in the album automatically.';

  @override
  String get alAddPhotos => 'Add photos';

  @override
  String get alOpenChat => 'Open the chat';

  @override
  String alPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get alFrozen => 'album locked';

  @override
  String get alLongPressHint => 'long-press a photo to remove it';

  @override
  String get memNone => 'No memories yet';

  @override
  String get memNoneHint =>
      'Your past private events (hosted or attended) will show up here with their photos.';

  @override
  String get memGuestRole => 'Guest';

  @override
  String memParticipants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String memAddUntil(String date) {
    return 'photos can be added until $date';
  }

  @override
  String get memSlideshow => 'Slideshow';

  @override
  String get ssSaveFailed => 'Unable to save this photo';

  @override
  String get ssPause => 'Pause';

  @override
  String get ssPlay => 'Play';

  @override
  String get ssRemove => 'Remove from album';

  @override
  String get ssSaveShare => 'Save / share';

  @override
  String get abAlbum => 'Photo album';

  @override
  String get abSeeAlbum => 'See the album';

  @override
  String get abFirstPhotos => 'Add the first photos of the event';

  @override
  String abSlideshowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos · slideshow',
      one: '1 photo · slideshow',
    );
    return '$_temp0';
  }

  @override
  String get hostOrganizedBy => 'HOSTED BY';

  @override
  String get pdfGuestList => 'Guest list';

  @override
  String pdfSummaryMax(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed / $max spots',
      one: '1 confirmed / $max spots',
    );
    return '$_temp0';
  }

  @override
  String pdfSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed',
      one: '1 confirmed',
    );
    return '$_temp0';
  }

  @override
  String pdfGenerated(String date) {
    return 'Generated on $date with MaCity';
  }

  @override
  String get pdfConfidential =>
      'Confidential document: personal data, not to be shared beyond the event organisation.';

  @override
  String pdfConfirmedSection(int count) {
    return 'Confirmed ($count)  ·  in order of confirmation';
  }

  @override
  String get pdfNoConfirm => 'No confirmations yet.';

  @override
  String get pdfColNumber => 'No.';

  @override
  String get pdfColConfirmedOn => 'Confirmed on';

  @override
  String pdfShareText(String title) {
    return 'Guest list: $title';
  }

  @override
  String get pdfExportFailed => 'PDF export failed, try again';

  @override
  String get interestConcert => 'Concerts';

  @override
  String get interestFestival => 'Festivals';

  @override
  String get interestSpectacle => 'Live shows';

  @override
  String get interestStandup => 'Stand-up / Comedy';

  @override
  String get interestOpera => 'Opera / Classical';

  @override
  String get interestDj => 'DJ set / Electro';

  @override
  String get interestConference => 'Conferences / Talks';

  @override
  String get interestAtelier => 'Workshops';

  @override
  String get interestFootball => 'Football';

  @override
  String get interestRugby => 'Rugby';

  @override
  String get interestBasketball => 'Basketball';

  @override
  String get interestTennis => 'Tennis';

  @override
  String get interestHandball => 'Handball';

  @override
  String get interestCourse => 'Running';

  @override
  String get interestFitness => 'Fitness / Weights';

  @override
  String get interestYoga => 'Yoga / Pilates';

  @override
  String get interestNatation => 'Swimming';

  @override
  String get interestCyclisme => 'Cycling';

  @override
  String get interestArtsMartiaux => 'Martial arts / Combat sports';

  @override
  String get interestExpo => 'Exhibitions';

  @override
  String get interestTheatre => 'Theatre';

  @override
  String get interestMusee => 'Museums';

  @override
  String get interestCinema => 'Cinema';

  @override
  String get interestDanse => 'Dance';

  @override
  String get interestVisite => 'Guided tours';

  @override
  String get interestLecture => 'Reading / Literature';

  @override
  String get interestPhoto => 'Photography';

  @override
  String get interestSpectacleEnfant => 'Kids\' shows';

  @override
  String get interestParc => 'Parks / Gardens';

  @override
  String get interestCinemaFamille => 'Cinema';

  @override
  String get interestBowling => 'Bowling / Laser tag';

  @override
  String get interestAtelierEnfant => 'Creative workshops';

  @override
  String get interestFeteForaine => 'Funfairs';

  @override
  String get interestZoo => 'Zoo / Aquarium';

  @override
  String get interestRestaurant => 'Restaurants';

  @override
  String get interestBrunch => 'Brunches';

  @override
  String get interestCafe => 'Cafés / Tea rooms';

  @override
  String get interestMarche => 'Markets / Food markets';

  @override
  String get interestDegustation => 'Tastings / Wine';

  @override
  String get interestFoodTruck => 'Food trucks';

  @override
  String get interestCoursCuisine => 'Cooking classes';

  @override
  String get interestBienetre => 'Wellness / Spa';

  @override
  String get interestEsport => 'E-sports / Tournaments';

  @override
  String get interestConvention => 'Conventions / Fairs';

  @override
  String get interestBarJeux => 'Board game bars';

  @override
  String get interestLan => 'LAN party';

  @override
  String get interestManga => 'Manga / Anime';

  @override
  String get interestVr => 'Virtual reality';

  @override
  String get interestEscapeGame => 'Escape rooms';

  @override
  String get interestBar => 'Bars / Pubs';

  @override
  String get interestClub => 'Clubs / Nightclubs';

  @override
  String get interestSoiree => 'Themed parties';

  @override
  String get interestConcertLive => 'Live gigs / Showcases';

  @override
  String get interestKaraoke => 'Karaoke';

  @override
  String get interestAfterwork => 'Afterwork';

  @override
  String get interestVisiteGuidee => 'Guided tours';

  @override
  String get interestBalade => 'Walks / Hikes';

  @override
  String get interestPatrimoine => 'Heritage / Monuments';

  @override
  String get interestNature => 'Nature / Outdoors';

  @override
  String get interestCroisiere => 'River cruises';

  @override
  String get interestOenotourisme => 'Wine tourism';

  @override
  String get prefsUpdated => 'Preferences updated';

  @override
  String get commonErrorRetry => 'Error, please try again';

  @override
  String get prefsProfileSubtitle => 'Change your name/nickname and photo';

  @override
  String get prefsMyTownHalls => 'My town halls';

  @override
  String get prefsMyTownHallsSubtitle =>
      'Get notifications from several town halls';

  @override
  String get prefsMyHub => 'My Hub';

  @override
  String get prefsMyHubSubtitle => 'Choose your main city for events';

  @override
  String get prefsInterests => 'Interests';

  @override
  String get prefsInterestsSubtitle =>
      'Pick your activities to get relevant notifications. Tap a category to fine-tune your choices.';

  @override
  String get prefsNameHint => 'E.g. Alex';

  @override
  String get prefsBio => 'Bio';

  @override
  String get prefsBioHint => 'A few words about you (shown on your stories)';

  @override
  String get prefsAddCity => 'Add a city...';

  @override
  String get mairieLoading => 'Loading news...';

  @override
  String get mairieOffline => 'Oops, no connection';

  @override
  String get mairieLoadError => 'Unable to load notifications';

  @override
  String get mairieMyCities => 'My Cities';

  @override
  String get mairieNoCity => 'No city';

  @override
  String mairieNewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'news items',
      one: 'news item',
    );
    return '$_temp0';
  }

  @override
  String get mairieAll => 'All';

  @override
  String get mairieNoNewsForCity => 'No news from this town hall';

  @override
  String get mairieNothingNew => 'Nothing new!';

  @override
  String mairieCityNoNews(String city) {
    return '$city hasn\'t posted any news yet';
  }

  @override
  String get mairieNoNews => 'No news for now';

  @override
  String get mairieWillNotify => 'You\'ll be notified of anything new';

  @override
  String get mairieNew => 'NEW';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get mairieUpdated => 'Town halls updated';

  @override
  String get mairieManage => 'Manage my town halls';

  @override
  String get mairieManageSubtitle => 'Add or remove the cities you follow';

  @override
  String get mairieNoneFollowed => 'No town halls followed yet';

  @override
  String get offerAt => 'At';

  @override
  String get offerValid => 'Valid';

  @override
  String get offerNoExpiry => 'No expiry date';

  @override
  String offerUntil(String date) {
    return 'until $date';
  }

  @override
  String get offerAvailability => 'Availability';

  @override
  String get offerUnlimited => 'Unlimited';

  @override
  String get offerUnlimitedShort => '∞ Unlimited';

  @override
  String get offerValidateFailed => 'Unable to validate the offer';

  @override
  String get offerGeneratingCode => 'Generating the code...';

  @override
  String get offerAlreadyUsed => 'ALREADY USED';

  @override
  String get offerShowMerchant => 'SHOW TO THE MERCHANT';

  @override
  String get offerCodeCopied => 'Code copied!';

  @override
  String get offerTapToCopy => 'Tap to copy';

  @override
  String get offerShowCodeHint =>
      'Show this code to the merchant to get the offer';

  @override
  String get premiumRestos => 'Restaurants';

  @override
  String get premiumBars => 'Bars';

  @override
  String get premiumWellness => 'Wellness';

  @override
  String get premiumTitle => 'Premium offers';

  @override
  String get premiumPitch =>
      '3 more exclusive offers every month, in your favourite categories.';

  @override
  String get premiumUnlock => 'Unlock · €5.90/month';

  @override
  String get proTypeAssociation => 'Non-profit';

  @override
  String get proTypePrivate => 'Private business';

  @override
  String get proTypeLegalEntity => 'Approved legal entity';

  @override
  String get pwdRequired => 'Password is required';

  @override
  String get pwdMin10 => 'At least 10 characters';

  @override
  String get pwdUppercase => 'At least 1 uppercase letter';

  @override
  String get pwdDigit => 'At least 1 digit';

  @override
  String get pwdHint10 => '10+ characters';

  @override
  String get pwdHintUpper => '1 uppercase';

  @override
  String get pwdHintDigit => '1 digit';

  @override
  String get proSpaceTitle => 'Business area';

  @override
  String get proLoginSubtitle => 'Log in to your account';

  @override
  String get proSignupSubtitle => 'Sign up to post events';

  @override
  String get proEmailRequired => 'Email is required';

  @override
  String get proPassword => 'Password';

  @override
  String get proSendingInProgress => 'Sending...';

  @override
  String get proForgotPassword => 'Forgot your password?';

  @override
  String get proStructureName => 'Organisation name';

  @override
  String get proNameRequired => 'Name is required';

  @override
  String get proStructureType => 'Organisation type';

  @override
  String get proPhoneRequired => 'Phone is required';

  @override
  String get proSubmitSignup => 'Complete sign-up';

  @override
  String get proEnterEmailFirst => 'Enter your email first';

  @override
  String get proResetSent => 'Reset email sent!';

  @override
  String get proResetFailed => 'Sending failed. Check your email.';

  @override
  String get proLoginSuccess => 'Logged in!';

  @override
  String get proEnter6Digits => 'Enter the 6-digit code';

  @override
  String get proNewCodeSent => 'New code sent by email';

  @override
  String get proResendFailed => 'Error resending the code';

  @override
  String get proApproved => 'Account approved! Welcome to MaCity';

  @override
  String get proEmailVerification => 'Email verification';

  @override
  String get proCodeSentTo => 'A 6-digit code was sent to\n';

  @override
  String get proLogout => 'Log out';

  @override
  String get proEmailVerified => 'Email verified!';

  @override
  String get proPendingTitle => 'Account pending approval';

  @override
  String get proPendingBody =>
      'Our team will call you very soon on the number you provided to finalise your account approval.\n\nOnce approved, you\'ll be able to post offers and use all pro features.';

  @override
  String get proWaitCall => 'OK, I\'ll wait for the call';

  @override
  String get pveNoListing =>
      'No listing linked to your pro account.\nClaim your business from its listing to edit it.';

  @override
  String pveLoadError(String error) {
    return 'Loading error: $error';
  }

  @override
  String pveUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String pveDeleteFailed(String error) {
    return 'Deletion failed: $error';
  }

  @override
  String get pveFilmNow => 'Record now';

  @override
  String get pvePickVideo => 'Choose a video from the gallery';

  @override
  String get pveCoverUpdated => 'Cover updated';

  @override
  String pveCoverUploadFailed(String error) {
    return 'Cover upload failed: $error';
  }

  @override
  String get pveCompressing => 'Compressing...';

  @override
  String pveCompressed(String size) {
    return 'Compressed: $size MB';
  }

  @override
  String pveUploadPct(int pct) {
    return 'Uploading $pct%';
  }

  @override
  String get pveVideoUploaded => 'Video uploaded successfully';

  @override
  String get pveDeleteVideo => 'Delete the video?';

  @override
  String get pveUnknownError => 'Unknown error';

  @override
  String get pveAutoSaved => 'Your changes are saved automatically.';

  @override
  String get pveCoverSection => 'Cover (shown in lists)';

  @override
  String get pveCoverHint => 'Main image shown on your business card in lists.';

  @override
  String get pvePhotosSection => 'Listing detail photos';

  @override
  String get pvePhotosHint => 'Up to 6 photos. Shown in order on the listing.';

  @override
  String get pveVideoSection => 'Teaser video';

  @override
  String get pveVideoHint =>
      'Record with your phone or pick from the gallery. Max 30 s, 50 MB after automatic compression.';

  @override
  String get pveDone => 'Done';

  @override
  String get pveCover => 'Cover';

  @override
  String get pvePhotoGridHint => 'Long-press to delete · Tap to replace';

  @override
  String get pveAddVideo => 'Add a video';

  @override
  String get pvePreparing => 'Preparing...';

  @override
  String get pveDeletePhoto => 'Delete this photo?';

  @override
  String get aoEditTitle => 'Edit offer';

  @override
  String get aoBusinessName => 'Business name';

  @override
  String get aoBusinessNameRequired => 'Business name is required';

  @override
  String get aoTitle => 'Offer title (e.g. free massage)';

  @override
  String get aoDescription => 'Description (e.g. 30 min free with any booking)';

  @override
  String get aoEmoji => 'Emoji (just 1)';

  @override
  String get aoAddPhoto => 'Add a photo';

  @override
  String get aoSpotsRequired => 'Number of spots is required';

  @override
  String get aoValidNumber => 'Enter a valid number';

  @override
  String get aoUnlimitedSpots => 'Unlimited spots';

  @override
  String get aoExpiryDate => 'Expiry date';

  @override
  String get aoExpiryRequired => 'Expiry date is required';

  @override
  String get aoNoExpiry => 'No expiry date';

  @override
  String get aoEditing => 'Saving...';

  @override
  String get aoFixFields => 'Check the fields in red before posting';

  @override
  String get aoEdited => 'Offer updated!';

  @override
  String get aoPublished => 'Offer posted!';

  @override
  String commonErrorWith(String error) {
    return 'Error: $error';
  }

  @override
  String get aoProRequired => 'Pro login required';

  @override
  String get aoPendingBody =>
      'Your pro account has been created. Our team will call you very soon on the number you provided to approve it. You\'ll be able to post offers as soon as it\'s approved.';

  @override
  String get aoProRequiredBody =>
      'You need to be logged in with an approved pro account to post an offer.';

  @override
  String get commonOk => 'OK';

  @override
  String get moDeleteOffer => 'Delete this offer?';

  @override
  String get moDeleted => 'Offer deleted';

  @override
  String get moNoExpiry => 'No expiry';

  @override
  String get moExpired => 'Expired';

  @override
  String get moFull => 'Full';

  @override
  String get moLive => 'Live';

  @override
  String get moInactive => 'Inactive';

  @override
  String get moNone => 'No offers yet';

  @override
  String get moNoneHint =>
      'Create your first promotional offer to attract more customers.';

  @override
  String get subAllPremium => 'All premium offers unlocked';

  @override
  String get subAllPremiumSub =>
      'Free coffee, discounts, concert tickets, experiences...';

  @override
  String get subWeekly => 'New offers every week';

  @override
  String get subWeeklySub => 'Picked from the best local businesses.';

  @override
  String get subCancel => 'Cancel anytime';

  @override
  String get subCancelSub => 'No commitment. Stop whenever you want.';

  @override
  String get subHeadline => 'Enjoy the best\ndeals in your city.';

  @override
  String get subPitch =>
      'One subscription, hundreds of premium offers\npicked from partner businesses.';

  @override
  String get subPerMonth => 'per month';

  @override
  String get subAutoRenew =>
      'Renews automatically. Cancel anytime from settings.';

  @override
  String get subPaymentSoon => 'Payment coming soon';

  @override
  String get subSubscribe => 'Subscribe for €5.90/month';

  @override
  String get foodChipRestaurants => 'Restaurants';

  @override
  String get foodChipGuinguette => 'Riverside café';

  @override
  String get foodChipBuffets => 'Buffets';

  @override
  String get foodChipTeaRoom => 'Tea room';

  @override
  String get foodChipBrunch => 'Brunch';

  @override
  String get foodChipTapas => 'Tapas';

  @override
  String get foodChipPintxos => 'Pintxos';

  @override
  String get foodChipFish => 'Fish';

  @override
  String get foodChipMeat => 'Meat';

  @override
  String get foodLocateToSort => 'Turn on location to sort by distance.';

  @override
  String get foodNearestToMe => 'Nearest to me';

  @override
  String get foodPartners => 'Our partner restaurants';

  @override
  String get foodBannerTitle => 'Book, discover, enjoy.';

  @override
  String get foodBannerSubtitle => 'The best tables await you.';

  @override
  String get foodTitle => 'Food.';

  @override
  String get foodSubtitle => 'Restaurants and flavours to share.';

  @override
  String get foodAroundMe => 'Around me';

  @override
  String get foodFavourite => 'EDITOR\'S PICK';

  @override
  String get foodKickerHome => 'Section · Treats';

  @override
  String get foodBlurb =>
      'Restaurants, brunches, markets: the city\'s food map.';

  @override
  String get foodNoRestaurant => 'No restaurants';

  @override
  String get mapNearestRestaurant => 'Nearest restaurant';

  @override
  String get resErrDate => 'Pick a date';

  @override
  String get resErrTime => 'Pick a time';

  @override
  String get resErrSignup => 'Finish signing up (first name required)';

  @override
  String get resSent => 'Request sent. You\'ll be notified when they reply.';

  @override
  String get resBook => 'Book';

  @override
  String get resPeople => 'Number of people';

  @override
  String get resPhoneOptional => 'Phone (optional)';

  @override
  String get resComment => 'Comment (allergies, occasion...)';

  @override
  String get resSendRequest => 'Send request';
}
