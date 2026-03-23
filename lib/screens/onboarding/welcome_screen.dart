/// Welcome screen shown to first-time users before connecting their vault.
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

// Group 3: Local package imports.
import 'package:sanctum/screens/onboarding/connect_screen.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The first onboarding screen shown to users who have not yet connected
/// a vault.
///
/// Introduces the app and leads the user to [ConnectScreen] via a
/// "Get Started" button.
class WelcomeScreen extends StatelessWidget {
  /// Creates the Welcome onboarding screen.
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanctumTheme.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // App logo placeholder.
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: SanctumTheme.accentIndigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'S',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: SanctumTheme.textOnAccent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App name.
              Text(
                'SANCTUM',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Tagline.
              Text(
                'Your finances. Your data. Your rules.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SanctumTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Plain-English vault description — no technical terms.
              Text(
                'Sanctum keeps your spending records in a private storage '
                'space that only you control — not on our servers.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Get Started button — exact label required by sprint spec.
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectScreen(),
                  ),
                ),
                child: const Text('Get Started'),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
