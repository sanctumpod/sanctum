/// Dashboard screen for Sanctum showing spending chart, summary and warnings.
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
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Group 3: Local package imports.
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/providers/dashboard_providers.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The Dashboard tab showing spending chart, summaries, and budget warnings.
class DashboardScreen extends ConsumerWidget {
  /// Creates the Dashboard screen.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dateRangeProvider);
    final spending = ref.watch(spendingByCategoryProvider);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final overBudget = budgetProgress.where((p) => p.isOverBudget).toList();

    // Compute summary figures.
    final totalSpent = spending.values.fold(0.0, (a, b) => a + b);
    final txCount = ref.watch(transactionListProvider).value?.length ?? 0;
    final topCategory = spending.isEmpty
        ? null
        : spending.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Over-budget warning banner.
        if (overBudget.isNotEmpty)
          Card(
            color: SanctumTheme.semanticError.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: overBudget
                    .map(
                      (p) => Text(
                        '⚠️ Budget exceeded in ${p.budget.category}',
                        style: const TextStyle(
                          color: SanctumTheme.semanticError,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Date range toggle using the DateRangeNotifier.set() method.
        _DateRangeToggle(currentRange: range),
        const SizedBox(height: 24),
        // Spending pie chart or empty state.
        spending.isEmpty
            ? const Center(
                child: Text('No spending data for this period.'),
              )
            : SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: spending.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        title: '${e.key}\n\$${e.value.toStringAsFixed(0)}',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: SanctumTheme.textPrimary,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  ),
                ),
              ),
        const SizedBox(height: 24),
        // Summary cards row.
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Spent',
                value: '\$${totalSpent.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Transactions',
                value: '$txCount',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Top Category',
                value: topCategory ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Toggle widget for switching the dashboard date range.
class _DateRangeToggle extends ConsumerWidget {
  /// Creates a [_DateRangeToggle] with the given [currentRange].
  const _DateRangeToggle({required this.currentRange});

  /// The currently selected date range.
  final DateRange currentRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<DateRange>(
      segments: const [
        ButtonSegment(
          value: DateRange.thisMonth,
          label: Text('This Month'),
        ),
        ButtonSegment(
          value: DateRange.lastMonth,
          label: Text('Last Month'),
        ),
        ButtonSegment(
          value: DateRange.allTime,
          label: Text('All Time'),
        ),
      ],
      selected: {currentRange},
      onSelectionChanged: (selection) {
        // Use the notifier's set() method to update the active range.
        ref.read(dateRangeProvider.notifier).set(selection.first);
      },
    );
  }
}

/// A small metric card used in the Dashboard summary row.
class _SummaryCard extends StatelessWidget {
  /// Creates a [_SummaryCard] with a [label] and [value].
  const _SummaryCard({required this.label, required this.value});

  /// The metric label shown below the value.
  final String label;

  /// The metric value displayed prominently.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
