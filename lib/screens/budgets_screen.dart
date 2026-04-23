/// Budgets screen displaying monthly spending progress for Sanctum.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/budget_progress.dart';
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/screens/add_budget_screen.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Screen showing a progress bar for each budget with colour-coded spend status.
///
/// Green: under 75% — Amber: 75–99% — Red: at or over 100%.
/// A FAB navigates to [AddBudgetScreen] to create new budgets.
class BudgetsScreen extends ConsumerWidget {
  /// Creates the Budgets screen.
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBudgets = ref.watch(budgetListProvider);
    final progressList = ref.watch(budgetProgressProvider);

    return Scaffold(
      body: asyncBudgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(budgetListProvider),
        ),
        data: (_) {
          if (progressList.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: progressList.length,
            itemBuilder: (context, index) =>
                _BudgetCard(progress: progressList[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AddBudgetScreen()),
        ),
        tooltip: 'Set Budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget card
// ---------------------------------------------------------------------------

/// Card displaying a single budget's category icon, progress bar, and amounts.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress});

  final BudgetProgress progress;

  /// Returns the semantic colour for the current spend fraction.
  Color _statusColor() {
    if (progress.isOverBudget) return SanctumTheme.semanticError;
    if (progress.fraction >= 0.75) return SanctumTheme.semanticWarning;
    return SanctumTheme.semanticSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');
    final budget = progress.budget;
    final statusColor = _statusColor();
    final catColor = SanctumTheme.categoryColor(budget.category);
    final catIcon = SanctumTheme.categoryIcon(budget.category);
    final pct = (progress.fraction * 100).round();
    final remaining = budget.monthlyLimit - progress.spent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SanctumTheme.backgroundCard,
        borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        border: Border.all(color: SanctumTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — icon, category/month, percentage badge.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Category icon badge.
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, size: 20, color: catColor),
                ),
                const SizedBox(width: 12),

                // Category name and month.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(
                          color: SanctumTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        budget.month,
                        style: const TextStyle(
                          color: SanctumTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Percentage chip.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress track.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 6,
                backgroundColor: SanctumTheme.backgroundElevated,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Amount row — spent / limit and remaining.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currencyFmt.format(progress.spent)} of '
                  '${currencyFmt.format(budget.monthlyLimit)}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  progress.isOverBudget
                      ? '${currencyFmt.format(progress.spent - budget.monthlyLimit)} over'
                      : '${currencyFmt.format(remaining)} left',
                  style: TextStyle(
                    color: progress.isOverBudget
                        ? SanctumTheme.semanticError
                        : SanctumTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

/// Empty state shown when the user has no budgets yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SanctumTheme.accentIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline,
              size: 32,
              color: SanctumTheme.accentIndigo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No budgets yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to set your first monthly budget.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Error state shown when the budget list fails to load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: SanctumTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load budgets.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
