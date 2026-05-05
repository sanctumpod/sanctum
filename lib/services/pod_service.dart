/// Pod data access layer for Sanctum — all RDF/Turtle logic lives here.
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
import 'package:flutter/foundation.dart';

// Group 2: Third-party package imports.
import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart'
    show
        SolidFunctionCallStatus,
        deleteFile,
        getDirUrl,
        getResourcesInContainer,
        readPod,
        writePod;

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/models/budget.dart';
import 'package:sanctum/models/transaction.dart';
import 'package:sanctum/services/app_error.dart';

/// Provides CRUD operations for all three financial data types.
///
/// This is the ONLY class that imports [rdflib] or constructs Turtle strings.
/// No other file in the codebase may import rdflib or build Turtle content.
///
/// All methods throw [AppError] on failure — never raw exceptions.
class PodService {
  // ── Pod path constants ───────────────────────────────────────────────────────

  /// Data directory on the Pod (relative to `sanctum/data/`).
  static const String _txDir = 'transactions';

  /// Data directory on the Pod (relative to `sanctum/data/`).
  static const String _budgetDir = 'budgets';

  /// Data directory on the Pod (relative to `sanctum/data/`).
  static const String _reminderDir = 'reminders';

  /// App directory name on the Pod (for full-path `getDirUrl` calls).
  static const String _appDataBase = 'sanctum/data';

  // ── RDF prefixes ────────────────────────────────────────────────────────────
  static const String _fin = 'http://sanctum.app/finance#';
  static const String _xsd = 'http://www.w3.org/2001/XMLSchema#';

  // ── Transaction ─────────────────────────────────────────────────────────────

  /// Writes [tx] to the Pod as an encrypted Turtle file.
  ///
  /// Creates the `sanctum/transactions/` directory on first write.
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveTransaction(Transaction tx) async {
    try {
      final path = '$_txDir/tx_${tx.id}.enc.ttl';
      await writePod(path, _transactionToTurtle(tx), encrypted: true);
    } on AppError {
      rethrow;
    } catch (e) {
      debugPrint('saveTransaction error: $e');
      throw AppError.networkError;
    }
  }

  /// Reads all transactions from the Pod, sorted newest-first.
  ///
  /// Returns an empty list if the directory does not yet exist.
  /// Skips files that cannot be parsed rather than throwing.
  Future<List<Transaction>> loadAllTransactions() async {
    try {
      final dirUrl = await getDirUrl('$_appDataBase/$_txDir');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <Transaction>[];

      // Iterate each file in the transactions directory.
      for (final file in resources.files) {
        if (!file.endsWith('.enc.ttl')) continue;

        String content;
        try {
          content = await readPod('$_txDir/$file');
        } catch (e) {
          debugPrint('loadAllTransactions: skipping unreadable file $file: $e');
          continue;
        }

        // Skip error sentinel values returned by solidpod.
        if (content == SolidFunctionCallStatus.fail.toString() ||
            content == SolidFunctionCallStatus.notLoggedIn.toString()) {
          continue;
        }

        try {
          results.add(_transactionFromTurtle(content));
        } on AppError {
          debugPrint('loadAllTransactions: skipping corrupt file $file');
        }
      }

      // Return sorted newest-first.
      return results..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (e is AppError) rethrow;
      // Log the real error so it appears in the debug console.
      debugPrint('loadAllTransactions error: $e');
      // Re-throw so the provider enters error state rather than silently
      // returning an empty list, which makes failures invisible to the user.
      throw AppError.networkError;
    }
  }

  /// Deletes the transaction with [id] from the Pod.
  ///
  /// Throws [AppError.fileNotFound] if the file does not exist.
  Future<void> deleteTransaction(String id) async {
    try {
      await deleteFile('$_txDir/tx_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
      throw AppError.networkError;
    }
  }

  // ── Budget ──────────────────────────────────────────────────────────────────

  /// Writes [budget] to the Pod as an encrypted Turtle file.
  ///
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveBudget(Budget budget) async {
    try {
      final path = '$_budgetDir/budget_${budget.id}.enc.ttl';
      await writePod(path, _budgetToTurtle(budget), encrypted: true);
    } on AppError {
      rethrow;
    } catch (e) {
      debugPrint('saveBudget error: $e');
      throw AppError.networkError;
    }
  }

  /// Reads all budgets from the Pod.
  ///
  /// Returns an empty list if the directory does not yet exist.
  Future<List<Budget>> loadAllBudgets() async {
    try {
      final dirUrl = await getDirUrl('$_appDataBase/$_budgetDir');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <Budget>[];

      // Iterate each file in the budgets directory.
      for (final file in resources.files) {
        if (!file.endsWith('.enc.ttl')) continue;

        String content;
        try {
          content = await readPod('$_budgetDir/$file');
        } catch (e) {
          debugPrint('loadAllBudgets: skipping unreadable file $file: $e');
          continue;
        }

        // Skip error sentinel values returned by solidpod.
        if (content == SolidFunctionCallStatus.fail.toString() ||
            content == SolidFunctionCallStatus.notLoggedIn.toString()) {
          continue;
        }

        try {
          results.add(_budgetFromTurtle(content));
        } on AppError {
          debugPrint('loadAllBudgets: skipping corrupt file $file');
        }
      }

      return results;
    } catch (e) {
      if (e is AppError) rethrow;
      debugPrint('loadAllBudgets error: $e');
      return [];
    }
  }

  /// Deletes the budget with [id] from the Pod.
  Future<void> deleteBudget(String id) async {
    try {
      await deleteFile('$_budgetDir/budget_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteBudget error: $e');
      throw AppError.networkError;
    }
  }

  // ── BillReminder ────────────────────────────────────────────────────────────

  /// Writes [reminder] to the Pod as an encrypted Turtle file.
  ///
  /// Throws [AppError.networkError] if the Pod is unreachable.
  Future<void> saveBillReminder(BillReminder reminder) async {
    try {
      final path = '$_reminderDir/reminder_${reminder.id}.enc.ttl';
      await writePod(path, _reminderToTurtle(reminder), encrypted: true);
    } on AppError {
      rethrow;
    } catch (e) {
      debugPrint('saveBillReminder error: $e');
      throw AppError.networkError;
    }
  }

  /// Reads all bill reminders from the Pod, sorted by due date ascending.
  ///
  /// Returns an empty list if the directory does not yet exist.
  Future<List<BillReminder>> loadAllBillReminders() async {
    try {
      final dirUrl = await getDirUrl('$_appDataBase/$_reminderDir');
      final resources = await getResourcesInContainer(dirUrl);
      final results = <BillReminder>[];

      // Iterate each file in the reminders directory.
      for (final file in resources.files) {
        if (!file.endsWith('.enc.ttl')) continue;

        String content;
        try {
          content = await readPod('$_reminderDir/$file');
        } catch (e) {
          debugPrint('loadAllBillReminders: skipping unreadable file $file: $e');
          continue;
        }

        // Skip error sentinel values returned by solidpod.
        if (content == SolidFunctionCallStatus.fail.toString() ||
            content == SolidFunctionCallStatus.notLoggedIn.toString()) {
          continue;
        }

        try {
          results.add(_reminderFromTurtle(content));
        } on AppError {
          debugPrint('loadAllBillReminders: skipping corrupt file $file');
        }
      }

      // Return sorted by due date ascending.
      return results..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      if (e is AppError) rethrow;
      debugPrint('loadAllBillReminders error: $e');
      return [];
    }
  }

  /// Overwrites the existing Pod file for [reminder] with new content.
  ///
  /// Used when marking a bill as paid or updating any field.
  /// Passes `overwrite: true` so writePod replaces the existing encrypted file.
  Future<void> updateBillReminder(BillReminder reminder) async {
    try {
      final path = '$_reminderDir/reminder_${reminder.id}.enc.ttl';
      await writePod(
        path,
        _reminderToTurtle(reminder),
        encrypted: true,
        overwrite: true,
      );
    } on AppError {
      rethrow;
    } catch (e) {
      debugPrint('updateBillReminder error: $e');
      throw AppError.networkError;
    }
  }

  /// Deletes the bill reminder with [id] from the Pod.
  Future<void> deleteBillReminder(String id) async {
    try {
      await deleteFile('$_reminderDir/reminder_$id.enc.ttl');
    } catch (e) {
      debugPrint('deleteBillReminder error: $e');
      throw AppError.networkError;
    }
  }

  // ── Transaction serialization ────────────────────────────────────────────────

  /// Serialises [tx] to a Turtle string using the `fin:` namespace.
  String _transactionToTurtle(Transaction tx) {
    final notes = tx.notes ?? '';
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#tx> a fin:Transaction ;
    fin:id       "${tx.id}" ;
    fin:amount   "${tx.amount.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:merchant "${tx.merchant}" ;
    fin:category "${tx.category}" ;
    fin:date     "${tx.date.toIso8601String().substring(0, 10)}"^^xsd:date ;
    fin:notes    "$notes" .
''';
  }

  /// Parses a Turtle string into a [Transaction].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  Transaction _transactionFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      final notes = _get(g, 'notes');
      return Transaction(
        id: _get(g, 'id'),
        amount: double.parse(_get(g, 'amount')),
        merchant: _get(g, 'merchant'),
        category: _get(g, 'category'),
        date: DateTime.parse(_get(g, 'date')),
        notes: notes.isEmpty ? null : notes,
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  /// Exposed for unit testing only — calls [_transactionToTurtle].
  @visibleForTesting
  String testTransactionToTurtle(Transaction tx) => _transactionToTurtle(tx);

  /// Exposed for unit testing only — calls [_transactionFromTurtle].
  @visibleForTesting
  Transaction testTransactionFromTurtle(String turtle) =>
      _transactionFromTurtle(turtle);

  // ── Budget serialization ─────────────────────────────────────────────────────

  /// Serialises [budget] to a Turtle string using the `fin:` namespace.
  String _budgetToTurtle(Budget budget) {
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#budget> a fin:Budget ;
    fin:id           "${budget.id}" ;
    fin:category     "${budget.category}" ;
    fin:monthlyLimit "${budget.monthlyLimit.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:month        "${budget.month}" .
''';
  }

  /// Parses a Turtle string into a [Budget].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  Budget _budgetFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      return Budget(
        id: _get(g, 'id'),
        category: _get(g, 'category'),
        monthlyLimit: double.parse(_get(g, 'monthlyLimit')),
        month: _get(g, 'month'),
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  /// Exposed for unit testing only — calls [_budgetToTurtle].
  @visibleForTesting
  String testBudgetToTurtle(Budget budget) => _budgetToTurtle(budget);

  /// Exposed for unit testing only — calls [_budgetFromTurtle].
  @visibleForTesting
  Budget testBudgetFromTurtle(String turtle) => _budgetFromTurtle(turtle);

  // ── BillReminder serialization ───────────────────────────────────────────────

  /// Serialises [reminder] to a Turtle string using the `fin:` namespace.
  String _reminderToTurtle(BillReminder reminder) {
    final notifLine = reminder.notificationDate != null
        ? '    fin:notificationDate "${reminder.notificationDate!.toIso8601String()}"^^xsd:dateTime ;\n'
        : '';
    final paidLine = reminder.paidDate != null
        ? '    fin:paidDate "${reminder.paidDate!.toIso8601String()}"^^xsd:dateTime ;\n'
        : '';
    return '''
@prefix fin: <$_fin> .
@prefix xsd: <$_xsd> .

<#reminder> a fin:BillReminder ;
    fin:id         "${reminder.id}" ;
    fin:name       "${reminder.name}" ;
    fin:amount     "${reminder.amount.toStringAsFixed(2)}"^^xsd:decimal ;
    fin:dueDate    "${reminder.dueDate.toIso8601String().substring(0, 10)}"^^xsd:date ;
    fin:recurrence "${reminder.recurrence}" ;
${notifLine}${paidLine}    fin:isPaid     "${reminder.isPaid}"^^xsd:boolean .
''';
  }

  /// Parses a Turtle string into a [BillReminder].
  ///
  /// Throws [AppError.parseError] if the graph is missing required predicates.
  BillReminder _reminderFromTurtle(String turtle) {
    try {
      final g = Graph();
      g.parseTurtle(turtle);
      final rawNotif = _getOptional(g, 'notificationDate');
      final rawPaid = _getOptional(g, 'paidDate');
      return BillReminder(
        id: _get(g, 'id'),
        name: _get(g, 'name'),
        amount: double.parse(_get(g, 'amount')),
        dueDate: DateTime.parse(_get(g, 'dueDate')),
        recurrence: _get(g, 'recurrence'),
        isPaid: _get(g, 'isPaid') == 'true',
        notificationDate: rawNotif != null ? DateTime.parse(rawNotif) : null,
        paidDate: rawPaid != null ? DateTime.parse(rawPaid) : null,
      );
    } catch (_) {
      throw AppError.parseError;
    }
  }

  /// Exposed for unit testing only — calls [_reminderToTurtle].
  @visibleForTesting
  String testReminderToTurtle(BillReminder r) => _reminderToTurtle(r);

  /// Exposed for unit testing only — calls [_reminderFromTurtle].
  @visibleForTesting
  BillReminder testReminderFromTurtle(String turtle) =>
      _reminderFromTurtle(turtle);

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Extracts the value of the first triple whose predicate ends with [pred].
  String _get(Graph g, String pred) =>
      g.triples.firstWhere((t) => t.pre.value.endsWith(pred)).obj.value;

  /// Returns the value of the first triple whose predicate matches the full
  /// [fin:pred] URI, or null if no such triple exists.
  String? _getOptional(Graph g, String pred) {
    try {
      return g.triples
          .firstWhere((t) => t.pre.value == '$_fin$pred')
          .obj
          .value;
    } catch (_) {
      return null;
    }
  }
}
