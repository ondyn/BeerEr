// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override String get appTitle => 'Beerer';
  @override String get tapKeg => 'Narazit sud';
  @override String get untapKeg => 'Odrazit sud';
  @override String get kegDone => 'Sud je prázdný';
  @override String get iGotBeer => 'Mám pivo';
  @override String get pourForSomeone => 'Načepovat někomu';
  @override String get undo => 'Zpět';
  @override String get statistics => 'Statistiky';
  @override String get estimatedBac => 'Odhad BAC';
  @override String get drinkResponsibly => 'Pijte prosím zodpovědně.';
  @override String volumeRemaining(String volume) => '$volume zbývá';

  @override String get kegInformation => 'Informace o sudu';
  @override String get beerInformation => 'Informace o pivu';
  @override String get kegInfo => 'Informace o sudu';
  @override String get beerName => 'Název';
  @override String get alcoholPercent => 'Alkohol %';
  @override String get brewery => 'Pivovar';
  @override String get malt => 'Slad';
  @override String get fermentation => 'Kvašení';
  @override String get beerType => 'Druh';
  @override String get beerGroup => 'Skupina';
  @override String get beerStyle => 'Pivní styl';
  @override String get degreePlato => 'Stupňovitost';
  @override String get totalVolume => 'Celkový objem';
  @override String get price => 'Cena';
  @override String get status => 'Stav';
  @override String get started => 'Zahájeno';

  @override String get home => 'Domů';
  @override String get settings => 'Nastavení';
  @override String get about => 'O aplikaci';
  @override String get profile => 'Profil';
  @override String get myProfile => 'Můj profil';
  @override String get pastSessions => 'Minulé akce';
  @override String get signOut => 'Odhlásit se';

  @override String get beerer => 'Beerer';
  @override String get noKegSessionsYet => 'Zatím žádné akce';
  @override String get tapPlusToCreate => 'Klepněte na + a vytvořte svou první akci!';
  @override String get noActiveKegSessions => 'Žádné aktivní akce';
  @override String get tapPlusToCreateNew => 'Klepněte na + a vytvořte novou akci';
  @override String get joinKegSession => 'Připojit se k akci';
  @override String get newKegSession => 'Nová akce';
  @override String get joinAKegSession => 'Připojit se k akci';
  @override String get pasteInviteLinkOrId => 'Vložte odkaz nebo zadejte ID akce:';
  @override String get inviteLinkHint => 'beerer://join/... nebo ID akce';
  @override String get pasteFromClipboard => 'Vložit ze schránky';
  @override String get scanQrCode => 'Naskenovat QR kód';
  @override String get cancel => 'Zrušit';
  @override String get join => 'Připojit se';
  @override String get invalidLinkOrId => 'Neplatný odkaz nebo ID akce';
  @override String get noPastSessions => 'Žádné minulé akce';
  @override String error(String message) => 'Chyba: $message';
  @override String get notSignedIn => 'Nepřihlášen/a';

  @override String get signIn => 'Přihlásit se';
  @override String get createAccount => 'Vytvořit účet';
  @override String get signInToBeerEr => 'Přihlásit se do Beerer';
  @override String get email => 'E-mail';
  @override String get password => 'Heslo';
  @override String get confirmPassword => 'Potvrzení hesla';
  @override String get pleaseEnterEmail => 'Zadejte prosím svůj e-mail';
  @override String get enterValidEmail => 'Zadejte platný e-mail';
  @override String get pleaseEnterPassword => 'Zadejte prosím své heslo';
  @override String get passwordMinLength => 'Heslo musí mít alespoň 6 znaků';
  @override String get passwordsDoNotMatch => 'Hesla se neshodují';
  @override String get forgotPassword => 'Zapomenuté heslo?';
  @override String get noAccount => 'Nemáte účet? ';
  @override String get registerLink => 'Registrovat ›';
  @override String get alreadyHaveOne => 'Již máte účet? ';
  @override String get signInLink => 'Přihlásit se ›';
  @override String get signInFailed => 'Přihlášení se nezdařilo. Zkuste to prosím znovu.';
  @override String get verifyEmailMessage => 'Ověřte prosím svou e-mailovou adresu. Poslali jsme vám ověřovací odkaz.';
  @override String get accountCreatedVerify => 'Účet vytvořen. Před přihlášením ověřte svůj e-mail.';
  @override String get registrationFailed => 'Registrace se nezdařila. Zkuste to prosím znovu.';
  @override String get emailSignInNotConfigured => 'Přihlašování e-mailem není nakonfigurováno. Kontaktujte prosím správce.';

  @override String get forgotPasswordTitle => 'Zapomenuté heslo?';
  @override String get forgotPasswordSubtitle => 'Zadejte svůj e-mail a my vám pošleme odkaz pro obnovení.';
  @override String get sendResetLink => 'Odeslat odkaz pro obnovení';
  @override String get checkYourEmail => 'Zkontrolujte svůj e-mail';
  @override String resetLinkSent(String email) => 'Na adresu $email jsme poslali odkaz pro obnovení hesla.';
  @override String get backToSignIn => 'Zpět k přihlášení';
  @override String get pleaseEnterValidEmail => 'Zadejte prosím platnou e-mailovou adresu';

  @override String get profileDetails => 'Údaje profilu';
  @override String get nickname => 'Přezdívka';
  @override String get pleaseChooseNickname => 'Zvolte si prosím přezdívku';
  @override String get weightKg => 'Váha (kg)';
  @override String get age => 'Věk';
  @override String get genderLabel => 'Pohlaví:';
  @override String get male => 'Muž';
  @override String get female => 'Žena';
  @override String get bacPrivacyNote => 'ℹ Váha a věk se používají pouze pro odhad BAC na vašem zařízení.';

  @override String get welcomeTagline => 'Sleduj každé pivo.\nVyrovnej každý účet.\nVypij všechny sudy.';
  @override String get splashTagline => 'Počítej každou kapku';

  @override String get editProfile => 'Upravit profil';
  @override String get save => 'Uložit';
  @override String get weight => 'Váha';
  @override String get gender => 'Pohlaví';
  @override String get deleteAccount => 'Smazat účet';
  @override String get showStatsToOthers => 'Zobrazit statistiky ostatním';
  @override String get showBacEstimate => 'Zobrazit odhad BAC';
  @override String get setWeightForBac => 'Pro výpočet BAC nastavte váhu v profilu';
  @override String get sessionHistory => 'Historie akcí';
  @override String get viewHistory => 'Zobrazit historii';
  @override String get privacySettings => 'Nastavení soukromí';

  @override String get notifications => 'Oznámení';
  @override String get display => 'Zobrazení';
  @override String get account => 'Účet';
  @override String get allowPourForMe => 'Povolit ostatním čepovat za mě';
  @override String get allowPourForMeSubtitle => 'Ostatní účastníci mohou zaznamenat pivo za vás';
  @override String get notifyPourForMe => 'Upozornit při načepování za mě';
  @override String get notifyPourForMeSubtitle => 'Dostanete upozornění, když vám někdo načepuje pivo';
  @override String get kegNearlyEmpty => 'Sud je skoro prázdný';
  @override String get readyToDrive => 'Připraven k řízení';
  @override String get readyToDriveSubtitle => 'Upozornění, když váš odhadovaný BAC dosáhne 0';
  @override String get slowdownReminder => 'Připomínka zpomalení';
  @override String get slowdownReminderSubtitle => 'Upozornění, když vaše tempo pití klesne';
  @override String get volumeUnits => 'Jednotky objemu';
  @override String get currencySymbol => 'Symbol měny';
  @override String get decimalSeparator => 'Oddělovač desetinných míst';
  @override String get dotSeparator => 'Tečka (1.5)';
  @override String get commaSeparator => 'Čárka (1,5)';
  @override String get changePassword => 'Změnit heslo';
  @override String get language => 'Jazyk';

  @override String version(String version) => 'Verze $version';
  @override String get aboutDescription => 'Beerer je aplikace pro sledování čepování piva ze sudu na párty. Sledujte každé pivo, zobrazujte statistiky v reálném čase a snadno vyrovnejte náklady.';
  @override String get enjoyUsingBeerer => 'Baví vás Beerer?';
  @override String get buyDeveloperBeer => 'Kupte vývojáři pivo!';
  @override String get tipViaRevolut => 'Přispět přes Revolut';
  @override String get drinkResponsiblyTitle => 'Pijte zodpovědně';
  @override String get drinkResponsiblyBody => 'Odhady BAC jsou pouze informativní a neměly by se používat k posouzení schopnosti řídit. Pijte prosím zodpovědně.';
  @override String get addictionAwareness => 'Pokud tuto aplikaci používáte často, zvažte návštěvu:';
  @override String get addictionCenterEU => 'Centrum závislostí EU';
  @override String get beerTastingQuestion => 'Chcete se naučit degustovat pivo?';
  @override String get privacyPolicy => 'Zásady ochrany osobních údajů';
  @override String get openSourceLicences => 'Open-source licence';

  @override String get shareKegSession => 'Sdílet akci';
  @override String get inviteFriendsToJoin => 'Pozvěte přátele';
  @override String get copyLink => 'Kopírovat odkaz';
  @override String get shareLink => 'Sdílet odkaz';
  @override String get linkCopied => 'Odkaz zkopírován!';
  @override String joinMyKegParty(String link) => 'Připoj se k mé párty! $link';

  @override String get exportToSettleUp => 'Exportovat do Settle Up';
  @override String get reviewBillSplit => 'Přehled rozúčtování';
  @override String get noJointAccountsFound => 'Nenalezeny žádné společné účty. Budou exportovány individuální náklady.';
  @override String membersCount(int count) => '$count členů';
  @override String totalWithAmount(String amount) => 'Celkem: $amount';
  @override String get settleUpInfo => 'ℹ Settle Up vytvoří skupinu s těmito částkami.';
  @override String get exportedSuccessfully => 'Úspěšně exportováno do Settle Up!';
  @override String exportFailed(String error) => 'Export se nezdařil: $error';
  @override String get sessionNotFound => 'Akce nenalezena';

  @override String newKegSessionStep(int step) => 'Nová relace sudu  $step/2';
  @override String get searchBeerOnBeerWeb => 'Hledat pivo na BeerWeb…';
  @override String get egKozel => 'např. Kozel';
  @override String get egPilsnerUrquell => 'např. Pilsner Urquell';
  @override String get pleaseEnterBeerName => 'Zadejte název piva';
  @override String get beerDetailsOptional => 'Detaily piva (volitelné)';
  @override String get alcoholContentPercent => 'Obsah alkoholu (%)';
  @override String get egAlcohol => 'např. 5,0';
  @override String get egBrewery => 'např. Plzeňský Prazdroj';
  @override String get egMalt => 'např. ječný';
  @override String get egFermentation => 'např. Spodní kvašení';
  @override String get type => 'Druh';
  @override String get egType => 'např. Světlé';
  @override String get group => 'Skupina';
  @override String get egGroup => 'např. Plné';
  @override String get egBeerStyle => 'např. Pale Ale';
  @override String get egDegreePlato => 'např. 12';
  @override String get next => 'Další →';
  @override String get back => '← Zpět';
  @override String get kegVolumeLitres => 'Objem sudu (litry)';
  @override String get orEnterCustomVolume => 'Nebo zadejte vlastní objem';
  @override String get egVolume => 'např. 25';
  @override String kegPriceLabel(String currency) => 'Cena sudu ($currency)';
  @override String get enterValidNumber => 'Zadejte platné číslo';
  @override String get predefinedPourSizes => 'Předdefinované objemy';
  @override String get tapToRemove => 'Klepněte × pro odebrání';
  @override String get addChip => '+ Přidat';
  @override String get createSession => 'Vytvořit akci';
  @override String failedToCreateSession(String error) => 'Nepodařilo se vytvořit relaci: $error';
  @override String get addPourSize => 'Přidat objem';
  @override String get volumeMl => 'Objem (ml)';
  @override String get egPourSize => 'např. 500';
  @override String get add => 'Přidat';

  @override String get logPourForYou => 'Zaznamenat pivo pro vás';
  @override String get orEnterManually => 'Nebo zadejte ručně:';
  @override String get logPour => 'Zaznamenat';

  @override String get checkInboxToVerify => 'Zkontrolujte doručenou poštu a ověřte svůj e-mail.';
  @override String get resend => 'Poslat znovu';
  @override String get chooseAvatar => 'Vyberte avatar';

  @override String estBacValue(String value) => 'Odhad BAC: $value ‰';
  @override String readyToDriveIn(String duration) => 'Připraven k řízení za ~$duration';

  @override String get statusCreated => 'Vytvořen';
  @override String get statusReady => 'Připraven';
  @override String get statusActive => 'Aktivní';
  @override String get statusPaused => 'Pozastaven';
  @override String get statusDone => 'Dokončen';
  @override String percentLeft(String percent) => '$percent zbývá';
  @override String peopleDuration(int count, String duration) => '$count lidí · $duration';

  @override String get myJointAccount => 'Můj společný účet';
  @override String get jointAccounts => 'Společné účty';
  @override String get members => 'Členové';
  @override String get youSuffix => ' (vy)';
  @override String get addMember => 'Přidat člena';
  @override String get leaveAccount => 'Opustit účet';
  @override String get createANewGroup => 'Vytvořit novou skupinu';
  @override String get groupNameHint => 'Název skupiny (např. "Rodina Nováků")';
  @override String get createGroup => 'Vytvořit skupinu';
  @override String get orJoinExistingGroup => 'Nebo se připojte ke stávající skupině';
  @override String memberCount(int count) => '$count člen(ů)';
  @override String get alreadyInGroup => 'Již jste ve skupině.';
  @override String get leaveCurrentGroupFirst => 'Nejprve musíte opustit svou aktuální skupinu.';
  @override String failedToCreateGroup(String error) => 'Vytvoření skupiny se nezdařilo: $error';
  @override String get allParticipantsInGroup => 'Všichni účastníci jsou již ve skupině.';
  @override String get userAlreadyInAnotherGroup => 'Tento uživatel je již v jiné skupině.';

  @override String get guest => 'Host';
  @override String get english => 'English';
  @override String get czech => 'Čeština';
  @override String get german => 'Deutsch';

  // ---- Keg Detail Screen ----
  @override String get sessionReady => 'RELACE PŘIPRAVENA';
  @override String get tapTheKegToStart => 'Načepujte sud a začněte!';
  @override String get kegIsUntapped => 'Sud je odpojen';
  @override String get pouringDisabled => 'Čepování je zakázáno.';
  @override String get tapKegAgain => 'Znovu načepovat';
  @override String get sessionComplete => 'RELACE DOKONČENA';
  @override String get finalStats => 'Konečné statistiky';
  @override String get totalKegTime => 'Celkový čas sudu';
  @override String get totalPoured => 'Celkem načepováno';
  @override String get pureAlcohol => 'Čistý alkohol';
  @override String get participantsLabel => 'Účastníci';
  @override String get myTotal => 'Můj celkem';
  @override String get kegPriceLabel2 => 'Cena sudu';
  @override String get billSplit => 'Rozdělení účtu';
  @override String get basedOnActualConsumption => 'Na základě skutečné spotřeby';
  @override String get reviewBill => 'Zkontrolovat účet';
  @override String get kegLevel => 'STAV SUDU';
  @override String get remaining => 'zbývá';
  @override String get untilEmpty => 'do prázdna';
  @override String get myStats => 'Moje statistiky';
  @override String get currentBeer => 'Aktuální pivo';
  @override String get sinceLast => 'Od posledního';
  @override String get avgRate => 'Prům. tempo';
  @override String get myVolume => 'Můj objem';
  @override String get beers => 'Piv';
  @override String get bacEstimate => 'Odhad BAC';
  @override String get driveIn => 'Řídit za';
  @override String get bacEstimateWarning => '⚠ BAC je pouze odhad — skutečné hodnoty se mohou lišit.';
  @override String get pourLogged => 'Pivo zaznamenáno!';
  @override String pourFailed(String error) => 'Čepování selhalo: $error';
  @override String pourForNickname(String nickname) => 'Čepovat pro $nickname';
  @override String pouredForNickname(String nickname) => 'Načepováno pro $nickname!';
  @override String get accountsBills => 'Účty / Vyúčtování';
  @override String get joinCreateAccount => 'Připojit / Vytvořit účet';
  @override String get addGuest => 'Přidat hosta';
  @override String get guestName => 'Jméno hosta';
  @override String get removeGuest => 'Odebrat hosta';
  @override String removeGuestConfirm(String nickname) => 'Odebrat "$nickname" a všechna jejich piva z této relace?';
  @override String get remove => 'Odebrat';
  @override String get markKegAsDoneQuestion => 'Označit sud jako dokončený?';
  @override String get sessionReadOnlyWarning => 'Relace bude pouze pro čtení. Nelze to vrátit.';
  @override String get deleteSessionQuestion => 'Smazat relaci?';
  @override String get deleteSessionWarning => 'Toto trvale smaže relaci sudu. Nelze to vrátit.';
  @override String get delete => 'Smazat';
  @override String get shareJoinLink => 'Sdílet odkaz';
  @override String get editSession => 'Upravit relaci';
  @override String get untapUnfinishedKeg => 'Odpojit nedokončený sud';
  @override String get markKegAsDone => 'Označit sud jako dokončený';
  @override String pourForDisabled(String name) => '$name zakázal/a „Čepovat za mě".';
  @override String get solo => 'sólo';

  // ---- Bill Review Screen ----
  @override String get pours => 'Čepování';
  @override String get drinkers => 'Pijáci';
  @override String get totalConsumed => 'Celkem spotřebováno';
  @override String get noPours => 'Žádná piva';
  @override String addBeerFor(String name) => 'Přidat pivo pro $name';
  @override String addedVolumeFor(String volume, String name) => 'Přidáno $volume pro $name';
  @override String get failedToAddPour => 'Nepodařilo se přidat pivo';
  @override String get removePourQuestion => 'Odebrat pivo?';
  @override String removePourConfirm(String volume) => 'Odebrat $volume piva?';
  @override String get pourRemoved => 'Pivo odebráno';

  // ---- Participant Detail Screen ----
  @override String get consumptionOverTime => 'SPOTŘEBA V ČASE';
  @override String get estimatedBacOverTime => 'ODHADOVANÉ BAC V ČASE';
  @override String get bacDoNotUseForDriving => '⚠ BAC je pouze odhad — nepoužívejte jej k určení způsobilosti k řízení.';
  @override String get stats => 'STATISTIKY';
  @override String get beerCount => 'Počet piv';
  @override String get volume => 'Objem';
  @override String get shareOfKeg => 'Podíl sudu';
  @override String get avgRateLabel => 'Prům. tempo';
  @override String get cost => 'Cena';
  @override String get estBac => 'Odh. BAC';
  @override String get estTimeToDrive => 'Odh. čas k řízení';

  // ---- Join Session Screen ----
  @override String get youreInvitedToParty => 'Jste pozváni na párty!';
  @override String get visibilitySettings => 'Nastavení viditelnosti';
  @override String get showMyStats => 'Zobrazit mé statistiky';
  @override String get showBacEstimateJoin => 'Zobrazit odhad BAC';
  @override String get areYouOneOfGuests => 'Jste jedním z těchto hostů?';
  @override String get selectYourselfToMerge => 'Vyberte se pro převzetí jejich piv, nebo přeskočte.';
  @override String get joinAndMerge => 'Připojit a sloučit';
  @override String get joinSession => 'Připojit se k relaci';
  @override String get failedToJoin => 'Připojení selhalo';

  // ---- QR Scanner Screen ----
  @override String get pointAtBeererQrCode => 'Zamiřte na Beerer QR kód';

  // ---- Misc ----
  @override String get guestLower => 'host';
  @override String get removeGuestTooltip => 'Odebrat hosta';
  @override String get removePourTooltip => 'Odebrat pivo';
  @override String get ago => 'zpět';
  @override String get total => 'Celkem';
  @override String errorWithMessage(String error) => 'Chyba: $error';

  // ---- Refactored UI ----
  @override String get pourBeer => 'Nalít pivo';
  @override String get addPerson => 'Přidat osobu';
  @override String get removeFromSession => 'Odebrat ze session';
  @override String removeFromSessionConfirm(String nickname) => 'Odebrat "$nickname" a všechna jeho piva z této session?';
  @override String get guestDetail => 'Detail hosta';
}
