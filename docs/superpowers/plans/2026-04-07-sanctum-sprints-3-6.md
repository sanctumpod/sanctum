# Sanctum Sprints 3–6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full data layer (PodService CRUD for Transactions, Budgets, BillReminders), all four UI screens, error handling, and in-code documentation so a user can log in, manage finances, and log out without a crash.

**Architecture:** All RDF/Turtle serialization is strictly isolated inside `PodService` — no other file imports `rdflib`. State is managed via Riverpod `AsyncNotifier` providers. Pod I/O uses `writePod`/`readPod`/`getDirUrl`/`getResourcesInContainer` from `solidpod` (no manifest.ttl, directory listing only). Errors are typed as `AppError` and displayed in `SnackBar` widgets.

**Tech Stack:** Flutter, Riverpod 3.1.0, solidpod 0.10.1, rdflib 0.2.12, fl_chart 0.70.2, intl 0.20.1, uuid 4.5.1, flutter_local_notifications 18.0.1

---

## File Structure

### New files to create

```
lib/
├── models/
│   ├── transaction.dart          # Transaction data class with copyWith + fromMap
│   ├── budget.dart               # Budget data class with copyWith
│   ├── bill_reminder.dart        # BillReminder data class with copyWith
│   └── budget_progress.dart      # BudgetProgress helper (Budget + spent amount)
├── services/
│   ├── app_error.dart            # AppError enum + userMessage extension
│   └── pod_service.dart          # ALL RDF logic — 11 public methods, no rdflib outside here
├── providers/
│   ├── pod_service_provider.dart # podServiceProvider (Provider<PodService>)
│   ├── transaction_providers.dart# TransactionListNotifier + transactionListProvider
│   ├── budget_providers.dart     # BudgetListNotifier + budgetListProvider + budgetProgressProvider
│   ├── bill_providers.dart       # BillReminderListNotifier + billReminderListProvider
│   └── dashboard_providers.dart  # dateRangeProvider + spendingByCategoryProvider
└── screens/
    ├── add_transaction_screen.dart # Transaction entry form
    ├── add_budget_screen.dart      # Budget entry form
    └── add_bill_screen.dart        # BillReminder entry form

test/
├── models/
│   ├── transaction_test.dart
│   ├── budget_test.dart
│   └── bill_reminder_test.dart
└── services/
    └── pod_service_turtle_test.dart  # Turtle encode/decode round-trip tests (no Pod I/O)
```

### Files to modify

```
lib/screens/transactions_screen.dart   # Replace placeholder with full list + FAB
lib/screens/budgets_screen.dart        # Replace placeholder with full budget progress list
lib/screens/bills_screen.dart          # Replace placeholder with bill list + mark-paid
lib/screens/dashboard_screen.dart      # Replace placeholder with chart + summary cards
lib/main.dart                          # Add timezone init for notifications
```

---

## Task 1: Data Models

**Files:**
- Create: `lib/models/transaction.dart`
- Create: `lib/models/budget.dart`
- Create: `lib/models/bill_reminder.dart`
- Create: `lib/models/budget_progress.dart`
- Create: `test/models/transaction_test.dart`
- Create: `test/models/budget_test.dart`
- Create: `test/models/bill_reminder_test.dart`

- [ ] **Step 1: Write failing tests for Transaction**

Create `test/models/transaction_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/models/transaction_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: package:sanctum/models/transaction.dart`

- [ ] **Step 3: Create `lib/models/transaction.dart`**

```dart
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

// Group 1: Flutter/Dart SDK imports.
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
```

- [ ] **Step 4: Write failing tests for Budget**

Create `test/models/budget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/models/budget.dart';

void main() {
  group('Budget', () {
    const base = Budget(
      id: 'b-001',
      category: 'Groceries',
      monthlyLimit: 500.0,
      month: '2026-04',
    );

    test('copyWith overrides specified fields', () {
      final copy = base.copyWith(monthlyLimit: 600.0);
      expect(copy.id, 'b-001');
      expect(copy.monthlyLimit, 600.0);
      expect(copy.month, '2026-04');
    });
  });
}
```

- [ ] **Step 5: Create `lib/models/budget.dart`**

```dart
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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/foundation.dart';

/// A monthly spending budget for a single category.
///
/// All field names map directly to RDF predicates in `fin:Budget`.
@immutable
class Budget {
  /// Creates a [Budget].
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
```

- [ ] **Step 6: Write failing tests for BillReminder**

Create `test/models/bill_reminder_test.dart`:

```dart
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
```

- [ ] **Step 7: Create `lib/models/bill_reminder.dart`**

```dart
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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/foundation.dart';

/// A bill reminder tracking an upcoming or recurring payment.
///
/// All field names map directly to RDF predicates in `fin:BillReminder`.
@immutable
class BillReminder {
  /// Creates a [BillReminder].
  const BillReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.recurrence,
    required this.isPaid,
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

  /// Returns a copy of this reminder with the given fields replaced.
  BillReminder copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? recurrence,
    bool? isPaid,
  }) {
    return BillReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      isPaid: isPaid ?? this.isPaid,
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
          other.isPaid == isPaid;

  @override
  int get hashCode =>
      Object.hash(id, name, amount, dueDate, recurrence, isPaid);
}
```

- [ ] **Step 8: Create `lib/models/budget_progress.dart`**

```dart
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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/foundation.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/budget.dart';

/// Pairs a [Budget] with the current amount spent in its month.
///
/// Computed by [budgetProgressProvider] — not stored on Pod.
@immutable
class BudgetProgress {
  /// Creates a [BudgetProgress].
  const BudgetProgress({required this.budget, required this.spent});

  /// The budget definition.
  final Budget budget;

  /// Total spending in [Budget.category] during [Budget.month].
  final double spent;

  /// Fraction of limit spent — clamped to [0.0, 1.0] for progress bars.
  double get fraction =>
      (spent / budget.monthlyLimit).clamp(0.0, 1.0);

  /// Whether spending has reached or exceeded the monthly limit.
  bool get isOverBudget => spent >= budget.monthlyLimit;
}
```

- [ ] **Step 9: Run all model tests**

```
flutter test test/models/
```

Expected: 4 tests pass, 0 fail.

- [ ] **Step 10: Commit**

```bash
git add lib/models/ test/models/
git commit -m "feat: add Transaction, Budget, BillReminder, BudgetProgress models"
```

---

## Task 2: AppError Enum

**Files:**
- Create: `lib/services/app_error.dart`

- [ ] **Step 1: Create `lib/services/app_error.dart`**

```dart
/// Application-level error types for Sanctum.
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

/// Typed errors returned by [PodService] and surfaced to the UI.
///
/// Throw these instead of raw exceptions so the UI can show human-readable
/// messages without leaking implementation details.
enum AppError implements Exception {
  /// The device has no internet connection or the Pod server is unreachable.
  networkError,

  /// The user's OAuth2 token has expired and they must re-authenticate.
  authExpired,

  /// A requested Pod file was not found — it may have been deleted externally.
  fileNotFound,

  /// A Pod file was found but its Turtle content could not be parsed.
  parseError,

  /// Any other unexpected error.
  unknownError,
}

/// Human-readable messages for each [AppError] value.
extension AppErrorMessage on AppError {
  /// Returns a message suitable for display in a [SnackBar].
  String get userMessage => switch (this) {
        AppError.networkError =>
          'No connection — check your internet and try again.',
        AppError.authExpired =>
          'Session expired — please log in again.',
        AppError.fileNotFound =>
          'Data not found — it may have been deleted.',
        AppError.parseError =>
          'Could not read this record — it may be corrupted.',
        AppError.unknownError =>
          'Something went wrong. Please try again.',
      };
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/app_error.dart
git commit -m "feat: add AppError enum with userMessage extension"
```

---

## Task 3: PodService Skeleton

**Files:**
- Create: `lib/services/pod_service.dart`

- [ ] **Step 1: Create `lib/services/pod_service.dart` with all method stubs**

```dart
/// Pod data access layer for Sanctum — all RDF/Turtle logic lives here.
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
import 'package:flutter/foundation.dart';

// Group 2: Third-party package imports.
import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/services/app_error.dart';

/// Provides CRUD operations for all three financial data types.
///
/// This is the ONLY class that imports [rdflib] or constructs Turtle strings.
/// No other file in the codebase may import rdflib or build Turtle content.
///
/// All methods throw [AppError] on failure — never raw exceptions.
class PodService {
  // ── RDF prefixes ────────────────────────────────────────────────────────────

  static const String _fin = 'http://sanctum.app/finance#';
  static const String _xsd = 'http://www.w3.org/2001/XMLSchema#';

  // ── Transaction ─────────────────────────────────────────────────────────────

  /// Writes [tx] to the Pod as an encrypted Turtle file.
  ///
  /// Creates the `sanctum/transactions/` directory on first write.
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveTransaction(Transaction tx) async {
    throw UnimplementedError();
  }

  /// Reads all transactions from the Pod, sorted newest-first.
  ///
  /// Returns an empty list if the directory does not yet exist.
  /// Skips files that cannot be parsed rather than throwing.
  Future<List<Transaction>> loadAllTransactions() async {
    throw UnimplementedError();
  }

  /// Deletes the transaction with [id] from the Pod.
  ///
  /// Throws [AppError.fileNotFound] if the file does not exist.
  Future<void> deleteTransaction(String id) async {
    throw UnimplementedError();
  }

  // ── Budget ──────────────────────────────────────────────────────────────────

  /// Writes [budget] to the Pod as an encrypted Turtle file.
  ///
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveBudget(Budget budget) async {
    throw UnimplementedError();
  }

  /// Reads all budgets from the Pod.
  ///
  /// Returns an empty list if the directory does not yet exist.
  Future<List<Budget>> loadAllBudgets() async {
    throw UnimplementedError();
  }

  /// Deletes the budget with [id] from the Pod.
  Future<void> deleteBudget(String id) async {
    throw UnimplementedError();
  }

  // ── BillReminder ────────────────────────────────────────────────────────────

  /// Writes [reminder] to the Pod as an encrypted Turtle file.
  ///
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveBillReminder(BillReminder reminder) async {
    throw UnimplementedError();
  }

  /// Reads all bill reminders from the Pod, sorted by due date ascending.
  ///
  /// Returns an empty list if the directory does not yet exist.
  Future<List<BillReminder>> loadAllBillReminders() async {
    throw UnimplementedError();
  }

  /// Overwrites the existing Pod file for [reminder] with new content.
  ///
  /// Used when marking a bill as paid or updating any field.
  Future<void> updateBillReminder(BillReminder reminder) async {
    throw UnimplementedError();
  }

  /// Deletes the bill reminder with [id] from the Pod.
  Future<void> deleteBillReminder(String id) async {
    throw UnimplementedError();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Extracts the value of the first triple whose predicate ends with [pred].
  String _get(Graph g, String pred) =>
      g.triples.firstWhere((t) => t.pre.value.endsWith(pred)).obj.value;

  // Turtle serializers and parsers are added in Tasks 4–6.
}
```

- [ ] **Step 2: Confirm the app still compiles (no runtime errors expected yet)**

```
flutter analyze lib/services/pod_service.dart
```

Expected: no errors (UnimplementedError is fine — it's a stub).

- [ ] **Step 3: Commit**

```bash
git add lib/services/pod_service.dart
git commit -m "feat: add PodService skeleton with all 11 method stubs"
```

---

## Task 4: Transaction Turtle Serializer + Parser

**Files:**
- Modify: `lib/services/pod_service.dart`
- Create: `test/services/pod_service_turtle_test.dart`

- [ ] **Step 1: Write failing round-trip test for Transaction**

Create `test/services/pod_service_turtle_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
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
      expect(decoded.date.toIso8601String().substring(0, 10),
          tx.date.toIso8601String().substring(0, 10));
      expect(decoded.notes, tx.notes);
    });

    test('null notes round-trips correctly', () {
      final noNotes = tx.copyWith(notes: null);
      final turtle = svc.testTransactionToTurtle(noNotes);
      final decoded = svc.testTransactionFromTurtle(turtle);
      expect(decoded.notes, isNull);
    });
  });
}
```

**Note:** We expose `testTransactionToTurtle` and `testTransactionFromTurtle` as `@visibleForTesting` methods to allow unit testing without Pod I/O.

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: FAIL — `testTransactionToTurtle` not defined.

- [ ] **Step 3: Add Transaction serialization to `lib/services/pod_service.dart`**

Add inside the `PodService` class, after `_get`:

```dart
  // ── Transaction serialization ────────────────────────────────────────────────

  /// Serialises [tx] to a Turtle string using the `fin:` namespace.
  ///
  /// The result is written encrypted to the Pod — do not use this format
  /// for plain-text storage.
  String _transactionToTurtle(Transaction tx) {
    final notes = tx.notes ?? '';
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#tx> a fin:Transaction ;
    fin:id       "${tx.id}" ;
    fin:amount   "${tx.amount.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:merchant "${tx.merchant}" ;
    fin:category "${tx.category}" ;
    fin:date     "${tx.date.toIso8601String().substring(0, 10)}"^^xsd:date ;
    fin:notes    "$notes" .
''';
  }

  /// Parses a Turtle string into a [Transaction].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  Transaction _transactionFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      final notes = _get(g, 'notes');
      return Transaction(
        id: _get(g, 'id'),
        amount: double.parse(_get(g, 'amount')),
        merchant: _get(g, 'merchant'),
        category: _get(g, 'category'),
        date: DateTime.parse(_get(g, 'date')),
        notes: notes.isEmpty ? null : notes,
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  // ── Test-visible wrappers (do not call from production code) ─────────────────

  /// Exposed for unit testing only — calls [_transactionToTurtle].
  @visibleForTesting
  String testTransactionToTurtle(Transaction tx) => _transactionToTurtle(tx);

  /// Exposed for unit testing only — calls [_transactionFromTurtle].
  @visibleForTesting
  Transaction testTransactionFromTurtle(String turtle) =>
      _transactionFromTurtle(turtle);
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/pod_service.dart test/services/pod_service_turtle_test.dart
git commit -m "feat: add Transaction Turtle serializer and parser with tests"
```

---

## Task 5: Budget Turtle Serializer + Parser

**Files:**
- Modify: `lib/services/pod_service.dart`
- Modify: `test/services/pod_service_turtle_test.dart`

- [ ] **Step 1: Add failing Budget round-trip test**

Append to the `main()` function in `test/services/pod_service_turtle_test.dart`:

```dart
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
```

Also add the import at the top of the test file:
```dart
import 'package:sanctum/models/budget.dart';
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: FAIL — `testBudgetToTurtle` not defined.

- [ ] **Step 3: Add Budget serialization to `lib/services/pod_service.dart`**

Add inside `PodService` after the Transaction serialization block:

```dart
  // ── Budget serialization ─────────────────────────────────────────────────────

  /// Serialises [budget] to a Turtle string using the `fin:` namespace.
  String _budgetToTurtle(Budget budget) {
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#budget> a fin:Budget ;
    fin:id           "${budget.id}" ;
    fin:category     "${budget.category}" ;
    fin:monthlyLimit "${budget.monthlyLimit.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:month        "${budget.month}" .
''';
  }

  /// Parses a Turtle string into a [Budget].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  Budget _budgetFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      return Budget(
        id: _get(g, 'id'),
        category: _get(g, 'category'),
        monthlyLimit: double.parse(_get(g, 'monthlyLimit')),
        month: _get(g, 'month'),
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  /// Exposed for unit testing only — calls [_budgetToTurtle].
  @visibleForTesting
  String testBudgetToTurtle(Budget budget) => _budgetToTurtle(budget);

  /// Exposed for unit testing only — calls [_budgetFromTurtle].
  @visibleForTesting
  Budget testBudgetFromTurtle(String turtle) => _budgetFromTurtle(turtle);
```

- [ ] **Step 4: Run tests**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/pod_service.dart test/services/pod_service_turtle_test.dart
git commit -m "feat: add Budget Turtle serializer and parser with tests"
```

---

## Task 6: BillReminder Turtle Serializer + Parser

**Files:**
- Modify: `lib/services/pod_service.dart`
- Modify: `test/services/pod_service_turtle_test.dart`

- [ ] **Step 1: Add failing BillReminder round-trip tests**

Append to `main()` in the test file:

```dart
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
```

Add import at top:
```dart
import 'package:sanctum/models/bill_reminder.dart';
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: FAIL — `testReminderToTurtle` not defined.

- [ ] **Step 3: Add BillReminder serialization to `lib/services/pod_service.dart`**

```dart
  // ── BillReminder serialization ───────────────────────────────────────────────

  /// Serialises [reminder] to a Turtle string using the `fin:` namespace.
  String _reminderToTurtle(BillReminder reminder) {
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#reminder> a fin:BillReminder ;
    fin:id         "${reminder.id}" ;
    fin:name       "${reminder.name}" ;
    fin:amount     "${reminder.amount.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:dueDate    "${reminder.dueDate.toIso8601String().substring(0, 10)}"^^xsd:date ;
    fin:recurrence "${reminder.recurrence}" ;
    fin:isPaid     "${reminder.isPaid}"^^xsd:boolean .
''';
  }

  /// Parses a Turtle string into a [BillReminder].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  BillReminder _reminderFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      return BillReminder(
        id: _get(g, 'id'),
        name: _get(g, 'name'),
        amount: double.parse(_get(g, 'amount')),
        dueDate: DateTime.parse(_get(g, 'dueDate')),
        recurrence: _get(g, 'recurrence'),
        isPaid: _get(g, 'isPaid') == 'true',
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  /// Exposed for unit testing only — calls [_reminderToTurtle].
  @visibleForTesting
  String testReminderToTurtle(BillReminder r) => _reminderToTurtle(r);

  /// Exposed for unit testing only — calls [_reminderFromTurtle].
  @visibleForTesting
  BillReminder testReminderFromTurtle(String turtle) =>
      _reminderFromTurtle(turtle);
```

- [ ] **Step 4: Run all tests**

```
flutter test test/services/pod_service_turtle_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/pod_service.dart test/services/pod_service_turtle_test.dart
git commit -m "feat: add BillReminder Turtle serializer and parser with tests"
```

---

## Task 7: Transaction CRUD (Pod I/O)

**Files:**
- Modify: `lib/services/pod_service.dart` — implement `saveTransaction`, `loadAllTransactions`, `deleteTransaction`

- [ ] **Step 1: Implement `saveTransaction`**

Replace the `saveTransaction` stub:

```dart
  @override
  Future<void> saveTransaction(Transaction tx) async {
    try {
      final path = 'sanctum/transactions/tx_${tx.id}.enc.ttl';
      await writePod(path, _transactionToTurtle(tx), encrypted: true);
    } on AppError {
      rethrow;
    } catch (e) {
      debugPrint('saveTransaction error: $e');
      throw AppError.networkError;
    }
  }
```

- [ ] **Step 2: Implement `loadAllTransactions`**

Replace the `loadAllTransactions` stub:

```dart
  @override
  Future<List<Transaction>> loadAllTransactions() async {
    try {
      final dirUrl = await getDirUrl('sanctum/transactions');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <Transaction>[];
      for (final file in (resources.files ?? [])) {
        if (!file.endsWith('.enc.ttl')) continue;
        final content = await readPod('sanctum/transactions/$file');
        // Skip files that could not be read — solidpod returns an error string.
        if (content == null || content.contains('SolidFunctionCallStatus')) {
          continue;
        }
        try {
          results.add(_transactionFromTurtle(content));
        } on AppError {
          // Skip corrupt files — never crash the list.
          debugPrint('Skipping corrupt transaction file: $file');
        }
      }
      // Sort newest-first.
      return results..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (e is AppError) rethrow;
      // Directory does not exist on first launch — return empty list.
      debugPrint('loadAllTransactions: $e');
      return [];
    }
  }
```

- [ ] **Step 3: Implement `deleteTransaction`**

Replace the `deleteTransaction` stub:

```dart
  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await deletePod('sanctum/transactions/tx_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
      throw AppError.networkError;
    }
  }
```

- [ ] **Step 4: Run analyze**

```
flutter analyze lib/services/pod_service.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/pod_service.dart
git commit -m "feat: implement Transaction CRUD in PodService"
```

---

## Task 8: Budget CRUD (Pod I/O)

**Files:**
- Modify: `lib/services/pod_service.dart` — implement `saveBudget`, `loadAllBudgets`, `deleteBudget`

- [ ] **Step 1: Implement Budget CRUD methods**

Replace the three Budget stubs:

```dart
  @override
  Future<void> saveBudget(Budget budget) async {
    try {
      final path = 'sanctum/budgets/budget_${budget.id}.enc.ttl';
      await writePod(path, _budgetToTurtle(budget), encrypted: true);
    } catch (e) {
      debugPrint('saveBudget error: $e');
      throw AppError.networkError;
    }
  }

  @override
  Future<List<Budget>> loadAllBudgets() async {
    try {
      final dirUrl = await getDirUrl('sanctum/budgets');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <Budget>[];
      for (final file in (resources.files ?? [])) {
        if (!file.endsWith('.enc.ttl')) continue;
        final content = await readPod('sanctum/budgets/$file');
        if (content == null || content.contains('SolidFunctionCallStatus')) {
          continue;
        }
        try {
          results.add(_budgetFromTurtle(content));
        } on AppError {
          debugPrint('Skipping corrupt budget file: $file');
        }
      }
      return results;
    } catch (e) {
      debugPrint('loadAllBudgets: $e');
      return [];
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await deletePod('sanctum/budgets/budget_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteBudget error: $e');
      throw AppError.networkError;
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/pod_service.dart
git commit -m "feat: implement Budget CRUD in PodService"
```

---

## Task 9: BillReminder CRUD (Pod I/O)

**Files:**
- Modify: `lib/services/pod_service.dart` — implement `saveBillReminder`, `loadAllBillReminders`, `updateBillReminder`, `deleteBillReminder`

- [ ] **Step 1: Implement BillReminder CRUD methods**

Replace the four BillReminder stubs:

```dart
  @override
  Future<void> saveBillReminder(BillReminder reminder) async {
    try {
      final path = 'sanctum/reminders/reminder_${reminder.id}.enc.ttl';
      await writePod(path, _reminderToTurtle(reminder), encrypted: true);
    } catch (e) {
      debugPrint('saveBillReminder error: $e');
      throw AppError.networkError;
    }
  }

  @override
  Future<List<BillReminder>> loadAllBillReminders() async {
    try {
      final dirUrl = await getDirUrl('sanctum/reminders');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <BillReminder>[];
      for (final file in (resources.files ?? [])) {
        if (!file.endsWith('.enc.ttl')) continue;
        final content = await readPod('sanctum/reminders/$file');
        if (content == null || content.contains('SolidFunctionCallStatus')) {
          continue;
        }
        try {
          results.add(_reminderFromTurtle(content));
        } on AppError {
          debugPrint('Skipping corrupt reminder file: $file');
        }
      }
      // Sort by due date ascending so soonest bill is first.
      return results..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      debugPrint('loadAllBillReminders: $e');
      return [];
    }
  }

  @override
  Future<void> updateBillReminder(BillReminder reminder) async {
    // updateBillReminder overwrites the same path as save — identical impl.
    await saveBillReminder(reminder);
  }

  @override
  Future<void> deleteBillReminder(String id) async {
    try {
      await deletePod('sanctum/reminders/reminder_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteBillReminder error: $e');
      throw AppError.networkError;
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/pod_service.dart
git commit -m "feat: implement BillReminder CRUD in PodService"
```

---

## Task 10: PodService Provider

**Files:**
- Create: `lib/providers/pod_service_provider.dart`

- [ ] **Step 1: Create the provider**

```dart
/// Riverpod provider that exposes the singleton [PodService].
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
import 'package:sanctum/services/pod_service.dart';

/// Exposes the application-wide [PodService] instance.
///
/// All data providers read from this provider to access Pod storage.
/// Widgets must never instantiate [PodService] directly.
final podServiceProvider = Provider<PodService>((ref) => PodService());
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/pod_service_provider.dart
git commit -m "feat: add podServiceProvider"
```

---

## Task 11: Transaction Providers

**Files:**
- Create: `lib/providers/transaction_providers.dart`

- [ ] **Step 1: Create the file**

```dart
/// Riverpod providers for Transaction state management.
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
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/pod_service_provider.dart';

/// Manages the list of transactions loaded from the user's Pod.
///
/// Invalidates itself after every mutation so the UI stays in sync.
class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() =>
      ref.read(podServiceProvider).loadAllTransactions();

  /// Saves [tx] to the Pod and refreshes the transaction list.
  Future<void> add(Transaction tx) async {
    await ref.read(podServiceProvider).saveTransaction(tx);
    ref.invalidateSelf();
  }

  /// Deletes the transaction with [id] from the Pod and refreshes the list.
  Future<void> delete(String id) async {
    await ref.read(podServiceProvider).deleteTransaction(id);
    ref.invalidateSelf();
  }
}

/// Provides the async list of all transactions for the current user.
final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<Transaction>>(
  TransactionListNotifier.new,
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/transaction_providers.dart
git commit -m "feat: add TransactionListNotifier and transactionListProvider"
```

---

## Task 12: AddTransactionScreen

**Files:**
- Create: `lib/screens/add_transaction_screen.dart`

- [ ] **Step 1: Create the form screen**

```dart
/// Add-transaction entry form for Sanctum.
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/app_error.dart';

/// The preset list of spending categories available to the user.
const List<String> kCategories = [
  'Groceries',
  'Transport',
  'Utilities',
  'Dining',
  'Health',
  'Entertainment',
  'Other',
];

/// Form screen for entering a new financial transaction.
///
/// Validates all fields before writing to the Pod and pops on success.
class AddTransactionScreen extends ConsumerStatefulWidget {
  /// Creates the add-transaction screen.
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = kCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens a date picker and updates [_date] if the user confirms.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Validates and submits the form, writing to the Pod via Riverpod.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final merchant = _merchantController.text.trim();
    final notes = _notesController.text.trim();

    final tx = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      merchant: merchant,
      category: _category,
      date: _date,
      notes: notes.isEmpty ? null : notes,
    );

    setState(() => _saving = true);
    try {
      await ref.read(transactionListProvider.notifier).add(tx);
      if (mounted) Navigator.pop(context);
    } on AppError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _submit,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount field.
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (AUD)',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Merchant field.
            TextFormField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Merchant'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Merchant is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Category dropdown.
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            // Date picker row.
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                '${_date.day}/${_date.month}/${_date.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            // Optional notes field.
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Submit button.
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Transaction'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/add_transaction_screen.dart
git commit -m "feat: add AddTransactionScreen form"
```

---

## Task 13: TransactionsScreen (Full Implementation)

**Files:**
- Modify: `lib/screens/transactions_screen.dart`

- [ ] **Step 1: Replace the placeholder with the full list screen**

```dart
/// Transactions list screen for Sanctum.
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
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/screens/add_transaction_screen.dart';
import 'package:sanctum/services/app_error.dart';

/// Displays all transactions from the user's Pod with swipe-to-delete.
class TransactionsScreen extends ConsumerWidget {
  /// Creates the Transactions screen.
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddTransactionScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: asyncTransactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorWidget(
          message: e is AppError ? e.userMessage : 'Could not load transactions.',
          onRetry: () => ref.invalidate(transactionListProvider),
        ),
        data: (transactions) => transactions.isEmpty
            ? const _EmptyState()
            : _TransactionList(transactions: transactions),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt =
        NumberFormat.currency(locale: 'en_AU', symbol: '\$');
    final dateFmt = DateFormat('d MMM yyyy');

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => _deleteTransaction(context, ref, tx.id),
          child: ListTile(
            leading: Text(
              dateFmt.format(tx.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            title: Text(tx.merchant),
            subtitle: Text(tx.category),
            trailing: Text(
              currencyFmt.format(tx.amount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog before deletion.
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will remove the record from your Pod.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Calls the notifier to delete [id] and shows a SnackBar on error.
  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(transactionListProvider.notifier).delete(id);
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 64),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add your first transaction.'),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/transactions_screen.dart
git commit -m "feat: implement TransactionsScreen with list, delete, and FAB"
```

---

## Task 14: Budget Providers

**Files:**
- Create: `lib/providers/budget_providers.dart`

- [ ] **Step 1: Create the file**

```dart
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
  final budgets = ref.watch(budgetListProvider).valueOrNull ?? [];
  final transactions = ref.watch(transactionListProvider).valueOrNull ?? [];

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
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/budget_providers.dart
git commit -m "feat: add BudgetListNotifier and budgetProgressProvider"
```

---

## Task 15: Bill Reminder Providers

**Files:**
- Create: `lib/providers/bill_providers.dart`

- [ ] **Step 1: Create the file**

```dart
/// Riverpod providers for BillReminder state management.
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
import 'dart:io';

// Group 2: Third-party package imports.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/pod_service_provider.dart';

/// Manages the list of bill reminders loaded from the user's Pod.
class BillReminderListNotifier extends AsyncNotifier<List<BillReminder>> {
  final _notifications = FlutterLocalNotificationsPlugin();

  @override
  Future<List<BillReminder>> build() =>
      ref.read(podServiceProvider).loadAllBillReminders();

  /// Saves [reminder] to the Pod, schedules a notification, and refreshes.
  Future<void> add(BillReminder reminder) async {
    await ref.read(podServiceProvider).saveBillReminder(reminder);
    await _scheduleNotification(reminder);
    ref.invalidateSelf();
  }

  /// Marks the reminder with [id] as paid.
  ///
  /// For monthly reminders, creates a new reminder for the following month.
  Future<void> markPaid(String id) async {
    final svc = ref.read(podServiceProvider);
    final reminder = state.value!.firstWhere((r) => r.id == id);

    // Overwrite the Pod file with isPaid = true.
    await svc.updateBillReminder(reminder.copyWith(isPaid: true));

    // For monthly recurrence, create the next occurrence.
    if (reminder.recurrence == 'monthly') {
      final due = reminder.dueDate;
      final next = reminder.copyWith(
        id: const Uuid().v4(),
        dueDate: DateTime(due.year, due.month + 1, due.day),
        isPaid: false,
      );
      await svc.saveBillReminder(next);
      await _scheduleNotification(next);
    }

    ref.invalidateSelf();
  }

  /// Deletes the reminder with [id] from the Pod and refreshes.
  Future<void> delete(String id) async {
    await ref.read(podServiceProvider).deleteBillReminder(id);
    ref.invalidateSelf();
  }

  /// Schedules a local notification 3 days before [r.dueDate].
  ///
  /// Silently skips if the notification date is already past, if running on
  /// web (unsupported), or if the platform does not support scheduling.
  Future<void> _scheduleNotification(BillReminder r) async {
    // Web does not support local notifications.
    if (kIsWeb) return;
    // Skip on unsupported desktop platforms.
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final notifyDate = r.dueDate.subtract(const Duration(days: 3));
    if (notifyDate.isBefore(DateTime.now())) return;

    try {
      await _notifications.zonedSchedule(
        r.id.hashCode,
        'Upcoming bill: ${r.name}',
        '${r.name} is due in 3 days — \$${r.amount.toStringAsFixed(2)}',
        tz.TZDateTime.from(notifyDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('bills', 'Bill Reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Notification scheduling failure must never crash the app.
      debugPrint('_scheduleNotification failed: $e');
    }
  }
}

/// Provides the async list of all bill reminders for the current user.
final billReminderListProvider =
    AsyncNotifierProvider<BillReminderListNotifier, List<BillReminder>>(
  BillReminderListNotifier.new,
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/bill_providers.dart
git commit -m "feat: add BillReminderListNotifier with markPaid and notification scheduling"
```

---

## Task 16: Dashboard Providers

**Files:**
- Create: `lib/providers/dashboard_providers.dart`

- [ ] **Step 1: Create the file**

```dart
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

/// Controls which date range is active on the Dashboard.
///
/// Defaults to [DateRange.thisMonth] on app start.
final dateRangeProvider =
    StateProvider<DateRange>((ref) => DateRange.thisMonth);

/// Aggregates spending by category for the currently selected [DateRange].
///
/// Returns a map of `category → total spent`. Empty if no transactions exist.
final spendingByCategoryProvider = Provider<Map<String, double>>((ref) {
  final range = ref.watch(dateRangeProvider);
  final transactions = ref.watch(transactionListProvider).valueOrNull ?? [];
  final now = DateTime.now();

  final filtered = transactions.where((tx) {
    return switch (range) {
      DateRange.thisMonth =>
        tx.date.year == now.year && tx.date.month == now.month,
      DateRange.lastMonth => now.month == 1
          ? tx.date.year == now.year - 1 && tx.date.month == 12
          : tx.date.year == now.year && tx.date.month == now.month - 1,
      DateRange.allTime => true,
    };
  });

  final map = <String, double>{};
  for (final tx in filtered) {
    map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
  }
  return map;
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/dashboard_providers.dart
git commit -m "feat: add dateRangeProvider and spendingByCategoryProvider"
```

---

## Task 17: DashboardScreen (Full Implementation)

**Files:**
- Modify: `lib/screens/dashboard_screen.dart`

- [ ] **Step 1: Replace the placeholder**

```dart
/// Dashboard screen for Sanctum.
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
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Group 3: Local package imports.
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/providers/dashboard_providers.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The Dashboard tab showing spending chart, summaries, and budget warnings.
class DashboardScreen extends ConsumerWidget {
  /// Creates the Dashboard screen.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dateRangeProvider);
    final spending = ref.watch(spendingByCategoryProvider);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final overBudget = budgetProgress.where((p) => p.isOverBudget).toList();

    // Compute summary figures.
    final totalSpent = spending.values.fold(0.0, (a, b) => a + b);
    final txCount = ref
        .watch(transactionListProvider)
        .valueOrNull
        ?.length ?? 0;
    final topCategory = spending.isEmpty
        ? null
        : spending.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Over-budget warning banner.
        if (overBudget.isNotEmpty)
          Card(
            color: SanctumTheme.semanticError.withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: overBudget
                    .map(
                      (p) => Text(
                        '⚠️ Budget exceeded in ${p.budget.category}',
                        style: const TextStyle(color: SanctumTheme.semanticError),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Date range toggle.
        SegmentedButton<DateRange>(
          segments: const [
            ButtonSegment(value: DateRange.thisMonth, label: Text('This Month')),
            ButtonSegment(value: DateRange.lastMonth, label: Text('Last Month')),
            ButtonSegment(value: DateRange.allTime, label: Text('All Time')),
          ],
          selected: {range},
          onSelectionChanged: (s) =>
              ref.read(dateRangeProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 24),
        // Spending pie chart or empty state.
        spending.isEmpty
            ? const Center(child: Text('No spending data for this period.'))
            : SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: spending.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        title: '${e.key}\n\$${e.value.toStringAsFixed(0)}',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: SanctumTheme.textPrimary,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                  ),
                ),
              ),
        const SizedBox(height: 24),
        // Summary cards row.
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Spent',
                value: '\$${totalSpent.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Transactions',
                value: '$txCount',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: 'Top Category',
                value: topCategory ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small metric card used in the Dashboard summary row.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/dashboard_screen.dart
git commit -m "feat: implement DashboardScreen with pie chart, summary, and budget warnings"
```

---

## Task 18: BudgetsScreen + AddBudgetScreen

**Files:**
- Create: `lib/screens/add_budget_screen.dart`
- Modify: `lib/screens/budgets_screen.dart`

- [ ] **Step 1: Create `lib/screens/add_budget_screen.dart`**

```dart
/// Add-budget entry form for Sanctum.
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/screens/add_transaction_screen.dart';
import 'package:sanctum/services/app_error.dart';

/// Form screen for creating a new monthly budget for a category.
class AddBudgetScreen extends ConsumerStatefulWidget {
  /// Creates the add-budget screen.
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  String _category = kCategories.first;
  String _month = _currentMonth();
  bool _saving = false;

  /// Returns the current year-month as "YYYY-MM".
  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final budget = Budget(
      id: const Uuid().v4(),
      category: _category,
      monthlyLimit: double.parse(_limitController.text.trim()),
      month: _month,
    );

    setState(() => _saving = true);
    try {
      await ref.read(budgetListProvider.notifier).add(budget);
      if (mounted) Navigator.pop(context);
    } on AppError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,6}\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (AUD)',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Limit is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _month,
              decoration:
                  const InputDecoration(labelText: 'Month (YYYY-MM)'),
              onChanged: (v) => _month = v.trim(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Month is required.';
                final parts = v.trim().split('-');
                if (parts.length != 2) return 'Use YYYY-MM format.';
                final year = int.tryParse(parts[0]);
                final month = int.tryParse(parts[1]);
                if (year == null || month == null || month < 1 || month > 12) {
                  return 'Invalid month.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Budget'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Replace `lib/screens/budgets_screen.dart`**

```dart
/// Budgets screen for Sanctum.
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
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Group 3: Local package imports.
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/screens/add_budget_screen.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Displays budget progress bars for each active budget.
class BudgetsScreen extends ConsumerWidget {
  /// Creates the Budgets screen.
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBudgets = ref.watch(budgetListProvider);
    final progress = ref.watch(budgetProgressProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddBudgetScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: asyncBudgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e is AppError ? e.userMessage : 'Could not load budgets.'),
              TextButton(
                onPressed: () => ref.invalidate(budgetListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (budgets) => budgets.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No budgets yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap + to set your first budget.'),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: progress.length,
                itemBuilder: (context, index) {
                  final p = progress[index];
                  final color = p.spent < p.budget.monthlyLimit * 0.75
                      ? SanctumTheme.semanticSuccess
                      : p.spent < p.budget.monthlyLimit
                          ? SanctumTheme.semanticWarning
                          : SanctumTheme.semanticError;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.budget.category,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(p.budget.month),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: p.fraction,
                            color: color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Spent \$${p.spent.toStringAsFixed(2)} of '
                            '\$${p.budget.monthlyLimit.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/add_budget_screen.dart lib/screens/budgets_screen.dart
git commit -m "feat: implement BudgetsScreen and AddBudgetScreen with progress bars"
```

---

## Task 19: BillsScreen + AddBillScreen

**Files:**
- Create: `lib/screens/add_bill_screen.dart`
- Modify: `lib/screens/bills_screen.dart`

- [ ] **Step 1: Create `lib/screens/add_bill_screen.dart`**

```dart
/// Add-bill-reminder entry form for Sanctum.
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/services/app_error.dart';

/// Form screen for adding a new bill reminder.
class AddBillScreen extends ConsumerStatefulWidget {
  /// Creates the add-bill screen.
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _recurrence = 'one-off';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reminder = BillReminder(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      dueDate: _dueDate,
      recurrence: _recurrence,
      isPaid: false,
    );

    setState(() => _saving = true);
    try {
      await ref.read(billReminderListProvider.notifier).add(reminder);
      if (mounted) Navigator.pop(context);
    } on AppError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill Reminder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Bill name'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,6}\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (AUD)',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(
                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: const [
                DropdownMenuItem(value: 'one-off', child: Text('One-off')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Reminder'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Replace `lib/screens/bills_screen.dart`**

```dart
/// Bills screen for Sanctum.
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
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/screens/add_bill_screen.dart';
import 'package:sanctum/services/app_error.dart';

/// Displays upcoming (unpaid) bill reminders sorted by due date.
class BillsScreen extends ConsumerWidget {
  /// Creates the Bills screen.
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBills = ref.watch(billReminderListProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const AddBillScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: asyncBills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e is AppError
                  ? e.userMessage
                  : 'Could not load bill reminders.'),
              TextButton(
                onPressed: () => ref.invalidate(billReminderListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reminders) {
          // Show only unpaid reminders.
          final unpaid = reminders.where((r) => !r.isPaid).toList();
          if (unpaid.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'All bills paid!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add an upcoming bill.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: unpaid.length,
            itemBuilder: (context, index) {
              final r = unpaid[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due ${dateFmt.format(r.dueDate)} — '
                              '\$${r.amount.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                r.recurrence == 'monthly'
                                    ? 'Monthly'
                                    : 'One-off',
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _markPaid(context, ref, r.id),
                        child: const Text('Mark Paid'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Marks the reminder with [id] as paid and shows a SnackBar on error.
  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(billReminderListProvider.notifier).markPaid(id);
    } on AppError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/add_bill_screen.dart lib/screens/bills_screen.dart
git commit -m "feat: implement BillsScreen and AddBillScreen"
```

---

## Task 20: Notification Initialization in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update `lib/main.dart` to initialize notifications and timezone**

```dart
/// Entry point for the Sanctum application.
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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Group 3: Local package imports.
import 'package:sanctum/sanctum.dart';

/// Initialises platform services then launches the Sanctum application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise timezone database — required by flutter_local_notifications.
  tz.initializeTimeZones();

  // Initialise local notifications on supported mobile platforms only.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await FlutterLocalNotificationsPlugin().initialize(initSettings);
  }

  runApp(const ProviderScope(child: Sanctum()));
}
```

- [ ] **Step 2: Run analyze**

```
flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialise timezone and local notifications in main"
```

---

## Task 21: Full Analyze Pass

- [ ] **Step 1: Run flutter analyze on the whole project**

```
flutter analyze
```

Expected: no errors. Warnings about `@visibleForTesting` are acceptable.

- [ ] **Step 2: Run all unit tests**

```
flutter test
```

Expected: all 5 Turtle tests + 4 model tests pass. No failures.

- [ ] **Step 3: Fix any issues found**

Address any analyzer errors. Common issues:
- Missing imports: add to the correct group with a blank line separator.
- `prefer_const_constructors`: add `const` keyword.
- `require_trailing_commas`: add trailing comma.
- `prefer_single_quotes`: replace double quotes.

- [ ] **Step 4: Commit fixes if needed**

```bash
git add -u
git commit -m "fix: resolve flutter analyze warnings"
```

---

## Task 22: Manual Integration Test Checklist

These cannot be automated — run manually against a real solidcommunity.au Pod.

- [ ] Log in with a real solidcommunity.au account
- [ ] Add a transaction (Woolworths, $52.00, Groceries) → appears in list
- [ ] Restart app → transaction still appears (loaded from Pod)
- [ ] Add two more transactions in different categories
- [ ] View Dashboard → pie chart shows three categories
- [ ] Set a budget ($200 Groceries, current month) → progress bar appears
- [ ] Add more Groceries transactions to exceed $200 → bar turns red, banner appears
- [ ] Add a monthly bill reminder (Netflix, $22.99, future date) → appears in Bills
- [ ] Mark Netflix as paid → disappears from unpaid list, reappears next month
- [ ] Delete a transaction → gone from list and Pod
- [ ] Log out → returns to welcome screen
- [ ] Log in again → all data still present

---

## Self-Review Checklist

### Spec coverage

| Requirement | Task |
|---|---|
| PodService skeleton with 11 methods | Task 3 |
| Transaction Turtle encode/decode | Task 4 |
| Budget Turtle encode/decode | Task 5 |
| BillReminder Turtle encode/decode | Task 6 |
| Transaction CRUD (save/load/delete) | Task 7 |
| Budget CRUD | Task 8 |
| BillReminder CRUD + update | Task 9 |
| podServiceProvider | Task 10 |
| TransactionListNotifier | Task 11 |
| AddTransactionScreen form | Task 12 |
| TransactionsScreen list + delete | Task 13 |
| BudgetListNotifier + budgetProgressProvider | Task 14 |
| BillReminderListNotifier + markPaid | Task 15 |
| Dashboard providers (dateRange, spendingByCategory) | Task 16 |
| DashboardScreen (chart, summary, banner) | Task 17 |
| BudgetsScreen + AddBudgetScreen | Task 18 |
| BillsScreen + AddBillScreen | Task 19 |
| Notification init in main.dart | Task 20 |
| AppError enum | Task 2 |
| First-run safety (empty list, no crash) | Tasks 7–9 (catch returns []) |
| Form validation (amount, merchant, category) | Tasks 12, 18, 19 |
| In-code doc comments | All tasks (every public class and method) |

### Known constraints respected

- No `rdflib` imports outside `pod_service.dart` ✅
- No `solid_auth` direct imports ✅
- No `manifest.ttl` ✅
- No new `pubspec.yaml` dependencies ✅ (timezone is a transitive dep of flutter_local_notifications)
- All four screens within `SolidScaffold` ✅
- No custom bottom nav ✅
- All colours via `Theme.of(context)` or `SanctumTheme` constants ✅
- `flutter_launcher_icons` and `flutter_native_splash` are **NOT included** — both require adding dev dependencies, which violates CLAUDE.md constraints. Flag for manual addition if needed.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-07-sanctum-sprints-3-6.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — Fresh subagent per task, two-stage review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints.

Which approach?
