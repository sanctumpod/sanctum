/// Tests for the Transaction data model.
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

import 'package:flutter_test/flutter_test.dart';

import 'package:sanctum/models/transaction.dart';

void main() {
  group('Transaction', () {
    final base = Transaction(
      id: 'abc-123',
      amount: 42.50,
      merchant: 'Woolworths',
      category: 'Groceries',
      date: DateTime(2026, 4, 7),
      notes: 'weekly shop',
    );

    test('copyWith overrides specified fields', () {
      final copy = base.copyWith(amount: 99.0, notes: null);
      expect(copy.id, 'abc-123');
      expect(copy.amount, 99.0);
      expect(copy.notes, isNull);
      expect(copy.merchant, 'Woolworths');
    });

    test('equality is field-based', () {
      final same = Transaction(
        id: 'abc-123',
        amount: 42.50,
        merchant: 'Woolworths',
        category: 'Groceries',
        date: DateTime(2026, 4, 7),
        notes: 'weekly shop',
      );
      expect(base == same, isTrue);
    });
  });
}
