/// Tests for FinancialIntelligenceResult and related value types.
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
import 'package:sanctum/models/financial_intelligence_result.dart';

void main() {
  group('FinancialIntelligenceResult', () {
    test('grade is Excellent for score 80', () {
      final r = FinancialIntelligenceResult(
        overallScore: 80,
        budgetAdherenceScore: 80,
        billReliabilityScore: 80,
        spendingConsistencyScore: 80,
        insights: const [],
      );
      expect(r.grade, 'Excellent');
    });

    test('grade is Good for score 60', () {
      final r = FinancialIntelligenceResult(
        overallScore: 60,
        budgetAdherenceScore: 60,
        billReliabilityScore: 60,
        spendingConsistencyScore: 60,
        insights: const [],
      );
      expect(r.grade, 'Good');
    });

    test('grade is Needs Attention for score 40', () {
      final r = FinancialIntelligenceResult(
        overallScore: 40,
        budgetAdherenceScore: 40,
        billReliabilityScore: 40,
        spendingConsistencyScore: 40,
        insights: const [],
      );
      expect(r.grade, 'Needs Attention');
    });

    test('grade is At Risk for score 39', () {
      final r = FinancialIntelligenceResult(
        overallScore: 39,
        budgetAdherenceScore: 39,
        billReliabilityScore: 39,
        spendingConsistencyScore: 39,
        insights: const [],
      );
      expect(r.grade, 'At Risk');
    });
  });

  group('InsightString ordering', () {
    test('alert severity has higher sort weight than warning', () {
      expect(
        InsightSeverity.alert.sortWeight > InsightSeverity.warning.sortWeight,
        isTrue,
      );
    });
    test('warning severity has higher sort weight than info', () {
      expect(
        InsightSeverity.warning.sortWeight > InsightSeverity.info.sortWeight,
        isTrue,
      );
    });
  });
}
