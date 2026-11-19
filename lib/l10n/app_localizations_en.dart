// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Seerat-un-Nabi ﷺ';

  @override
  String get appSubtitle => 'Research-Based Seerah Study Platform';

  @override
  String get continueReadingPrompt => 'You left your reading here.';

  @override
  String get continueReadingButton => 'Continue Reading';

  @override
  String get chaptersHeading => 'Chapters of Seerah';

  @override
  String get chapterOneTitle => 'Chapter 1: Historical Background';

  @override
  String get chapterTwoTitle => 'Chapter 2: Birth and Early Childhood';

  @override
  String get reliabilityTitle => 'Historical Reliability Legend';

  @override
  String get reliabilityConfirmed => 'Confirmed';

  @override
  String get reliabilityWeak => 'Weak Narration';

  @override
  String get reliabilityDisputed => 'Disputed';

  @override
  String get readingSettings => 'Reading Settings';

  @override
  String get fontSizeLabel => 'Font Size';

  @override
  String get themeToggle => 'Reading Theme';

  @override
  String get phaseOnePlaceholderNote =>
      'Phase 1: Chapter architecture and Urdu typography setup (historical content will be added in later phases).';

  @override
  String get exploreFeaturesHeading => 'Research & Reading Tools';
}
