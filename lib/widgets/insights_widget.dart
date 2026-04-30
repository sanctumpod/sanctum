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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/providers/financial_intelligence_provider.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Displays a feed of financial insights sorted by severity.
class InsightsFeedWidget extends ConsumerWidget {
  /// Creates an [InsightsFeedWidget].
  const InsightsFeedWidget({super.key});

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
            ...result.insights.map((insight) => _InsightCard(insight: insight)),
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

/// A single insight card with severity-coloured icon and insight text.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final InsightString insight;

  /// Returns the icon for the insight severity.
  IconData _icon() => switch (insight.severity) {
        InsightSeverity.alert => Icons.warning_rounded,
        InsightSeverity.warning => Icons.info_outline_rounded,
        InsightSeverity.info => Icons.check_circle_outline_rounded,
      };

  /// Returns the colour for the insight severity.
  Color _color() => switch (insight.severity) {
        InsightSeverity.alert => SanctumTheme.semanticError,
        InsightSeverity.warning => SanctumTheme.semanticWarning,
        InsightSeverity.info => SanctumTheme.semanticSuccess,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(), color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
