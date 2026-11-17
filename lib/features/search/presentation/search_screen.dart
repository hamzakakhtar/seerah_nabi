import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/features/search/domain/search_models.dart';
import 'package:seerat_un_nabi/features/search/presentation/search_provider.dart';
import 'package:seerat_un_nabi/features/search/presentation/widgets/search_result_card.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Offline SQLite search screen across Seerah chapters, historical claims,
/// timeline events, primary sources, locations, and pronunciation entries.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  static const List<String> _suggestedQueries = <String>[
    'عام الفیل',
    'قریش',
    'حلیمہ',
    'ابواء',
    'ابن ہشام',
    'مکہ',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    ref.read(searchFilterProvider.notifier).updateQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);
    final showReliabilityFilters = filter.category == SearchCategory.all ||
        filter.category == SearchCategory.claims ||
        filter.category == SearchCategory.timeline;

    return Scaffold(
      appBar: const SeerahAppBar(title: 'تحقیقی تلاش'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: filter.query.isNotEmpty
                    ? IconButton(
                        tooltip: 'تلاش صاف کریں',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _applyQuery(''),
                      )
                    : null,
                hintText:
                    'ابواب، واقعات، مآخذ، مقامات یا تلفظ تلاش کریں (مثلاً: عام الفیل، ابواء)...',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(searchFilterProvider.notifier).updateQuery(value);
              },
            ),
          ),
          resultsAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'مقامی تلاش مکمل کرنے میں دشواری پیش آئی۔',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            data: (SearchResultsBundle bundle) {
              if (filter.query.trim().isEmpty) {
                return Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.offline_bolt_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'مکمل آف لائن تحقیقی تلاش',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'انٹرنیٹ کے بغیر براہِ راست مقامی SQLite ریکارڈ میں سے ابوابِ سیرت، تاریخی بیانات، زمانی خطِ سیر، قدیم مآخذ، مقامات اور عربی تلفظ تلاش کریں۔ اعراب کے بغیر اردو املا (مثلاً «ابواء» یا «قریش») خودکار طور پر عربی الفاظ سے بھی مطابقت رکھتا ہے۔',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'فوری تلاش کے موضوعات',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedQueries
                            .map(
                              (String topic) => ActionChip(
                                avatar: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                ),
                                label: Text(topic),
                                onPressed: () => _applyQuery(topic),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                );
              }

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Row(
                        children: SearchCategory.values.map((SearchCategory category) {
                          final count = bundle.countFor(category);
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              label: Text('${category.urduLabel} ($count)'),
                              selected: filter.category == category,
                              onSelected: (_) {
                                ref
                                    .read(searchFilterProvider.notifier)
                                    .setCategory(category);
                              },
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                    if (showReliabilityFilters)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('تمام درجاتِ استناد'),
                              selected: filter.reliabilityFilter == null,
                              onSelected: (_) {
                                ref
                                    .read(searchFilterProvider.notifier)
                                    .setReliabilityFilter(null);
                              },
                            ),
                            const SizedBox(width: 8),
                            ...ReliabilityStatus.values
                                .map((ReliabilityStatus status) {
                              return Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 8),
                                child: ChoiceChip(
                                  label: Text(status.urduLabel),
                                  selected: filter.reliabilityFilter == status,
                                  onSelected: (_) {
                                    ref
                                        .read(searchFilterProvider.notifier)
                                        .setReliabilityFilter(status);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                      child: Text(
                        '${bundle.items.length} نتائج موصول ہوئے',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: bundle.items.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.manage_search_rounded,
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '«${filter.query}» کے مطابق کوئی ریکارڈ نہیں ملا۔',
                                      style: theme.textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'الفاظ تبدیل کر کے دیکھیں یا اوپر سے زمرہ «تمام نتائج» منتخب کریں۔',
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                              itemCount: bundle.items.length,
                              itemBuilder: (context, index) {
                                final item = bundle.items[index];
                                return SearchResultCard(
                                  item: item,
                                  onTap: () => context.push(item.routePath),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
