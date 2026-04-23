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
import 'package:intl/intl.dart';

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

    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Hero spend block — total and date range toggle.
        _HeroSpendCard(
          totalSpent: totalSpent,
          currentRange: range,
          currencyFmt: currencyFmt,
        ),
        const SizedBox(height: 16),

        // Over-budget alerts.
        if (overBudget.isNotEmpty) ...[
          _WarningBanner(overBudget: overBudget),
          const SizedBox(height: 16),
        ],

        // Spending donut chart with legend.
        spending.isEmpty
            ? const _EmptyChartState()
            : _SpendingChartSection(
                spending: spending,
                totalSpent: totalSpent,
                currencyFmt: currencyFmt,
              ),
        const SizedBox(height: 20),

        // Summary stat cards row.
        _SummaryRow(
          totalSpent: totalSpent,
          txCount: txCount,
          topCategory: topCategory,
          currencyFmt: currencyFmt,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero spend card
// ---------------------------------------------------------------------------

/// Large hero block showing the period total and date range toggle.
class _HeroSpendCard extends ConsumerWidget {
  /// Creates the hero spend card.
  const _HeroSpendCard({
    required this.totalSpent,
    required this.currentRange,
    required this.currencyFmt,
  });

  /// The total amount spent in the selected period.
  final double totalSpent;

  /// The currently selected date range.
  final DateRange currentRange;

  /// Currency formatter for the amount display.
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeLabel = switch (currentRange) {
      DateRange.thisMonth => 'This Month',
      DateRange.lastMonth => 'Last Month',
      DateRange.allTime => 'All Time',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SanctumTheme.accentIndigo.withValues(alpha: 0.22),
            SanctumTheme.accentBlue.withValues(alpha: 0.10),
            SanctumTheme.backgroundCard,
          ],
        ),
        borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        border: Border.all(
          color: SanctumTheme.accentIndigo.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label.
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SanctumTheme.accentIndigo,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$rangeLabel · Total Spent',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SanctumTheme.textTertiary,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hero amount.
          Text(
            currencyFmt.format(totalSpent),
            style: const TextStyle(
              color: SanctumTheme.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 20),

          // Date range segmented toggle.
          SegmentedButton<DateRange>(
            showSelectedIcon: false,
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
            onSelectionChanged: (selection) =>
                ref.read(dateRangeProvider.notifier).set(selection.first),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Warning banner
// ---------------------------------------------------------------------------

/// Alert strip shown when one or more budgets are exceeded.
class _WarningBanner extends StatelessWidget {
  /// Creates the warning banner.
  const _WarningBanner({required this.overBudget});

  /// Budget progress items that have exceeded their limit.
  final List<dynamic> overBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SanctumTheme.semanticError.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SanctumTheme.semanticError.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: SanctumTheme.semanticError,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${overBudget.length} budget category '
              '${overBudget.length == 1 ? 'has' : 'have'} exceeded '
              'the monthly limit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SanctumTheme.semanticError,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spending chart section
// ---------------------------------------------------------------------------

/// Donut chart paired with a category legend below it.
class _SpendingChartSection extends StatelessWidget {
  /// Creates the spending chart section.
  const _SpendingChartSection({
    required this.spending,
    required this.totalSpent,
    required this.currencyFmt,
  });

  /// Category → amount map for the selected period.
  final Map<String, double> spending;

  /// Sum of all category amounts.
  final double totalSpent;

  /// Currency formatter used by the legend labels.
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    final entries = spending.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SanctumTheme.backgroundCard,
        borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        border: Border.all(color: SanctumTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Breakdown',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 20),

          // Donut chart with centre total overlay.
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 64,
                    sectionsSpace: 3,
                    sections: entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final color = SanctumTheme.categoryColors[
                          i % SanctumTheme.categoryColors.length];
                      return PieChartSectionData(
                        value: e.value,
                        title: '',
                        radius: 46,
                        color: color,
                      );
                    }).toList(),
                  ),
                ),
                // Center overlay showing the total.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: SanctumTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category legend.
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final category = entry.value.key;
              final amount = entry.value.value;
              final color = SanctumTheme.categoryColors[
                  i % SanctumTheme.categoryColors.length];
              final pct = totalSpent > 0
                  ? (amount / totalSpent * 100).toStringAsFixed(0)
                  : '0';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$category  $pct%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty chart state
// ---------------------------------------------------------------------------

/// Shown when there are no transactions in the selected period.
class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: SanctumTheme.backgroundCard,
        borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        border: Border.all(color: SanctumTheme.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_outlined,
              size: 40,
              color: SanctumTheme.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No spending data for this period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row
// ---------------------------------------------------------------------------

/// Three stat cards displayed side-by-side below the chart.
class _SummaryRow extends StatelessWidget {
  /// Creates the summary row.
  const _SummaryRow({
    required this.totalSpent,
    required this.txCount,
    required this.topCategory,
    required this.currencyFmt,
  });

  /// Total amount spent.
  final double totalSpent;

  /// Number of transactions.
  final int txCount;

  /// Top spending category name, or null if none.
  final String? topCategory;

  /// Currency formatter for the spend total card.
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: SanctumTheme.accentIndigo,
            label: 'Spent',
            value: '\$${totalSpent.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_outlined,
            iconColor: SanctumTheme.accentBlue,
            label: 'Transactions',
            value: '$txCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: topCategory != null
                ? SanctumTheme.categoryIcon(topCategory!)
                : Icons.category_outlined,
            iconColor: topCategory != null
                ? SanctumTheme.categoryColor(topCategory!)
                : SanctumTheme.textTertiary,
            label: 'Top Category',
            value: topCategory ?? '—',
          ),
        ),
      ],
    );
  }
}

/// A single stat card with an icon, numeric value, and label.
class _StatCard extends StatelessWidget {
  /// Creates a stat card.
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  /// The icon shown at the top of the card.
  final IconData icon;

  /// Colour applied to [icon].
  final Color iconColor;

  /// Short descriptor shown below the value.
  final String label;

  /// The metric value displayed prominently.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: SanctumTheme.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SanctumTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          // Value.
          Text(
            value,
            style: const TextStyle(
              color: SanctumTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Label.
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
