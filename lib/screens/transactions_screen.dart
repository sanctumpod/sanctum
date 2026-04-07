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
import 'package:sanctum/services/app_error.dart';

/// Displays all transactions from the user's Pod with swipe-to-delete.
class TransactionsScreen extends ConsumerWidget {
  /// Creates the Transactions screen.
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddTransactionScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: asyncTransactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorWidget(
          message: e is AppError
              ? e.userMessage
              : 'Could not load transactions.',
          onRetry: () => ref.invalidate(transactionListProvider),
        ),
        data: (transactions) => transactions.isEmpty
            ? const _EmptyState()
            : _TransactionList(transactions: transactions),
      ),
    );
  }
}

/// Renders the scrollable list of transaction tiles with swipe-to-delete.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: '\$');
    final dateFmt = DateFormat('d MMM yyyy');

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => _deleteTransaction(context, ref, tx.id),
          child: ListTile(
            leading: Text(
              dateFmt.format(tx.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            title: Text(tx.merchant),
            subtitle: Text(tx.category),
            trailing: Text(
              currencyFmt.format(tx.amount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting the transaction.
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will remove the record from your Pod.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Calls the notifier to delete [id] from the Pod and handles errors.
  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
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

/// Shown when the transaction list is empty.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 64),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add your first transaction.'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
