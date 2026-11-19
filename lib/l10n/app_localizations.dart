import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ur'),
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ur, this message translates to:
  /// **'سیرت النبی ﷺ'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In ur, this message translates to:
  /// **'تحقیقی و مستند مطالعۂ سیرت'**
  String get appSubtitle;

  /// No description provided for @continueReadingPrompt.
  ///
  /// In ur, this message translates to:
  /// **'آپ یہاں مطالعہ چھوڑ کر گئے تھے۔'**
  String get continueReadingPrompt;

  /// No description provided for @continueReadingButton.
  ///
  /// In ur, this message translates to:
  /// **'مطالعہ جاری رکھیں'**
  String get continueReadingButton;

  /// No description provided for @chaptersHeading.
  ///
  /// In ur, this message translates to:
  /// **'ابوابِ سیرت'**
  String get chaptersHeading;

  /// No description provided for @chapterOneTitle.
  ///
  /// In ur, this message translates to:
  /// **'باب اول: ابتدائی پس منظر'**
  String get chapterOneTitle;

  /// No description provided for @chapterTwoTitle.
  ///
  /// In ur, this message translates to:
  /// **'باب دوم: ولادت و طفولیت'**
  String get chapterTwoTitle;

  /// No description provided for @reliabilityTitle.
  ///
  /// In ur, this message translates to:
  /// **'مستندیت کی علامات'**
  String get reliabilityTitle;

  /// No description provided for @reliabilityConfirmed.
  ///
  /// In ur, this message translates to:
  /// **'ثابت و مستند'**
  String get reliabilityConfirmed;

  /// No description provided for @reliabilityWeak.
  ///
  /// In ur, this message translates to:
  /// **'ضعیف روایت'**
  String get reliabilityWeak;

  /// No description provided for @reliabilityDisputed.
  ///
  /// In ur, this message translates to:
  /// **'مختلف فیہ'**
  String get reliabilityDisputed;

  /// No description provided for @readingSettings.
  ///
  /// In ur, this message translates to:
  /// **'مطالعے کی ترتیبات'**
  String get readingSettings;

  /// No description provided for @fontSizeLabel.
  ///
  /// In ur, this message translates to:
  /// **'حروف کا حجم'**
  String get fontSizeLabel;

  /// No description provided for @themeToggle.
  ///
  /// In ur, this message translates to:
  /// **'اندازِ مطالعہ'**
  String get themeToggle;

  /// No description provided for @phaseOnePlaceholderNote.
  ///
  /// In ur, this message translates to:
  /// **'مرحلہ اول: ابواب کا ڈھانچہ اور اردو خطاطی کی ترتیب (تاریخی متن مرحلہ دوم و سوم میں شامل کیا جائے گا)۔'**
  String get phaseOnePlaceholderNote;

  /// No description provided for @exploreFeaturesHeading.
  ///
  /// In ur, this message translates to:
  /// **'تحقیقی و مطالعاتی سہولیات'**
  String get exploreFeaturesHeading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
