/// Riverpod provider for financial intelligence analysis.
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
import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/financial_intelligence_service.dart';

/// Provides financial intelligence analysis by combining transactions, budgets, and bills.
///
/// Watches all three data providers and returns an [AsyncValue] wrapping
/// the [FinancialIntelligenceResult] produced by [FinancialIntelligenceService].
/// Propagates loading and error states from any upstream provider.
final financialIntelligenceProvider =
    Provider<AsyncValue<FinancialIntelligenceResult>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final budgetAsync = ref.watch(budgetListProvider);
  final billAsync = ref.watch(billReminderListProvider);

  return txAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (txs) => budgetAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (budgets) => billAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (bills) => AsyncValue.data(
          const FinancialIntelligenceService().analyse(txs, budgets, bills),
        ),
      ),
    ),
  );
});
