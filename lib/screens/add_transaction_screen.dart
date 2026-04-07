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
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/app_error.dart';

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
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _submit,
            ),
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
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,6}\.?\d{0,2}'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (AUD)',
                prefixText: '\$',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Merchant'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Merchant is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration:
                  const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Transaction'),
                  ),
          ],
        ),
      ),
    );
  }
}
