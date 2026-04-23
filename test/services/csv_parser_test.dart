/// Unit tests for CsvParser.
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
