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
import 'package:solidpod/solidpod.dart' show getWebId;
import 'package:solidui/solidui.dart';

// Group 3: Local package imports.
import 'package:sanctum/screens/bills_screen.dart';
import 'package:sanctum/screens/budgets_screen.dart';
import 'package:sanctum/screens/dashboard_screen.dart';
import 'package:sanctum/screens/transactions_screen.dart';

/// Main navigation host widget using [SolidScaffold].
///
/// Presents the four primary sections of Sanctum as menu items and
/// populates the nav drawer with the authenticated user's webId.
class Home extends StatelessWidget {
  /// Creates the Home navigation widget.
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to read the persisted webId without converting to
    // a StatefulWidget — avoids unnecessary rebuild complexity.
    return FutureBuilder<String?>(
      future: getWebId(),
      builder: (context, snapshot) {
        return SolidScaffold(
          userInfo: SolidNavUserInfo(
            webId: snapshot.data,
            showWebId: true,
          ),
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
      },
    );
  }
}
