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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Beerer'**
  String get appTitle;

  /// No description provided for @tapKeg.
  ///
  /// In en, this message translates to:
  /// **'Tap Keg'**
  String get tapKeg;

  /// No description provided for @untapKeg.
  ///
  /// In en, this message translates to:
  /// **'Untap Keg'**
  String get untapKeg;

  /// No description provided for @kegDone.
  ///
  /// In en, this message translates to:
  /// **'Keg Done'**
  String get kegDone;

  /// No description provided for @iGotBeer.
  ///
  /// In en, this message translates to:
  /// **'I Got Beer'**
  String get iGotBeer;

  /// No description provided for @pourForSomeone.
  ///
  /// In en, this message translates to:
  /// **'Pour for Someone'**
  String get pourForSomeone;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @estimatedBac.
  ///
  /// In en, this message translates to:
  /// **'Est. BAC'**
  String get estimatedBac;

  /// No description provided for @drinkResponsibly.
  ///
  /// In en, this message translates to:
  /// **'Please drink responsibly.'**
  String get drinkResponsibly;

  /// No description provided for @kegInformation.
  ///
  /// In en, this message translates to:
  /// **'Keg Information'**
  String get kegInformation;

  /// No description provided for @kegVolumeChart.
  ///
  /// In en, this message translates to:
  /// **'Keg Volume Over Time'**
  String get kegVolumeChart;

  /// No description provided for @pourRateChart.
  ///
  /// In en, this message translates to:
  /// **'Pour Rate Over Time'**
  String get pourRateChart;

  /// No description provided for @volumeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{volume} ml remaining'**
  String volumeRemaining(String volume);

  /// No description provided for @poursPerHour.
  ///
  /// In en, this message translates to:
  /// **'pours/h'**
  String get poursPerHour;

  /// No description provided for @beerInformation.
  ///
  /// In en, this message translates to:
  /// **'Beer Information'**
  String get beerInformation;

  /// No description provided for @kegInfo.
  ///
  /// In en, this message translates to:
  /// **'Keg Information'**
  String get kegInfo;

  /// No description provided for @beerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get beerName;

  /// No description provided for @alcoholPercent.
  ///
  /// In en, this message translates to:
  /// **'Alcohol %'**
  String get alcoholPercent;

  /// No description provided for @brewery.
  ///
  /// In en, this message translates to:
  /// **'Brewery'**
  String get brewery;

  /// No description provided for @malt.
  ///
  /// In en, this message translates to:
  /// **'Malt'**
  String get malt;

  /// No description provided for @fermentation.
  ///
  /// In en, this message translates to:
  /// **'Fermentation'**
  String get fermentation;

  /// No description provided for @beerType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get beerType;

  /// No description provided for @beerGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get beerGroup;

  /// No description provided for @beerStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get beerStyle;

  /// No description provided for @degreePlato.
  ///
  /// In en, this message translates to:
  /// **'Degree Plato'**
  String get degreePlato;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @pastSessions.
  ///
  /// In en, this message translates to:
  /// **'Past Sessions'**
  String get pastSessions;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @beerer.
  ///
  /// In en, this message translates to:
  /// **'Beerer'**
  String get beerer;

  /// No description provided for @noKegSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No keg sessions yet'**
  String get noKegSessionsYet;

  /// No description provided for @tapPlusToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first keg session!'**
  String get tapPlusToCreate;

  /// No description provided for @noActiveKegSessions.
  ///
  /// In en, this message translates to:
  /// **'No active keg sessions'**
  String get noActiveKegSessions;

  /// No description provided for @tapPlusToCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new keg session'**
  String get tapPlusToCreateNew;

  /// No description provided for @joinKegSession.
  ///
  /// In en, this message translates to:
  /// **'Join Keg Session'**
  String get joinKegSession;

  /// No description provided for @newKegSession.
  ///
  /// In en, this message translates to:
  /// **'New Keg Session'**
  String get newKegSession;

  /// No description provided for @joinAKegSession.
  ///
  /// In en, this message translates to:
  /// **'Join a Keg Session'**
  String get joinAKegSession;

  /// No description provided for @pasteInviteLinkOrId.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite link or enter the session ID:'**
  String get pasteInviteLinkOrId;

  /// No description provided for @inviteLinkHint.
  ///
  /// In en, this message translates to:
  /// **'beerer://join/... or session ID'**
  String get inviteLinkHint;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @invalidLinkOrId.
  ///
  /// In en, this message translates to:
  /// **'Invalid link or session ID'**
  String get invalidLinkOrId;

  /// No description provided for @noPastSessions.
  ///
  /// In en, this message translates to:
  /// **'No past sessions'**
  String get noPastSessions;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signInToBeerEr.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Beerer'**
  String get signInToBeerEr;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? '**
  String get noAccount;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register ›'**
  String get registerLink;

  /// No description provided for @alreadyHaveOne.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveOne;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in ›'**
  String get signInLink;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleSignInFailed;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @accountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email using a different sign-in method. Try signing in with email and password instead.'**
  String get accountExistsWithDifferentCredential;

  /// No description provided for @verifyEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address. We\'ve sent you a verification link.'**
  String get verifyEmailMessage;

  /// No description provided for @accountCreatedVerify.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to verify before signing in.'**
  String get accountCreatedVerify;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// No description provided for @emailSignInNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not configured. Please contact the app admin.'**
  String get emailSignInNotConfigured;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile details'**
  String get profileDetails;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a few details for accurate stats and BAC estimation.'**
  String get completeProfileSubtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @pleaseEnterNickname.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get pleaseEnterNickname;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @pleaseChooseNickname.
  ///
  /// In en, this message translates to:
  /// **'Please choose a nickname'**
  String get pleaseChooseNickname;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender:'**
  String get genderLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @bacPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'ℹ Weight & age are used only for BAC estimation on your device.'**
  String get bacPrivacyNote;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Track every pour.\nSettle every tab.\nDrink all the kegs.'**
  String get welcomeTagline;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Count every drop'**
  String get splashTagline;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @showStatsToOthers.
  ///
  /// In en, this message translates to:
  /// **'Show stats to others'**
  String get showStatsToOthers;

  /// No description provided for @showBacEstimate.
  ///
  /// In en, this message translates to:
  /// **'Show BAC estimate'**
  String get showBacEstimate;

  /// No description provided for @showPersonalInfoToOthers.
  ///
  /// In en, this message translates to:
  /// **'Show personal info to others'**
  String get showPersonalInfoToOthers;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfo;

  /// No description provided for @setWeightForBac.
  ///
  /// In en, this message translates to:
  /// **'Set your weight in profile to enable BAC'**
  String get setWeightForBac;

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get viewHistory;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get privacySettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @allowPourForMe.
  ///
  /// In en, this message translates to:
  /// **'Allow others to pour for me'**
  String get allowPourForMe;

  /// No description provided for @allowPourForMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Other participants can log a pour on your behalf'**
  String get allowPourForMeSubtitle;

  /// No description provided for @notifyPourForMe.
  ///
  /// In en, this message translates to:
  /// **'Notify when poured for me'**
  String get notifyPourForMe;

  /// No description provided for @notifyPourForMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone pours beer on your behalf'**
  String get notifyPourForMeSubtitle;

  /// No description provided for @kegNearlyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keg nearly empty'**
  String get kegNearlyEmpty;

  /// No description provided for @readyToDrive.
  ///
  /// In en, this message translates to:
  /// **'Ready to drive'**
  String get readyToDrive;

  /// No description provided for @readyToDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when your estimated BAC reaches 0'**
  String get readyToDriveSubtitle;

  /// No description provided for @slowdownReminder.
  ///
  /// In en, this message translates to:
  /// **'Slowdown reminder'**
  String get slowdownReminder;

  /// No description provided for @slowdownReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get nudged when your drinking pace drops'**
  String get slowdownReminderSubtitle;

  /// No description provided for @volumeUnits.
  ///
  /// In en, this message translates to:
  /// **'Volume units'**
  String get volumeUnits;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol'**
  String get currencySymbol;

  /// No description provided for @decimalSeparator.
  ///
  /// In en, this message translates to:
  /// **'Decimal separator'**
  String get decimalSeparator;

  /// No description provided for @dotSeparator.
  ///
  /// In en, this message translates to:
  /// **'Dot (1.5)'**
  String get dotSeparator;

  /// No description provided for @commaSeparator.
  ///
  /// In en, this message translates to:
  /// **'Comma (1,5)'**
  String get commaSeparator;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Beerer is a keg beer tracker for parties. Track every pour, see real-time stats, and settle costs easily.'**
  String get aboutDescription;

  /// No description provided for @enjoyUsingBeerer.
  ///
  /// In en, this message translates to:
  /// **'Enjoy using Beerer?'**
  String get enjoyUsingBeerer;

  /// No description provided for @buyDeveloperBeer.
  ///
  /// In en, this message translates to:
  /// **'Buy the developer a beer!'**
  String get buyDeveloperBeer;

  /// No description provided for @tipViaRevolut.
  ///
  /// In en, this message translates to:
  /// **'Tip via Revolut'**
  String get tipViaRevolut;

  /// No description provided for @drinkResponsiblyTitle.
  ///
  /// In en, this message translates to:
  /// **'Drink Responsibly'**
  String get drinkResponsiblyTitle;

  /// No description provided for @drinkResponsiblyBody.
  ///
  /// In en, this message translates to:
  /// **'BAC estimates are for informational purposes only and should not be used to determine fitness to drive. Please drink responsibly.'**
  String get drinkResponsiblyBody;

  /// No description provided for @addictionAwareness.
  ///
  /// In en, this message translates to:
  /// **'If you are using this app often, consider visiting:'**
  String get addictionAwareness;

  /// No description provided for @addictionCenterEU.
  ///
  /// In en, this message translates to:
  /// **'Addiction Center EU'**
  String get addictionCenterEU;

  /// No description provided for @beerTastingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Want to learn beer tasting?'**
  String get beerTastingQuestion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicences;

  /// No description provided for @shareKegSession.
  ///
  /// In en, this message translates to:
  /// **'Share Keg Session'**
  String get shareKegSession;

  /// No description provided for @inviteFriendsToJoin.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to join'**
  String get inviteFriendsToJoin;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @reviewBillSplit.
  ///
  /// In en, this message translates to:
  /// **'Review the bill split'**
  String get reviewBillSplit;

  /// No description provided for @noJointAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No joint accounts found. Individual costs will be exported.'**
  String get noJointAccountsFound;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get sessionNotFound;

  /// No description provided for @searchBeer.
  ///
  /// In en, this message translates to:
  /// **'Search beer…'**
  String get searchBeer;

  /// No description provided for @egKozel.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kozel'**
  String get egKozel;

  /// No description provided for @egPilsnerUrquell.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pilsner Urquell'**
  String get egPilsnerUrquell;

  /// No description provided for @pleaseEnterBeerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a beer name'**
  String get pleaseEnterBeerName;

  /// No description provided for @beerDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Beer details (optional)'**
  String get beerDetailsOptional;

  /// No description provided for @alcoholContentPercent.
  ///
  /// In en, this message translates to:
  /// **'Alcohol content (%)'**
  String get alcoholContentPercent;

  /// No description provided for @egAlcohol.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5.0'**
  String get egAlcohol;

  /// No description provided for @egBrewery.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pilsner Urquell Brewery'**
  String get egBrewery;

  /// No description provided for @egMalt.
  ///
  /// In en, this message translates to:
  /// **'e.g. barley'**
  String get egMalt;

  /// No description provided for @egFermentation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bottom-fermented'**
  String get egFermentation;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @egType.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pale'**
  String get egType;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @egGroup.
  ///
  /// In en, this message translates to:
  /// **'e.g. Full'**
  String get egGroup;

  /// No description provided for @egBeerStyle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pale Ale'**
  String get egBeerStyle;

  /// No description provided for @egDegreePlato.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12'**
  String get egDegreePlato;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'← Back'**
  String get back;

  /// No description provided for @kegVolumeLitres.
  ///
  /// In en, this message translates to:
  /// **'Keg volume (litres)'**
  String get kegVolumeLitres;

  /// No description provided for @orEnterCustomVolume.
  ///
  /// In en, this message translates to:
  /// **'Or enter custom volume'**
  String get orEnterCustomVolume;

  /// No description provided for @egVolume.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get egVolume;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @predefinedPourSizes.
  ///
  /// In en, this message translates to:
  /// **'Predefined pour sizes'**
  String get predefinedPourSizes;

  /// No description provided for @tapToRemove.
  ///
  /// In en, this message translates to:
  /// **'Tap × to remove'**
  String get tapToRemove;

  /// No description provided for @addChip.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get addChip;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get createSession;

  /// No description provided for @addPourSize.
  ///
  /// In en, this message translates to:
  /// **'Add pour size'**
  String get addPourSize;

  /// No description provided for @volumeMl.
  ///
  /// In en, this message translates to:
  /// **'Volume (ml)'**
  String get volumeMl;

  /// No description provided for @egPourSize.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get egPourSize;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @logPourForYou.
  ///
  /// In en, this message translates to:
  /// **'Log a pour for you'**
  String get logPourForYou;

  /// No description provided for @orEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter manually:'**
  String get orEnterManually;

  /// No description provided for @logPour.
  ///
  /// In en, this message translates to:
  /// **'Log Pour'**
  String get logPour;

  /// No description provided for @checkInboxToVerify.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox to verify your email.'**
  String get checkInboxToVerify;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get chooseAvatar;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statusCreated;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @myJointAccount.
  ///
  /// In en, this message translates to:
  /// **'My Joint Account'**
  String get myJointAccount;

  /// No description provided for @jointAccounts.
  ///
  /// In en, this message translates to:
  /// **'Joint Accounts'**
  String get jointAccounts;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **' (you)'**
  String get youSuffix;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @leaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Leave account'**
  String get leaveAccount;

  /// No description provided for @createANewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create a new group'**
  String get createANewGroup;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name (e.g. \"Novák family\")'**
  String get groupNameHint;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @orJoinExistingGroup.
  ///
  /// In en, this message translates to:
  /// **'Or join an existing group'**
  String get orJoinExistingGroup;

  /// No description provided for @alreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'You are already in a group.'**
  String get alreadyInGroup;

  /// No description provided for @leaveCurrentGroupFirst.
  ///
  /// In en, this message translates to:
  /// **'You must leave your current group first.'**
  String get leaveCurrentGroupFirst;

  /// No description provided for @allParticipantsInGroup.
  ///
  /// In en, this message translates to:
  /// **'All participants are already in a group.'**
  String get allParticipantsInGroup;

  /// No description provided for @userAlreadyInAnotherGroup.
  ///
  /// In en, this message translates to:
  /// **'This user is already in another group.'**
  String get userAlreadyInAnotherGroup;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @czech.
  ///
  /// In en, this message translates to:
  /// **'Čeština'**
  String get czech;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @sessionReady.
  ///
  /// In en, this message translates to:
  /// **'SESSION READY'**
  String get sessionReady;

  /// No description provided for @tapTheKegToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the keg to start!'**
  String get tapTheKegToStart;

  /// No description provided for @kegIsUntapped.
  ///
  /// In en, this message translates to:
  /// **'Keg is untapped'**
  String get kegIsUntapped;

  /// No description provided for @pouringDisabled.
  ///
  /// In en, this message translates to:
  /// **'Pouring is disabled.'**
  String get pouringDisabled;

  /// No description provided for @tapKegAgain.
  ///
  /// In en, this message translates to:
  /// **'Tap Keg Again'**
  String get tapKegAgain;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get sessionComplete;

  /// No description provided for @finalStats.
  ///
  /// In en, this message translates to:
  /// **'Final stats'**
  String get finalStats;

  /// No description provided for @totalKegTime.
  ///
  /// In en, this message translates to:
  /// **'Total keg time'**
  String get totalKegTime;

  /// No description provided for @totalPoured.
  ///
  /// In en, this message translates to:
  /// **'Total poured'**
  String get totalPoured;

  /// No description provided for @pureAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Pure alcohol'**
  String get pureAlcohol;

  /// No description provided for @participantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsLabel;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @sortConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get sortConsumption;

  /// No description provided for @sortUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get sortUsername;

  /// No description provided for @myTotal.
  ///
  /// In en, this message translates to:
  /// **'My total'**
  String get myTotal;

  /// No description provided for @kegPriceLabel2.
  ///
  /// In en, this message translates to:
  /// **'Keg price'**
  String get kegPriceLabel2;

  /// No description provided for @billSplit.
  ///
  /// In en, this message translates to:
  /// **'Bill split'**
  String get billSplit;

  /// No description provided for @basedOnActualConsumption.
  ///
  /// In en, this message translates to:
  /// **'Based on actual consumption'**
  String get basedOnActualConsumption;

  /// No description provided for @reviewBill.
  ///
  /// In en, this message translates to:
  /// **'Review Bill'**
  String get reviewBill;

  /// No description provided for @kegLevel.
  ///
  /// In en, this message translates to:
  /// **'KEG LEVEL'**
  String get kegLevel;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @untilEmpty.
  ///
  /// In en, this message translates to:
  /// **'until empty'**
  String get untilEmpty;

  /// No description provided for @myStats.
  ///
  /// In en, this message translates to:
  /// **'My stats'**
  String get myStats;

  /// No description provided for @currentBeer.
  ///
  /// In en, this message translates to:
  /// **'Current beer'**
  String get currentBeer;

  /// No description provided for @sinceLast.
  ///
  /// In en, this message translates to:
  /// **'Since last'**
  String get sinceLast;

  /// No description provided for @avgRate.
  ///
  /// In en, this message translates to:
  /// **'Avg rate'**
  String get avgRate;

  /// No description provided for @myVolume.
  ///
  /// In en, this message translates to:
  /// **'My volume'**
  String get myVolume;

  /// No description provided for @beers.
  ///
  /// In en, this message translates to:
  /// **'Beers'**
  String get beers;

  /// No description provided for @bacEstimate.
  ///
  /// In en, this message translates to:
  /// **'BAC estimate'**
  String get bacEstimate;

  /// No description provided for @driveIn.
  ///
  /// In en, this message translates to:
  /// **'Drive in'**
  String get driveIn;

  /// No description provided for @bacEstimateWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ BAC is an estimate only — actual values may differ.'**
  String get bacEstimateWarning;

  /// No description provided for @pourLogged.
  ///
  /// In en, this message translates to:
  /// **'Pour logged!'**
  String get pourLogged;

  /// No description provided for @accountsBills.
  ///
  /// In en, this message translates to:
  /// **'Accounts / Bills'**
  String get accountsBills;

  /// No description provided for @joinCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Join / Create Account'**
  String get joinCreateAccount;

  /// No description provided for @addGuest.
  ///
  /// In en, this message translates to:
  /// **'Add Guest'**
  String get addGuest;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest name'**
  String get guestName;

  /// No description provided for @removeGuest.
  ///
  /// In en, this message translates to:
  /// **'Remove Guest'**
  String get removeGuest;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @markKegAsDoneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Mark keg as done?'**
  String get markKegAsDoneQuestion;

  /// No description provided for @sessionReadOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'The session will become read-only. This cannot be undone.'**
  String get sessionReadOnlyWarning;

  /// No description provided for @deleteSessionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get deleteSessionQuestion;

  /// No description provided for @deleteSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the keg session. This cannot be undone.'**
  String get deleteSessionWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @shareJoinLink.
  ///
  /// In en, this message translates to:
  /// **'Share join link'**
  String get shareJoinLink;

  /// No description provided for @editSession.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get editSession;

  /// No description provided for @untapUnfinishedKeg.
  ///
  /// In en, this message translates to:
  /// **'Untap unfinished keg'**
  String get untapUnfinishedKeg;

  /// No description provided for @markKegAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark keg as done'**
  String get markKegAsDone;

  /// No description provided for @solo.
  ///
  /// In en, this message translates to:
  /// **'solo'**
  String get solo;

  /// No description provided for @pours.
  ///
  /// In en, this message translates to:
  /// **'Pours'**
  String get pours;

  /// No description provided for @drinkers.
  ///
  /// In en, this message translates to:
  /// **'Drinkers'**
  String get drinkers;

  /// No description provided for @totalConsumed.
  ///
  /// In en, this message translates to:
  /// **'Total consumed'**
  String get totalConsumed;

  /// No description provided for @noPours.
  ///
  /// In en, this message translates to:
  /// **'No pours logged'**
  String get noPours;

  /// No description provided for @failedToAddPour.
  ///
  /// In en, this message translates to:
  /// **'Failed to add pour'**
  String get failedToAddPour;

  /// No description provided for @removePourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove pour?'**
  String get removePourQuestion;

  /// No description provided for @pourRemoved.
  ///
  /// In en, this message translates to:
  /// **'Pour removed'**
  String get pourRemoved;

  /// No description provided for @consumptionOverTime.
  ///
  /// In en, this message translates to:
  /// **'CONSUMPTION OVER TIME'**
  String get consumptionOverTime;

  /// No description provided for @estimatedBacOverTime.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED BAC OVER TIME'**
  String get estimatedBacOverTime;

  /// No description provided for @bacDoNotUseForDriving.
  ///
  /// In en, this message translates to:
  /// **'⚠ BAC is an estimate only — do not use it to determine fitness to drive.'**
  String get bacDoNotUseForDriving;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get stats;

  /// No description provided for @beerCount.
  ///
  /// In en, this message translates to:
  /// **'Beer count'**
  String get beerCount;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @shareOfKeg.
  ///
  /// In en, this message translates to:
  /// **'Share of keg'**
  String get shareOfKeg;

  /// No description provided for @avgRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg. rate'**
  String get avgRateLabel;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @estBac.
  ///
  /// In en, this message translates to:
  /// **'Est. BAC'**
  String get estBac;

  /// No description provided for @estTimeToDrive.
  ///
  /// In en, this message translates to:
  /// **'Est. time to drive'**
  String get estTimeToDrive;

  /// No description provided for @visibilitySettings.
  ///
  /// In en, this message translates to:
  /// **'Visibility settings'**
  String get visibilitySettings;

  /// No description provided for @showMyStats.
  ///
  /// In en, this message translates to:
  /// **'Show my stats'**
  String get showMyStats;

  /// No description provided for @showBacEstimateJoin.
  ///
  /// In en, this message translates to:
  /// **'Show BAC estimate'**
  String get showBacEstimateJoin;

  /// No description provided for @areYouOneOfGuests.
  ///
  /// In en, this message translates to:
  /// **'Are you one of these guests?'**
  String get areYouOneOfGuests;

  /// No description provided for @selectYourselfToMerge.
  ///
  /// In en, this message translates to:
  /// **'Select yourself to take over their pours, or skip.'**
  String get selectYourselfToMerge;

  /// No description provided for @joinAndMerge.
  ///
  /// In en, this message translates to:
  /// **'Join & Merge'**
  String get joinAndMerge;

  /// No description provided for @joinSession.
  ///
  /// In en, this message translates to:
  /// **'Join Session'**
  String get joinSession;

  /// No description provided for @failedToJoin.
  ///
  /// In en, this message translates to:
  /// **'Failed to join'**
  String get failedToJoin;

  /// No description provided for @pointAtBeererQrCode.
  ///
  /// In en, this message translates to:
  /// **'Point at a Beerer QR code'**
  String get pointAtBeererQrCode;

  /// No description provided for @guestLower.
  ///
  /// In en, this message translates to:
  /// **'guest'**
  String get guestLower;

  /// No description provided for @removeGuestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove guest'**
  String get removeGuestTooltip;

  /// No description provided for @removePourTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove pour'**
  String get removePourTooltip;

  /// No description provided for @ago.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get ago;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pourBeer.
  ///
  /// In en, this message translates to:
  /// **'Pour Beer'**
  String get pourBeer;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get addPerson;

  /// No description provided for @removeFromSession.
  ///
  /// In en, this message translates to:
  /// **'Remove from session'**
  String get removeFromSession;

  /// No description provided for @guestDetail.
  ///
  /// In en, this message translates to:
  /// **'Guest detail'**
  String get guestDetail;

  /// No description provided for @guestNameTaken.
  ///
  /// In en, this message translates to:
  /// **'This name is already taken by another participant. Please choose a different name.'**
  String get guestNameTaken;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}.'**
  String resetLinkSent(String email);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @joinMyKegParty.
  ///
  /// In en, this message translates to:
  /// **'Join my keg party! {link}'**
  String joinMyKegParty(String link);

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @totalWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalWithAmount(String amount);

  /// No description provided for @newKegSessionStep.
  ///
  /// In en, this message translates to:
  /// **'New Keg Session  {step}/2'**
  String newKegSessionStep(int step);

  /// No description provided for @kegPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Keg price ({currency})'**
  String kegPriceLabel(String currency);

  /// No description provided for @failedToCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to create session: {error}'**
  String failedToCreateSession(String error);

  /// No description provided for @estBacValue.
  ///
  /// In en, this message translates to:
  /// **'Est. BAC: {value} ‰'**
  String estBacValue(String value);

  /// No description provided for @readyToDriveIn.
  ///
  /// In en, this message translates to:
  /// **'Ready to drive in ~{duration}'**
  String readyToDriveIn(String duration);

  /// No description provided for @percentLeft.
  ///
  /// In en, this message translates to:
  /// **'{percent} left'**
  String percentLeft(String percent);

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} member(s)'**
  String memberCount(int count);

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group: {error}'**
  String failedToCreateGroup(String error);

  /// No description provided for @pourFailed.
  ///
  /// In en, this message translates to:
  /// **'Pour failed: {error}'**
  String pourFailed(String error);

  /// No description provided for @pourForNickname.
  ///
  /// In en, this message translates to:
  /// **'Pour for {nickname}'**
  String pourForNickname(String nickname);

  /// No description provided for @pouredForNickname.
  ///
  /// In en, this message translates to:
  /// **'Poured for {nickname}!'**
  String pouredForNickname(String nickname);

  /// No description provided for @removeGuestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{nickname}\" and all their pours from this session?'**
  String removeGuestConfirm(String nickname);

  /// No description provided for @pourForDisabled.
  ///
  /// In en, this message translates to:
  /// **'{name} has disabled \"Pour for me\".'**
  String pourForDisabled(String name);

  /// No description provided for @addBeerFor.
  ///
  /// In en, this message translates to:
  /// **'Add beer for {name}'**
  String addBeerFor(String name);

  /// No description provided for @removePourConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {volume} pour?'**
  String removePourConfirm(String volume);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @removeFromSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{nickname}\" and all their pours from this session?'**
  String removeFromSessionConfirm(String nickname);

  /// No description provided for @peopleDuration.
  ///
  /// In en, this message translates to:
  /// **'{count} people · {duration}'**
  String peopleDuration(int count, String duration);

  /// No description provided for @addedVolumeFor.
  ///
  /// In en, this message translates to:
  /// **'Added {volume} for {name}'**
  String addedVolumeFor(String volume, String name);

  /// No description provided for @wrongPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get wrongPasswordError;

  /// No description provided for @userNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email address.'**
  String get userNotFoundError;

  /// No description provided for @invalidCredentialError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check your credentials.'**
  String get invalidCredentialError;

  /// No description provided for @tooManyRequestsError.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyRequestsError;

  /// No description provided for @emailNotVerifiedError.
  ///
  /// In en, this message translates to:
  /// **'Your email has not been verified yet. Please check your inbox.'**
  String get emailNotVerifiedError;

  /// No description provided for @verificationEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent! Check your inbox.'**
  String get verificationEmailResent;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @youreInvitedToParty.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited to a party!'**
  String get youreInvitedToParty;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. Your personal data will be removed and your account will be deactivated. Your pours in other users\' sessions will be kept as \'Deleted User\'.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted. We\'re sorry to see you go!'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {message}'**
  String deleteAccountFailed(String message);

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountConfirmButton;

  /// No description provided for @volumeConsumed.
  ///
  /// In en, this message translates to:
  /// **'Volume consumed'**
  String get volumeConsumed;

  /// No description provided for @volumeRemaining2.
  ///
  /// In en, this message translates to:
  /// **'Volume remaining'**
  String get volumeRemaining2;

  /// No description provided for @alcoholConsumed.
  ///
  /// In en, this message translates to:
  /// **'Alcohol consumed'**
  String get alcoholConsumed;

  /// No description provided for @alcoholRemaining.
  ///
  /// In en, this message translates to:
  /// **'Alcohol remaining'**
  String get alcoholRemaining;

  /// No description provided for @pricePerBeer.
  ///
  /// In en, this message translates to:
  /// **'Price per {beerSize}'**
  String pricePerBeer(String beerSize);

  /// No description provided for @breweryAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get breweryAddress;

  /// No description provided for @breweryRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get breweryRegion;

  /// No description provided for @breweryYearFounded.
  ///
  /// In en, this message translates to:
  /// **'Year founded'**
  String get breweryYearFounded;

  /// No description provided for @breweryWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get breweryWebsite;

  /// No description provided for @elapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time'**
  String get elapsedTime;

  /// No description provided for @sessionStatistics.
  ///
  /// In en, this message translates to:
  /// **'Session Statistics'**
  String get sessionStatistics;

  /// No description provided for @notifSlowdownTitle.
  ///
  /// In en, this message translates to:
  /// **'🍺 Feeling thirsty?'**
  String get notifSlowdownTitle;

  /// No description provided for @notifSlowdownBody.
  ///
  /// In en, this message translates to:
  /// **'Looks like you\'ve slowed down—ready for another round?'**
  String get notifSlowdownBody;

  /// No description provided for @notifBacZeroTitle.
  ///
  /// In en, this message translates to:
  /// **'🚗 Ready to drive!'**
  String get notifBacZeroTitle;

  /// No description provided for @notifBacZeroBody.
  ///
  /// In en, this message translates to:
  /// **'Your estimated BAC has reached 0. Drive safely!'**
  String get notifBacZeroBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['cs', 'de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs': return AppLocalizationsCs();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
