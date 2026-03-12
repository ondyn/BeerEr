// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BeerEr';

  @override
  String get tapKeg => 'Tap Keg';

  @override
  String get untapKeg => 'Untap Keg';

  @override
  String get kegDone => 'Keg Done';

  @override
  String get iGotBeer => 'I Got Beer';

  @override
  String get pourForSomeone => 'Pour for Someone';

  @override
  String get undo => 'Undo';

  @override
  String get statistics => 'Statistics';

  @override
  String get estimatedBac => 'Est. BAC';

  @override
  String get drinkResponsibly => 'Please drink responsibly.';

  @override
  String volumeRemaining(String volume) {
    return '$volume ml remaining';
  }
}
