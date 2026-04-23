/// Add-budget entry form for Sanctum.
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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/screens/add_transaction_screen.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

/// Form screen for creating a monthly spending budget.
///
/// On success, writes the [Budget] to the Pod via [budgetListProvider] and
/// pops the current route. On failure, shows an [AppError] SnackBar.
class AddBudgetScreen extends ConsumerStatefulWidget {
  /// Creates the add-budget screen.
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  String _category = kCategories.first;
  String _month = _currentMonth();
  bool _saving = false;

  /// Returns the current calendar month formatted as "YYYY-MM".
  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  /// Validates and submits the form, writing to the Pod via Riverpod.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final budget = Budget(
      id: const Uuid().v4(),
      category: _category,
      monthlyLimit: double.parse(_limitController.text.trim()),
      month: _month,
    );

    setState(() => _saving = true);
    try {
      await ref.read(budgetListProvider.notifier).add(budget);
      if (mounted) Navigator.pop(context);
    } on AppError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = SanctumTheme.categoryColor(_category);
    final catIcon = SanctumTheme.categoryIcon(_category);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Category selector.
            const _SectionLabel(label: 'Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(),
              dropdownColor: SanctumTheme.backgroundElevated,
              items: kCategories.map((c) {
                final color = SanctumTheme.categoryColor(c);
                final icon = SanctumTheme.categoryIcon(c);
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 10),
                      Text(c),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),

            // Selected category preview badge.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcon, size: 20, color: catColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _category,
                    style: TextStyle(
                      color: catColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monthly limit — hero field.
            const _SectionLabel(label: 'Monthly Limit'),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,6}\.?\d{0,2}'),
                ),
              ],
              style: const TextStyle(
                color: SanctumTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: const InputDecoration(
                prefixText: r'$  ',
                prefixStyle: TextStyle(
                  color: SanctumTheme.accentIndigo,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: SanctumTheme.textTertiary,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Limit is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Month input.
            const _SectionLabel(label: 'Month'),
            TextFormField(
              initialValue: _month,
              decoration: const InputDecoration(
                hintText: 'YYYY-MM',
              ),
              onChanged: (v) => _month = v.trim(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Month is required.';
                final parts = v.trim().split('-');
                if (parts.length != 2) return 'Use YYYY-MM format.';
                final year = int.tryParse(parts[0]);
                final month = int.tryParse(parts[1]);
                if (year == null ||
                    month == null ||
                    month < 1 ||
                    month > 12) {
                  return 'Invalid month.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save button or loading indicator.
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Budget'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase section label used above form inputs.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SanctumTheme.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
