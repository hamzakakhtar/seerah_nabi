import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';

/// Quick-access grid connecting to Phase 2–10 research & reading modules.
class ResearchToolsGrid extends StatelessWidget {
  const ResearchToolsGrid({super.key});

  static const List<_ToolDestination> _tools = <_ToolDestination>[
    _ToolDestination(
      labelUrdu: 'شواہد و اسناد',
      icon: Icons.verified_outlined,
      route: RouteNames.evidenceExplorer,
    ),
    _ToolDestination(
      labelUrdu: 'زمانی خطِ سیر',
      icon: Icons.timeline_rounded,
      route: RouteNames.timeline,
    ),
    _ToolDestination(
      labelUrdu: 'تاریخی نقشے',
      icon: Icons.map_outlined,
      route: RouteNames.historicalMaps,
    ),
    _ToolDestination(
      labelUrdu: 'تقابلِ روایات',
      icon: Icons.compare_arrows_rounded,
      route: RouteNames.narrationComparison,
    ),
    _ToolDestination(
      labelUrdu: 'عربی مآخذ',
      icon: Icons.library_books_outlined,
      route: RouteNames.sourceViewer,
    ),
    _ToolDestination(
      labelUrdu: 'تلفظ رہنما',
      icon: Icons.record_voice_over_outlined,
      route: RouteNames.pronunciation,
    ),
    _ToolDestination(
      labelUrdu: 'روزمرہ سیرت',
      icon: Icons.today_outlined,
      route: RouteNames.dailySeerah,
    ),
    _ToolDestination(
      labelUrdu: 'نشانِ مطالعہ',
      icon: Icons.bookmarks_outlined,
      route: RouteNames.bookmarks,
    ),
    _ToolDestination(
      labelUrdu: 'ذاتی حواشی',
      icon: Icons.edit_note_rounded,
      route: RouteNames.personalNotes,
    ),
    _ToolDestination(
      labelUrdu: 'رفتارِ مطالعہ',
      icon: Icons.auto_stories_outlined,
      route: RouteNames.readingProgress,
    ),
    _ToolDestination(
      labelUrdu: 'تلاش',
      icon: Icons.search_rounded,
      route: RouteNames.search,
    ),
    _ToolDestination(
      labelUrdu: 'تحقیقی معاون',
      icon: Icons.psychology_alt_outlined,
      route: RouteNames.askAi,
    ),
    _ToolDestination(
      labelUrdu: 'تاریخِ تحقیق',
      icon: Icons.history_edu_outlined,
      route: RouteNames.researchHistory,
    ),
    _ToolDestination(
      labelUrdu: 'علمی نظرِ ثانی',
      icon: Icons.fact_check_outlined,
      route: RouteNames.scholarReview,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tools.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(tool.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tool.icon,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool.labelUrdu,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolDestination {
  const _ToolDestination({
    required this.labelUrdu,
    required this.icon,
    required this.route,
  });

  final String labelUrdu;
  final IconData icon;
  final String route;
}
