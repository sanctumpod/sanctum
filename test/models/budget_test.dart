/// Tests for the Budget data model.
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
