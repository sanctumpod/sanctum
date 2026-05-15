/// Insights Feed Widget displaying actionable financial insights.
//
// Time-stamp: <>
//
/// Copyright (C) 2025, Cyrill Adrian Wicaksono
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Cyrill Adrian Wicaksono

library;

// Group 1: Flutter/Dart SDK imports.
import 'dart:math' show min;

import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/providers/financial_intelligence_provider.dart';
import 'package:sanctum/providers/nav_provider.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Displays a feed of up to 5 financial insights sorted by severity.
class InsightsFeedWidget extends ConsumerWidget {
  /// Creates an [InsightsFeedWidget].
  const InsightsFeedWidget({super.key});

  /// Maps an [InsightCategory] to the corresponding [NavIndex] tab index.
  int _tabForCategory(InsightCategory category) => switch (category) {
        InsightCategory.budget => NavIndex.budgets,
        InsightCategory.bills => NavIndex.bills,
        InsightCategory.spending => NavIndex.transactions,
        InsightCategory.general => NavIndex.dashboard,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(financialIntelligenceProvider);

    return asyncResult.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Unable to load insights: $e',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (result) {
        if (result.insights.isEmpty) {
          return const _EmptyInsights();
        }
        // Render-side cap: engine enforces max 5 but guard against regressions.
        final displayInsights =
            result.insights.sublist(0, min(result.insights.length, 5));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...displayInsights.map(
              (insight) => _InsightCard(
                insight: insight,
                onTap: () => ref
                    .read(selectedTabProvider.notifier)
                    .setTab(_tabForCategory(insight.category)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shown when there are no insights to display.
class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No insights available yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// A single insight card with severity-coloured left border, icon, badge, and text.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onTap});

  final InsightString insight;

  /// Called when the card is tapped to navigate to the relevant tab.
  final VoidCallback onTap;

  /// Returns the icon for the insight severity.
  IconData _icon() => switch (insight.severity) {
        InsightSeverity.alert => Icons.error_outline_rounded,
        InsightSeverity.warning => Icons.warning_amber_rounded,
        InsightSeverity.info => Icons.check_circle_outline_rounded,
      };

  /// Returns the colour for the insight severity.
  Color _color() => switch (insight.severity) {
        InsightSeverity.alert => SanctumTheme.semanticError,
        InsightSeverity.warning => SanctumTheme.semanticWarning,
        InsightSeverity.info => SanctumTheme.semanticSuccess,
      };

  /// Returns the display label for the insight category.
  String _categoryLabel() => switch (insight.category) {
        InsightCategory.budget => 'Budget',
        InsightCategory.bills => 'Bills',
        InsightCategory.spending => 'Spending',
        InsightCategory.general => 'General',
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4-px severity-coloured left border stripe.
              Container(
                width: 4,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icon(), color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _categoryLabel(),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              insight.text,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: SanctumTheme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
