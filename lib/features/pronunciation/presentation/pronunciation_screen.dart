import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/pronunciation/domain/pronunciation_entry_model.dart';
import 'package:seerat_un_nabi/features/pronunciation/presentation/pronunciation_provider.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Pronunciation Guide screen helping Urdu readers pronounce classical Arabic
/// names, tribes, and historical places accurately.
class PronunciationScreen extends ConsumerWidget {
  const PronunciationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(pronunciationEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'تلفظ رہنما'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: TextField(
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'عربی یا اردو نام تلاش کریں (مثلاً: ابواء، ثویبہ)...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(pronunciationSearchQueryProvider.notifier)
                    .updateQuery(value);
              },
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'تلفظ رہنما لوڈ کرنے میں دشواری پیش آئی۔',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              data: (List<PronunciationEntryModel> entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'کوئی متعلقہ لفظ نہیں ملا۔',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.termArabic,
                                    style: AppTypography.arabicSource(
                                      color: theme.colorScheme.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                                Chip(label: Text(entry.transliteration)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اردو املا: ${entry.termUrdu}  |  صوتی تقسیم: ${entry.phoneticGuide}',
                              style: theme.textTheme.titleMedium,
                            ),
                            if (entry.urduExplanation.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                entry.urduExplanation,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
