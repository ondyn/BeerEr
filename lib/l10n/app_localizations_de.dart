// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override String get appTitle => 'BeerEr';
  @override String get tapKeg => 'Fass anzapfen';
  @override String get untapKeg => 'Fass abschließen';
  @override String get kegDone => 'Fass leer';
  @override String get iGotBeer => 'Ich hab Bier';
  @override String get pourForSomeone => 'Für jemanden einschenken';
  @override String get undo => 'Rückgängig';
  @override String get statistics => 'Statistiken';
  @override String get estimatedBac => 'Geschätzter BAK';
  @override String get drinkResponsibly => 'Bitte trinken Sie verantwortungsvoll.';
  @override String volumeRemaining(String volume) => '$volume ml übrig';

  @override String get kegInformation => 'Fass-Informationen';
  @override String get beerInformation => 'Bier-Informationen';
  @override String get kegInfo => 'Fass-Informationen';
  @override String get beerName => 'Name';
  @override String get alcoholPercent => 'Alkohol %';
  @override String get brewery => 'Brauerei';
  @override String get malt => 'Malz';
  @override String get fermentation => 'Gärung';
  @override String get beerType => 'Typ';
  @override String get beerGroup => 'Gruppe';
  @override String get beerStyle => 'Bierstil';
  @override String get degreePlato => 'Stammwürze';
  @override String get totalVolume => 'Gesamtvolumen';
  @override String get price => 'Preis';
  @override String get status => 'Status';
  @override String get started => 'Gestartet';

  @override String get home => 'Startseite';
  @override String get settings => 'Einstellungen';
  @override String get about => 'Über';
  @override String get profile => 'Profil';
  @override String get myProfile => 'Mein Profil';
  @override String get pastSessions => 'Vergangene Sitzungen';
  @override String get signOut => 'Abmelden';

  @override String get beerer => 'Beerer';
  @override String get noKegSessionsYet => 'Noch keine Fasssitzungen';
  @override String get tapPlusToCreate => 'Tippen Sie auf +, um Ihre erste Sitzung zu erstellen!';
  @override String get noActiveKegSessions => 'Keine aktiven Fasssitzungen';
  @override String get tapPlusToCreateNew => 'Tippen Sie auf +, um eine neue Sitzung zu erstellen';
  @override String get joinKegSession => 'Sitzung beitreten';
  @override String get newKegSession => 'Neue Fasssitzung';
  @override String get joinAKegSession => 'Einer Fasssitzung beitreten';
  @override String get pasteInviteLinkOrId => 'Einladungslink einfügen oder Sitzungs-ID eingeben:';
  @override String get inviteLinkHint => 'beerer://join/... oder Sitzungs-ID';
  @override String get pasteFromClipboard => 'Aus Zwischenablage einfügen';
  @override String get scanQrCode => 'QR-Code scannen';
  @override String get cancel => 'Abbrechen';
  @override String get join => 'Beitreten';
  @override String get invalidLinkOrId => 'Ungültiger Link oder Sitzungs-ID';
  @override String get noPastSessions => 'Keine vergangenen Sitzungen';
  @override String error(String message) => 'Fehler: $message';
  @override String get notSignedIn => 'Nicht angemeldet';

  @override String get signIn => 'Anmelden';
  @override String get createAccount => 'Konto erstellen';
  @override String get signInToBeerEr => 'Bei BeerEr anmelden';
  @override String get email => 'E-Mail';
  @override String get password => 'Passwort';
  @override String get confirmPassword => 'Passwort bestätigen';
  @override String get pleaseEnterEmail => 'Bitte geben Sie Ihre E-Mail ein';
  @override String get enterValidEmail => 'Geben Sie eine gültige E-Mail ein';
  @override String get pleaseEnterPassword => 'Bitte geben Sie Ihr Passwort ein';
  @override String get passwordMinLength => 'Passwort muss mindestens 6 Zeichen haben';
  @override String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';
  @override String get forgotPassword => 'Passwort vergessen?';
  @override String get noAccount => 'Kein Konto? ';
  @override String get registerLink => 'Registrieren ›';
  @override String get alreadyHaveOne => 'Bereits registriert? ';
  @override String get signInLink => 'Anmelden ›';
  @override String get signInFailed => 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';
  @override String get verifyEmailMessage => 'Bitte bestätigen Sie Ihre E-Mail-Adresse. Wir haben Ihnen einen Bestätigungslink gesendet.';
  @override String get accountCreatedVerify => 'Konto erstellt. Überprüfen Sie Ihre E-Mail, um sich anzumelden.';
  @override String get registrationFailed => 'Registrierung fehlgeschlagen. Bitte versuchen Sie es erneut.';
  @override String get emailSignInNotConfigured => 'E-Mail-Anmeldung ist nicht konfiguriert. Bitte kontaktieren Sie den Administrator.';

  @override String get forgotPasswordTitle => 'Passwort vergessen?';
  @override String get forgotPasswordSubtitle => 'Geben Sie Ihre E-Mail ein und wir senden Ihnen einen Link zum Zurücksetzen.';
  @override String get sendResetLink => 'Link senden';
  @override String get checkYourEmail => 'E-Mail überprüfen';
  @override String resetLinkSent(String email) => 'Wir haben einen Link zum Zurücksetzen an $email gesendet.';
  @override String get backToSignIn => 'Zurück zur Anmeldung';
  @override String get pleaseEnterValidEmail => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override String get profileDetails => 'Profildetails';
  @override String get nickname => 'Spitzname';
  @override String get pleaseChooseNickname => 'Bitte wählen Sie einen Spitznamen';
  @override String get weightKg => 'Gewicht (kg)';
  @override String get age => 'Alter';
  @override String get genderLabel => 'Geschlecht:';
  @override String get male => 'Männlich';
  @override String get female => 'Weiblich';
  @override String get bacPrivacyNote => 'ℹ Gewicht & Alter werden nur für die BAK-Schätzung auf Ihrem Gerät verwendet.';

  @override String get welcomeTagline => 'Zähle jeden Schluck.\nTeile jede Rechnung.\nTrinke alle Fässer.';
  @override String get splashTagline => 'Zähle jeden Tropfen';

  @override String get editProfile => 'Profil bearbeiten';
  @override String get save => 'Speichern';
  @override String get weight => 'Gewicht';
  @override String get gender => 'Geschlecht';
  @override String get deleteAccount => 'Konto löschen';
  @override String get showStatsToOthers => 'Statistiken anderen zeigen';
  @override String get showBacEstimate => 'BAK-Schätzung anzeigen';
  @override String get setWeightForBac => 'Geben Sie Ihr Gewicht im Profil für BAK ein';
  @override String get sessionHistory => 'Sitzungsverlauf';
  @override String get viewHistory => 'Verlauf anzeigen';
  @override String get privacySettings => 'Datenschutzeinstellungen';

  @override String get notifications => 'Benachrichtigungen';
  @override String get display => 'Anzeige';
  @override String get account => 'Konto';
  @override String get allowPourForMe => 'Anderen erlauben, für mich einzuschenken';
  @override String get allowPourForMeSubtitle => 'Andere Teilnehmer können ein Bier für Sie eintragen';
  @override String get notifyPourForMe => 'Benachrichtigen, wenn für mich eingeschenkt';
  @override String get notifyPourForMeSubtitle => 'Benachrichtigung erhalten, wenn jemand Ihnen Bier einschenkt';
  @override String get kegNearlyEmpty => 'Fass fast leer';
  @override String get readyToDrive => 'Fahrbereit';
  @override String get readyToDriveSubtitle => 'Benachrichtigung, wenn Ihr geschätzter BAK 0 erreicht';
  @override String get slowdownReminder => 'Verlangsamungs-Erinnerung';
  @override String get slowdownReminderSubtitle => 'Erinnerung, wenn Ihr Trinktempo nachlässt';
  @override String get volumeUnits => 'Volumeneinheiten';
  @override String get currencySymbol => 'Währungssymbol';
  @override String get decimalSeparator => 'Dezimaltrennzeichen';
  @override String get dotSeparator => 'Punkt (1.5)';
  @override String get commaSeparator => 'Komma (1,5)';
  @override String get changePassword => 'Passwort ändern';
  @override String get language => 'Sprache';

  @override String version(String version) => 'Version $version';
  @override String get aboutDescription => 'Beerer ist ein Fass-Bier-Tracker für Partys. Verfolge jeden Ausschank, sieh Echtzeit-Statistiken und teile Kosten einfach auf.';
  @override String get enjoyUsingBeerer => 'Gefällt Ihnen Beerer?';
  @override String get buyDeveloperBeer => 'Spendieren Sie dem Entwickler ein Bier!';
  @override String get tipViaRevolut => 'Trinkgeld via Revolut';
  @override String get drinkResponsiblyTitle => 'Trinken Sie verantwortungsvoll';
  @override String get drinkResponsiblyBody => 'BAK-Schätzungen dienen nur zu Informationszwecken und sollten nicht zur Beurteilung der Fahrtüchtigkeit verwendet werden. Bitte trinken Sie verantwortungsvoll.';
  @override String get addictionAwareness => 'Wenn Sie diese App häufig nutzen, besuchen Sie:';
  @override String get addictionCenterEU => 'Suchtberatung EU';
  @override String get beerTastingQuestion => 'Möchten Sie Bierverkostung lernen?';
  @override String get privacyPolicy => 'Datenschutzrichtlinie';
  @override String get openSourceLicences => 'Open-Source-Lizenzen';

  @override String get shareKegSession => 'Sitzung teilen';
  @override String get inviteFriendsToJoin => 'Freunde einladen';
  @override String get copyLink => 'Link kopieren';
  @override String get shareLink => 'Link teilen';
  @override String get linkCopied => 'Link kopiert!';
  @override String joinMyKegParty(String link) => 'Komm zu meiner Fassparty! $link';

  @override String get exportToSettleUp => 'Nach Settle Up exportieren';
  @override String get reviewBillSplit => 'Kostenaufteilung prüfen';
  @override String get noJointAccountsFound => 'Keine gemeinsamen Konten gefunden. Einzelkosten werden exportiert.';
  @override String membersCount(int count) => '$count Mitglieder';
  @override String totalWithAmount(String amount) => 'Gesamt: $amount';
  @override String get settleUpInfo => 'ℹ Settle Up erstellt eine Gruppe mit diesen Beträgen.';
  @override String get exportedSuccessfully => 'Erfolgreich nach Settle Up exportiert!';
  @override String exportFailed(String error) => 'Export fehlgeschlagen: $error';
  @override String get sessionNotFound => 'Sitzung nicht gefunden';

  @override String newKegSessionStep(int step) => 'Neue Fasssitzung  $step/2';
  @override String get searchBeerOnBeerWeb => 'Bier auf BeerWeb suchen…';
  @override String get egKozel => 'z.B. Kozel';
  @override String get egPilsnerUrquell => 'z.B. Pilsner Urquell';
  @override String get pleaseEnterBeerName => 'Bitte Biernamen eingeben';
  @override String get beerDetailsOptional => 'Bierdetails (optional)';
  @override String get alcoholContentPercent => 'Alkoholgehalt (%)';
  @override String get egAlcohol => 'z.B. 5,0';
  @override String get egBrewery => 'z.B. Pilsner Urquell Brauerei';
  @override String get egMalt => 'z.B. Gerste';
  @override String get egFermentation => 'z.B. Untergärig';
  @override String get type => 'Typ';
  @override String get egType => 'z.B. Hell';
  @override String get group => 'Gruppe';
  @override String get egGroup => 'z.B. Voll';
  @override String get egBeerStyle => 'z.B. Pale Ale';
  @override String get egDegreePlato => 'z.B. 12';
  @override String get next => 'Weiter →';
  @override String get back => '← Zurück';
  @override String get kegVolumeLitres => 'Fassvolumen (Liter)';
  @override String get orEnterCustomVolume => 'Oder eigenes Volumen eingeben';
  @override String get egVolume => 'z.B. 25';
  @override String kegPriceLabel(String currency) => 'Fasspreis ($currency)';
  @override String get enterValidNumber => 'Gültige Zahl eingeben';
  @override String get predefinedPourSizes => 'Vordefinierte Ausschankgrößen';
  @override String get tapToRemove => '× tippen zum Entfernen';
  @override String get addChip => '+ Hinzufügen';
  @override String get createSession => 'Sitzung erstellen';
  @override String failedToCreateSession(String error) => 'Sitzung konnte nicht erstellt werden: $error';
  @override String get addPourSize => 'Ausschankgröße hinzufügen';
  @override String get volumeMl => 'Volumen (ml)';
  @override String get egPourSize => 'z.B. 500';
  @override String get add => 'Hinzufügen';

  @override String get logPourForYou => 'Bier für Sie eintragen';
  @override String get orEnterManually => 'Oder manuell eingeben:';
  @override String get logPour => 'Eintragen';

  @override String get checkInboxToVerify => 'Überprüfen Sie Ihren Posteingang, um Ihre E-Mail zu bestätigen.';
  @override String get resend => 'Erneut senden';
  @override String get chooseAvatar => 'Avatar auswählen';

  @override String estBacValue(String value) => 'Geschätzter BAK: $value ‰';
  @override String readyToDriveIn(String duration) => 'Fahrbereit in ~$duration';

  @override String get statusCreated => 'Erstellt';
  @override String get statusReady => 'Bereit';
  @override String get statusActive => 'Aktiv';
  @override String get statusPaused => 'Pausiert';
  @override String get statusDone => 'Fertig';
  @override String percentLeft(String percent) => '$percent übrig';
  @override String peopleDuration(int count, String duration) => '$count Personen · $duration';

  @override String get myJointAccount => 'Mein gemeinsames Konto';
  @override String get jointAccounts => 'Gemeinsame Konten';
  @override String get members => 'Mitglieder';
  @override String get youSuffix => ' (Sie)';
  @override String get addMember => 'Mitglied hinzufügen';
  @override String get leaveAccount => 'Konto verlassen';
  @override String get createANewGroup => 'Neue Gruppe erstellen';
  @override String get groupNameHint => 'Gruppenname (z.B. "Familie Müller")';
  @override String get createGroup => 'Gruppe erstellen';
  @override String get orJoinExistingGroup => 'Oder bestehender Gruppe beitreten';
  @override String memberCount(int count) => '$count Mitglied(er)';
  @override String get alreadyInGroup => 'Sie sind bereits in einer Gruppe.';
  @override String get leaveCurrentGroupFirst => 'Sie müssen zuerst Ihre aktuelle Gruppe verlassen.';
  @override String failedToCreateGroup(String error) => 'Gruppe konnte nicht erstellt werden: $error';
  @override String get allParticipantsInGroup => 'Alle Teilnehmer sind bereits in einer Gruppe.';
  @override String get userAlreadyInAnotherGroup => 'Dieser Benutzer ist bereits in einer anderen Gruppe.';

  @override String get guest => 'Gast';
  @override String get english => 'English';
  @override String get czech => 'Čeština';
  @override String get german => 'Deutsch';

  // ---- Keg Detail Screen ----
  @override String get sessionReady => 'SITZUNG BEREIT';
  @override String get tapTheKegToStart => 'Fass anzapfen und loslegen!';
  @override String get kegIsUntapped => 'Fass ist abgezapft';
  @override String get pouringDisabled => 'Zapfen ist deaktiviert.';
  @override String get tapKegAgain => 'Fass erneut anzapfen';
  @override String get sessionComplete => 'SITZUNG ABGESCHLOSSEN';
  @override String get finalStats => 'Endstatistiken';
  @override String get totalKegTime => 'Gesamte Fasszeit';
  @override String get totalPoured => 'Gesamt gezapft';
  @override String get pureAlcohol => 'Reiner Alkohol';
  @override String get participantsLabel => 'Teilnehmer';
  @override String get myTotal => 'Meine Summe';
  @override String get kegPriceLabel2 => 'Fasspreis';
  @override String get billSplit => 'Rechnung aufteilen';
  @override String get basedOnActualConsumption => 'Basierend auf tatsächlichem Verbrauch';
  @override String get reviewBill => 'Rechnung prüfen';
  @override String get kegLevel => 'FASS-LEVEL';
  @override String get remaining => 'verbleibend';
  @override String get untilEmpty => 'bis leer';
  @override String get myStats => 'Meine Statistiken';
  @override String get currentBeer => 'Aktuelles Bier';
  @override String get sinceLast => 'Seit letztem';
  @override String get avgRate => 'Durchschn. Rate';
  @override String get myVolume => 'Mein Volumen';
  @override String get beers => 'Biere';
  @override String get bacEstimate => 'BAC-Schätzung';
  @override String get driveIn => 'Fahren in';
  @override String get bacEstimateWarning => '⚠ BAC ist nur eine Schätzung — tatsächliche Werte können abweichen.';
  @override String get pourLogged => 'Bier eingetragen!';
  @override String pourFailed(String error) => 'Zapfen fehlgeschlagen: $error';
  @override String pourForNickname(String nickname) => 'Zapfen für $nickname';
  @override String pouredForNickname(String nickname) => 'Gezapft für $nickname!';
  @override String get accountsBills => 'Konten / Rechnungen';
  @override String get joinCreateAccount => 'Beitreten / Konto erstellen';
  @override String get addGuest => 'Gast hinzufügen';
  @override String get guestName => 'Gastname';
  @override String get removeGuest => 'Gast entfernen';
  @override String removeGuestConfirm(String nickname) => '"$nickname" und alle Biere aus dieser Sitzung entfernen?';
  @override String get remove => 'Entfernen';
  @override String get markKegAsDoneQuestion => 'Fass als fertig markieren?';
  @override String get sessionReadOnlyWarning => 'Die Sitzung wird schreibgeschützt. Dies kann nicht rückgängig gemacht werden.';
  @override String get deleteSessionQuestion => 'Sitzung löschen?';
  @override String get deleteSessionWarning => 'Dies löscht die Fasssitzung dauerhaft. Dies kann nicht rückgängig gemacht werden.';
  @override String get delete => 'Löschen';
  @override String get shareJoinLink => 'Einladungslink teilen';
  @override String get editSession => 'Sitzung bearbeiten';
  @override String get untapUnfinishedKeg => 'Unfertiges Fass abzapfen';
  @override String get markKegAsDone => 'Fass als fertig markieren';
  @override String pourForDisabled(String name) => '$name hat „Für mich zapfen" deaktiviert.';
  @override String get solo => 'solo';

  // ---- Bill Review Screen ----
  @override String get pours => 'Zapfungen';
  @override String get drinkers => 'Trinker';
  @override String get totalConsumed => 'Gesamt verbraucht';
  @override String get noPours => 'Keine Biere eingetragen';
  @override String addBeerFor(String name) => 'Bier hinzufügen für $name';
  @override String addedVolumeFor(String volume, String name) => '$volume hinzugefügt für $name';
  @override String get failedToAddPour => 'Bier konnte nicht hinzugefügt werden';
  @override String get removePourQuestion => 'Bier entfernen?';
  @override String removePourConfirm(String volume) => '$volume Bier entfernen?';
  @override String get pourRemoved => 'Bier entfernt';

  // ---- Participant Detail Screen ----
  @override String get consumptionOverTime => 'VERBRAUCH ÜBER ZEIT';
  @override String get estimatedBacOverTime => 'GESCHÄTZTER BAC ÜBER ZEIT';
  @override String get bacDoNotUseForDriving => '⚠ BAC ist nur eine Schätzung — verwenden Sie ihn nicht zur Bestimmung der Fahrtüchtigkeit.';
  @override String get stats => 'STATISTIKEN';
  @override String get beerCount => 'Bieranzahl';
  @override String get volume => 'Volumen';
  @override String get shareOfKeg => 'Fassanteil';
  @override String get avgRateLabel => 'Durchschn. Rate';
  @override String get cost => 'Kosten';
  @override String get estBac => 'Gesch. BAC';
  @override String get estTimeToDrive => 'Gesch. Zeit zum Fahren';

  // ---- Join Session Screen ----
  @override String get youreInvitedToParty => 'Sie sind zu einer Party eingeladen!';
  @override String get visibilitySettings => 'Sichtbarkeitseinstellungen';
  @override String get showMyStats => 'Meine Statistiken zeigen';
  @override String get showBacEstimateJoin => 'BAC-Schätzung zeigen';
  @override String get areYouOneOfGuests => 'Sind Sie einer dieser Gäste?';
  @override String get selectYourselfToMerge => 'Wählen Sie sich aus, um ihre Biere zu übernehmen, oder überspringen.';
  @override String get joinAndMerge => 'Beitreten & Zusammenführen';
  @override String get joinSession => 'Sitzung beitreten';
  @override String get failedToJoin => 'Beitritt fehlgeschlagen';

  // ---- QR Scanner Screen ----
  @override String get pointAtBeererQrCode => 'Auf einen Beerer QR-Code richten';

  // ---- Misc ----
  @override String get guestLower => 'Gast';
  @override String get removeGuestTooltip => 'Gast entfernen';
  @override String get removePourTooltip => 'Ausschank entfernen';
  @override String get ago => 'her';
  @override String get total => 'Gesamt';
  @override String errorWithMessage(String error) => 'Fehler: $error';
}
