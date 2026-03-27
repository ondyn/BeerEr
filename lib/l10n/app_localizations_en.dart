// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override String get appTitle => 'Beerer';
  @override String get tapKeg => 'Tap Keg';
  @override String get untapKeg => 'Untap Keg';
  @override String get kegDone => 'Keg Done';
  @override String get iGotBeer => 'I Got Beer';
  @override String get pourForSomeone => 'Pour for Someone';
  @override String get undo => 'Undo';
  @override String get statistics => 'Statistics';
  @override String get estimatedBac => 'Est. BAC';
  @override String get drinkResponsibly => 'Please drink responsibly.';
  @override String volumeRemaining(String volume) => '$volume ml remaining';

  @override String get kegInformation => 'Keg Information';
  @override String get beerInformation => 'Beer Information';
  @override String get kegInfo => 'Keg Information';
  @override String get beerName => 'Name';
  @override String get alcoholPercent => 'Alcohol %';
  @override String get brewery => 'Brewery';
  @override String get malt => 'Malt';
  @override String get fermentation => 'Fermentation';
  @override String get beerType => 'Type';
  @override String get beerGroup => 'Group';
  @override String get beerStyle => 'Style';
  @override String get degreePlato => 'Degree Plato';
  @override String get totalVolume => 'Total Volume';
  @override String get price => 'Price';
  @override String get status => 'Status';
  @override String get started => 'Started';

  @override String get home => 'Home';
  @override String get settings => 'Settings';
  @override String get about => 'About';
  @override String get profile => 'Profile';
  @override String get myProfile => 'My Profile';
  @override String get pastSessions => 'Past Sessions';
  @override String get signOut => 'Sign out';

  @override String get beerer => 'Beerer';
  @override String get noKegSessionsYet => 'No keg sessions yet';
  @override String get tapPlusToCreate => 'Tap + to create your first keg session!';
  @override String get noActiveKegSessions => 'No active keg sessions';
  @override String get tapPlusToCreateNew => 'Tap + to create a new keg session';
  @override String get joinKegSession => 'Join Keg Session';
  @override String get newKegSession => 'New Keg Session';
  @override String get joinAKegSession => 'Join a Keg Session';
  @override String get pasteInviteLinkOrId => 'Paste the invite link or enter the session ID:';
  @override String get inviteLinkHint => 'beerer://join/... or session ID';
  @override String get pasteFromClipboard => 'Paste from clipboard';
  @override String get scanQrCode => 'Scan QR code';
  @override String get cancel => 'Cancel';
  @override String get join => 'Join';
  @override String get invalidLinkOrId => 'Invalid link or session ID';
  @override String get noPastSessions => 'No past sessions';
  @override String error(String message) => 'Error: $message';
  @override String get notSignedIn => 'Not signed in';

  @override String get signIn => 'Sign in';
  @override String get createAccount => 'Create account';
  @override String get signInToBeerEr => 'Sign in to Beerer';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get confirmPassword => 'Confirm password';
  @override String get pleaseEnterEmail => 'Please enter your email';
  @override String get enterValidEmail => 'Enter a valid email';
  @override String get pleaseEnterPassword => 'Please enter your password';
  @override String get passwordMinLength => 'Password must be at least 6 characters';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get forgotPassword => 'Forgot password?';
  @override String get noAccount => 'No account? ';
  @override String get registerLink => 'Register ›';
  @override String get alreadyHaveOne => 'Already have one? ';
  @override String get signInLink => 'Sign in ›';
  @override String get signInFailed => 'Sign in failed. Please try again.';
  @override String get verifyEmailMessage => 'Please verify your email address. We\'ve sent you a verification link.';
  @override String get accountCreatedVerify => 'Account created. Check your email to verify before signing in.';
  @override String get registrationFailed => 'Registration failed. Please try again.';
  @override String get emailSignInNotConfigured => 'Email sign-in is not configured. Please contact the app admin.';

  @override String get forgotPasswordTitle => 'Forgot password?';
  @override String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you a reset link.';
  @override String get sendResetLink => 'Send reset link';
  @override String get checkYourEmail => 'Check your email';
  @override String resetLinkSent(String email) => 'We\'ve sent a password reset link to $email.';
  @override String get backToSignIn => 'Back to sign in';
  @override String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override String get profileDetails => 'Profile details';
  @override String get nickname => 'Nickname';
  @override String get pleaseChooseNickname => 'Please choose a nickname';
  @override String get weightKg => 'Weight (kg)';
  @override String get age => 'Age';
  @override String get genderLabel => 'Gender:';
  @override String get male => 'Male';
  @override String get female => 'Female';
  @override String get bacPrivacyNote => 'ℹ Weight & age are used only for BAC estimation on your device.';

  @override String get welcomeTagline => 'Track every pour.\nSettle every tab.\nDrink all the kegs.';
  @override String get splashTagline => 'Count every drop';

  @override String get editProfile => 'Edit Profile';
  @override String get save => 'Save';
  @override String get weight => 'Weight';
  @override String get gender => 'Gender';
  @override String get deleteAccount => 'Delete account';
  @override String get showStatsToOthers => 'Show stats to others';
  @override String get showBacEstimate => 'Show BAC estimate';
  @override String get setWeightForBac => 'Set your weight in profile to enable BAC';
  @override String get sessionHistory => 'Session History';
  @override String get viewHistory => 'View history';
  @override String get privacySettings => 'Privacy settings';

  @override String get notifications => 'Notifications';
  @override String get display => 'Display';
  @override String get account => 'Account';
  @override String get allowPourForMe => 'Allow others to pour for me';
  @override String get allowPourForMeSubtitle => 'Other participants can log a pour on your behalf';
  @override String get notifyPourForMe => 'Notify when poured for me';
  @override String get notifyPourForMeSubtitle => 'Get notified when someone pours beer on your behalf';
  @override String get kegNearlyEmpty => 'Keg nearly empty';
  @override String get readyToDrive => 'Ready to drive';
  @override String get readyToDriveSubtitle => 'Get notified when your estimated BAC reaches 0';
  @override String get slowdownReminder => 'Slowdown reminder';
  @override String get slowdownReminderSubtitle => 'Get nudged when your drinking pace drops';
  @override String get volumeUnits => 'Volume units';
  @override String get currencySymbol => 'Currency symbol';
  @override String get decimalSeparator => 'Decimal separator';
  @override String get dotSeparator => 'Dot (1.5)';
  @override String get commaSeparator => 'Comma (1,5)';
  @override String get changePassword => 'Change password';
  @override String get language => 'Language';

  @override String version(String version) => 'Version $version';
  @override String get aboutDescription => 'Beerer is a keg beer tracker for parties. Track every pour, see real-time stats, and settle costs easily.';
  @override String get enjoyUsingBeerer => 'Enjoy using Beerer?';
  @override String get buyDeveloperBeer => 'Buy the developer a beer!';
  @override String get tipViaRevolut => 'Tip via Revolut';
  @override String get drinkResponsiblyTitle => 'Drink Responsibly';
  @override String get drinkResponsiblyBody => 'BAC estimates are for informational purposes only and should not be used to determine fitness to drive. Please drink responsibly.';
  @override String get addictionAwareness => 'If you are using this app often, consider visiting:';
  @override String get addictionCenterEU => 'Addiction Center EU';
  @override String get beerTastingQuestion => 'Want to learn beer tasting?';
  @override String get privacyPolicy => 'Privacy Policy';
  @override String get openSourceLicences => 'Open-source licences';

  @override String get shareKegSession => 'Share Keg Session';
  @override String get inviteFriendsToJoin => 'Invite friends to join';
  @override String get copyLink => 'Copy link';
  @override String get shareLink => 'Share link';
  @override String get linkCopied => 'Link copied!';
  @override String joinMyKegParty(String link) => 'Join my keg party! $link';

  @override String get exportToSettleUp => 'Export to Settle Up';
  @override String get reviewBillSplit => 'Review the bill split';
  @override String get noJointAccountsFound => 'No joint accounts found. Individual costs will be exported.';
  @override String membersCount(int count) => '$count members';
  @override String totalWithAmount(String amount) => 'Total: $amount';
  @override String get settleUpInfo => 'ℹ Settle Up will create a group with these amounts.';
  @override String get exportedSuccessfully => 'Exported to Settle Up successfully!';
  @override String exportFailed(String error) => 'Export failed: $error';
  @override String get sessionNotFound => 'Session not found';

  @override String newKegSessionStep(int step) => 'New Keg Session  $step/2';
  @override String get searchBeerOnBeerWeb => 'Search beer on BeerWeb…';
  @override String get egKozel => 'e.g. Kozel';
  @override String get egPilsnerUrquell => 'e.g. Pilsner Urquell';
  @override String get pleaseEnterBeerName => 'Please enter a beer name';
  @override String get beerDetailsOptional => 'Beer details (optional)';
  @override String get alcoholContentPercent => 'Alcohol content (%)';
  @override String get egAlcohol => 'e.g. 5.0';
  @override String get egBrewery => 'e.g. Pilsner Urquell Brewery';
  @override String get egMalt => 'e.g. barley';
  @override String get egFermentation => 'e.g. Bottom-fermented';
  @override String get type => 'Type';
  @override String get egType => 'e.g. Pale';
  @override String get group => 'Group';
  @override String get egGroup => 'e.g. Full';
  @override String get egBeerStyle => 'e.g. Pale Ale';
  @override String get egDegreePlato => 'e.g. 12';
  @override String get next => 'Next →';
  @override String get back => '← Back';
  @override String get kegVolumeLitres => 'Keg volume (litres)';
  @override String get orEnterCustomVolume => 'Or enter custom volume';
  @override String get egVolume => 'e.g. 25';
  @override String kegPriceLabel(String currency) => 'Keg price ($currency)';
  @override String get enterValidNumber => 'Enter a valid number';
  @override String get predefinedPourSizes => 'Predefined pour sizes';
  @override String get tapToRemove => 'Tap × to remove';
  @override String get addChip => '+ Add';
  @override String get createSession => 'Create Session';
  @override String failedToCreateSession(String error) => 'Failed to create session: $error';
  @override String get addPourSize => 'Add pour size';
  @override String get volumeMl => 'Volume (ml)';
  @override String get egPourSize => 'e.g. 500';
  @override String get add => 'Add';

  @override String get logPourForYou => 'Log a pour for you';
  @override String get orEnterManually => 'Or enter manually:';
  @override String get logPour => 'Log Pour';

  @override String get checkInboxToVerify => 'Check your inbox to verify your email.';
  @override String get resend => 'Resend';
  @override String get chooseAvatar => 'Choose avatar';

  @override String estBacValue(String value) => 'Est. BAC: $value ‰';
  @override String readyToDriveIn(String duration) => 'Ready to drive in ~$duration';

  @override String get statusCreated => 'Created';
  @override String get statusReady => 'Ready';
  @override String get statusActive => 'Active';
  @override String get statusPaused => 'Paused';
  @override String get statusDone => 'Done';
  @override String percentLeft(String percent) => '$percent left';
  @override String peopleDuration(int count, String duration) => '$count people · $duration';

  @override String get myJointAccount => 'My Joint Account';
  @override String get jointAccounts => 'Joint Accounts';
  @override String get members => 'Members';
  @override String get youSuffix => ' (you)';
  @override String get addMember => 'Add member';
  @override String get leaveAccount => 'Leave account';
  @override String get createANewGroup => 'Create a new group';
  @override String get groupNameHint => 'Group name (e.g. "Novák family")';
  @override String get createGroup => 'Create Group';
  @override String get orJoinExistingGroup => 'Or join an existing group';
  @override String memberCount(int count) => '$count member(s)';
  @override String get alreadyInGroup => 'You are already in a group.';
  @override String get leaveCurrentGroupFirst => 'You must leave your current group first.';
  @override String failedToCreateGroup(String error) => 'Failed to create group: $error';
  @override String get allParticipantsInGroup => 'All participants are already in a group.';
  @override String get userAlreadyInAnotherGroup => 'This user is already in another group.';

  @override String get guest => 'Guest';
  @override String get english => 'English';
  @override String get czech => 'Čeština';
  @override String get german => 'Deutsch';

  // ---- Keg Detail Screen ----
  @override String get sessionReady => 'SESSION READY';
  @override String get tapTheKegToStart => 'Tap the keg to start!';
  @override String get kegIsUntapped => 'Keg is untapped';
  @override String get pouringDisabled => 'Pouring is disabled.';
  @override String get tapKegAgain => 'Tap Keg Again';
  @override String get sessionComplete => 'SESSION COMPLETE';
  @override String get finalStats => 'Final stats';
  @override String get totalKegTime => 'Total keg time';
  @override String get totalPoured => 'Total poured';
  @override String get pureAlcohol => 'Pure alcohol';
  @override String get participantsLabel => 'Participants';
  @override String get myTotal => 'My total';
  @override String get kegPriceLabel2 => 'Keg price';
  @override String get billSplit => 'Bill split';
  @override String get basedOnActualConsumption => 'Based on actual consumption';
  @override String get reviewBill => 'Review Bill';
  @override String get kegLevel => 'KEG LEVEL';
  @override String get remaining => 'remaining';
  @override String get untilEmpty => 'until empty';
  @override String get myStats => 'My stats';
  @override String get currentBeer => 'Current beer';
  @override String get sinceLast => 'Since last';
  @override String get avgRate => 'Avg rate';
  @override String get myVolume => 'My volume';
  @override String get beers => 'Beers';
  @override String get bacEstimate => 'BAC estimate';
  @override String get driveIn => 'Drive in';
  @override String get bacEstimateWarning => '⚠ BAC is an estimate only — actual values may differ.';
  @override String get pourLogged => 'Pour logged!';
  @override String pourFailed(String error) => 'Pour failed: $error';
  @override String pourForNickname(String nickname) => 'Pour for $nickname';
  @override String pouredForNickname(String nickname) => 'Poured for $nickname!';
  @override String get accountsBills => 'Accounts / Bills';
  @override String get joinCreateAccount => 'Join / Create Account';
  @override String get addGuest => 'Add Guest';
  @override String get guestName => 'Guest name';
  @override String get removeGuest => 'Remove Guest';
  @override String removeGuestConfirm(String nickname) => 'Remove "$nickname" and all their pours from this session?';
  @override String get remove => 'Remove';
  @override String get markKegAsDoneQuestion => 'Mark keg as done?';
  @override String get sessionReadOnlyWarning => 'The session will become read-only. This cannot be undone.';
  @override String get deleteSessionQuestion => 'Delete session?';
  @override String get deleteSessionWarning => 'This will permanently delete the keg session. This cannot be undone.';
  @override String get delete => 'Delete';
  @override String get shareJoinLink => 'Share join link';
  @override String get editSession => 'Edit session';
  @override String get untapUnfinishedKeg => 'Untap unfinished keg';
  @override String get markKegAsDone => 'Mark keg as done';
  @override String pourForDisabled(String name) => '$name has disabled "Pour for me".';
  @override String get solo => 'solo';

  // ---- Bill Review Screen ----
  @override String get pours => 'Pours';
  @override String get drinkers => 'Drinkers';
  @override String get totalConsumed => 'Total consumed';
  @override String get noPours => 'No pours logged';
  @override String addBeerFor(String name) => 'Add beer for $name';
  @override String addedVolumeFor(String volume, String name) => 'Added $volume for $name';
  @override String get failedToAddPour => 'Failed to add pour';
  @override String get removePourQuestion => 'Remove pour?';
  @override String removePourConfirm(String volume) => 'Remove $volume pour?';
  @override String get pourRemoved => 'Pour removed';

  // ---- Participant Detail Screen ----
  @override String get consumptionOverTime => 'CONSUMPTION OVER TIME';
  @override String get estimatedBacOverTime => 'ESTIMATED BAC OVER TIME';
  @override String get bacDoNotUseForDriving => '⚠ BAC is an estimate only — do not use it to determine fitness to drive.';
  @override String get stats => 'STATS';
  @override String get beerCount => 'Beer count';
  @override String get volume => 'Volume';
  @override String get shareOfKeg => 'Share of keg';
  @override String get avgRateLabel => 'Avg. rate';
  @override String get cost => 'Cost';
  @override String get estBac => 'Est. BAC';
  @override String get estTimeToDrive => 'Est. time to drive';

  // ---- Join Session Screen ----
  @override String get youreInvitedToParty => "You're invited to a party!";
  @override String get visibilitySettings => 'Visibility settings';
  @override String get showMyStats => 'Show my stats';
  @override String get showBacEstimateJoin => 'Show BAC estimate';
  @override String get areYouOneOfGuests => 'Are you one of these guests?';
  @override String get selectYourselfToMerge => 'Select yourself to take over their pours, or skip.';
  @override String get joinAndMerge => 'Join & Merge';
  @override String get joinSession => 'Join Session';
  @override String get failedToJoin => 'Failed to join';

  // ---- QR Scanner Screen ----
  @override String get pointAtBeererQrCode => 'Point at a Beerer QR code';

  // ---- Misc ----
  @override String get guestLower => 'guest';
  @override String get removeGuestTooltip => 'Remove guest';
  @override String get removePourTooltip => 'Remove pour';
  @override String get ago => 'ago';
  @override String get total => 'Total';
  @override String errorWithMessage(String error) => 'Error: $error';

  // ---- Refactored UI ----
  @override String get pourBeer => 'Pour Beer';
  @override String get addPerson => 'Add Person';
  @override String get removeFromSession => 'Remove from session';
  @override String removeFromSessionConfirm(String nickname) => 'Remove "$nickname" and all their pours from this session?';
  @override String get guestDetail => 'Guest detail';
  @override String get guestNameTaken => 'This name is already taken by another participant. Please choose a different name.';
}
