/// Tests for the BillReminder data model.
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

import 'package:sanctum/models/bill_reminder.dart';

void main() {
  group('BillReminder', () {
    final base = BillReminder(
      id: 'r-001',
      name: 'Netflix',
      amount: 22.99,
      dueDate: DateTime(2026, 5, 1),
      recurrence: 'monthly',
      isPaid: false,
    );

    test('copyWith sets isPaid', () {
      final paid = base.copyWith(isPaid: true);
      expect(paid.isPaid, isTrue);
      expect(paid.name, 'Netflix');
    });

    test('copyWith advances dueDate', () {
      final next = base.copyWith(
        id: 'r-002',
        dueDate: DateTime(2026, 6, 1),
        isPaid: false,
      );
      expect(next.dueDate, DateTime(2026, 6, 1));
      expect(next.id, 'r-002');
    });
  });
}
