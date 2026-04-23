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
import 'package:sanctum/theme/app_theme.dart';

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
            '${parseResult.missingColumns.join(', ')}.\n'
            'Required: ${TransactionCsvFields.required.join(', ')}';
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
        _ImportState.importing => const _ImportingView(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state
// ---------------------------------------------------------------------------

/// Shown before any file has been selected.
class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPickFile, this.errorMessage});

  final VoidCallback onPickFile;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // Intro header.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SanctumTheme.accentIndigo.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
            border: Border.all(
              color: SanctumTheme.accentIndigo.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SanctumTheme.accentIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: SanctumTheme.accentIndigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import from CSV',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bulk-add transactions from a spreadsheet export.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Column spec table.
        const Text(
          'REQUIRED FORMAT',
          style: TextStyle(
            color: SanctumTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        const _ColumnTable(),
        const SizedBox(height: 20),

        // Example block.
        const Text(
          'EXAMPLE',
          style: TextStyle(
            color: SanctumTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SanctumTheme.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SanctumTheme.cardBorder),
          ),
          child: const Text(
            'date,amount,merchant,category,notes\n'
            '2026-01-15,42.50,Woolworths,Groceries,Weekly shop\n'
            '2026-01-16,12.00,Spotify,Entertainment,',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: SanctumTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ),

        // Error message.
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SanctumTheme.semanticError.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SanctumTheme.semanticError.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: SanctumTheme.semanticError,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: SanctumTheme.semanticError,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),

        // Pick file button.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Choose CSV File'),
            onPressed: onPickFile,
          ),
        ),
      ],
    );
  }
}

/// Required/optional column reference table.
class _ColumnTable extends StatelessWidget {
  const _ColumnTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SanctumTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SanctumTheme.cardBorder),
      ),
      child: Column(
        children: [
          _tableRow(context, 'COLUMN', 'FORMAT', 'REQ.', isHeader: true),
          _tableRow(context, 'date', 'YYYY-MM-DD', 'Required'),
          _tableRow(context, 'amount', 'Positive decimal', 'Required'),
          _tableRow(context, 'merchant', 'Any text', 'Required'),
          _tableRow(context, 'category', 'Any text', 'Required'),
          _tableRow(context, 'notes', 'Any text', 'Optional', isLast: true),
        ],
      ),
    );
  }

  Widget _tableRow(
    BuildContext context,
    String col,
    String format,
    String req, {
    bool isHeader = false,
    bool isLast = false,
  }) {
    final isRequired = req == 'Required';
    final reqColor = isRequired ? SanctumTheme.semanticSuccess : SanctumTheme.textTertiary;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: SanctumTheme.cardBorder),
              ),
        color: isHeader
            ? SanctumTheme.backgroundElevated.withValues(alpha: 0.6)
            : null,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : isHeader
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              col,
              style: isHeader
                  ? const TextStyle(
                      color: SanctumTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )
                  : const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: SanctumTheme.accentIndigo,
                    ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              format,
              style: TextStyle(
                color: isHeader ? SanctumTheme.textTertiary : SanctumTheme.textSecondary,
                fontSize: isHeader ? 11 : 12,
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: isHeader ? 0.5 : 0,
              ),
            ),
          ),
          Text(
            req,
            style: TextStyle(
              color: isHeader ? SanctumTheme.textTertiary : reqColor,
              fontSize: isHeader ? 11 : 12,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: isHeader ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview state
// ---------------------------------------------------------------------------

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: SanctumTheme.accentIndigo.withValues(alpha: 0.12),
            border: const Border(
              bottom: BorderSide(color: SanctumTheme.cardBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: SanctumTheme.semanticSuccess,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${transactions.length} transaction(s) ready to import',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: SanctumTheme.textPrimary,
                        ),
                  ),
                ],
              ),
              if (skippedRows > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$skippedRows row(s) skipped — invalid data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SanctumTheme.semanticWarning,
                      ),
                ),
              ],
            ],
          ),
        ),

        // Transaction preview list.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final catColor = SanctumTheme.categoryColor(tx.category);
              final catIcon = SanctumTheme.categoryIcon(tx.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SanctumTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SanctumTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(catIcon, size: 16, color: catColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.merchant,
                            style: const TextStyle(
                              color: SanctumTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            tx.category,
                            style: const TextStyle(
                              color: SanctumTheme.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFmt.format(tx.amount),
                          style: const TextStyle(
                            color: SanctumTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          dateFmt.format(tx.date),
                          style: const TextStyle(
                            color: SanctumTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Error message if Pod save failed.
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SanctumTheme.semanticError.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SanctumTheme.semanticError.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: SanctumTheme.semanticError,
                  fontSize: 13,
                ),
              ),
            ),
          ),

        // Action buttons.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickAgain,
                  child: const Text('Pick Another'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text('Import ${transactions.length}'),
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Importing state
// ---------------------------------------------------------------------------

/// Full-screen loading indicator shown while transactions are being written.
class _ImportingView extends StatelessWidget {
  const _ImportingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SanctumTheme.accentIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Saving to Pod…',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Writing encrypted records to your SOLID Pod.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
