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
import 'package:intl/intl.dart';

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
          final unpaid = bills.where((r) => !r.isPaid).toList();
          if (unpaid.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: unpaid.length,
            itemBuilder: (context, index) =>
                _BillCard(reminder: unpaid[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AddBillScreen()),
        ),
        tooltip: 'Add Bill Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bill card
// ---------------------------------------------------------------------------

/// Card displaying a single unpaid bill with countdown, amount, and Mark Paid.
class _BillCard extends ConsumerWidget {
  const _BillCard({required this.reminder});

  final BillReminder reminder;

  /// Computes days until due date (negative means overdue).
  int _daysUntilDue() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final due = DateTime(
      reminder.dueDate.year,
      reminder.dueDate.month,
      reminder.dueDate.day,
    );
    return due.difference(today).inDays;
  }

  /// Returns the urgency colour based on days remaining.
  Color _urgencyColor(int days) {
    if (days < 0) return SanctumTheme.semanticError;
    if (days <= 3) return SanctumTheme.semanticError;
    if (days <= 7) return SanctumTheme.semanticWarning;
    return SanctumTheme.semanticSuccess;
  }

  /// Formats the due date countdown label.
  String _dueDateLabel(int days) {
    if (days < 0) return '${days.abs()}d overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in ${days}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');
    final dateFmt = DateFormat('d MMM yyyy');
    final days = _daysUntilDue();
    final urgencyColor = _urgencyColor(days);
    final dueDateLabel = _dueDateLabel(days);

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
          // Top strip showing urgency bar.
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SanctumTheme.cardRadius),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill name and amount.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bill icon badge.
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        reminder.recurrence == 'monthly'
                            ? Icons.repeat
                            : Icons.receipt_outlined,
                        size: 20,
                        color: urgencyColor,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + recurrence tag.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.name,
                            style: const TextStyle(
                              color: SanctumTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SanctumTheme.backgroundElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  reminder.recurrence,
                                  style: const TextStyle(
                                    color: SanctumTheme.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount (right-aligned).
                    Text(
                      currencyFmt.format(reminder.amount),
                      style: const TextStyle(
                        color: SanctumTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Divider.
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Due date info and Mark Paid button.
                Row(
                  children: [
                    // Days countdown badge.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: urgencyColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dueDateLabel,
                            style: TextStyle(
                              color: urgencyColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFmt.format(reminder.dueDate),
                      style: const TextStyle(
                        color: SanctumTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),

                    // Mark Paid action button.
                    TextButton(
                      onPressed: () => _markPaid(context, ref),
                      style: TextButton.styleFrom(
                        backgroundColor: SanctumTheme.semanticSuccess
                            .withValues(alpha: 0.12),
                        foregroundColor: SanctumTheme.semanticSuccess,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mark Paid'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calls the notifier to mark this reminder as paid.
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

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

/// Empty state shown when all bills are paid or no bills exist yet.
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
              color: SanctumTheme.semanticSuccess.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: SanctumTheme.semanticSuccess,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All bills are paid.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add an upcoming bill reminder.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Error state shown when the bill list fails to load.
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
              'Could not load bill reminders.',
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
