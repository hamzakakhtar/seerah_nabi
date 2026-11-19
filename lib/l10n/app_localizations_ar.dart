// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'السيرة النبوية ﷺ';

  @override
  String get appSubtitle => 'منصة علمية موثقة لدراسة السيرة النبوية';

  @override
  String get continueReadingPrompt => 'توقفت عند هذا الموضع في القراءة.';

  @override
  String get continueReadingButton => 'متابعة القراءة';

  @override
  String get chaptersHeading => 'أبواب السيرة';

  @override
  String get chapterOneTitle => 'الباب الأول: الخلفية التاريخية';

  @override
  String get chapterTwoTitle => 'الباب الثاني: المولد والنشأة';

  @override
  String get reliabilityTitle => 'دليل درجات التوثيق التاريخي';

  @override
  String get reliabilityConfirmed => 'ثابت وموثق';

  @override
  String get reliabilityWeak => 'رواية ضعيفة';

  @override
  String get reliabilityDisputed => 'مختلف فيه';

  @override
  String get readingSettings => 'إعدادات القراءة';

  @override
  String get fontSizeLabel => 'حجم الخط';

  @override
  String get themeToggle => 'وضع القراءة';

  @override
  String get phaseOnePlaceholderNote =>
      'المرحلة الأولى: هيكلة الأبواب وضبط الخطوط (سيتم إدراج المحتوى التاريخي في المراحل القادمة).';

  @override
  String get exploreFeaturesHeading => 'أدوات البحث والمطالعة';
}
