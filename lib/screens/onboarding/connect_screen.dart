/// Connect screen where the user links their private vault to Sanctum.
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

import 'package:solidui/solidui.dart';

import 'package:sanctum/constants/app.dart';
import 'package:sanctum/home.dart';
import 'package:sanctum/theme/app_theme.dart';

/// The second onboarding screen where the user connects their private vault.
///
/// Explains in plain English what a vault is, pre-fills the server URL, and
/// triggers the [SolidLogin] auth flow via the "Connect My Vault" button.
class ConnectScreen extends StatefulWidget {
  /// Creates the Connect onboarding screen.
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  /// Controller for the server URL input field.
  late final TextEditingController _serverController;

  /// Whether the vault connection is in progress.
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill with the default server URL.
    _serverController = TextEditingController(text: kDefaultServerUrl);
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  /// Shows a plain-English explanation of what a vault is.
  void _showVaultExplanation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SanctumTheme.backgroundElevated,
        title: Text(
          'What is a private vault?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          'Think of it like a USB drive in the cloud — a place where your '
          'data is stored that only you can access. Sanctum saves your '
          'transactions there instead of on our servers, so your financial '
          'records stay private and fully under your control.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Launches the Solid login flow using the server URL entered by the user.
  ///
  /// Sets [_isConnecting] to show a loading state on the button, then
  /// navigates to [SolidLogin] which handles the full OAuth flow.
  void _connectVault() {
    setState(() => _isConnecting = true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SolidLogin(
          appDirectory: kAppDirectory,
          webID: _serverController.text.trim(),
          image: const AssetImage('assets/images/app_image.png'),
          logo: const AssetImage('assets/images/app_icon.png'),
          snackbarConfig: const SnackbarConfig(
            backgroundColor: SanctumTheme.backgroundElevated,
            textColor: SanctumTheme.textPrimary,
            actionTextColor: SanctumTheme.accentIndigo,
            borderRadius: SanctumTheme.cardRadius,
          ),
          child: const Home(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanctumTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: SanctumTheme.backgroundPrimary,
        elevation: 0,
        leading: BackButton(color: SanctumTheme.textSecondary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Heading.
              Text(
                'Connect your vault',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              // Plain-language explanation — no Pod, WebID, RDF, or Turtle.
              Text(
                'Sanctum stores your data in your own private vault — '
                'not on our servers. Choose where your vault is hosted '
                'below, then tap Connect My Vault to sign in.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 8),

              // What is a vault tooltip trigger.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showVaultExplanation,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'What is a vault?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SanctumTheme.accentIndigo,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Server URL input label.
              Text(
                'Vault server',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 8),

              // Server URL text field pre-filled with the default server.
              TextField(
                controller: _serverController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'https://solidcommunity.au',
                ),
              ),

              const Spacer(),

              // Connect My Vault button — exact label required by sprint spec.
              ElevatedButton(
                onPressed: _isConnecting ? null : _connectVault,
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SanctumTheme.textOnAccent,
                        ),
                      )
                    : const Text('Connect My Vault'),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
