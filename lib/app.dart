import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/router/app_router.dart';
import 'package:seerat_un_nabi/core/theme/app_theme.dart';
import 'package:seerat_un_nabi/core/theme/theme_provider.dart';
import 'package:seerat_un_nabi/core/utils/rtl_helper.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';

/// Root MaterialApp configured with Riverpod, GoRouter, Urdu RTL localization,
/// editorial light/dark themes, and adjustable Urdu typography.
class SeeratUnNabiApp extends ConsumerWidget {
  const SeeratUnNabiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final readingSettings = ref.watch(readingSettingsProvider);

    return MaterialApp.router(
      title: AppConstants.appNameUrdu,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(readingFontSize: readingSettings.fontSize),
      darkTheme: AppTheme.dark(readingFontSize: readingSettings.fontSize),
      themeMode: themeMode,
      locale: readingSettings.locale,
      supportedLocales: RtlHelper.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        return RtlHelper.materialDelegateLocaleFor(locale);
      },
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final direction = RtlHelper.directionForLocale(readingSettings.locale);
        return Directionality(
          textDirection: direction,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
