/// Confirmation screen shown after a user successfully connects their vault.
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
import 'package:solidpod/solidpod.dart' show getWebId;

// Group 3: Local package imports.
import 'package:sanctum/home.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The third onboarding screen, displayed after a successful vault connection.
///
/// Confirms the connected vault identity and routes to [Home] via the
/// "Start Using Sanctum" button.
class ConfirmationScreen extends StatelessWidget {
  /// Creates the Confirmation onboarding screen.
  const ConfirmationScreen({super.key});

  /// Navigates to [Home] and removes all prior routes from the stack.
  void _startUsingSanctum(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

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
              const Icon(
                Icons.check_circle_outline,
                color: SanctumTheme.semanticSuccess,
                size: 72,
              ),

              const SizedBox(height: 32),

              // Heading.
              Text(
                'Vault connected!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Plain-English confirmation message.
              Text(
                'Your private vault is ready. Your financial records will be '
                'saved there and never shared with us.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Display the connected vault identity.
              FutureBuilder<String?>(
                future: getWebId(),
                builder: (context, snapshot) {
                  final webId = snapshot.data;
                  if (webId == null || webId.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: SanctumTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(SanctumTheme.cardRadius),
                      border: Border.all(color: SanctumTheme.cardBorder),
                    ),
                    child: Text(
                      webId,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),

              const Spacer(),

              // Start Using Sanctum button — exact label required by sprint spec.
              ElevatedButton(
                onPressed: () => _startUsingSanctum(context),
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
