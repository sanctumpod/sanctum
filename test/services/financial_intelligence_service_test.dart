/// Financial Intelligence Service tests.
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
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/services/financial_intelligence_service.dart';

void main() {
  final svc = const FinancialIntelligenceService();

  // ── Budget Adherence ───────────────────────────────────────────────────────

  group('Budget Adherence', () {
    test('BA-01: returns 100 when no budgets', () {
      final r = svc.analyse([], [], []);
      expect(r.budgetAdherenceScore, 100);
    });

    test('BA-02: returns 100 when spend is zero vs budget', () {
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 500,
          month: '2026-05',
        ),
      ];
      final r = svc.analyse([], budgets, []);
      expect(r.budgetAdherenceScore, 100);
    });

    test('BA-03: returns 0 when all budgets exceeded', () {
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final r = svc.analyse(txs, budgets, []);
      expect(r.budgetAdherenceScore, 0);
    });

    test('BA-04: returns 50 when half budgets exceeded', () {
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
        const Budget(
          id: 'b2',
          category: 'Transport',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      // Food is over, Transport is under.
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
        Transaction(
          id: 'tx2',
          amount: 50,
          merchant: 'Bus',
          category: 'Transport',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final r = svc.analyse(txs, budgets, []);
      expect(r.budgetAdherenceScore, 50);
    });

    test('BA-05: ignores budgets from other months', () {
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2025-01',
        ),
      ];
      // Transaction in current month but budget is from past month.
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
      ];
      // No current-month budgets → neutral 100.
      final r = svc.analyse(txs, budgets, []);
      expect(r.budgetAdherenceScore, 100);
    });

    test('BA-06: generates over-budget insight for exceeded budget', () {
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final r = svc.analyse(txs, budgets, []);
      final overBudgetInsights = r.insights
          .where(
            (i) =>
                i.category == InsightCategory.budget &&
                i.severity == InsightSeverity.alert,
          )
          .toList();
      expect(overBudgetInsights, isNotEmpty);
      expect(overBudgetInsights.first.text, contains('Food'));
      expect(overBudgetInsights.first.severity, InsightSeverity.alert);
    });
  });

  // ── Bill Reliability ───────────────────────────────────────────────────────

  group('Bill Reliability', () {
    test('BR-01: returns 100 when no bills', () {
      final r = svc.analyse([], [], []);
      expect(r.billReliabilityScore, 100);
    });

    test('BR-02: returns 100 when all bills paid', () {
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Netflix',
          amount: 15,
          dueDate: DateTime(2026, 5, 1),
          recurrence: 'monthly',
          isPaid: true,
        ),
        BillReminder(
          id: 'bill2',
          name: 'Spotify',
          amount: 10,
          dueDate: DateTime(2026, 5, 5),
          recurrence: 'monthly',
          isPaid: true,
        ),
      ];
      final r = svc.analyse([], [], bills);
      expect(r.billReliabilityScore, 100);
    });

    test('BR-03: returns 0 when all bills overdue', () {
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Electric',
          amount: 80,
          dueDate: DateTime(2026, 4, 1),
          recurrence: 'one-off',
          isPaid: false,
        ),
      ];
      final r = svc.analyse([], [], bills);
      expect(r.billReliabilityScore, 0);
    });

    test('BR-04: returns 50 when half bills overdue', () {
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Electric',
          amount: 80,
          dueDate: DateTime(2026, 4, 1),
          recurrence: 'one-off',
          isPaid: true,
        ),
        BillReminder(
          id: 'bill2',
          name: 'Internet',
          amount: 60,
          dueDate: DateTime(2026, 4, 1),
          recurrence: 'one-off',
          isPaid: false,
        ),
      ];
      final r = svc.analyse([], [], bills);
      expect(r.billReliabilityScore, 50);
    });

    test('BR-05: ignores future unpaid bills', () {
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Netflix',
          amount: 15,
          dueDate: DateTime(2026, 6, 1),
          recurrence: 'monthly',
          isPaid: false,
        ),
      ];
      final r = svc.analyse([], [], bills);
      expect(r.billReliabilityScore, 100);
    });

    test('BR-06: generates overdue insight for overdue bill', () {
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Netflix',
          amount: 15,
          dueDate: DateTime(2026, 4, 1),
          recurrence: 'monthly',
          isPaid: false,
        ),
      ];
      final r = svc.analyse([], [], bills);
      final overdueInsights = r.insights
          .where(
            (i) =>
                i.category == InsightCategory.bills &&
                i.severity == InsightSeverity.alert,
          )
          .toList();
      expect(overdueInsights, isNotEmpty);
      expect(overdueInsights.first.text, contains('Netflix'));
      expect(overdueInsights.first.severity, InsightSeverity.alert);
    });
  });

  // ── Spending Consistency ───────────────────────────────────────────────────

  group('Spending Consistency', () {
    test('SC-01: returns 50 when no transactions', () {
      final r = svc.analyse([], [], []);
      expect(r.spendingConsistencyScore, 50);
    });

    test(
      'SC-02: returns 100 when current month spend equals historical average',
      () {
        // Three historical months + current month all spending 100.
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 2, 15),
          ),
          Transaction(
            id: 'tx2',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 3, 15),
          ),
          Transaction(
            id: 'tx3',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 4, 15),
          ),
          Transaction(
            id: 'tx4',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
        ];
        final r = svc.analyse(txs, [], []);
        expect(r.spendingConsistencyScore, 100);
      },
    );

    test(
      'SC-03: returns 0 when current spend is 3x or more the historical average',
      () {
        // Historical avg = 100, current = 300.
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 2, 15),
          ),
          Transaction(
            id: 'tx2',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 3, 15),
          ),
          Transaction(
            id: 'tx3',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 4, 15),
          ),
          Transaction(
            id: 'tx4',
            amount: 300,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
        ];
        final r = svc.analyse(txs, [], []);
        expect(r.spendingConsistencyScore, 0);
      },
    );

    test(
      'SC-04: returns ~50 when current spend is 2x the historical average',
      () {
        // Historical avg = 100, current = 200 → deviation = 1.0 → score = 0 max(0, 100-100) = 0.
        // Wait: deviation = |200-100|/100 = 1.0, score = max(0, 100-1.0*100) = 0.
        // Per spec: score ≈ 50, delta 5. Let's check: deviation=100/100=1.0 → 100-100=0.
        // The spec says "score ≈ 50, delta 5" — this suggests the formula is
        // score = max(0, 100 - deviation * 50) so 100-50 = 50.
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 2, 15),
          ),
          Transaction(
            id: 'tx2',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 3, 15),
          ),
          Transaction(
            id: 'tx3',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 4, 15),
          ),
          Transaction(
            id: 'tx4',
            amount: 200,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
        ];
        final r = svc.analyse(txs, [], []);
        expect(r.spendingConsistencyScore, closeTo(50, 5));
      },
    );

    test(
      'SC-05: ignores current month from historical calculation',
      () {
        // All txs in current month only — no historical data → score 50.
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
        ];
        final r = svc.analyse(txs, [], []);
        // Only one month of data (current) → no historical months → score 50.
        expect(r.spendingConsistencyScore, 50);
      },
    );

    test(
      'SC-06: generates high-spend insight when current exceeds historical by 50%+',
      () {
        // Current spend 200, historical avg 100 (deviation > 0.5).
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 4, 15),
          ),
          Transaction(
            id: 'tx2',
            amount: 200,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
        ];
        final r = svc.analyse(txs, [], []);
        final highSpendInsights = r.insights
            .where(
              (i) =>
                  i.category == InsightCategory.spending &&
                  i.severity == InsightSeverity.warning,
            )
            .toList();
        expect(highSpendInsights, isNotEmpty);
        expect(highSpendInsights.first.severity, InsightSeverity.warning);
      },
    );
  });

  // ── Overall Score ──────────────────────────────────────────────────────────

  group('Overall Score', () {
    test('OS-01: overall score is weighted sum of pillars', () {
      // All pillars 100 → overall 100.
      final r = svc.analyse([], [], []);
      expect(r.overallScore, 100);
    });

    test('OS-02: grade is Excellent when score >= 80', () {
      // All pillars 100 → score 100 → Excellent.
      final r = svc.analyse([], [], []);
      expect(r.grade, 'Excellent');
    });

    test('OS-03: grade is Good when score >= 60 and < 80', () {
      // 1 budget Food 100 month 2026-05, 1 tx Food 200 (over) → BA = 0.
      // No bills → BR = 100. No history → SC = 50.
      // Overall = 0*0.40 + 100*0.35 + 50*0.25 = 0 + 35 + 12.5 = 47.5 → 48.
      // That is not >= 60. Need to arrange differently.
      // BA = 50 (1 budget half exceeded):
      //   2 budgets Food 100, Transport 100; Food over (200), Transport under (50)
      //   → 1 of 2 exceeded → score 50.
      // BR = 100 (no bills).
      // SC = 50 (no history).
      // Overall = 50*0.40 + 100*0.35 + 50*0.25 = 20 + 35 + 12.5 = 67.5 → 68 = 'Good'.
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
        const Budget(
          id: 'b2',
          category: 'Transport',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
        Transaction(
          id: 'tx2',
          amount: 50,
          merchant: 'Bus',
          category: 'Transport',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final r = svc.analyse(txs, budgets, []);
      expect(r.grade, 'Good');
    });

    test('OS-04: grade is Needs Attention when score >= 40 and < 60', () {
      // BA = 0 (1 budget exceeded), BR = 100 (no bills), SC = 50 (no history).
      // Overall = 0*0.40 + 100*0.35 + 50*0.25 = 47.5 → 48 = 'Needs Attention'.
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final r = svc.analyse(txs, budgets, []);
      expect(r.grade, 'Needs Attention');
    });

    test('OS-05: grade is At Risk when score < 40', () {
      // BA = 0, BR = 0 (all overdue), SC = 50.
      // Overall = 0*0.40 + 0*0.35 + 50*0.25 = 12.5 → 13 = 'At Risk'.
      final budgets = [
        const Budget(
          id: 'b1',
          category: 'Food',
          monthlyLimit: 100,
          month: '2026-05',
        ),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 200,
          merchant: 'Shop',
          category: 'Food',
          date: DateTime(2026, 5, 15),
        ),
      ];
      final bills = [
        BillReminder(
          id: 'bill1',
          name: 'Electric',
          amount: 80,
          dueDate: DateTime(2026, 4, 1),
          recurrence: 'one-off',
          isPaid: false,
        ),
      ];
      final r = svc.analyse(txs, budgets, bills);
      expect(r.grade, 'At Risk');
    });
  });

  // ── Insights ───────────────────────────────────────────────────────────────

  group('Insights', () {
    test(
      'insights are sorted by severity descending (alert first)',
      () {
        // Over-budget (alert) + overdue bill (alert) + high spend (warning).
        final budgets = [
          const Budget(
            id: 'b1',
            category: 'Food',
            monthlyLimit: 100,
            month: '2026-05',
          ),
        ];
        final txs = [
          Transaction(
            id: 'tx1',
            amount: 200,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 5, 15),
          ),
          Transaction(
            id: 'tx2',
            amount: 100,
            merchant: 'Shop',
            category: 'Food',
            date: DateTime(2026, 4, 15),
          ),
        ];
        final bills = [
          BillReminder(
            id: 'bill1',
            name: 'Netflix',
            amount: 15,
            dueDate: DateTime(2026, 4, 1),
            recurrence: 'monthly',
            isPaid: false,
          ),
        ];
        final r = svc.analyse(txs, budgets, bills);
        // Verify sort order: no info before warning, no warning before alert.
        for (var i = 0; i < r.insights.length - 1; i++) {
          expect(
            r.insights[i].severity.sortWeight,
            greaterThanOrEqualTo(r.insights[i + 1].severity.sortWeight),
          );
        }
        // First insight must be an alert.
        expect(r.insights.first.severity, InsightSeverity.alert);
        // Last insight must be info.
        expect(r.insights.last.severity, InsightSeverity.info);
      },
    );
  });
}
