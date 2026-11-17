import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/theme/theme_provider.dart';
import 'package:seerat_un_nabi/core/utils/rtl_helper.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';

/// Shared editorial AppBar providing quick access to language selection,
/// light/dark theme toggle, and reading font-size controls.
class SeerahAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SeerahAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppBar(
      title: Text(title),
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          tooltip: 'زبان / ژبه',
          icon: const Icon(Icons.translate_rounded),
          onPressed: () => _showReadingSettingsSheet(context),
        ),
        IconButton(
          tooltip: 'حروف کا حجم',
          icon: const Icon(Icons.format_size_rounded),
          onPressed: () => _showReadingSettingsSheet(context),
        ),
        IconButton(
          tooltip: isDark ? 'روشن انداز' : 'تاریک انداز',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleLightDark();
          },
        ),
      ],
    );
  }

  void _showReadingSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(readingSettingsProvider);
            final theme = Theme.of(context);
            final activeCode = settings.locale.languageCode;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مطالعے کی ترتیبات',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('زبان کا انتخاب', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RtlHelper.supportedLocales.map((locale) {
                      final code = locale.languageCode;
                      return ChoiceChip(
                        label: Text(RtlHelper.nativeLabelForCode(code)),
                        selected: activeCode == code,
                        onSelected: (_) {
                          ref
                              .read(readingSettingsProvider.notifier)
                              .setLocale(locale);
                        },
                      );
                    }).toList(growable: false),
                  ),
                  if (activeCode != AppConstants.defaultLanguageCode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'غیر مترجم حصے خودکار طور پر مستند اردو متن میں دکھائے جائیں گے۔',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('حروف کا حجم', style: theme.textTheme.titleMedium),
                      Text(
                        '${settings.fontSize.toInt()} pt',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Slider(
                    min: AppConstants.minReadingFontSize,
                    max: AppConstants.maxReadingFontSize,
                    divisions: 7,
                    value: settings.fontSize,
                    onChanged: (value) {
                      ref
                          .read(readingSettingsProvider.notifier)
                          .setFontSize(value);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
