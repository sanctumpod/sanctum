/// Post-login confirmation screen shown after successful vault connection.
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
import 'package:sanctum/home.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The third onboarding screen, shown after [SolidLogin] completes successfully.
///
/// Confirms that the vault is connected and presents a "Start Using Sanctum"
/// button that replaces the entire onboarding stack with [Home].
class PostLoginScreen extends StatelessWidget {
  /// Creates the post-login confirmation screen.
  const PostLoginScreen({super.key});

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

              // Success icon.
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SanctumTheme.semanticSuccess.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: SanctumTheme.semanticSuccess,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Confirmation heading.
              Text(
                'Vault connected!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Plain-English confirmation.
              Text(
                'Your private vault is all set. Your financial records will '
                'be stored there — only you have access.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Start Using Sanctum button — exact label required by sprint spec.
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Home()),
                  (_) => false,
                ),
                child: const Text('Start Using Sanctum'),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
