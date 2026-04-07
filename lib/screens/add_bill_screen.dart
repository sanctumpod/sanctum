/// Add-bill entry form for Sanctum.
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
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/services/app_error.dart';

/// Available recurrence options for bill reminders.
const List<String> kRecurrenceOptions = ['one-off', 'monthly'];

/// Form screen for creating a new bill reminder.
///
/// On success, writes the [BillReminder] to the Pod via [billReminderListProvider]
/// and pops the current route. On failure, shows an [AppError] SnackBar.
class AddBillScreen extends ConsumerStatefulWidget {
  /// Creates the add-bill screen.
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  // Default due date is one week from today.
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _recurrence = kRecurrenceOptions.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Opens a date picker and updates [_dueDate] if the user confirms.
  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  /// Validates and submits the form, writing to the Pod via Riverpod.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reminder = BillReminder(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      dueDate: _dueDate,
      recurrence: _recurrence,
      isPaid: false,
    );

    setState(() => _saving = true);
    try {
      await ref.read(billReminderListProvider.notifier).add(reminder);
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
      appBar: AppBar(title: const Text('Add Bill Reminder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Bill Name'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due Date'),
              subtitle: Text(
                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: kRecurrenceOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save Bill Reminder'),
                  ),
          ],
        ),
      ),
    );
  }
}
