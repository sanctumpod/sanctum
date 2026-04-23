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

// Local package imports.
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
    final nonBlank = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

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
    final colIndex = <String, int>{
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

      if (dateStr == null ||
          amountStr == null ||
          merchant == null ||
          category == null) {
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
