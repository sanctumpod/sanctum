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
