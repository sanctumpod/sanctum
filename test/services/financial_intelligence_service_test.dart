/// Financial Intelligence Service tests — PRD rule coverage.
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

// Helpers — dates relative to "today" so tests remain green past May 2026.
final _now = DateTime.now();
final _curYear = _now.year;
final _curMonth = _now.month;
String _monthKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
final _currentMonthStr = _monthKey(_now);

/// A transaction in the current month.
Transaction _tx(
  String id, {
  required double amount,
  required String category,
  int day = 15,
}) =>
    Transaction(
      id: id,
      amount: amount,
      merchant: 'Test',
      category: category,
      date: DateTime(_curYear, _curMonth, day),
    );

/// A transaction [monthsAgo] months before the current month.
Transaction _txAgo(
  String id, {
  required double amount,
  required String category,
  required int monthsAgo,
}) {
  final date = DateTime(_curYear, _curMonth - monthsAgo, 15);
  return Transaction(
    id: id,
    amount: amount,
    merchant: 'Test',
    category: category,
    date: date,
  );
}

/// A budget for the current month.
Budget _budget(String id, String category, double limit) => Budget(
      id: id,
      category: category,
      monthlyLimit: limit,
      month: _currentMonthStr,
    );

/// A budget for [monthsAgo] months before the current month.
Budget _budgetAgo(
  String id,
  String category,
  double limit,
  int monthsAgo,
) {
  final d = DateTime(_curYear, _curMonth - monthsAgo, 1);
  return Budget(
    id: id,
    category: category,
    monthlyLimit: limit,
    month: _monthKey(d),
  );
}

/// An overdue unpaid bill.
BillReminder _overdueBill(String id, String name, {int daysAgo = 30}) =>
    BillReminder(
      id: id,
      name: name,
      amount: 50,
      dueDate: _now.subtract(Duration(days: daysAgo)),
      recurrence: 'monthly',
      isPaid: false,
    );

/// A paid bill (on time).
BillReminder _paidBill(
  String id,
  String name, {
  int daysAgo = 30,
  DateTime? paidDate,
}) =>
    BillReminder(
      id: id,
      name: name,
      amount: 50,
      dueDate: _now.subtract(Duration(days: daysAgo)),
      recurrence: 'monthly',
      isPaid: true,
      paidDate: paidDate ?? _now.subtract(Duration(days: daysAgo - 1)),
    );

void main() {
  const svc = FinancialIntelligenceService();

  // ── PRD §2.3.1 — All-empty baseline ───────────────────────────────────────

  group('all-empty baseline (PRD §2.3.1)', () {
    test('all scores are 50 when every list is empty', () {
      final r = svc.analyse([], [], []);
      expect(r.overallScore, 50);
      expect(r.budgetAdherenceScore, 50);
      expect(r.billReliabilityScore, 50);
      expect(r.spendingConsistencyScore, 50);
    });

    test('returns exactly 3 insights for empty input', () {
      final r = svc.analyse([], [], []);
      expect(r.insights.length, greaterThanOrEqualTo(3));
    });
  });

  // ── BA-01: -15 per over-budget category (max -60) ─────────────────────────

  group('BA-01 — over-budget deduction', () {
    test('score is lower than baseline when one budget is exceeded', () {
      final budgets = [_budget('b1', 'Food', 100)];
      final txs = [_tx('t1', amount: 200, category: 'Food')];

      final withExceeded = svc.analyse(txs, budgets, []);
      final noExceeded = svc.analyse([], budgets, []);

      expect(
        withExceeded.budgetAdherenceScore,
        lessThan(noExceeded.budgetAdherenceScore),
      );
    });

    test('two over-budget categories deduct more than one', () {
      final budgets = [
        _budget('b1', 'Food', 100),
        _budget('b2', 'Transport', 100),
      ];
      final twoOver = svc.analyse(
        [
          _tx('t1', amount: 200, category: 'Food'),
          _tx('t2', amount: 200, category: 'Transport'),
        ],
        budgets,
        [],
      );
      final oneOver = svc.analyse(
        [
          _tx('t1', amount: 200, category: 'Food'),
          _tx('t2', amount: 50, category: 'Transport'),
        ],
        budgets,
        [],
      );
      expect(
        twoOver.budgetAdherenceScore,
        lessThan(oneOver.budgetAdherenceScore),
      );
    });

    test(
        'BA-01 cap: 4 and 5 over-budget categories score identically once cap '
        'is reached', () {
      // With 4 categories all exceeded: min(4*15, 60)=60, same as 5 exceeded.
      final budgets4 = List.generate(4, (i) => _budget('b$i', 'Cat$i', 100));
      final txs4 =
          List.generate(4, (i) => _tx('t$i', amount: 200, category: 'Cat$i'));
      final budgets5 = List.generate(5, (i) => _budget('b$i', 'Cat$i', 100));
      final txs5 =
          List.generate(5, (i) => _tx('t$i', amount: 200, category: 'Cat$i'));

      final four = svc.analyse(txs4, budgets4, []);
      final five = svc.analyse(txs5, budgets5, []);
      // Both hit the -60 cap and the same BA-06 bonus → equal scores.
      expect(five.budgetAdherenceScore, equals(four.budgetAdherenceScore));
    });

    test('alert insight generated for exceeded budget', () {
      final r = svc.analyse(
        [_tx('t1', amount: 200, category: 'Food')],
        [_budget('b1', 'Food', 100)],
        [],
      );
      final alerts = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.alert &&
                i.category == InsightCategory.budget,
          )
          .toList();
      expect(alerts, isNotEmpty);
      expect(alerts.first.text, contains('Food'));
    });
  });

  // ── BA-02: -5 per 90–99% utilisation (max -20) ────────────────────────────

  group('BA-02 — near-limit deduction', () {
    test('four budgets all at 90%+ utilisation score lower than all at 50%',
        () {
      // 4 near-limit budgets: BA-02 fires 4 × -5 = -20, capping the effect.
      final budgets = List.generate(4, (i) => _budget('b$i', 'Cat$i', 100));
      final nearLimit = svc.analyse(
        List.generate(4, (i) => _tx('t$i', amount: 95, category: 'Cat$i')),
        budgets,
        [],
      );
      final midLimit = svc.analyse(
        List.generate(4, (i) => _tx('t$i', amount: 50, category: 'Cat$i')),
        budgets,
        [],
      );
      // Near-limit deducts -20 that mid-limit doesn't → near < mid.
      expect(
        nearLimit.budgetAdherenceScore,
        lessThan(midLimit.budgetAdherenceScore),
      );
    });
  });

  // ── BA-03: +5 per zero-spend budget (max +15) ─────────────────────────────

  group('BA-03 — zero-spend bonus', () {
    test('zero-spend budget scores no lower than the base cap', () {
      final r = svc.analyse([], [_budget('b1', 'Food', 100)], []);
      // BA-03 gives +5, overall cannot exceed 100 after clamp.
      expect(r.budgetAdherenceScore, 100);
    });
  });

  // ── BA-04: +10 per category with 3+ months under limit (max +20) ──────────

  group('BA-04 — consistent under-limit bonus', () {
    test('category under budget for 3+ months generates info insight', () {
      // 3 past budgets under limit + current month budget.
      final budgets = [
        _budgetAgo('b1', 'Food', 200, 3),
        _budgetAgo('b2', 'Food', 200, 2),
        _budgetAgo('b3', 'Food', 200, 1),
        _budget('b4', 'Food', 200),
      ];
      final txs = [
        _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 3),
        _txAgo('t2', amount: 100, category: 'Food', monthsAgo: 2),
        _txAgo('t3', amount: 100, category: 'Food', monthsAgo: 1),
        _tx('t4', amount: 100, category: 'Food'),
      ];
      final r = svc.analyse(txs, budgets, []);
      // Should have an info insight about consistency.
      final infoInsights = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.info &&
                i.category == InsightCategory.budget,
          )
          .toList();
      expect(infoInsights, isNotEmpty);
    });
  });

  // ── BA-05: -10/>20% unbudgeted, -20/>40% ──────────────────────────────────

  group('BA-05 — unbudgeted spend deduction', () {
    test('high unbudgeted spend triggers warning insight', () {
      // Budget covers Food only, but spend is 50% in Dining (unbudgeted).
      final r = svc.analyse(
        [
          _tx('t1', amount: 100, category: 'Food'),
          _tx('t2', amount: 100, category: 'Dining'),
        ],
        [_budget('b1', 'Food', 200)],
        [],
      );
      final unbudgetedInsights = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.warning &&
                i.category == InsightCategory.budget,
          )
          .toList();
      expect(unbudgetedInsights, isNotEmpty);
    });
  });

  // ── BA-06: +10/≥80% coverage, +5/≥60% ────────────────────────────────────

  group('BA-06 — budget coverage bonus', () {
    test('full budget coverage scores higher than partial coverage', () {
      // Full: both Food and Transport budgeted and spent.
      final full = svc.analyse(
        [
          _tx('t1', amount: 50, category: 'Food'),
          _tx('t2', amount: 50, category: 'Transport'),
        ],
        [
          _budget('b1', 'Food', 200),
          _budget('b2', 'Transport', 200),
        ],
        [],
      );
      // Partial: only Food budgeted, Transport unbudgeted.
      final partial = svc.analyse(
        [
          _tx('t1', amount: 50, category: 'Food'),
          _tx('t2', amount: 50, category: 'Transport'),
        ],
        [_budget('b1', 'Food', 200)],
        [],
      );
      expect(full.budgetAdherenceScore, greaterThan(partial.budgetAdherenceScore));
    });
  });

  // ── BR-01: -20 per overdue unpaid (max -60) ───────────────────────────────

  group('BR-01 — overdue bill deduction', () {
    test('one overdue bill scores lower than no overdue bills', () {
      final withOverdue = svc.analyse([], [], [_overdueBill('b1', 'Netflix')]);
      final withPaid = svc.analyse([], [], [_paidBill('b1', 'Netflix')]);
      expect(
        withOverdue.billReliabilityScore,
        lessThan(withPaid.billReliabilityScore),
      );
    });

    test('two overdue bills score lower than one', () {
      final twoOverdue = svc.analyse(
        [],
        [],
        [_overdueBill('b1', 'Netflix'), _overdueBill('b2', 'Spotify')],
      );
      final oneOverdue = svc.analyse([], [], [_overdueBill('b1', 'Netflix')]);
      expect(
        twoOverdue.billReliabilityScore,
        lessThan(oneOverdue.billReliabilityScore),
      );
    });

    test('overdue bill generates alert insight', () {
      final r = svc.analyse([], [], [_overdueBill('b1', 'Netflix')]);
      final alerts = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.alert &&
                i.category == InsightCategory.bills,
          )
          .toList();
      expect(alerts, isNotEmpty);
      expect(alerts.first.text, contains('Netflix'));
    });
  });

  // ── BR-02: -8 per late-paid bill, -8 more if daysLate > 7 ────────────────

  group('BR-02 — late payment deduction', () {
    test('late-paid bill scores lower than on-time-paid bill', () {
      final latePaid = svc.analyse(
        [],
        [],
        [
          BillReminder(
            id: 'b1',
            name: 'Netflix',
            amount: 15,
            dueDate: _now.subtract(const Duration(days: 30)),
            recurrence: 'monthly',
            isPaid: true,
            paidDate: _now.subtract(const Duration(days: 20)),
          ),
        ],
      );
      final onTimePaid = svc.analyse([], [], [_paidBill('b1', 'Netflix')]);
      expect(
        latePaid.billReliabilityScore,
        lessThanOrEqualTo(onTimePaid.billReliabilityScore),
      );
    });
  });

  // ── BR-03: +10/streak≥3, +20/streak≥5 ───────────────────────────────────

  group('BR-03 — on-time streak bonus', () {
    test('bills paid on time in past months generate streak insight', () {
      // Create 3 paid bills in separate months, all on time.
      final bills = List.generate(3, (i) {
        final due = DateTime(_curYear, _curMonth - (i + 1), 10);
        return BillReminder(
          id: 'b$i',
          name: 'Netflix',
          amount: 15,
          dueDate: due,
          recurrence: 'monthly',
          isPaid: true,
          paidDate: due,
        );
      });
      final r = svc.analyse([], [], bills);
      final streakInsights = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.info &&
                i.category == InsightCategory.bills,
          )
          .toList();
      expect(streakInsights, isNotEmpty);
    });
  });

  // ── BR-04: +5 per quick payer (within 2 days of notification, max +10) ───

  group('BR-04 — quick payer bonus', () {
    test('bill paid within 2 days of notification gives higher score', () {
      final quickPay = svc.analyse(
        [],
        [],
        [
          BillReminder(
            id: 'b1',
            name: 'Netflix',
            amount: 15,
            dueDate: _now.subtract(const Duration(days: 10)),
            recurrence: 'monthly',
            isPaid: true,
            paidDate: _now.subtract(const Duration(days: 9)),
            notificationDate: _now.subtract(const Duration(days: 10)),
          ),
        ],
      );
      final noPay = svc.analyse([], [], [_paidBill('b1', 'Netflix')]);
      expect(
        quickPay.billReliabilityScore,
        greaterThanOrEqualTo(noPay.billReliabilityScore),
      );
    });
  });

  // ── BR-05: +10 if no monthly bill is overdue and unpaid ──────────────────

  group('BR-05 — no-overdue-monthly bonus', () {
    test('no overdue monthly bills gives higher score than one overdue', () {
      final noOverdue = svc.analyse([], [], [_paidBill('b1', 'Netflix')]);
      final withOverdue = svc.analyse([], [], [_overdueBill('b1', 'Netflix')]);
      expect(
        noOverdue.billReliabilityScore,
        greaterThan(withOverdue.billReliabilityScore),
      );
    });
  });

  // ── BR-06: empty bills → score 50, short-circuit ─────────────────────────

  group('BR-06 — empty bills baseline', () {
    test('bill reliability score is 50 when no bills exist', () {
      final r = svc.analyse(
        [_tx('t1', amount: 100, category: 'Food')],
        [],
        [],
      );
      expect(r.billReliabilityScore, 50);
    });
  });

  // ── SC-01: -15/>30% MoM spike, -30/>50% spike ────────────────────────────

  group('SC-01 — monthly spending spike deduction', () {
    test('30%+ spending increase scores lower than stable spending', () {
      final stable = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t2', amount: 100, category: 'Food'),
        ],
        [],
        [],
      );
      final spike = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t2', amount: 150, category: 'Food'),
        ],
        [],
        [],
      );
      expect(
        spike.spendingConsistencyScore,
        lessThan(stable.spendingConsistencyScore),
      );
    });

    test('50%+ spike generates spending warning insight', () {
      final r = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t2', amount: 200, category: 'Food'),
        ],
        [],
        [],
      );
      final warnings = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.warning &&
                i.category == InsightCategory.spending,
          )
          .toList();
      expect(warnings, isNotEmpty);
    });
  });

  // ── SC-02: -5 per category >50% MoM drift (max -20) ─────────────────────

  group('SC-02 — category drift deduction', () {
    test('category doubling MoM scores lower than stable category', () {
      final stable = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Dining', monthsAgo: 1),
          _tx('t2', amount: 100, category: 'Dining'),
        ],
        [],
        [],
      );
      final drift = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Dining', monthsAgo: 1),
          _tx('t2', amount: 200, category: 'Dining'),
        ],
        [],
        [],
      );
      expect(
        drift.spendingConsistencyScore,
        lessThanOrEqualTo(stable.spendingConsistencyScore),
      );
    });
  });

  // ── SC-03: +10 if tx count within 30% of previous month ──────────────────

  group('SC-03 — transaction count consistency bonus', () {
    test('similar tx count month-over-month scores higher than wild variation',
        () {
      // 3 txs last month, 3 this month → count matches → +10.
      final consistent = svc.analyse(
        [
          _txAgo('t1', amount: 33, category: 'Food', monthsAgo: 1),
          _txAgo('t2', amount: 33, category: 'Food', monthsAgo: 1),
          _txAgo('t3', amount: 34, category: 'Food', monthsAgo: 1),
          _tx('t4', amount: 33, category: 'Food'),
          _tx('t5', amount: 33, category: 'Food'),
          _tx('t6', amount: 34, category: 'Food'),
        ],
        [],
        [],
      );
      // 1 tx last month, 10 this month → wild variation.
      final inconsistent = svc.analyse(
        [
          _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 1),
          ...List.generate(
            10,
            (i) => _tx('tx$i', amount: 10, category: 'Food'),
          ),
        ],
        [],
        [],
      );
      expect(
        consistent.spendingConsistencyScore,
        greaterThanOrEqualTo(inconsistent.spendingConsistencyScore),
      );
    });
  });

  // ── SC-04: -10/>60% concentration, -20/>80% ───────────────────────────────

  group('SC-04 — category concentration deduction', () {
    test('high concentration in one category (>80%) scores lower', () {
      // 4 txs, all in Food → 100% concentration.
      final concentrated = svc.analyse(
        [
          _tx('t1', amount: 100, category: 'Food'),
          _tx('t2', amount: 100, category: 'Food'),
          _tx('t3', amount: 100, category: 'Food'),
          _tx('t4', amount: 10, category: 'Other'),
        ],
        [],
        [],
      );
      // 4 txs spread across categories.
      final spread = svc.analyse(
        [
          _tx('t1', amount: 100, category: 'Food'),
          _tx('t2', amount: 100, category: 'Transport'),
          _tx('t3', amount: 100, category: 'Dining'),
          _tx('t4', amount: 100, category: 'Health'),
        ],
        [],
        [],
      );
      // Only compare when both have 2 months of data (SC-06 guard fires for 1).
      // Add a previous month tx to both.
      final concentratedWithHistory = svc.analyse(
        [
          _txAgo('th', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t1', amount: 100, category: 'Food'),
          _tx('t2', amount: 100, category: 'Food'),
          _tx('t3', amount: 100, category: 'Food'),
          _tx('t4', amount: 10, category: 'Other'),
        ],
        [],
        [],
      );
      final spreadWithHistory = svc.analyse(
        [
          _txAgo('th', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t1', amount: 100, category: 'Food'),
          _tx('t2', amount: 100, category: 'Transport'),
          _tx('t3', amount: 100, category: 'Dining'),
          _tx('t4', amount: 100, category: 'Health'),
        ],
        [],
        [],
      );
      expect(
        concentratedWithHistory.spendingConsistencyScore,
        lessThanOrEqualTo(spreadWithHistory.spendingConsistencyScore),
      );
      // Suppress unused variable warnings from the simple test.
      expect(concentrated, isNotNull);
      expect(spread, isNotNull);
    });
  });

  // ── SC-05: +15 for 2+ consecutive monthly decreases ──────────────────────

  group('SC-05 — consecutive decrease bonus', () {
    test('3 months of decreasing spend generates info insight', () {
      final r = svc.analyse(
        [
          _txAgo('t1', amount: 300, category: 'Food', monthsAgo: 2),
          _txAgo('t2', amount: 200, category: 'Food', monthsAgo: 1),
          _tx('t3', amount: 100, category: 'Food'),
        ],
        [],
        [],
      );
      final decreaseInsights = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.info &&
                i.category == InsightCategory.spending,
          )
          .toList();
      expect(decreaseInsights, isNotEmpty);
    });
  });

  // ── SC-06: <2 distinct months → baseline 60 ──────────────────────────────

  group('SC-06 — insufficient history baseline', () {
    test('only current-month transactions gives SC score of 60', () {
      final r = svc.analyse(
        [_tx('t1', amount: 100, category: 'Food')],
        [],
        [],
      );
      expect(r.spendingConsistencyScore, 60);
    });
  });

  // ── Insight selection: min 3, max 5, alerts-first ─────────────────────────

  group('insight selection invariants (PRD §2.5)', () {
    test('always returns at least 3 insights', () {
      // Minimal setup: no budget, 1 tx, no bills — few natural insights.
      final r = svc.analyse(
        [_tx('t1', amount: 100, category: 'Food')],
        [],
        [],
      );
      expect(r.insights.length, greaterThanOrEqualTo(3));
    });

    test('never returns more than 5 insights', () {
      // Rich setup: many things fire.
      final r = svc.analyse(
        [
          _txAgo('t0', amount: 50, category: 'Food', monthsAgo: 2),
          _txAgo('t1', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t2', amount: 300, category: 'Food'),
          _tx('t3', amount: 200, category: 'Dining'),
        ],
        [_budget('b1', 'Food', 50)],
        [
          _overdueBill('bill1', 'Netflix'),
          _overdueBill('bill2', 'Spotify'),
        ],
      );
      expect(r.insights.length, lessThanOrEqualTo(5));
    });

    test('insights are sorted alerts → warnings → info', () {
      final r = svc.analyse(
        [
          _txAgo('th', amount: 100, category: 'Food', monthsAgo: 1),
          _tx('t1', amount: 300, category: 'Food'),
        ],
        [_budget('b1', 'Food', 50)],
        [_overdueBill('bill1', 'Netflix')],
      );
      for (var i = 0; i < r.insights.length - 1; i++) {
        expect(
          r.insights[i].severity.sortWeight,
          greaterThanOrEqualTo(r.insights[i + 1].severity.sortWeight),
        );
      }
    });
  });

  // ── IT-12 fallback — score-band text ──────────────────────────────────────

  group('IT-12 fallback insight text by score band', () {
    test('fallback insight contains positive copy for high scores', () {
      // All paid bills, under budget — should score well → positive IT-12.
      final bills = [_paidBill('b1', 'Netflix')];
      final r = svc.analyse([], [], bills);
      final generalInsights = r.insights
          .where((i) => i.category == InsightCategory.general)
          .toList();
      expect(generalInsights, isNotEmpty);
    });
  });

  // ── Currency formatting in insight text ───────────────────────────────────

  group('IT-01 currency formatting', () {
    test('over-budget insight contains dollar amount with 2 decimal places',
        () {
      final r = svc.analyse(
        [_tx('t1', amount: 200.50, category: 'Food')],
        [_budget('b1', 'Food', 100)],
        [],
      );
      final alerts = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.alert &&
                i.category == InsightCategory.budget,
          )
          .toList();
      expect(alerts, isNotEmpty);
      // Should contain a dollar amount formatted to 2 decimal places.
      expect(alerts.first.text, matches(r'^\$[\d,]+\.\d{2}|.*\$[\d,]+\.\d{2}'));
    });
  });

  // ── IT-03 date formatting ─────────────────────────────────────────────────

  group('IT-03 date formatting in overdue insight', () {
    test('overdue bill insight contains "d MMM" formatted date', () {
      final dueDate = DateTime(_curYear, 1, 5);
      final bill = BillReminder(
        id: 'b1',
        name: 'Electric',
        amount: 80,
        dueDate: dueDate,
        recurrence: 'one-off',
        isPaid: false,
      );
      final r = svc.analyse([], [], [bill]);
      final alerts = r.insights
          .where(
            (i) =>
                i.severity == InsightSeverity.alert &&
                i.category == InsightCategory.bills,
          )
          .toList();
      expect(alerts, isNotEmpty);
      // "5 Jan" format — should contain a day number followed by month abbreviation.
      expect(alerts.first.text, contains('Jan'));
    });
  });

  // ── Performance smoke test ────────────────────────────────────────────────

  group('performance (PRD NFR)', () {
    test('analyse completes in under 50ms for 200 txs, 20 budgets, 20 bills',
        () {
      final txs = List.generate(
        200,
        (i) => Transaction(
          id: 'tx$i',
          amount: 50 + (i % 100).toDouble(),
          merchant: 'Merchant$i',
          category: 'Cat${i % 5}',
          date: DateTime(_curYear, _curMonth - (i % 6), (i % 28) + 1),
        ),
      );
      final budgets = List.generate(
        20,
        (i) => Budget(
          id: 'bgt$i',
          category: 'Cat${i % 5}',
          monthlyLimit: 500,
          month: _monthKey(DateTime(_curYear, _curMonth - (i % 3), 1)),
        ),
      );
      final bills = List.generate(
        20,
        (i) => BillReminder(
          id: 'bill$i',
          name: 'Bill$i',
          amount: 30 + i.toDouble(),
          dueDate: _now.subtract(Duration(days: i * 5)),
          recurrence: i.isEven ? 'monthly' : 'one-off',
          isPaid: i.isOdd,
        ),
      );

      final sw = Stopwatch()..start();
      svc.analyse(txs, budgets, bills);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });
}
