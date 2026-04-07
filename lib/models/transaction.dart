/// Transaction data model for Sanctum.
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

/// Represents a single financial transaction recorded in the user's Pod.
///
/// All field names map directly to RDF predicates in `fin:Transaction`.
/// Do not rename fields — they are the serialization contract.
@immutable
class Transaction {
  /// Creates a [Transaction] with all required fields.
  const Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.date,
    this.notes,
  });

  /// Unique identifier — UUID v4.
  final String id;

  /// Transaction amount in AUD — always positive.
  final double amount;

  /// Merchant or payee name, e.g. "Woolworths".
  final String merchant;

  /// Spending category, e.g. "Groceries".
  final String category;

  /// Date the transaction occurred.
  final DateTime date;

  /// Optional free-text note about the transaction.
  final String? notes;

  /// Returns a copy of this transaction with the given fields replaced.
  Transaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? category,
    DateTime? date,
    Object? notes = const _Sentinel(),
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes is _Sentinel ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.amount == amount &&
          other.merchant == merchant &&
          other.category == category &&
          other.date == date &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(id, amount, merchant, category, date, notes);
}

/// Sentinel value to distinguish "notes not provided" from "notes set to null".
class _Sentinel {
  const _Sentinel();
}
