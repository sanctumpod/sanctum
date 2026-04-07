/// Unit tests for PodService Turtle serializers and parsers.
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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter_test/flutter_test.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/services/pod_service.dart';

void main() {
  final svc = PodService();

  group('Transaction Turtle round-trip', () {
    final tx = Transaction(
      id: 'test-uuid-001',
      amount: 50.00,
      merchant: 'Woolworths',
      category: 'Groceries',
      date: DateTime(2026, 2, 24),
      notes: 'weekly shop',
    );

    test('encode then decode produces identical Transaction', () {
      final turtle = svc.testTransactionToTurtle(tx);
      final decoded = svc.testTransactionFromTurtle(turtle);
      expect(decoded.id, tx.id);
      expect(decoded.amount, tx.amount);
      expect(decoded.merchant, tx.merchant);
      expect(decoded.category, tx.category);
      expect(
        decoded.date.toIso8601String().substring(0, 10),
        tx.date.toIso8601String().substring(0, 10),
      );
      expect(decoded.notes, tx.notes);
    });

    test('null notes round-trips correctly', () {
      final noNotes = tx.copyWith(notes: null);
      final turtle = svc.testTransactionToTurtle(noNotes);
      final decoded = svc.testTransactionFromTurtle(turtle);
      expect(decoded.notes, isNull);
    });
  });

  group('Budget Turtle round-trip', () {
    const budget = Budget(
      id: 'b-uuid-001',
      category: 'Groceries',
      monthlyLimit: 500.0,
      month: '2026-04',
    );

    test('encode then decode produces identical Budget', () {
      final turtle = svc.testBudgetToTurtle(budget);
      final decoded = svc.testBudgetFromTurtle(turtle);
      expect(decoded.id, budget.id);
      expect(decoded.category, budget.category);
      expect(decoded.monthlyLimit, budget.monthlyLimit);
      expect(decoded.month, budget.month);
    });
  });

  group('BillReminder Turtle round-trip', () {
    final reminder = BillReminder(
      id: 'r-uuid-001',
      name: 'Netflix',
      amount: 22.99,
      dueDate: DateTime(2026, 5, 1),
      recurrence: 'monthly',
      isPaid: false,
    );

    test('encode then decode produces identical BillReminder', () {
      final turtle = svc.testReminderToTurtle(reminder);
      final decoded = svc.testReminderFromTurtle(turtle);
      expect(decoded.id, reminder.id);
      expect(decoded.name, reminder.name);
      expect(decoded.amount, reminder.amount);
      expect(decoded.recurrence, reminder.recurrence);
      expect(decoded.isPaid, isFalse);
    });

    test('isPaid true round-trips correctly', () {
      final paid = reminder.copyWith(isPaid: true);
      final turtle = svc.testReminderToTurtle(paid);
      final decoded = svc.testReminderFromTurtle(turtle);
      expect(decoded.isPaid, isTrue);
    });
  });
}
