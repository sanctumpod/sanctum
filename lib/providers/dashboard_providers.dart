/// Riverpod providers for Dashboard derived state.
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
import 'package:sanctum/providers/transaction_providers.dart';

/// The time range applied to all dashboard aggregations.
enum DateRange {
  /// Only transactions in the current calendar month.
  thisMonth,

  /// Only transactions in the previous calendar month.
  lastMonth,

  /// All transactions regardless of date.
  allTime,
}

/// Notifier that holds the active [DateRange] selection.
///
/// Exposes [set] so widgets can change the selected range.
class DateRangeNotifier extends Notifier<DateRange> {
  @override
  DateRange build() => DateRange.thisMonth;

  /// Updates the active date range to [range].
  void set(DateRange range) => state = range;
}

/// Controls which date range is active on the Dashboard.
///
/// Defaults to [DateRange.thisMonth] on app start.
final dateRangeProvider =
    NotifierProvider<DateRangeNotifier, DateRange>(DateRangeNotifier.new);

/// Aggregates spending by category for the currently selected [DateRange].
///
/// Returns a map of category to total spent. Empty if no transactions exist.
final spendingByCategoryProvider = Provider<Map<String, double>>((ref) {
  final range = ref.watch(dateRangeProvider);
  final transactions = ref.watch(transactionListProvider).value ?? [];
  final now = DateTime.now();

  final filtered = transactions.where((tx) {
    if (range == DateRange.thisMonth) {
      return tx.date.year == now.year && tx.date.month == now.month;
    }
    if (range == DateRange.lastMonth) {
      return now.month == 1
          ? tx.date.year == now.year - 1 && tx.date.month == 12
          : tx.date.year == now.year && tx.date.month == now.month - 1;
    }
    // DateRange.allTime — include all transactions.
    return true;
  });

  final map = <String, double>{};
  for (final tx in filtered) {
    map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
  }
  return map;
});
