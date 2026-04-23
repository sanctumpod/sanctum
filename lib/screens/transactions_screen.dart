/// Transactions list screen for Sanctum.
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
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/screens/add_transaction_screen.dart';
import 'package:sanctum/screens/import_csv_screen.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Displays all transactions from the user's Pod with swipe-to-delete.
class TransactionsScreen extends ConsumerWidget {
  /// Creates the Transactions screen.
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Import from CSV button.
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Import CSV',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ImportCsvScreen(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddTransactionScreen(),
          ),
        ),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      body: asyncTransactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorWidget(
          message: e is AppError ? e.userMessage : 'Could not load transactions.',
          onRetry: () => ref.invalidate(transactionListProvider),
        ),
        data: (transactions) => transactions.isEmpty
            ? const _EmptyState()
            : _TransactionList(transactions: transactions),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction list
// ---------------------------------------------------------------------------

/// Scrollable list of transaction tiles grouped by month, with swipe-to-delete.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');
    final monthFmt = DateFormat('MMMM yyyy');
    final dateFmt = DateFormat('d MMM');

    // Build flattened list items: month headers + transaction rows.
    final items = <_ListItem>[];
    String? lastMonth;

    for (final tx in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(tx.date);
      if (monthKey != lastMonth) {
        items.add(_MonthHeader(label: monthFmt.format(tx.date)));
        lastMonth = monthKey;
      }
      items.add(_TxRow(tx: tx));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _MonthHeader) {
          return _MonthSeparator(label: item.label);
        }
        final txRow = item as _TxRow;
        return _TransactionTile(
          tx: txRow.tx,
          currencyFmt: currencyFmt,
          dateFmt: dateFmt,
          onDelete: () => _deleteTransaction(context, ref, txRow.tx.id),
        );
      },
    );
  }

  /// Prompts for confirmation then deletes the transaction with [id].
  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SanctumTheme.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
        ),
        title: const Text('Delete transaction?'),
        content: const Text(
          'This will permanently remove the record from your Pod.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: SanctumTheme.semanticError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(transactionListProvider.notifier).delete(id);
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    }
  }
}

// List item type discriminators.
sealed class _ListItem {}

class _MonthHeader extends _ListItem {
  _MonthHeader({required this.label});
  final String label;
}

class _TxRow extends _ListItem {
  _TxRow({required this.tx});
  final Transaction tx;
}

/// Sticky month label separating groups of transactions.
class _MonthSeparator extends StatelessWidget {
  const _MonthSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SanctumTheme.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// A single transaction tile with swipe-to-delete affordance.
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.currencyFmt,
    required this.dateFmt,
    required this.onDelete,
  });

  final Transaction tx;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final catColor = SanctumTheme.categoryColor(tx.category);
    final catIcon = SanctumTheme.categoryIcon(tx.category);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: SanctumTheme.semanticError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: SanctumTheme.semanticError,
          size: 22,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: SanctumTheme.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SanctumTheme.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Category icon badge.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, size: 18, color: catColor),
              ),
              const SizedBox(width: 12),

              // Merchant and category.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.merchant,
                      style: const TextStyle(
                        color: SanctumTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.category,
                      style: const TextStyle(
                        color: SanctumTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount and date (right-aligned).
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFmt.format(tx.amount),
                    style: const TextStyle(
                      color: SanctumTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFmt.format(tx.date),
                    style: const TextStyle(
                      color: SanctumTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

/// Shown when the transaction list is empty.
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
              Icons.receipt_long_outlined,
              size: 32,
              color: SanctumTheme.accentIndigo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Shown when the provider returns an error, with a retry button.
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.message, required this.onRetry});

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
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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
