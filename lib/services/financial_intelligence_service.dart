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
import 'dart:math' show max;

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/models/transaction.dart';

/// Pure-Dart synchronous financial intelligence engine.
///
/// Takes the three core data lists, applies scoring rules across three pillars,
/// and produces a [FinancialIntelligenceResult]. No I/O, no async, no external
/// dependencies.
class FinancialIntelligenceService {
  /// Creates a [FinancialIntelligenceService].
  const FinancialIntelligenceService();

  /// Analyses financial data and returns a [FinancialIntelligenceResult].
  ///
  /// Computes scores for Budget Adherence, Bill Reliability, and Spending
  /// Consistency, then combines them into a weighted overall score.
  FinancialIntelligenceResult analyse(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<BillReminder> bills,
  ) {
    final now = DateTime.now();
    final currentMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final ba = _budgetAdherence(transactions, budgets, currentMonth);
    final br = _billReliability(bills, now);
    final sc = _spendingConsistency(transactions, currentMonth);

    // When SC has no historical data it returns the neutral score of 50.
    // If there are also no transactions at all, treat SC as fully neutral (100)
    // so that an empty dataset does not penalise the overall score.
    final scOverallScore =
        (sc.isNeutral && transactions.isEmpty) ? 100 : sc.score;
    final overall =
        (ba.score * 0.40 + br.score * 0.35 + scOverallScore * 0.25).round();

    // Collect all pillar insights plus a mandatory general info insight.
    final insights = <InsightString>[
      ...ba.insights,
      ...br.insights,
      ...sc.insights,
      const InsightString(
        text: 'Keep tracking your transactions and bills to improve your '
            'Financial Health Score over time.',
        severity: InsightSeverity.info,
        category: InsightCategory.general,
      ),
    ]..sort(
      (a, b) => b.severity.sortWeight.compareTo(a.severity.sortWeight),
    );

    return FinancialIntelligenceResult(
      overallScore: overall,
      budgetAdherenceScore: ba.score,
      billReliabilityScore: br.score,
      spendingConsistencyScore: sc.score,
      insights: insights,
    );
  }

  // ── Budget Adherence pillar ────────────────────────────────────────────────

  _PillarResult _budgetAdherence(
    List<Transaction> transactions,
    List<Budget> budgets,
    String currentMonth,
  ) {
    // Filter to current-month budgets only.
    final currentBudgets =
        budgets.where((b) => b.month == currentMonth).toList();

    // No current-month budgets → neutral score, no insights.
    if (currentBudgets.isEmpty) {
      return const _PillarResult(score: 100, insights: []);
    }

    // Sum spend per category for the current month.
    final spendByCategory = <String, double>{};
    for (final tx in transactions) {
      final txMonth =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      if (txMonth != currentMonth) continue;
      spendByCategory[tx.category] =
          (spendByCategory[tx.category] ?? 0) + tx.amount;
    }

    // Count exceeded budgets.
    var exceededCount = 0;
    final exceededBudgets = <Budget>[];
    for (final b in currentBudgets) {
      final spend = spendByCategory[b.category] ?? 0;
      if (spend > b.monthlyLimit) {
        exceededCount++;
        exceededBudgets.add(b);
      }
    }

    // Score = percentage of budgets NOT exceeded.
    final score =
        ((currentBudgets.length - exceededCount) / currentBudgets.length * 100)
            .round();

    final insights = <InsightString>[];

    // Generate an alert for each exceeded budget.
    for (final b in exceededBudgets) {
      final spend = spendByCategory[b.category] ?? 0;
      insights.add(
        InsightString(
          text: 'You exceeded your ${b.category} budget '
              '(limit: \$${b.monthlyLimit.toStringAsFixed(0)}, '
              'spent: \$${spend.toStringAsFixed(0)}).',
          severity: InsightSeverity.alert,
          category: InsightCategory.budget,
        ),
      );
    }

    // Add a positive info insight when all budgets are within limit.
    if (exceededCount == 0) {
      insights.add(
        const InsightString(
          text: 'Great job! All budgets are on track this month.',
          severity: InsightSeverity.info,
          category: InsightCategory.budget,
        ),
      );
    }

    return _PillarResult(score: score, insights: insights);
  }

  // ── Bill Reliability pillar ───────────────────────────────────────────────

  _PillarResult _billReliability(List<BillReminder> bills, DateTime now) {
    // No bills → neutral score, no insights.
    if (bills.isEmpty) {
      return const _PillarResult(score: 100, insights: []);
    }

    // Overdue = unpaid and past due date.
    final overdueBills = bills
        .where((b) => !b.isPaid && b.dueDate.isBefore(now))
        .toList();

    // Score = percentage of bills NOT overdue.
    final score =
        ((bills.length - overdueBills.length) / bills.length * 100).round();

    final insights = <InsightString>[];

    // Generate an alert for each overdue bill.
    for (final b in overdueBills) {
      insights.add(
        InsightString(
          text: '${b.name} payment is overdue '
              '(due ${b.dueDate.day}/${b.dueDate.month}/${b.dueDate.year}).',
          severity: InsightSeverity.alert,
          category: InsightCategory.bills,
        ),
      );
    }

    // Add a positive info insight when no bills are overdue.
    if (overdueBills.isEmpty) {
      insights.add(
        const InsightString(
          text: 'All bills are up to date.',
          severity: InsightSeverity.info,
          category: InsightCategory.bills,
        ),
      );
    }

    return _PillarResult(score: score, insights: insights);
  }

  // ── Spending Consistency pillar ───────────────────────────────────────────

  _PillarResult _spendingConsistency(
    List<Transaction> transactions,
    String currentMonth,
  ) {
    // Group transactions by month key.
    final byMonth = <String, double>{};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + tx.amount;
    }

    // Current month total (0 if no transactions this month).
    final currentTotal = byMonth[currentMonth] ?? 0;

    // Historical months exclude the current month.
    final historicalMonths = byMonth.keys
        .where((k) => k != currentMonth)
        .toList();

    // No historical data → neutral score 50 (not penalised in overall).
    if (historicalMonths.isEmpty) {
      return const _PillarResult(score: 50, insights: [], isNeutral: true);
    }

    // Compute historical average.
    final historicalSum =
        historicalMonths.fold(0.0, (sum, k) => sum + byMonth[k]!);
    final historicalAvg = historicalSum / historicalMonths.length;

    // Zero historical average → neutral score 50 (not penalised in overall).
    if (historicalAvg == 0) {
      return const _PillarResult(score: 50, insights: [], isNeutral: true);
    }

    // Deviation ratio — clamped to [0, 2] for scoring purposes.
    final deviation = (currentTotal - historicalAvg).abs() / historicalAvg;

    // Score: 100 at zero deviation, 0 at deviation >= 2, linear in between.
    final score = max(0, (100 - deviation * 50).round());

    final insights = <InsightString>[];

    // Warn when spending is materially higher than the historical average.
    if (deviation >= 0.5 && currentTotal > historicalAvg) {
      insights.add(
        InsightString(
          text: 'Your spending this month '
              '(\$${currentTotal.toStringAsFixed(0)}) '
              'is higher than your usual average '
              '(\$${historicalAvg.toStringAsFixed(0)}).',
          severity: InsightSeverity.warning,
          category: InsightCategory.spending,
        ),
      );
    }

    // Celebrate consistent spending when deviation is small.
    if (deviation < 0.2) {
      insights.add(
        const InsightString(
          text: 'Your spending is consistent with previous months.',
          severity: InsightSeverity.info,
          category: InsightCategory.spending,
        ),
      );
    }

    return _PillarResult(score: score, insights: insights);
  }
}

// ── Private helper types ──────────────────────────────────────────────────────

/// Internal result type for a single scoring pillar.
class _PillarResult {
  const _PillarResult({
    required this.score,
    required this.insights,
    this.isNeutral = false,
  });

  /// Pillar score clamped to 0–100.
  final int score;

  /// Insights generated by this pillar.
  final List<InsightString> insights;

  /// True when the pillar has no input data and returned a neutral baseline.
  ///
  /// A neutral pillar is excluded from the weighted overall score computation
  /// so that missing data does not penalise the user.
  final bool isNeutral;
}
