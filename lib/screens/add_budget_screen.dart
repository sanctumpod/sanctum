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
    return Scaffold(
      appBar: AppBar(title: const Text('Set Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,6}\.?\d{0,2}'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (AUD)',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Limit is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _month,
              decoration: const InputDecoration(labelText: 'Month (YYYY-MM)'),
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
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Budget'),
                  ),
          ],
        ),
      ),
    );
  }
}
