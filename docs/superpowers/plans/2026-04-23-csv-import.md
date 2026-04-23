# CSV Transaction Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to import multiple transactions into their SOLID Pod by uploading a `.csv` file from their device, with a preview-and-confirm step before any data is written.

**Architecture:** A built-in CSV parser (pure Dart, no external package) converts the file to `List<Transaction>`. A new `ImportCsvScreen` handles file picking (`file_picker` package — see prerequisite note), preview, and confirmation. Bulk save goes through the existing `transactionListProvider` notifier via a new `importMany()` method. All Pod writes use the existing `PodService.saveTransaction()` so the RDF/Turtle isolation contract is never broken.

**Tech Stack:** Flutter, Riverpod 3.1.0, solidpod 0.10.1, uuid 4.5.1, file_picker (⚠️ see Task 0), intl 0.20.1

---

## ⚠️ Prerequisite — New Dependency Required

`file_picker` is **not** in `pubspec.yaml`. The CLAUDE.md rule says "flag as a comment — do not add it." This plan requires explicit developer approval to add:

```yaml
# ⚠️ NEW DEPENDENCY — requires explicit approval before adding
# file_picker: ^8.1.6    # native file-picker dialog for Android / iOS / Web / Desktop
```

**If `file_picker` cannot be added:** replace Task 2 with a `TextField` that accepts pasted CSV text. The rest of the plan (Task 1, 3, 4, 5) is unaffected.

---

## Expected CSV Format

```
date,amount,merchant,category,notes
2026-01-15,42.50,Woolworths,Groceries,Weekly shop
2026-01-16,12.00,Spotify,Entertainment,
2026-01-17,8.50,Shell,Transport,
```

| Column | Type | Required | Format |
|--------|------|----------|--------|
| `date` | date | ✅ | `YYYY-MM-DD` |
| `amount` | decimal | ✅ | positive number, e.g. `42.50` |
| `merchant` | string | ✅ | any non-empty string |
| `category` | string | ✅ | any non-empty string |
| `notes` | string | ❌ | may be empty |

Column header names are case-insensitive. Unknown columns are silently ignored.

---

## What Happens in the User's SOLID Pod

This is the core contract the whole feature is built around. Every imported CSV row ends up as a **separate encrypted Turtle file** on the authenticated user's SOLID Pod at `solidcommunity.au`. Nothing is stored locally on the device.

### Storage path per transaction

```
sanctum/
└── transactions/
    └── tx_<uuid>.enc.ttl   ← one file per imported CSV row
```

`<uuid>` is a freshly generated UUID v4 assigned at import time by `importMany()` in the provider. The file name format matches what `AddTransactionScreen` already writes, so imported and manually-entered transactions are indistinguishable at the storage layer.

### File format

Each `.enc.ttl` file is an **AES-encrypted Turtle RDF graph** written by `solidpod`'s `writePod(path, content, encrypted: true)`. Before encryption the plaintext Turtle looks like this:

```turtle
@prefix fin: <http://sanctum.app/finance#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<#tx> a fin:Transaction ;
    fin:id       "a1b2c3d4-..." ;
    fin:amount   "42.50"^^xsd:decimal ;
    fin:merchant "Woolworths" ;
    fin:category "Groceries" ;
    fin:date     "2026-01-15"^^xsd:date ;
    fin:notes    "Weekly shop" .
```

### Call chain (CSV row → Pod file)

```
CsvParser.parseTransactions(csvText)
  → List<Transaction> (id = '' placeholder)

TransactionListNotifier.importMany(transactions)
  → for each tx: PodService.saveTransaction(tx.copyWith(id: uuid.v4()))
      → writePod('transactions/tx_<uuid>.enc.ttl', _transactionToTurtle(tx), encrypted: true)
          → solidpod encrypts + writes to Pod over HTTPS

ref.invalidateSelf()
  → UI re-reads PodService.loadAllTransactions()
  → Transactions screen now shows all imported rows
```

**No CSV data is ever retained in the app after import completes.** The in-memory `_preview` list in `ImportCsvScreen` is discarded when the screen pops.

---

## File Structure

### New files to create

```
lib/
├── constants/
│   └── csv_fields.dart             # CSV column name constants for transactions
├── services/
│   └── csv_parser.dart             # Pure-Dart CSV parsing → List<Transaction>; no Flutter/Pod imports
└── screens/
    └── import_csv_screen.dart      # File-pick → preview list → confirm import UI

test/
└── services/
    └── csv_parser_test.dart        # Unit tests for the CSV parser (no Pod I/O)
```

### Files to modify

```
lib/providers/transaction_providers.dart   # Add importMany(List<Transaction>) method
lib/screens/transactions_screen.dart       # Add "Import CSV" icon button to AppBar
```

---

## Task 0: Add `file_picker` Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Get explicit developer approval, then add the dependency**

In `pubspec.yaml`, under `dependencies:`, add after the `uuid` line:

```yaml
  # CSV file-picker — required for import-from-file feature (added 2026-04-23).
  file_picker: ^8.1.6
```

- [ ] **Step 2: Fetch the package**

```bash
flutter pub get
```

Expected output ends with: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add file_picker dependency for CSV import feature

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 1: CSV Field Constants

**Files:**
- Create: `lib/constants/csv_fields.dart`

- [ ] **Step 1: Create the constants file**

Create `lib/constants/csv_fields.dart`:

```dart
/// CSV column name constants for transaction imports.
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

/// CSV column name constants used by the transaction importer.
///
/// All comparisons against actual CSV headers must be done
/// case-insensitively (lowercase the header before comparing).
class TransactionCsvFields {
  /// Required: date of the transaction in YYYY-MM-DD format.
  static const String date = 'date';

  /// Required: transaction amount as a positive decimal string.
  static const String amount = 'amount';

  /// Required: merchant or payee name.
  static const String merchant = 'merchant';

  /// Required: spending category.
  static const String category = 'category';

  /// Optional: free-text notes about the transaction.
  static const String notes = 'notes';

  /// All required column names (lowercase).
  static const List<String> required = [date, amount, merchant, category];

  /// All optional column names (lowercase).
  static const List<String> optional = [notes];

  /// All column names in display order.
  static const List<String> all = [date, amount, merchant, category, notes];
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/constants/csv_fields.dart
git commit -m "feat: add TransactionCsvFields constants

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Pure-Dart CSV Parser

**Files:**
- Create: `lib/services/csv_parser.dart`
- Create: `test/services/csv_parser_test.dart`

The parser has **no Flutter, no Pod, no rdflib imports** — it is pure Dart business logic.

- [ ] **Step 1: Write the failing tests**

Create `test/services/csv_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/services/csv_parser.dart';

void main() {
  group('CsvParser.parseTransactions', () {
    test('parses a well-formed CSV with all columns', () {
      const csv = 'date,amount,merchant,category,notes\n'
          '2026-01-15,42.50,Woolworths,Groceries,Weekly shop\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
      expect(result.skippedRows, 0);
      final tx = result.parsed.first;
      expect(tx.amount, 42.50);
      expect(tx.merchant, 'Woolworths');
      expect(tx.category, 'Groceries');
      expect(tx.date, DateTime(2026, 1, 15));
      expect(tx.notes, 'Weekly shop');
    });

    test('sets notes to null when notes column is empty', () {
      const csv = 'date,amount,merchant,category,notes\n'
          '2026-01-16,12.00,Spotify,Entertainment,\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
      expect(result.parsed.first.notes, isNull);
    });

    test('parses CSV without notes column', () {
      const csv = 'date,amount,merchant,category\n'
          '2026-01-17,8.50,Shell,Transport\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
      expect(result.parsed.first.notes, isNull);
    });

    test('skips rows with invalid amount', () {
      const csv = 'date,amount,merchant,category\n'
          '2026-01-17,notanumber,Shell,Transport\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed, isEmpty);
      expect(result.skippedRows, 1);
    });

    test('skips rows with invalid date format', () {
      const csv = 'date,amount,merchant,category\n'
          '15-01-2026,8.50,Shell,Transport\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed, isEmpty);
      expect(result.skippedRows, 1);
    });

    test('skips rows with zero or negative amount', () {
      const csv = 'date,amount,merchant,category\n'
          '2026-01-17,-5.00,Shell,Transport\n'
          '2026-01-17,0,Shell,Transport\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed, isEmpty);
      expect(result.skippedRows, 2);
    });

    test('returns error when required columns are missing', () {
      const csv = 'date,amount\n2026-01-17,8.50\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.missingColumns, containsAll(['merchant', 'category']));
      expect(result.parsed, isEmpty);
    });

    test('handles quoted fields containing commas', () {
      const csv = 'date,amount,merchant,category,notes\n'
          '2026-01-18,25.00,"Smith, John",Dining,Lunch\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
      expect(result.parsed.first.merchant, 'Smith, John');
    });

    test('handles CRLF line endings', () {
      const csv = 'date,amount,merchant,category\r\n'
          '2026-01-19,10.00,Test,Other\r\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
    });

    test('is case-insensitive for column headers', () {
      const csv = 'Date,Amount,Merchant,Category\n'
          '2026-01-20,5.00,Test,Other\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
    });

    test('skips entirely blank rows', () {
      const csv = 'date,amount,merchant,category\n'
          '\n'
          '2026-01-20,5.00,Test,Other\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 1);
    });

    test('parses multiple rows, newest-first by date', () {
      const csv = 'date,amount,merchant,category\n'
          '2026-01-15,10.00,A,Other\n'
          '2026-01-20,20.00,B,Other\n';

      final result = CsvParser.parseTransactions(csv);

      expect(result.parsed.length, 2);
      // Newest first.
      expect(result.parsed.first.date, DateTime(2026, 1, 20));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
flutter test test/services/csv_parser_test.dart
```

Expected: multiple errors of the form `'package:sanctum/services/csv_parser.dart': No such file`

- [ ] **Step 3: Implement the CSV parser**

Create `lib/services/csv_parser.dart`:

```dart
/// Pure-Dart CSV parser for transaction import.
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

// Group 1: Dart SDK imports.
import 'dart:core';

// Group 3: Local package imports.
import 'package:sanctum/constants/csv_fields.dart';
import 'package:sanctum/models/transaction.dart';

/// Holds the result of a CSV parse attempt.
class CsvParseResult {
  /// Creates a [CsvParseResult].
  const CsvParseResult({
    required this.parsed,
    required this.skippedRows,
    required this.missingColumns,
  });

  /// Successfully parsed transactions.
  final List<Transaction> parsed;

  /// Number of data rows that were skipped due to validation errors.
  final int skippedRows;

  /// Required column names that were absent from the CSV header row.
  ///
  /// When non-empty, [parsed] will always be empty.
  final List<String> missingColumns;

  /// True when all required columns were present and at least one row parsed.
  bool get isSuccess => missingColumns.isEmpty && parsed.isNotEmpty;
}

/// Parses CSV text into [Transaction] objects.
///
/// This class contains no Flutter or Pod imports — it is pure business logic
/// that can be unit-tested without a running app or Pod connection.
class CsvParser {
  /// Parses [csvContent] and returns a [CsvParseResult].
  ///
  /// Expected CSV format:
  /// - Header row with at least: `date`, `amount`, `merchant`, `category`.
  /// - `notes` is optional.
  /// - Date must be in `YYYY-MM-DD` format.
  /// - Amount must be a positive decimal.
  /// - Column headers are compared case-insensitively.
  /// - Rows with validation errors are skipped and counted in [CsvParseResult.skippedRows].
  static CsvParseResult parseTransactions(String csvContent) {
    // Normalise line endings to \n.
    final lines = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    // Find first non-blank line as the header.
    final nonBlank = lines.where((l) => l.trim().isNotEmpty).toList();
    if (nonBlank.isEmpty) {
      return const CsvParseResult(
        parsed: [],
        skippedRows: 0,
        missingColumns: TransactionCsvFields.required,
      );
    }

    // Parse header row.
    final headers = _parseLine(nonBlank.first)
        .map((h) => h.trim().toLowerCase())
        .toList();

    // Check required columns.
    final missing = TransactionCsvFields.required
        .where((col) => !headers.contains(col))
        .toList();
    if (missing.isNotEmpty) {
      return CsvParseResult(
        parsed: [],
        skippedRows: 0,
        missingColumns: missing,
      );
    }

    // Map column names to their index positions.
    final colIndex = {
      for (final col in TransactionCsvFields.all)
        if (headers.contains(col)) col: headers.indexOf(col),
    };

    // Parse data rows.
    final parsed = <Transaction>[];
    var skipped = 0;

    for (var i = 1; i < nonBlank.length; i++) {
      final line = nonBlank[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseLine(line);

      // Safely retrieve a field value by column name.
      String? field(String col) {
        final idx = colIndex[col];
        if (idx == null || idx >= fields.length) return null;
        final v = fields[idx].trim();
        return v.isEmpty ? null : v;
      }

      // Validate required fields.
      final dateStr = field(TransactionCsvFields.date);
      final amountStr = field(TransactionCsvFields.amount);
      final merchant = field(TransactionCsvFields.merchant);
      final category = field(TransactionCsvFields.category);

      if (dateStr == null || amountStr == null ||
          merchant == null || category == null) {
        skipped++;
        continue;
      }

      // Parse date — must be YYYY-MM-DD.
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        skipped++;
        continue;
      }

      // Parse amount — must be a positive decimal.
      final amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) {
        skipped++;
        continue;
      }

      final notes = field(TransactionCsvFields.notes);

      parsed.add(
        Transaction(
          // IDs are assigned in the provider when calling saveTransaction.
          // Use a placeholder here; the provider will override with a real UUID.
          id: '',
          amount: amount,
          merchant: merchant,
          category: category,
          date: date,
          notes: notes,
        ),
      );
    }

    // Sort newest-first, matching PodService.loadAllTransactions() order.
    parsed.sort((a, b) => b.date.compareTo(a.date));

    return CsvParseResult(
      parsed: parsed,
      skippedRows: skipped,
      missingColumns: const [],
    );
  }

  /// Splits a single CSV line into fields, honouring RFC 4180 quoting.
  ///
  /// Handles:
  /// - Quoted fields containing commas.
  /// - Escaped double-quotes (`""` inside a quoted field).
  static List<String> _parseLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote inside a quoted field.
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }

    fields.add(buffer.toString());
    return fields;
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/services/csv_parser_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/constants/csv_fields.dart lib/services/csv_parser.dart test/services/csv_parser_test.dart
git commit -m "feat: implement CsvParser and TransactionCsvFields

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Add `importMany` to the Transaction Provider

**Files:**
- Modify: `lib/providers/transaction_providers.dart`

- [ ] **Step 1: Add `importMany` method to `TransactionListNotifier`**

In `lib/providers/transaction_providers.dart`, add the `importMany` method after the existing `delete` method. The full file after modification:

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
import 'package:uuid/uuid.dart';

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

  /// Saves every transaction in [transactions] to the user's SOLID Pod.
  ///
  /// Each [Transaction] is written as an individual encrypted Turtle file at
  /// `sanctum/transactions/tx_<uuid>.enc.ttl` on the Pod, via
  /// [PodService.saveTransaction]. A fresh UUID v4 is assigned to each
  /// transaction here because the CSV parser produces placeholder empty IDs.
  ///
  /// The provider invalidates itself after all writes so the Transactions
  /// screen immediately re-reads the Pod and shows the newly imported rows.
  ///
  /// Throws [AppError.networkError] on the first failed Pod write.
  Future<void> importMany(List<Transaction> transactions) async {
    const uuid = Uuid();
    final service = ref.read(podServiceProvider);
    for (final tx in transactions) {
      // Assign a real UUID — the parsed tx carries an empty placeholder id.
      await service.saveTransaction(tx.copyWith(id: uuid.v4()));
    }
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

- [ ] **Step 2: Run all existing tests to confirm nothing is broken**

```bash
flutter test
```

Expected: all tests that existed before still pass.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/transaction_providers.dart
git commit -m "feat: add importMany to TransactionListNotifier

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Import CSV Screen

**Files:**
- Create: `lib/screens/import_csv_screen.dart`

This screen has three logical states managed by a `_ImportState` enum:

| State | What the user sees |
|-------|--------------------|
| `idle` | "Pick a CSV file" button + format guide |
| `preview` | Parsed transaction list + row count + "Import N transactions" button |
| `importing` | Progress indicator while saving to Pod |

- [ ] **Step 1: Create the screen file**

Create `lib/screens/import_csv_screen.dart`:

```dart
/// CSV import screen for bulk transaction entry.
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
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/constants/csv_fields.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/services/csv_parser.dart';

/// Tracks which phase of the import flow is active.
enum _ImportState { idle, preview, importing }

/// Screen that lets users import transactions from a CSV file.
///
/// Flow: pick file → parse → preview rows → confirm → save to Pod → pop.
class ImportCsvScreen extends ConsumerStatefulWidget {
  /// Creates the import CSV screen.
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  _ImportState _state = _ImportState.idle;
  List<Transaction> _preview = [];
  int _skippedRows = 0;
  String? _errorMessage;

  // Formatters for the preview list.
  final _dateFmt = DateFormat('d MMM yyyy');
  final _currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');

  /// Opens the system file picker restricted to CSV files.
  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _state = _ImportState.idle;
    });

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Could not open file picker: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    // Read the file bytes and decode as UTF-8.
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      setState(() => _errorMessage = 'Could not read file bytes.');
      return;
    }

    final content = String.fromCharCodes(bytes);
    _parseContent(content);
  }

  /// Runs the CSV parser and transitions to the preview state.
  void _parseContent(String content) {
    final parseResult = CsvParser.parseTransactions(content);

    if (parseResult.missingColumns.isNotEmpty) {
      setState(() {
        _errorMessage =
            'CSV is missing required columns: '
            '${parseResult.missingColumns.join(", ")}.\n\n'
            'Required: ${TransactionCsvFields.required.join(", ")}';
      });
      return;
    }

    if (parseResult.parsed.isEmpty) {
      setState(() {
        _errorMessage =
            'No valid rows found. '
            '${parseResult.skippedRows} row(s) were skipped due to errors.';
      });
      return;
    }

    setState(() {
      _preview = parseResult.parsed;
      _skippedRows = parseResult.skippedRows;
      _state = _ImportState.preview;
    });
  }

  /// Saves all previewed transactions to the user's SOLID Pod.
  ///
  /// Calls [TransactionListNotifier.importMany], which writes one encrypted
  /// Turtle file per transaction to `sanctum/transactions/tx_<uuid>.enc.ttl`
  /// on the Pod via `solidpod`'s `writePod`. On success the screen pops and
  /// the Transactions screen re-reads the Pod — imported rows appear inline
  /// with any manually-entered transactions. On [AppError], the screen stays
  /// open so the user can retry or pick a different file.
  Future<void> _confirmImport() async {
    setState(() => _state = _ImportState.importing);

    try {
      await ref.read(transactionListProvider.notifier).importMany(_preview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${_preview.length} transaction(s).'),
          ),
        );
        Navigator.pop(context);
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _state = _ImportState.preview;
          _errorMessage = e.userMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: switch (_state) {
        _ImportState.idle => _IdleView(
            errorMessage: _errorMessage,
            onPickFile: _pickFile,
          ),
        _ImportState.preview => _PreviewView(
            transactions: _preview,
            skippedRows: _skippedRows,
            dateFmt: _dateFmt,
            currencyFmt: _currencyFmt,
            errorMessage: _errorMessage,
            onPickAgain: _pickFile,
            onConfirm: _confirmImport,
          ),
        _ImportState.importing => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving to Pod…'),
              ],
            ),
          ),
      },
    );
  }
}

/// Shown before any file has been selected.
class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPickFile, this.errorMessage});

  final VoidCallback onPickFile;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import transactions from a CSV file.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your CSV must have these columns (header names are '
            'case-insensitive):',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _ColumnTable(),
          const SizedBox(height: 8),
          Text(
            'Example:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'date,amount,merchant,category,notes\n'
              '2026-01-15,42.50,Woolworths,Groceries,Weekly shop\n'
              '2026-01-16,12.00,Spotify,Entertainment,',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick CSV File'),
              onPressed: onPickFile,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the required/optional column reference table.
class _ColumnTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1),
      },
      children: [
        _headerRow(context),
        _dataRow(context, 'date', 'YYYY-MM-DD', 'Required'),
        _dataRow(context, 'amount', 'Positive decimal', 'Required'),
        _dataRow(context, 'merchant', 'Any string', 'Required'),
        _dataRow(context, 'category', 'Any string', 'Required'),
        _dataRow(context, 'notes', 'Any string', 'Optional'),
      ],
    );
  }

  TableRow _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('Column', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('Format', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('', style: style),
        ),
      ],
    );
  }

  TableRow _dataRow(
    BuildContext context,
    String col,
    String format,
    String req,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(col, style: const TextStyle(fontFamily: 'monospace')),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(format, style: Theme.of(context).textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(req, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Shown after a file has been parsed — displays the transaction preview list.
class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.transactions,
    required this.skippedRows,
    required this.dateFmt,
    required this.currencyFmt,
    required this.onPickAgain,
    required this.onConfirm,
    this.errorMessage,
  });

  final List<Transaction> transactions;
  final int skippedRows;
  final DateFormat dateFmt;
  final NumberFormat currencyFmt;
  final VoidCallback onPickAgain;
  final VoidCallback onConfirm;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary banner.
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transactions.length} transaction(s) ready to import',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (skippedRows > 0)
                Text(
                  '$skippedRows row(s) skipped (invalid data).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),

        // Transaction preview list.
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
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
              );
            },
          ),
        ),

        // Error message if Pod save failed.
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),

        // Action buttons.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickAgain,
                  child: const Text('Pick Another File'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child:
                      Text('Import ${transactions.length} Transaction(s)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze` to check for errors**

```bash
flutter analyze lib/screens/import_csv_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/import_csv_screen.dart
git commit -m "feat: implement ImportCsvScreen with file-pick, preview, and confirm

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Wire Import Button into Transactions Screen

**Files:**
- Modify: `lib/screens/transactions_screen.dart`

The import entry point is an `IconButton` (upload icon) in the screen's `AppBar`, added via a wrapping `Scaffold` that sits inside `SolidScaffold`'s page slot.

- [ ] **Step 1: Add the import button to `TransactionsScreen`**

Replace the current `build` method in `TransactionsScreen`. The full file after modification:

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
import 'package:sanctum/screens/import_csv_screen.dart';
import 'package:sanctum/services/app_error.dart';

/// Displays all transactions from the user's Pod with swipe-to-delete.
class TransactionsScreen extends ConsumerWidget {
  /// Creates the Transactions screen.
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Import from CSV button.
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ImportCsvScreen(),
              ),
            ),
          ),
        ],
      ),
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
          message: e is AppError
              ? e.userMessage
              : 'Could not load transactions.',
          onRetry: () => ref.invalidate(transactionListProvider),
        ),
        data: (transactions) => transactions.isEmpty
            ? const _EmptyState()
            : _TransactionList(transactions: transactions),
      ),
    );
  }
}

/// Renders the scrollable list of transaction tiles with swipe-to-delete.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');
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

  /// Shows a confirmation dialog before deleting the transaction.
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

  /// Calls the notifier to delete [id] from the Pod and handles errors.
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

/// Shown when the transaction list is empty.
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

/// Shown when the provider returns an error, with a retry button.
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

- [ ] **Step 2: Run `flutter analyze` on modified files**

```bash
flutter analyze lib/screens/transactions_screen.dart lib/screens/import_csv_screen.dart lib/providers/transaction_providers.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/transactions_screen.dart
git commit -m "feat: add Import CSV button to TransactionsScreen AppBar

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Self-Review

### Spec coverage check

| Requirement | Covered by |
|-------------|-----------|
| Import transactions from a CSV file | Task 0 (dep) + Task 4 (screen) |
| CSV format definition with required/optional columns | Task 1 + Task 2 |
| File picker dialog | Task 4 (`_pickFile`) |
| Parse validation (missing columns, invalid rows) | Task 2 (parser + tests) |
| Preview list before confirming | Task 4 (`_PreviewView`) |
| Skip invalid rows with count shown | Task 2 + Task 4 banner |
| **Each CSV row written as an encrypted Turtle file to the user's SOLID Pod** | Task 3 (`importMany` → `PodService.saveTransaction` → `writePod`) — see "What Happens in the User's SOLID Pod" section |
| Pod file path: `sanctum/transactions/tx_<uuid>.enc.ttl` | Task 3 (`uuid.v4()` assigned in `importMany`; path built in `PodService.saveTransaction`) |
| Refresh UI after import | Task 3 (`ref.invalidateSelf()`) |
| Entry point visible on Transactions screen | Task 5 (AppBar icon button) |

### Placeholder scan

No TBD, TODO, or vague placeholders found.

### Type consistency

- `Transaction.id` is `String` — `importMany` assigns via `uuid.v4()` ✅
- `CsvParseResult.parsed` is `List<Transaction>` — passed directly to `importMany` ✅
- `_ImportState` enum used consistently across `_ImportCsvScreenState.build` ✅

### Known limitation

`withOpacity` is called on `colorScheme.primary` in `_PreviewView`. If the app's `ThemeData` later switches to `ColorScheme.fromSeed`, this will still work but may produce slightly different shading. Flag for design review after first run.
