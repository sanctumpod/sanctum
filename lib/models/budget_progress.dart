/// BudgetProgress helper model for Sanctum.
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

import 'package:flutter/foundation.dart';

import 'package:sanctum/models/budget.dart';

/// Pairs a [Budget] with the current amount spent in its month.
///
/// Computed by [budgetProgressProvider] — not stored on Pod.
@immutable
class BudgetProgress {
  /// Creates a [BudgetProgress] with a budget and the amount already spent.
  const BudgetProgress({
    required this.budget,
    required this.spent,
  });

  /// The budget this progress tracks.
  final Budget budget;

  /// Amount spent so far in [Budget.month] in AUD.
  final double spent;

  /// Fraction of limit spent — clamped to [0.0, 1.0] for progress bars.
  ///
  /// Returns 0.0 if [Budget.monthlyLimit] is zero to avoid division by zero.
  double get fraction {
    if (budget.monthlyLimit <= 0) return 0.0;
    return (spent / budget.monthlyLimit).clamp(0.0, 1.0);
  }

  /// Whether spending has reached or exceeded the monthly limit.
  bool get isOverBudget => spent >= budget.monthlyLimit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetProgress &&
          other.budget == budget &&
          other.spent == spent;

  @override
  int get hashCode => Object.hash(budget, spent);
}
