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
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/theme/app_theme.dart';

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

  final _dateFmt = DateFormat('d MMM yyyy');

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: SanctumTheme.accentIndigo,
              ),
        ),
        child: child!,
      ),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Bill name.
            const _SectionLabel(label: 'Bill Name'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Netflix, Electricity…',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Amount — hero field.
            const _SectionLabel(label: 'Amount'),
            TextFormField(
              controller: _amountController,
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
                if (v == null || v.trim().isEmpty) return 'Amount is required.';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive amount.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Due date picker.
            const _SectionLabel(label: 'Due Date'),
            _DatePickerField(
              displayValue: _dateFmt.format(_dueDate),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 20),

            // Recurrence toggle.
            const _SectionLabel(label: 'Recurrence'),
            Row(
              children: kRecurrenceOptions.map((r) {
                final selected = r == _recurrence;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: r == kRecurrenceOptions.first ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _recurrence = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? SanctumTheme.accentIndigo.withValues(alpha: 0.15)
                              : SanctumTheme.backgroundCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? SanctumTheme.accentIndigo.withValues(alpha: 0.5)
                                : SanctumTheme.cardBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              r == 'monthly'
                                  ? Icons.repeat
                                  : Icons.receipt_outlined,
                              size: 20,
                              color: selected
                                  ? SanctumTheme.accentIndigo
                                  : SanctumTheme.textTertiary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r == 'monthly' ? 'Monthly' : 'One-off',
                              style: TextStyle(
                                color: selected
                                    ? SanctumTheme.accentIndigo
                                    : SanctumTheme.textTertiary,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save button or loading indicator.
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Bill Reminder'),
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
