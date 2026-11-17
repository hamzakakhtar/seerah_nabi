import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Phase 1 architectural placeholder screen for modules scheduled in Phases 2–10.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.titleUrdu,
    required this.phaseLabel,
    required this.descriptionUrdu,
    required this.icon,
  });

  final String titleUrdu;
  final String phaseLabel;
  final String descriptionUrdu;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SeerahAppBar(title: titleUrdu),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      titleUrdu,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(label: Text(phaseLabel)),
                    const SizedBox(height: 12),
                    Text(
                      descriptionUrdu,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
