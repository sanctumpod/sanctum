/// Pure-Dart financial intelligence engine for Sanctum.
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
import 'dart:math' show max, min;

// Group 2: Third-party package imports.
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/models/transaction.dart';

/// Pure-Dart synchronous financial intelligence engine implementing all 18
/// PRD scoring rules across three pillars.
///
/// No I/O, no async, no Flutter — pure Dart only.
class FinancialIntelligenceService {
  /// Creates a [FinancialIntelligenceService].
  const FinancialIntelligenceService();

  static final _currency = NumberFormat.currency(
    locale: 'en_AU',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final _date = DateFormat('d MMM');

  /// Analyses financial data and returns a [FinancialIntelligenceResult].
  ///
  /// Short-circuits to a neutral baseline when all inputs are empty (PRD §2.3.1).
  /// Otherwise applies the 18 named rules across three pillars and selects 3–5
  /// insights (alerts first, then warnings, then info).
  FinancialIntelligenceResult analyse(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<BillReminder> bills,
  ) {
    // Short-circuit: all-empty → neutral baseline.
    if (transactions.isEmpty && budgets.isEmpty && bills.isEmpty) {
      return _emptyResult();
    }

    final now = DateTime.now();
    final currentMonth = _monthKey(now);

    final ba = _budgetAdherence(transactions, budgets, currentMonth);
    final br = _billReliability(bills, now);
    final sc = _spendingConsistency(transactions, currentMonth);

    final overall =
        (ba.score * 0.40 + br.score * 0.35 + sc.score * 0.25)
            .round()
            .clamp(0, 100);

    // Sort all insights by severity (alert first), cap at 5, pad to min 3.
    final allInsights = <InsightString>[
      ...ba.insights,
      ...br.insights,
      ...sc.insights,
    ]..sort((a, b) => b.severity.sortWeight.compareTo(a.severity.sortWeight));

    final selected = allInsights.take(5).toList();
    while (selected.length < 3) {
      selected.add(_it12(overall));
    }

    return FinancialIntelligenceResult(
      overallScore: overall,
      budgetAdherenceScore: ba.score,
      billReliabilityScore: br.score,
      spendingConsistencyScore: sc.score,
      insights: selected,
    );
  }

  // ── Budget Adherence (40%) ────────────────────────────────────────────────

  _PillarResult _budgetAdherence(
    List<Transaction> transactions,
    List<Budget> budgets,
    String currentMonth,
  ) {
    final currentBudgets =
        budgets.where((b) => b.month == currentMonth).toList();

    if (currentBudgets.isEmpty) {
      return const _PillarResult(score: 50, insights: []);
    }

    // Spend per category for the current month.
    final currentSpend = _spendByCategory(transactions, currentMonth);
    final totalCurrentSpend = currentSpend.values.fold(0.0, (s, v) => s + v);

    var score = 100;
    final insights = <InsightString>[];

    // BA-01: -15 per over-budget category (max -60).
    var ba01Count = 0;
    Budget? ba01Worst;
    var ba01WorstPct = 0.0;
    for (final b in currentBudgets) {
      final spend = currentSpend[b.category] ?? 0;
      if (spend > b.monthlyLimit && b.monthlyLimit > 0) {
        ba01Count++;
        final pct = spend / b.monthlyLimit;
        if (pct > ba01WorstPct) {
          ba01WorstPct = pct;
          ba01Worst = b;
        }
      }
    }
    score -= min(ba01Count * 15, 60);

    if (ba01Worst != null) {
      final spend = currentSpend[ba01Worst.category] ?? 0;
      final over = spend - ba01Worst.monthlyLimit;
      insights.add(InsightString(
        text: 'You\'ve gone over your ${ba01Worst.category} budget by '
            '${_currency.format(over)} '
            '(limit ${_currency.format(ba01Worst.monthlyLimit)}, '
            'spent ${_currency.format(spend)}).',
        severity: InsightSeverity.alert,
        category: InsightCategory.budget,
      ));
    }

    // BA-02: -5 per budget at 90–99% utilisation (max -20).
    var ba02Count = 0;
    Budget? ba02NearMiss;
    for (final b in currentBudgets) {
      if (b.monthlyLimit <= 0) continue;
      final spend = currentSpend[b.category] ?? 0;
      final pct = spend / b.monthlyLimit;
      if (pct >= 0.90 && pct < 1.0) {
        ba02Count++;
        ba02NearMiss ??= b;
      }
    }
    score -= min(ba02Count * 5, 20);

    if (ba02NearMiss != null && ba01Worst == null) {
      final spend = currentSpend[ba02NearMiss.category] ?? 0;
      final remaining = ba02NearMiss.monthlyLimit - spend;
      insights.add(InsightString(
        text: 'Your ${ba02NearMiss.category} budget is nearly full — '
            'only ${_currency.format(remaining)} remaining.',
        severity: InsightSeverity.warning,
        category: InsightCategory.budget,
      ));
    }

    // BA-03: +5 per zero-spend budgeted category (max +15).
    var ba03Count = 0;
    for (final b in currentBudgets) {
      final spend = currentSpend[b.category] ?? 0;
      if (spend == 0) ba03Count++;
    }
    score += min(ba03Count * 5, 15);

    // BA-04: +10 per category consistent ≥3 months under limit (max +20).
    final budgetsByCategory = <String, List<Budget>>{};
    for (final b in budgets) {
      budgetsByCategory.putIfAbsent(b.category, () => []).add(b);
    }

    var ba04Bonus = 0;
    String? ba04BestCategory;
    var ba04BestMonths = 0;
    for (final entry in budgetsByCategory.entries) {
      final category = entry.key;
      var underCount = 0;
      for (final b in entry.value) {
        final spend =
            _spendByCategory(transactions, b.month)[category] ?? 0;
        if (spend < b.monthlyLimit) underCount++;
      }
      if (underCount >= 3) {
        ba04Bonus = min(ba04Bonus + 10, 20);
        if (underCount > ba04BestMonths) {
          ba04BestMonths = underCount;
          ba04BestCategory = category;
        }
      }
    }
    score += ba04Bonus;

    if (ba04BestCategory != null &&
        ba01Worst == null &&
        ba02NearMiss == null) {
      insights.add(InsightString(
        text: 'Great discipline! You\'ve stayed under your '
            '$ba04BestCategory budget for $ba04BestMonths months in a row.',
        severity: InsightSeverity.info,
        category: InsightCategory.budget,
      ));
    }

    // BA-05: -10 if unbudgeted spend >20%, -20 if >40%.
    final budgetedCategories =
        currentBudgets.map((b) => b.category).toSet();
    var unbudgetedSpend = 0.0;
    for (final entry in currentSpend.entries) {
      if (!budgetedCategories.contains(entry.key)) {
        unbudgetedSpend += entry.value;
      }
    }
    final unbudgetedRatio =
        totalCurrentSpend > 0 ? unbudgetedSpend / totalCurrentSpend : 0.0;
    var ba05Fired = false;
    if (unbudgetedRatio > 0.40) {
      score -= 20;
      ba05Fired = true;
    } else if (unbudgetedRatio > 0.20) {
      score -= 10;
      ba05Fired = true;
    }
    if (ba05Fired) {
      final pctStr = '${(unbudgetedRatio * 100).round()}%';
      insights.add(InsightString(
        text: '$pctStr of your spending this month is in categories '
            'without a budget. Consider adding budgets for those categories.',
        severity: InsightSeverity.warning,
        category: InsightCategory.budget,
      ));
    }

    // BA-06: +10 if ≥80% of tx categories are budgeted, +5 if ≥60%.
    final txCategories = currentSpend.keys.toSet();
    if (txCategories.isNotEmpty) {
      final coverage = budgetedCategories.intersection(txCategories).length /
          txCategories.length;
      if (coverage >= 0.80) {
        score += 10;
      } else if (coverage >= 0.60) {
        score += 5;
      }
    }

    return _PillarResult(
      score: score.clamp(0, 100),
      insights: insights,
    );
  }

  // ── Bill Reliability (35%) ────────────────────────────────────────────────

  _PillarResult _billReliability(List<BillReminder> bills, DateTime now) {
    // BR-06: empty list → score 50 baseline, short-circuit.
    if (bills.isEmpty) {
      return const _PillarResult(score: 50, insights: []);
    }

    var score = 100;
    final insights = <InsightString>[];

    // BR-01: -20 per overdue unpaid (max -60).
    final overdue =
        bills.where((b) => !b.isPaid && b.dueDate.isBefore(now)).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    score -= min(overdue.length * 20, 60);

    if (overdue.isNotEmpty) {
      final worst = overdue.first;
      final daysLate = now.difference(worst.dueDate).inDays;
      insights.add(InsightString(
        text: '${worst.name} is overdue by $daysLate day${daysLate == 1 ? '' : 's'} '
            '(was due ${_date.format(worst.dueDate)}, '
            '${_currency.format(worst.amount)}).',
        severity: InsightSeverity.alert,
        category: InsightCategory.bills,
      ));
    }

    // IT-04: warning for bills due in 1–5 days (unpaid).
    final soonDue = bills
        .where((b) =>
            !b.isPaid &&
            !b.dueDate.isBefore(now) &&
            b.dueDate.difference(now).inDays <= 5)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (soonDue.isNotEmpty) {
      final next = soonDue.first;
      final daysLeft = next.dueDate.difference(now).inDays;
      insights.add(InsightString(
        text: '${next.name} is due in $daysLeft day${daysLeft == 1 ? '' : 's'} '
            '(${_date.format(next.dueDate)}, '
            '${_currency.format(next.amount)}).',
        severity: InsightSeverity.warning,
        category: InsightCategory.bills,
      ));
    }

    // BR-02: -8 per late paid bill, -8 more if daysLate > 7 (max -40).
    var br02Deduction = 0;
    for (final b in bills) {
      if (!b.isPaid || b.paidDate == null) continue;
      if (b.paidDate!.isAfter(b.dueDate)) {
        final daysLate = b.paidDate!.difference(b.dueDate).inDays;
        br02Deduction += (daysLate > 7) ? 16 : 8;
      }
    }
    score -= min(br02Deduction, 40);

    // BR-03: +10 streak≥3 consecutive months, +20 streak≥5 (replaces).
    final streak = _onTimePaymentStreak(bills, now);
    if (streak >= 5) {
      score += 20;
      insights.add(InsightString(
        text: 'Excellent! You\'ve paid all bills on time for '
            '$streak months in a row. Keep it up!',
        severity: InsightSeverity.info,
        category: InsightCategory.bills,
      ));
    } else if (streak >= 3) {
      score += 10;
      insights.add(InsightString(
        text: 'Nice streak! All bills paid on time for $streak months running.',
        severity: InsightSeverity.info,
        category: InsightCategory.bills,
      ));
    }

    // BR-04: +5 per bill paid within 2 days of notification (max +10).
    var br04Bonus = 0;
    for (final b in bills) {
      if (!b.isPaid ||
          b.notificationDate == null ||
          b.paidDate == null) continue;
      final days = b.paidDate!.difference(b.notificationDate!).inDays.abs();
      if (days <= 2) br04Bonus += 5;
    }
    score += min(br04Bonus, 10);

    // BR-05: +10 if no monthly bill is both overdue and unpaid.
    final hasOverdueMonthly = bills.any(
      (b) =>
          b.recurrence == 'monthly' && !b.isPaid && b.dueDate.isBefore(now),
    );
    if (!hasOverdueMonthly && overdue.isEmpty) {
      score += 10;
    }

    return _PillarResult(
      score: score.clamp(0, 100),
      insights: insights,
    );
  }

  // ── Spending Consistency (25%) ────────────────────────────────────────────

  _PillarResult _spendingConsistency(
    List<Transaction> transactions,
    String currentMonth,
  ) {
    // Build month → total spend map.
    final monthTotals = <String, double>{};
    final monthTxCount = <String, int>{};
    final monthCategorySpend = <String, Map<String, double>>{};

    for (final tx in transactions) {
      final key = _monthKey(tx.date);
      monthTotals[key] = (monthTotals[key] ?? 0) + tx.amount;
      monthTxCount[key] = (monthTxCount[key] ?? 0) + 1;
      final catMap = monthCategorySpend.putIfAbsent(key, () => {});
      catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
    }

    // SC-06: fewer than 2 distinct months → baseline 60, short-circuit.
    if (monthTotals.length < 2) {
      return const _PillarResult(score: 60, insights: []);
    }

    // Sort months chronologically.
    final sortedMonths = monthTotals.keys.toList()..sort();
    final prevMonth =
        sortedMonths.length >= 2 ? sortedMonths[sortedMonths.length - 2] : null;

    final currentTotal = monthTotals[currentMonth] ?? 0;
    final prevTotal = prevMonth != null ? (monthTotals[prevMonth] ?? 0) : 0.0;

    var score = 100;
    final insights = <InsightString>[];

    // SC-01: -15 if current > prev*1.30, -30 if > prev*1.50 (replaces).
    var sc01Fired = false;
    if (prevTotal > 0 && currentTotal > prevTotal * 1.50) {
      score -= 30;
      sc01Fired = true;
      insights.add(InsightString(
        text: 'Your spending this month (${_currency.format(currentTotal)}) '
            'is significantly higher than last month '
            '(${_currency.format(prevTotal)}). Consider reviewing your expenses.',
        severity: InsightSeverity.warning,
        category: InsightCategory.spending,
      ));
    } else if (prevTotal > 0 && currentTotal > prevTotal * 1.30) {
      score -= 15;
      sc01Fired = true;
      insights.add(InsightString(
        text: 'Spending is up this month (${_currency.format(currentTotal)}) '
            'compared to last month (${_currency.format(prevTotal)}).',
        severity: InsightSeverity.warning,
        category: InsightCategory.spending,
      ));
    }

    // SC-02: -5 per category with >50% MoM drift (max -20).
    if (prevMonth != null) {
      final prevCats = monthCategorySpend[prevMonth] ?? {};
      final currCats = monthCategorySpend[currentMonth] ?? {};
      var sc02Count = 0;
      String? sc02WorstCategory;
      var sc02WorstRatio = 0.0;
      for (final cat in currCats.keys) {
        final prev = prevCats[cat] ?? 0;
        if (prev <= 0) continue;
        final ratio = currCats[cat]! / prev;
        if (ratio > 1.50) {
          sc02Count++;
          if (ratio > sc02WorstRatio) {
            sc02WorstRatio = ratio;
            sc02WorstCategory = cat;
          }
        }
      }
      score -= min(sc02Count * 5, 20);
      if (sc02WorstCategory != null && !sc01Fired) {
        final curr = currCats[sc02WorstCategory]!;
        final prev = prevCats[sc02WorstCategory] ?? 0;
        insights.add(InsightString(
          text: '$sc02WorstCategory spending jumped '
              '${((sc02WorstRatio - 1) * 100).round()}% this month '
              '(${_currency.format(curr)} vs ${_currency.format(prev)} last month).',
          severity: InsightSeverity.warning,
          category: InsightCategory.spending,
        ));
      }
    }

    // SC-03: +10 if current tx count within 30% of previous month.
    if (prevMonth != null) {
      final currCount = monthTxCount[currentMonth] ?? 0;
      final prevCount = monthTxCount[prevMonth] ?? 0;
      if (prevCount > 0) {
        final countRatio = (currCount - prevCount).abs() / prevCount;
        if (countRatio <= 0.30) score += 10;
      }
    }

    // SC-04: -10 if top category > 60% of spend, -20 if > 80%; skip if <3 tx.
    final currCatSpend = monthCategorySpend[currentMonth] ?? {};
    final currTotal = monthTotals[currentMonth] ?? 0;
    final currTxCount = monthTxCount[currentMonth] ?? 0;
    if (currTxCount >= 3 && currTotal > 0 && currCatSpend.isNotEmpty) {
      final topSpend =
          currCatSpend.values.reduce((a, b) => a > b ? a : b);
      final topCategory = currCatSpend.entries
          .firstWhere((e) => e.value == topSpend)
          .key;
      final topRatio = topSpend / currTotal;
      if (topRatio > 0.80) {
        score -= 20;
        insights.add(InsightString(
          text: '${(topRatio * 100).round()}% of this month\'s spending '
              'is concentrated in $topCategory. '
              'Diversifying your budget may help.',
          severity: InsightSeverity.warning,
          category: InsightCategory.spending,
        ));
      } else if (topRatio > 0.60) {
        score -= 10;
        insights.add(InsightString(
          text: '$topCategory accounts for ${(topRatio * 100).round()}% '
              'of your spending this month.',
          severity: InsightSeverity.warning,
          category: InsightCategory.spending,
        ));
      }
    }

    // SC-05: +15 if 2+ consecutive month-over-month decreases (3+ months data).
    if (sortedMonths.length >= 3) {
      var consecutiveDecreases = 0;
      var maxConsecutive = 0;
      for (var i = 1; i < sortedMonths.length; i++) {
        final prev = monthTotals[sortedMonths[i - 1]] ?? 0;
        final curr = monthTotals[sortedMonths[i]] ?? 0;
        if (curr < prev) {
          consecutiveDecreases++;
          maxConsecutive = max(maxConsecutive, consecutiveDecreases);
        } else {
          consecutiveDecreases = 0;
        }
      }
      if (maxConsecutive >= 2) {
        score += 15;
        insights.add(const InsightString(
          text: 'Well done! Your spending has been decreasing '
              'consistently over multiple months.',
          severity: InsightSeverity.info,
          category: InsightCategory.spending,
        ));
      }
    }

    return _PillarResult(
      score: score.clamp(0, 100),
      insights: insights,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the number of consecutive past months where all bills were paid
  /// on time (paid on or before dueDate), ending at the month prior to [now].
  int _onTimePaymentStreak(List<BillReminder> bills, DateTime now) {
    // Only consider paid bills.
    final paidBills = bills.where((b) => b.isPaid).toList();
    if (paidBills.isEmpty) return 0;

    // Group paid bills by due month.
    final byMonth = <String, List<BillReminder>>{};
    for (final b in paidBills) {
      byMonth.putIfAbsent(_monthKey(b.dueDate), () => []).add(b);
    }

    // Walk backwards from last month, counting consecutive all-on-time months.
    var streak = 0;
    var checkDate = DateTime(now.year, now.month - 1);
    while (true) {
      if (checkDate.month <= 0) {
        checkDate = DateTime(checkDate.year - 1, 12);
      }
      final key = _monthKey(checkDate);
      final monthBills = byMonth[key];
      if (monthBills == null) break;
      final allOnTime = monthBills.every(
        (b) =>
            b.paidDate == null ||
            !b.paidDate!.isAfter(b.dueDate),
      );
      if (!allOnTime) break;
      streak++;
      checkDate = DateTime(checkDate.year, checkDate.month - 1);
    }
    return streak;
  }

  /// Returns category → total spend for [transactions] in [month].
  Map<String, double> _spendByCategory(
    List<Transaction> transactions,
    String month,
  ) {
    final result = <String, double>{};
    for (final tx in transactions) {
      if (_monthKey(tx.date) != month) continue;
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }

  /// Returns the IT-12 fallback insight text appropriate for [overallScore].
  InsightString _it12(int overallScore) {
    final text = switch (overallScore) {
      >= 80 =>
        'You\'re doing great! Keep maintaining your excellent financial habits.',
      >= 60 =>
        'Good progress! Small consistent improvements will strengthen your score further.',
      >= 40 =>
        'There\'s room to improve — focus on budgeting and paying bills on time.',
      _ =>
        'Your finances need attention. Start by tackling overdue bills and setting budgets.',
    };
    return InsightString(
      text: text,
      severity: InsightSeverity.info,
      category: InsightCategory.general,
    );
  }

  /// Returns the all-empty baseline result (PRD §2.3.1).
  FinancialIntelligenceResult _emptyResult() {
    return const FinancialIntelligenceResult(
      overallScore: 50,
      budgetAdherenceScore: 50,
      billReliabilityScore: 50,
      spendingConsistencyScore: 50,
      insights: [
        InsightString(
          text: 'Welcome to Sanctum! Add transactions, set budgets, and '
              'schedule bills to get your personalised Financial Health Score.',
          severity: InsightSeverity.info,
          category: InsightCategory.general,
        ),
        InsightString(
          text: 'Set a monthly budget for your top spending categories '
              'to keep your finances on track.',
          severity: InsightSeverity.info,
          category: InsightCategory.budget,
        ),
        InsightString(
          text: 'Add recurring bills so Sanctum can remind you before '
              'payments are due.',
          severity: InsightSeverity.info,
          category: InsightCategory.bills,
        ),
      ],
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Returns the ISO year-month key for [dt], e.g. `'2026-05'`.
String _monthKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

/// Internal result type for a single scoring pillar.
class _PillarResult {
  const _PillarResult({
    required this.score,
    required this.insights,
  });

  /// Pillar score clamped to 0–100.
  final int score;

  /// Insights generated by this pillar.
  final List<InsightString> insights;
}
