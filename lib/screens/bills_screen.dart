/// Bills screen displaying upcoming unpaid bill reminders for Sanctum.
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
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/screens/add_bill_screen.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Screen listing all unpaid bill reminders with a Mark Paid action.
///
/// Only unpaid reminders are shown. A FAB navigates to [AddBillScreen].
class BillsScreen extends ConsumerWidget {
  /// Creates the Bills screen.
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBills = ref.watch(billReminderListProvider);

    return Scaffold(
      body: asyncBills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(billReminderListProvider),
        ),
        data: (bills) {
          // Only display unpaid reminders.
          final unpaid = bills.where((r) => !r.isPaid).toList();
          if (unpaid.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: unpaid.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _BillCard(reminder: unpaid[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddBillScreen(),
          ),
        ),
        tooltip: 'Add Bill Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Empty state shown when all bills are paid or no bills exist yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: SanctumTheme.semanticSuccess,
          ),
          const SizedBox(height: 16),
          Text(
            'All bills are paid.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add an upcoming bill reminder.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Error state shown when the bill list fails to load.
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: SanctumTheme.semanticError,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load bill reminders.',
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

/// Card displaying a single unpaid bill with amount, due date, and Mark Paid button.
class _BillCard extends ConsumerWidget {
  const _BillCard({required this.reminder});

  /// The bill reminder to display.
  final BillReminder reminder;

  /// Formats [dt] as "DD/MM/YYYY".
  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill name and amount row.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reminder.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '\$${reminder.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: SanctumTheme.semanticError,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Due date and recurrence chip row.
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Due ${_formatDate(reminder.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    reminder.recurrence,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mark Paid action button.
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _markPaid(context, ref),
                child: const Text('Mark Paid'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calls the notifier to mark this reminder as paid.
  ///
  /// Shows an [AppError] SnackBar if the operation fails.
  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(billReminderListProvider.notifier).markPaid(reminder.id);
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    }
  }
}
