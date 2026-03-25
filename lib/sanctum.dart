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

// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/material.dart';

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart' show getWebId;
import 'package:solidui/solidui.dart';

// Group 3: Local package imports.
import 'package:sanctum/constants/app.dart';
import 'package:sanctum/home.dart';
import 'package:sanctum/screens/onboarding/welcome_screen.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The root widget of the Sanctum application.
///
/// Configures [SolidAuthHandler] on initialisation, checks for an existing
/// session via [getWebId], and routes returning users directly to [Home]
/// while first-time users are shown [WelcomeScreen].
class Sanctum extends ConsumerStatefulWidget {
  /// Creates the root Sanctum widget.
  const Sanctum({super.key});

  @override
  ConsumerState<Sanctum> createState() => _SanctumState();
}

class _SanctumState extends ConsumerState<Sanctum> {
  /// Whether the async session check has completed.
  bool _sessionChecked = false;

  /// Whether a valid session (non-null webId) was found on launch.
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();

    // Configure the Solid authentication handler with app-specific settings.
    SolidAuthHandler.instance.configure(
      const SolidAuthConfig(
        appTitle: kAppTitle,
        appDirectory: kAppDirectory,
        defaultServerUrl: kDefaultServerUrl,
        appImage: AssetImage('assets/images/app_image.png'),
        appLogo: AssetImage('assets/images/app_icon.png'),
      ),
    );

    // Check for an existing session after the first frame so that the
    // Navigator is available if needed.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingSession(),
    );
  }

  /// Reads the persisted webId from solidpod's secure storage.
  ///
  /// If a session exists the build method routes to [Home], bypassing
  /// onboarding. If no session exists [WelcomeScreen] is shown instead.
  Future<void> _checkExistingSession() async {
    final webId = await getWebId();
    if (!mounted) return;

    setState(() {
      _hasSession = webId != null && webId.isNotEmpty;
      _sessionChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the session check is in progress.
    if (!_sessionChecked) {
      return MaterialApp(
        title: kAppTitle,
        debugShowCheckedModeBanner: false,
        theme: SanctumTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false,
      theme: SanctumTheme.darkTheme,
      // Returning users land directly on Home; first-time users see onboarding.
      home: _hasSession ? const Home() : const WelcomeScreen(),
    );
  }
}
