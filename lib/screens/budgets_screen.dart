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
    // Watch load/error state from the async notifier.
    final asyncBudgets = ref.watch(budgetListProvider);
    // Derived list of budgets with computed spend totals.
    final progressList = ref.watch(budgetProgressProvider);

    return Scaffold(
      body: asyncBudgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(budgetListProvider),
        ),
        data: (_) {
          if (progressList.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: progressList.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _BudgetCard(progress: progressList[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddBudgetScreen(),
          ),
        ),
        tooltip: 'Set Budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Empty state shown when the user has no budgets yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to set your first monthly budget.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Error state shown when the budget list fails to load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  /// The raw error message for debugging context.
  final String message;

  /// Callback invoked when the user presses Retry.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: SanctumTheme.semanticError),
            const SizedBox(height: 12),
            Text(
              'Could not load budgets.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
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

/// Card displaying a single budget's progress bar and spend summary.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress});

  /// The budget and computed spend data to display.
  final BudgetProgress progress;

  /// Resolves the progress bar colour from the current spend fraction.
  Color _barColour() {
    if (progress.isOverBudget) return SanctumTheme.semanticError;
    if (progress.fraction >= 0.75) return SanctumTheme.semanticWarning;
    return SanctumTheme.semanticSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final budget = progress.budget;
    final barColour = _barColour();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and month header.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.category,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  budget.month,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Colour-coded progress bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(barColour),
              ),
            ),
            const SizedBox(height: 8),
            // Spend summary label.
            Text(
              'Spent \$${progress.spent.toStringAsFixed(2)}'
              ' of \$${budget.monthlyLimit.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: barColour,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
