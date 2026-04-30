/// BillReminder data model for Sanctum.
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

/// A bill reminder tracking an upcoming or recurring payment.
///
/// All field names map directly to RDF predicates in `fin:BillReminder`.
@immutable
class BillReminder {
  /// Creates a [BillReminder] with all required fields.
  const BillReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.recurrence,
    required this.isPaid,
    this.notificationDate,
    this.paidDate,
  });

  /// Unique identifier — UUID v4.
  final String id;

  /// Descriptive name of the bill, e.g. "Netflix".
  final String name;

  /// Amount owed in AUD.
  final double amount;

  /// Date this bill is due.
  final DateTime dueDate;

  /// Either "one-off" or "monthly".
  final String recurrence;

  /// Whether this bill has been marked as paid.
  final bool isPaid;

  /// DateTime the local notification was dispatched. Null until fired.
  final DateTime? notificationDate;

  /// DateTime the user tapped "Mark as Paid". Null until paid.
  final DateTime? paidDate;

  /// Returns a copy of this bill reminder with the given fields replaced.
  BillReminder copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? recurrence,
    bool? isPaid,
    Object? notificationDate = const _Sentinel(),
    Object? paidDate = const _Sentinel(),
  }) {
    return BillReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      isPaid: isPaid ?? this.isPaid,
      notificationDate: notificationDate is _Sentinel
          ? this.notificationDate
          : notificationDate as DateTime?,
      paidDate: paidDate is _Sentinel ? this.paidDate : paidDate as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillReminder &&
          other.id == id &&
          other.name == name &&
          other.amount == amount &&
          other.dueDate == dueDate &&
          other.recurrence == recurrence &&
          other.isPaid == isPaid &&
          other.notificationDate == notificationDate &&
          other.paidDate == paidDate;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        amount,
        dueDate,
        recurrence,
        isPaid,
        notificationDate,
        paidDate,
      );
}

/// Sentinel value to distinguish "field not provided" from "field set to null".
class _Sentinel {
  const _Sentinel();
}
