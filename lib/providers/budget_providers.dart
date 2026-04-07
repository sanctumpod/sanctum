/// Riverpod providers for Budget state management.
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

// Group 3: Local package imports.
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/budget_progress.dart';
import 'package:sanctum/providers/pod_service_provider.dart';
import 'package:sanctum/providers/transaction_providers.dart';

/// Manages the list of budgets loaded from the user's Pod.
///
/// Invalidates itself after every mutation so the UI stays in sync.
class BudgetListNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() =>
      ref.read(podServiceProvider).loadAllBudgets();

  /// Saves [budget] to the Pod and refreshes the list.
  Future<void> add(Budget budget) async {
    await ref.read(podServiceProvider).saveBudget(budget);
    ref.invalidateSelf();
  }

  /// Deletes the budget with [id] from the Pod and refreshes the list.
  Future<void> delete(String id) async {
    await ref.read(podServiceProvider).deleteBudget(id);
    ref.invalidateSelf();
  }
}

/// Provides the async list of all budgets for the current user.
final budgetListProvider =
    AsyncNotifierProvider<BudgetListNotifier, List<Budget>>(
  BudgetListNotifier.new,
);

/// Joins each [Budget] with the total spending in its category and month.
///
/// Invalidates automatically when either [budgetListProvider] or
/// [transactionListProvider] changes.
final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetListProvider).value ?? [];
  final transactions = ref.watch(transactionListProvider).value ?? [];

  return budgets.map((b) {
    final spent = transactions
        .where(
          (tx) =>
              tx.category == b.category &&
              tx.date.toIso8601String().substring(0, 7) == b.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
    return BudgetProgress(budget: b, spent: spent);
  }).toList();
});
