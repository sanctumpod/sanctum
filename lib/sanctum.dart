/// Root widget for the Sanctum application.
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidui/solidui.dart';

import 'package:sanctum/constants/app.dart';
import 'package:sanctum/home.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The root widget of the Sanctum application.
///
/// Configures [SolidAuthHandler] on initialisation and wraps the login flow
/// around [Home] via [SolidLogin].

class Sanctum extends ConsumerStatefulWidget {
  /// Creates the root Sanctum widget.

  const Sanctum({super.key});

  @override
  ConsumerState<Sanctum> createState() => _SanctumState();
}

class _SanctumState extends ConsumerState<Sanctum> {
  @override
  void initState() {
    super.initState();

    // Configure the Solid authentication handler with app-specific settings.

    SolidAuthHandler.instance.configure(
      const SolidAuthConfig(
        appTitle: kAppTitle,
        appDirectory: kAppDirectory,
        defaultServerUrl: kDefaultServerUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false,
      theme: SanctumTheme.darkTheme,
      home: const SolidLogin(
        appDirectory: kAppDirectory,
        webID: kDefaultServerUrl,
        child: Home(),
      ),
    );
  }
}
