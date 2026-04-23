/// Add-transaction entry form for Sanctum.
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
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The preset list of spending categories available to the user.
const List<String> kCategories = [
  'Groceries',
  'Transport',
  'Utilities',
  'Dining',
  'Health',
  'Entertainment',
  'Other',
];

/// Form screen for entering a new financial transaction.
///
/// Validates all fields before writing to the Pod and pops on success.
class AddTransactionScreen extends ConsumerStatefulWidget {
  /// Creates the add-transaction screen.
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = kCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens a date picker and updates [_date] if the user confirms.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: SanctumTheme.accentIndigo,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Validates and submits the form, writing to the Pod via Riverpod.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final merchant = _merchantController.text.trim();
    final notes = _notesController.text.trim();

    final tx = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      merchant: merchant,
      category: _category,
      date: _date,
      notes: notes.isEmpty ? null : notes,
    );

    setState(() => _saving = true);
    try {
      await ref.read(transactionListProvider.notifier).add(tx);
      if (mounted) Navigator.pop(context);
    } on AppError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            action: SnackBarAction(label: 'Retry', onPressed: _submit),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Amount — visually the most important field.
            const _SectionLabel(label: 'Amount'),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                if (v == null || v.trim().isEmpty) return 'Amount is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Merchant name.
            const _SectionLabel(label: 'Merchant'),
            TextFormField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Woolworths',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Merchant is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category.
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

            // Date picker.
            const _SectionLabel(label: 'Date'),
            _DatePickerField(
              displayValue: _dateFmt.format(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),

            // Notes (optional).
            const _SectionLabel(label: 'Notes  (optional)'),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Any extra details…',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button or loading indicator.
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Transaction'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form helpers
// ---------------------------------------------------------------------------

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

/// Tappable field that displays the selected date and opens a picker.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.displayValue,
    required this.onTap,
  });

  final String displayValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SanctumTheme.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SanctumTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: SanctumTheme.textTertiary,
            ),
            const SizedBox(width: 12),
            Text(
              displayValue,
              style: const TextStyle(
                color: SanctumTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: SanctumTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
