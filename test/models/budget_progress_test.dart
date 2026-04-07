import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/budget_progress.dart';

void main() {
  const budget500 = Budget(
    id: 'b-001',
    category: 'Groceries',
    monthlyLimit: 500.0,
    month: '2026-04',
  );

  group('BudgetProgress.fraction', () {
    test('normal spend returns correct fraction', () {
      final p = BudgetProgress(budget: budget500, spent: 250.0);
      expect(p.fraction, closeTo(0.5, 0.001));
    });

    test('over-budget fraction is clamped to 1.0', () {
      final p = BudgetProgress(budget: budget500, spent: 600.0);
      expect(p.fraction, 1.0);
    });

    test('zero limit returns 0.0 without throwing', () {
      const zeroBudget = Budget(
        id: 'b-002',
        category: 'Dining',
        monthlyLimit: 0.0,
        month: '2026-04',
      );
      final p = BudgetProgress(budget: zeroBudget, spent: 10.0);
      expect(p.fraction, 0.0);
    });
  });

  group('BudgetProgress.isOverBudget', () {
    test('returns false when under limit', () {
      final p = BudgetProgress(budget: budget500, spent: 400.0);
      expect(p.isOverBudget, isFalse);
    });

    test('returns true when at or over limit', () {
      final p = BudgetProgress(budget: budget500, spent: 500.0);
      expect(p.isOverBudget, isTrue);
    });
  });

  group('BudgetProgress equality', () {
    test('two instances with same fields are equal', () {
      final a = BudgetProgress(budget: budget500, spent: 100.0);
      final b = BudgetProgress(budget: budget500, spent: 100.0);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });
}
