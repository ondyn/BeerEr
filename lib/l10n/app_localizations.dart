import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
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
    Locale('cs'),
    Locale('de'),
  ];

  // ---- App Title ----
  String get appTitle;

  // ---- Keg Actions ----
  String get tapKeg;
  String get untapKeg;
  String get kegDone;
  String get iGotBeer;
  String get pourForSomeone;
  String get undo;
  String get statistics;
  String get estimatedBac;
  String get drinkResponsibly;
  String volumeRemaining(String volume);

  // ---- Keg Info ----
  String get kegInformation;
  String get beerInformation;
  String get kegInfo;
  String get beerName;
  String get alcoholPercent;
  String get brewery;
  String get malt;
  String get fermentation;
  String get beerType;
  String get beerGroup;
  String get beerStyle;
  String get degreePlato;
  String get totalVolume;
  String get price;
  String get status;
  String get started;

  // ---- Navigation ----
  String get home;
  String get settings;
  String get about;
  String get profile;
  String get myProfile;
  String get pastSessions;
  String get signOut;

  // ---- Home Screen ----
  String get beerer;
  String get noKegSessionsYet;
  String get tapPlusToCreate;
  String get noActiveKegSessions;
  String get tapPlusToCreateNew;
  String get joinKegSession;
  String get newKegSession;
  String get joinAKegSession;
  String get pasteInviteLinkOrId;
  String get inviteLinkHint;
  String get pasteFromClipboard;
  String get scanQrCode;
  String get cancel;
  String get join;
  String get invalidLinkOrId;
  String get noPastSessions;
  String error(String message);
  String get notSignedIn;

  // ---- Auth ----
  String get signIn;
  String get createAccount;
  String get signInToBeerEr;
  String get email;
  String get password;
  String get confirmPassword;
  String get pleaseEnterEmail;
  String get enterValidEmail;
  String get pleaseEnterPassword;
  String get passwordMinLength;
  String get passwordsDoNotMatch;
  String get forgotPassword;
  String get noAccount;
  String get registerLink;
  String get alreadyHaveOne;
  String get signInLink;
  String get signInFailed;
  String get verifyEmailMessage;
  String get accountCreatedVerify;
  String get registrationFailed;
  String get emailSignInNotConfigured;

  // ---- Forgot Password ----
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get sendResetLink;
  String get checkYourEmail;
  String resetLinkSent(String email);
  String get backToSignIn;
  String get pleaseEnterValidEmail;

  // ---- Register / Profile ----
  String get profileDetails;
  String get nickname;
  String get pleaseChooseNickname;
  String get weightKg;
  String get age;
  String get genderLabel;
  String get male;
  String get female;
  String get bacPrivacyNote;

  // ---- Welcome / Splash ----
  String get welcomeTagline;
  String get splashTagline;

  // ---- Profile Screen ----
  String get editProfile;
  String get save;
  String get weight;
  String get gender;
  String get deleteAccount;
  String get showStatsToOthers;
  String get showBacEstimate;
  String get setWeightForBac;
  String get sessionHistory;
  String get viewHistory;
  String get privacySettings;

  // ---- Settings ----
  String get notifications;
  String get display;
  String get account;
  String get allowPourForMe;
  String get allowPourForMeSubtitle;
  String get notifyPourForMe;
  String get notifyPourForMeSubtitle;
  String get kegNearlyEmpty;
  String get readyToDrive;
  String get readyToDriveSubtitle;
  String get slowdownReminder;
  String get slowdownReminderSubtitle;
  String get volumeUnits;
  String get currencySymbol;
  String get decimalSeparator;
  String get dotSeparator;
  String get commaSeparator;
  String get changePassword;
  String get language;

  // ---- About Screen ----
  String version(String version);
  String get aboutDescription;
  String get enjoyUsingBeerer;
  String get buyDeveloperBeer;
  String get tipViaRevolut;
  String get drinkResponsiblyTitle;
  String get drinkResponsiblyBody;
  String get addictionAwareness;
  String get addictionCenterEU;
  String get beerTastingQuestion;
  String get privacyPolicy;
  String get openSourceLicences;

  // ---- Share Session ----
  String get shareKegSession;
  String get inviteFriendsToJoin;
  String get copyLink;
  String get shareLink;
  String get linkCopied;
  String joinMyKegParty(String link);

  // ---- Settle Up ----
  String get exportToSettleUp;
  String get reviewBillSplit;
  String get noJointAccountsFound;
  String membersCount(int count);
  String totalWithAmount(String amount);
  String get settleUpInfo;
  String get exportedSuccessfully;
  String exportFailed(String error);
  String get sessionNotFound;

  // ---- Create Keg ----
  String newKegSessionStep(int step);
  String get searchBeerOnBeerWeb;
  String get egKozel;
  String get egPilsnerUrquell;
  String get pleaseEnterBeerName;
  String get beerDetailsOptional;
  String get alcoholContentPercent;
  String get egAlcohol;
  String get egBrewery;
  String get egMalt;
  String get egFermentation;
  String get type;
  String get egType;
  String get group;
  String get egGroup;
  String get egBeerStyle;
  String get egDegreePlato;
  String get next;
  String get back;
  String get kegVolumeLitres;
  String get orEnterCustomVolume;
  String get egVolume;
  String kegPriceLabel(String currency);
  String get enterValidNumber;
  String get predefinedPourSizes;
  String get tapToRemove;
  String get addChip;
  String get createSession;
  String failedToCreateSession(String error);
  String get addPourSize;
  String get volumeMl;
  String get egPourSize;
  String get add;

  // ---- Volume Picker / Pour ----
  String get logPourForYou;
  String get orEnterManually;
  String get logPour;

  // ---- Email Verification ----
  String get checkInboxToVerify;
  String get resend;

  // ---- Avatar Picker ----
  String get chooseAvatar;

  // ---- BAC Banner ----
  String estBacValue(String value);
  String readyToDriveIn(String duration);

  // ---- Status Badges ----
  String get statusCreated;
  String get statusReady;
  String get statusActive;
  String get statusPaused;
  String get statusDone;
  String percentLeft(String percent);
  String peopleDuration(int count, String duration);

  // ---- Joint Accounts ----
  String get myJointAccount;
  String get jointAccounts;
  String get members;
  String get youSuffix;
  String get addMember;
  String get leaveAccount;
  String get createANewGroup;
  String get groupNameHint;
  String get createGroup;
  String get orJoinExistingGroup;
  String memberCount(int count);
  String get alreadyInGroup;
  String get leaveCurrentGroupFirst;
  String failedToCreateGroup(String error);
  String get allParticipantsInGroup;
  String get userAlreadyInAnotherGroup;

  // ---- Keg Detail Screen ----
  String get sessionReady;
  String get tapTheKegToStart;
  String get kegIsUntapped;
  String get pouringDisabled;
  String get tapKegAgain;
  String get sessionComplete;
  String get finalStats;
  String get totalKegTime;
  String get totalPoured;
  String get pureAlcohol;
  String get participantsLabel;
  String get myTotal;
  String get kegPriceLabel2;
  String get billSplit;
  String get basedOnActualConsumption;
  String get reviewBill;
  String get kegLevel;
  String get remaining;
  String get untilEmpty;
  String get myStats;
  String get currentBeer;
  String get sinceLast;
  String get avgRate;
  String get myVolume;
  String get beers;
  String get bacEstimate;
  String get driveIn;
  String get bacEstimateWarning;
  String get pourLogged;
  String pourFailed(String error);
  String pourForNickname(String nickname);
  String pouredForNickname(String nickname);
  String get accountsBills;
  String get joinCreateAccount;
  String get addGuest;
  String get guestName;
  String get removeGuest;
  String removeGuestConfirm(String nickname);
  String get remove;
  String get markKegAsDoneQuestion;
  String get sessionReadOnlyWarning;
  String get deleteSessionQuestion;
  String get deleteSessionWarning;
  String get delete;
  String get shareJoinLink;
  String get editSession;
  String get untapUnfinishedKeg;
  String get markKegAsDone;
  String pourForDisabled(String name);
  String get solo;

  // ---- Bill Review Screen ----
  String get pours;
  String get drinkers;
  String get totalConsumed;
  String get noPours;
  String addBeerFor(String name);
  String addedVolumeFor(String volume, String name);
  String get failedToAddPour;
  String get removePourQuestion;
  String removePourConfirm(String volume);
  String get pourRemoved;

  // ---- Participant Detail Screen ----
  String get consumptionOverTime;
  String get estimatedBacOverTime;
  String get bacDoNotUseForDriving;
  String get stats;
  String get beerCount;
  String get volume;
  String get shareOfKeg;
  String get avgRateLabel;
  String get cost;
  String get estBac;
  String get estTimeToDrive;

  // ---- Join Session Screen ----
  String get youreInvitedToParty;
  String get visibilitySettings;
  String get showMyStats;
  String get showBacEstimateJoin;
  String get areYouOneOfGuests;
  String get selectYourselfToMerge;
  String get joinAndMerge;
  String get joinSession;
  String get failedToJoin;

  // ---- QR Scanner Screen ----
  String get pointAtBeererQrCode;

  // ---- Misc ----
  String get guest;
  String get guestLower;
  String get removeGuestTooltip;
  String get removePourTooltip;
  String get ago;
  String get total;
  String errorWithMessage(String error);
  String get english;
  String get czech;
  String get german;

  // ---- Refactored UI ----
  String get pourBeer;
  String get addPerson;
  String get removeFromSession;
  String removeFromSessionConfirm(String nickname);
  String get guestDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'cs', 'de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
