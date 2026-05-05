/// Financial intelligence result models for the Sanctum engine.
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

/// Severity level for an insight.
enum InsightSeverity {
  /// Immediate action required — shown in red.
  alert,

  /// Advisory — shown in amber.
  warning,

  /// Positive or informational — shown in blue.
  info;

  /// Numeric weight used to sort insights (higher = shown first).
  int get sortWeight => switch (this) {
        InsightSeverity.alert => 3,
        InsightSeverity.warning => 2,
        InsightSeverity.info => 1,
      };
}

/// Category of an insight, used for navigation and badging.
enum InsightCategory {
  /// Budget-related insight — tapping navigates to Budgets tab.
  budget,

  /// Bill-related insight — tapping navigates to Bills tab.
  bills,

  /// Spending pattern insight — tapping navigates to Transactions tab.
  spending,

  /// General or fallback insight — no navigation.
  general,
}

/// A single natural-language insight with metadata.
class InsightString {
  /// Creates an [InsightString].
  const InsightString({
    required this.text,
    required this.severity,
    required this.category,
  });

  /// The natural-language insight text in friendly coach tone.
  final String text;

  /// Severity level determining visual treatment and sort order.
  final InsightSeverity severity;

  /// Category determining the badge label and tap navigation target.
  final InsightCategory category;
}

/// The complete output of one run of [FinancialIntelligenceService.analyse].
class FinancialIntelligenceResult {
  /// Creates a [FinancialIntelligenceResult].
  const FinancialIntelligenceResult({
    required this.overallScore,
    required this.budgetAdherenceScore,
    required this.billReliabilityScore,
    required this.spendingConsistencyScore,
    required this.insights,
  });

  /// Weighted composite score 0–100.
  final int overallScore;

  /// Budget adherence pillar score 0–100.
  final int budgetAdherenceScore;

  /// Bill reliability pillar score 0–100.
  final int billReliabilityScore;

  /// Spending consistency pillar score 0–100.
  final int spendingConsistencyScore;

  /// Ordered list of 3–5 insights, alerts first then warnings then info.
  final List<InsightString> insights;

  /// Human-readable grade derived from [overallScore].
  String get grade => switch (overallScore) {
        >= 80 => 'Excellent',
        >= 60 => 'Good',
        >= 40 => 'Needs Attention',
        _ => 'At Risk',
      };
}
