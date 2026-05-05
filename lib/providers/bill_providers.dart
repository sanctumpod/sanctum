/// Riverpod providers for BillReminder state management.
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
import 'dart:io';

// Group 2: Third-party package imports.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

// Group 3: Local package imports.
import 'package:sanctum/models/bill_reminder.dart';
import 'package:sanctum/providers/pod_service_provider.dart';

/// Manages the list of bill reminders loaded from the user's Pod.
///
/// Invalidates itself after every mutation so the UI stays in sync.
class BillReminderListNotifier extends AsyncNotifier<List<BillReminder>> {
  final _notifications = FlutterLocalNotificationsPlugin();

  @override
  Future<List<BillReminder>> build() =>
      ref.read(podServiceProvider).loadAllBillReminders();

  /// Saves [reminder] to the Pod, schedules a notification, and refreshes.
  Future<void> add(BillReminder reminder) async {
    await ref.read(podServiceProvider).saveBillReminder(reminder);
    await _scheduleNotification(reminder);
    ref.invalidateSelf();
  }

  /// Marks the reminder with [id] as paid.
  ///
  /// For monthly reminders, creates a new reminder for the following month.
  Future<void> markPaid(String id) async {
    final svc = ref.read(podServiceProvider);
    final reminder = state.value!.firstWhere((r) => r.id == id);

    // Overwrite the Pod file with isPaid = true and record the paid date.
    await svc.updateBillReminder(
      reminder.copyWith(isPaid: true, paidDate: DateTime.now()),
    );

    if (reminder.recurrence == 'monthly') {
      final due = reminder.dueDate;
      final next = reminder.copyWith(
        id: const Uuid().v4(),
        dueDate: DateTime(due.year, due.month + 1, due.day),
        isPaid: false,
      );
      await svc.saveBillReminder(next);
      await _scheduleNotification(next);
    }

    ref.invalidateSelf();
  }

  /// Deletes the reminder with [id] from the Pod and refreshes.
  Future<void> delete(String id) async {
    await ref.read(podServiceProvider).deleteBillReminder(id);
    ref.invalidateSelf();
  }

  /// Schedules a local notification 3 days before [r.dueDate].
  ///
  /// Silently skips on web or unsupported desktop platforms, or if the
  /// notification date is already past. Records the scheduled notification
  /// date in the Pod for audit trail purposes.
  Future<void> _scheduleNotification(BillReminder r) async {
    // Web does not support local notifications.
    if (kIsWeb) return;
    // Skip on unsupported desktop platforms.
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final notifyDate = r.dueDate.subtract(const Duration(days: 3));
    if (notifyDate.isBefore(DateTime.now())) return;

    try {
      await _notifications.zonedSchedule(
        r.id.hashCode,
        'Upcoming bill: ${r.name}',
        '${r.name} is due in 3 days — \$${r.amount.toStringAsFixed(2)}',
        tz.TZDateTime.from(notifyDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('bills', 'Bill Reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // Record the scheduled notification date in the Pod.
      await ref.read(podServiceProvider).updateBillReminder(
        r.copyWith(notificationDate: notifyDate),
      );
    } catch (e) {
      // Notification scheduling failure must never crash the app.
      debugPrint('_scheduleNotification failed: $e');
    }
  }
}

/// Provides the async list of all bill reminders for the current user.
final billReminderListProvider =
    AsyncNotifierProvider<BillReminderListNotifier, List<BillReminder>>(
  BillReminderListNotifier.new,
);
