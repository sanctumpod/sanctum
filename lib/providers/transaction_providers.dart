/// Riverpod providers for Transaction state management.
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

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/pod_service_provider.dart';

/// Manages the list of transactions loaded from the user's Pod.
///
/// Invalidates itself after every mutation so the UI stays in sync.
class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() =>
      ref.read(podServiceProvider).loadAllTransactions();

  /// Saves [tx] to the Pod and refreshes the transaction list.
  Future<void> add(Transaction tx) async {
    await ref.read(podServiceProvider).saveTransaction(tx);
    ref.invalidateSelf();
  }

  /// Saves every transaction in [transactions] to the user's SOLID Pod.
  ///
  /// Each [Transaction] is written as an individual encrypted Turtle file at
  /// `sanctum/transactions/tx_<uuid>.enc.ttl` on the Pod, via
  /// [PodService.saveTransaction]. A fresh UUID v4 is assigned to each
  /// transaction here because the CSV parser produces placeholder empty IDs.
  ///
  /// The provider invalidates itself after all writes so the Transactions
  /// screen immediately re-reads the Pod and shows the newly imported rows.
  ///
  /// Throws [AppError.networkError] on the first failed Pod write.
  Future<void> importMany(List<Transaction> transactions) async {
    const uuid = Uuid();
    final service = ref.read(podServiceProvider);
    for (final tx in transactions) {
      // Assign a real UUID — the parsed tx carries an empty placeholder id.
      await service.saveTransaction(tx.copyWith(id: uuid.v4()));
    }
    ref.invalidateSelf();
  }

  /// Deletes the transaction with [id] from the Pod and refreshes the list.
  Future<void> delete(String id) async {
    await ref.read(podServiceProvider).deleteTransaction(id);
    ref.invalidateSelf();
  }
}

/// Provides the async list of all transactions for the current user.
final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<Transaction>>(
  TransactionListNotifier.new,
);
