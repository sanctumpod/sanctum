/// Entry point for the Sanctum application.
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Group 3: Local package imports.
import 'package:sanctum/sanctum.dart';

/// Initialises platform services then launches the Sanctum application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise timezone database — required by flutter_local_notifications.
  tz.initializeTimeZones();

  // Initialise local notifications on supported mobile platforms only.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await FlutterLocalNotificationsPlugin().initialize(initSettings);
  }

  runApp(const ProviderScope(child: Sanctum()));
}
