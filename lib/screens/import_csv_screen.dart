/// CSV import screen for bulk transaction entry.
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

// Group 2: Third-party package imports.
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Group 3: Local package imports.
import 'package:sanctum/constants/csv_fields.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/services/app_error.dart';
import 'package:sanctum/services/csv_parser.dart';

/// Tracks which phase of the import flow is active.
enum _ImportState { idle, preview, importing }

/// Screen that lets users import transactions from a CSV file.
///
/// Flow: pick file → parse → preview rows → confirm → save to Pod → pop.
/// Each confirmed CSV row is written as an encrypted Turtle file at
/// `sanctum/transactions/tx_<uuid>.enc.ttl` on the user's SOLID Pod.
class ImportCsvScreen extends ConsumerStatefulWidget {
  /// Creates the import CSV screen.
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  _ImportState _state = _ImportState.idle;
  List<Transaction> _preview = [];
  int _skippedRows = 0;
  String? _errorMessage;

  // Formatters for the preview list.
  final _dateFmt = DateFormat('d MMM yyyy');
  final _currencyFmt = NumberFormat.currency(locale: 'en_AU', symbol: r'$');

  /// Opens the system file picker restricted to CSV files.
  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _state = _ImportState.idle;
    });

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Could not open file picker: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    // Read the file bytes and decode as UTF-8.
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      setState(() => _errorMessage = 'Could not read file bytes.');
      return;
    }

    final content = String.fromCharCodes(bytes);
    _parseContent(content);
  }

  /// Runs the CSV parser and transitions to the preview state.
  void _parseContent(String content) {
    final parseResult = CsvParser.parseTransactions(content);

    if (parseResult.missingColumns.isNotEmpty) {
      setState(() {
        _errorMessage =
            'CSV is missing required columns: '
            '${parseResult.missingColumns.join(", ")}.\n\n'
            'Required: ${TransactionCsvFields.required.join(", ")}';
      });
      return;
    }

    if (parseResult.parsed.isEmpty) {
      setState(() {
        _errorMessage =
            'No valid rows found. '
            '${parseResult.skippedRows} row(s) were skipped due to errors.';
      });
      return;
    }

    setState(() {
      _preview = parseResult.parsed;
      _skippedRows = parseResult.skippedRows;
      _state = _ImportState.preview;
    });
  }

  /// Saves all previewed transactions to the user's SOLID Pod.
  ///
  /// Calls [TransactionListNotifier.importMany], which writes one encrypted
  /// Turtle file per transaction to `sanctum/transactions/tx_<uuid>.enc.ttl`
  /// on the Pod via `solidpod`'s `writePod`. On success the screen pops and
  /// the Transactions screen re-reads the Pod — imported rows appear inline
  /// with any manually-entered transactions. On [AppError], the screen stays
  /// open so the user can retry or pick a different file.
  Future<void> _confirmImport() async {
    setState(() => _state = _ImportState.importing);

    try {
      await ref.read(transactionListProvider.notifier).importMany(_preview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${_preview.length} transaction(s).'),
          ),
        );
        Navigator.pop(context);
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _state = _ImportState.preview;
          _errorMessage = e.userMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: switch (_state) {
        _ImportState.idle => _IdleView(
            errorMessage: _errorMessage,
            onPickFile: _pickFile,
          ),
        _ImportState.preview => _PreviewView(
            transactions: _preview,
            skippedRows: _skippedRows,
            dateFmt: _dateFmt,
            currencyFmt: _currencyFmt,
            errorMessage: _errorMessage,
            onPickAgain: _pickFile,
            onConfirm: _confirmImport,
          ),
        _ImportState.importing => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving to Pod…'),
              ],
            ),
          ),
      },
    );
  }
}

/// Shown before any file has been selected.
class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPickFile, this.errorMessage});

  final VoidCallback onPickFile;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import transactions from a CSV file.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your CSV must have these columns (header names are '
            'case-insensitive):',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _ColumnTable(),
          const SizedBox(height: 8),
          Text(
            'Example:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'date,amount,merchant,category,notes\n'
              '2026-01-15,42.50,Woolworths,Groceries,Weekly shop\n'
              '2026-01-16,12.00,Spotify,Entertainment,',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick CSV File'),
              onPressed: onPickFile,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the required/optional column reference table.
class _ColumnTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1),
      },
      children: [
        _headerRow(context),
        _dataRow(context, 'date', 'YYYY-MM-DD', 'Required'),
        _dataRow(context, 'amount', 'Positive decimal', 'Required'),
        _dataRow(context, 'merchant', 'Any string', 'Required'),
        _dataRow(context, 'category', 'Any string', 'Required'),
        _dataRow(context, 'notes', 'Any string', 'Optional'),
      ],
    );
  }

  TableRow _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('Column', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('Format', style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text('', style: style),
        ),
      ],
    );
  }

  TableRow _dataRow(
    BuildContext context,
    String col,
    String format,
    String req,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(col, style: const TextStyle(fontFamily: 'monospace')),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(format, style: Theme.of(context).textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(req, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Shown after a file has been parsed — displays the transaction preview list.
class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.transactions,
    required this.skippedRows,
    required this.dateFmt,
    required this.currencyFmt,
    required this.onPickAgain,
    required this.onConfirm,
    this.errorMessage,
  });

  final List<Transaction> transactions;
  final int skippedRows;
  final DateFormat dateFmt;
  final NumberFormat currencyFmt;
  final VoidCallback onPickAgain;
  final VoidCallback onConfirm;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary banner.
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.primary.withAlpha(31),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transactions.length} transaction(s) ready to import',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (skippedRows > 0)
                Text(
                  '$skippedRows row(s) skipped (invalid data).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),

        // Transaction preview list.
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                leading: Text(
                  dateFmt.format(tx.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                title: Text(tx.merchant),
                subtitle: Text(tx.category),
                trailing: Text(
                  currencyFmt.format(tx.amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
          ),
        ),

        // Error message if Pod save failed.
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),

        // Action buttons.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickAgain,
                  child: const Text('Pick Another File'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: Text('Import ${transactions.length} Transaction(s)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
