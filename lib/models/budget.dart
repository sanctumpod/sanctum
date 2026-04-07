/// Budget data model for Sanctum.
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

/// A monthly spending budget for a single category.
///
/// All field names map directly to RDF predicates in `fin:Budget`.
@immutable
class Budget {
  /// Creates a [Budget] with all required fields.
  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  /// Unique identifier — UUID v4.
  final String id;

  /// Spending category this budget applies to, e.g. "Groceries".
  final String category;

  /// Maximum spend allowed in [month] in AUD.
  final double monthlyLimit;

  /// ISO year-month string, e.g. "2026-04".
  final String month;

  /// Returns a copy of this budget with the given fields replaced.
  Budget copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          other.id == id &&
          other.category == category &&
          other.monthlyLimit == monthlyLimit &&
          other.month == month;

  @override
  int get hashCode => Object.hash(id, category, monthlyLimit, month);
}
