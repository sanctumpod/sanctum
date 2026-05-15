/// Home widget providing the main navigation scaffold.
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
import 'package:sanctum/providers/bill_providers.dart';
import 'package:sanctum/providers/budget_providers.dart';
import 'package:sanctum/providers/nav_provider.dart';
import 'package:sanctum/providers/transaction_providers.dart';
import 'package:sanctum/screens/bills_screen.dart';
import 'package:sanctum/screens/budgets_screen.dart';
import 'package:sanctum/screens/dashboard_screen.dart';
import 'package:sanctum/screens/onboarding/welcome_screen.dart';
import 'package:sanctum/screens/transactions_screen.dart';
import 'package:sanctum/services/app_error.dart';

/// Main navigation host widget using [SolidScaffold].
///
/// Presents the four primary sections of Sanctum as menu items and
/// populates the nav drawer with the authenticated user's webId.
/// Initialises the Pod security key on first mount so that all encrypted
/// read/write operations succeed without requiring individual screens to
/// prompt for the key.
class Home extends ConsumerStatefulWidget {
  /// Creates the Home navigation widget.
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  /// The authenticated user's WebID, populated after the first frame.
  String? _webId;

  /// Whether the Pod security key has been set for this session.
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();

    // Defer Pod initialisation until after the first frame so that the
    // Navigator and Overlay are available for any dialogs that need to appear.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialisePod());
  }

  /// Fetches the WebID and ensures the Pod security key is available.
  ///
  /// The security key must be set before any encrypted [writePod] or [readPod]
  /// call can succeed. This mirrors the pattern in healthpod's
  /// HomeStateManager.initialiseData.
  Future<void> _initialisePod() async {
    final webId = await getWebId();
    if (!mounted) return;

    setState(() => _webId = webId);

    if (webId == null || webId.isEmpty) return;

    // Prompt for the Pod security key once per session.
    if (!mounted) return;
    final keySaved =
        await SolidSecurityKeyCentralManager.instance.ensureSecurityKey(
      context,
      const Text('Enter your security key to access your Sanctum data.'),
    );

    if (!mounted) return;
    setState(() => _isKeySaved = keySaved);
  }

  /// Handles an auth-expiry error from any data provider.
  ///
  /// Shows the session-expired snackbar and navigates back to [WelcomeScreen],
  /// clearing the entire navigation stack.
  void _handleAuthExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppError.authExpired.userMessage),
        duration: const Duration(seconds: 4),
      ),
    );
    SolidAuthHandler.instance.handleLogout(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the selected tab index so the scaffold highlights the correct item.
    final selectedTab = ref.watch(selectedTabProvider);

    // Listen for auth-expiry errors on any of the three data providers and
    // redirect the user back to the welcome screen so they can re-authenticate.
    ref.listen(transactionListProvider, (_, next) {
      if (next is AsyncError && next.error == AppError.authExpired) {
        _handleAuthExpired();
      }
    });
    ref.listen(budgetListProvider, (_, next) {
      if (next is AsyncError && next.error == AppError.authExpired) {
        _handleAuthExpired();
      }
    });
    ref.listen(billReminderListProvider, (_, next) {
      if (next is AsyncError && next.error == AppError.authExpired) {
        _handleAuthExpired();
      }
    });

    return SolidScaffold(
      userInfo: SolidNavUserInfo(
        webId: _webId,
        showWebId: true,
      ),
      onLogout: (context) => SolidAuthHandler.instance.handleLogout(context),
      statusBar: SolidStatusBarConfig(
        loginStatus: SolidLoginStatus(webId: _webId),
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          onKeyStatusChanged: (status) =>
              setState(() => _isKeySaved = status),
        ),
      ),
      // Keep selectedIndex in sync with the Riverpod provider so that
      // insight card taps can switch tabs programmatically.
      selectedIndex: selectedTab,
      onMenuSelected: (index) =>
          ref.read(selectedTabProvider.notifier).setTab(index),
      menu: const [
        SolidMenuItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          child: DashboardScreen(),
        ),
        SolidMenuItem(
          title: 'Transactions',
          icon: Icons.receipt_long,
          child: TransactionsScreen(),
        ),
        SolidMenuItem(
          title: 'Budgets',
          icon: Icons.account_balance_wallet,
          child: BudgetsScreen(),
        ),
        SolidMenuItem(
          title: 'Bills',
          icon: Icons.calendar_today,
          child: BillsScreen(),
        ),
      ],
    );
  }
}
