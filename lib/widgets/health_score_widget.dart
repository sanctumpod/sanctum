/// Health Score Widget displaying the overall financial health score.
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sanctum/models/financial_intelligence_result.dart';
import 'package:sanctum/providers/financial_intelligence_provider.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Displays the overall financial health score with grade and pillar breakdown.
class HealthScoreWidget extends ConsumerWidget {
  /// Creates a [HealthScoreWidget].
  const HealthScoreWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(financialIntelligenceProvider);

    return asyncResult.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (result) => _ScoreCard(result: result),
    );
  }
}

/// Displays a loading indicator while the financial intelligence data is loading.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Displays an error message when the financial intelligence data fails to load.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load health score: $message',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Displays the full financial health score card with grade and pillar scores.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});
  final FinancialIntelligenceResult result;

  Color _gradeColor() => switch (result.grade) {
        'Excellent' => SanctumTheme.semanticSuccess,
        'Good' => SanctumTheme.accentIndigo,
        'Needs Attention' => SanctumTheme.semanticWarning,
        _ => SanctumTheme.semanticError,
      };

  @override
  Widget build(BuildContext context) {
    final gradeColor = _gradeColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Health',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${result.overallScore}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: gradeColor,
                        fontSize: 56,
                      ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.grade,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: gradeColor,
                          ),
                    ),
                    Text(
                      'out of 100',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PillarRow(
              label: 'Budgets',
              score: result.budgetAdherenceScore,
              color: gradeColor,
            ),
            const SizedBox(height: 8),
            _PillarRow(
              label: 'Bills',
              score: result.billReliabilityScore,
              color: gradeColor,
            ),
            const SizedBox(height: 8),
            _PillarRow(
              label: 'Spending',
              score: result.spendingConsistencyScore,
              color: gradeColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a single pillar label, progress bar, and score for the health card.
class _PillarRow extends StatelessWidget {
  const _PillarRow({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: SanctumTheme.backgroundElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
