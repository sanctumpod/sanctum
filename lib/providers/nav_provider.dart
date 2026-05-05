/// Riverpod provider for global navigation tab index.
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

// Group 2: Third-party package imports.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Menu index constants matching the [SolidScaffold] menu order in home.dart.
class NavIndex {
  NavIndex._();

  /// Dashboard tab index.
  static const int dashboard = 0;

  /// Transactions tab index.
  static const int transactions = 1;

  /// Budgets tab index.
  static const int budgets = 2;

  /// Bills tab index.
  static const int bills = 3;
}

/// Notifier that holds the currently selected [SolidScaffold] tab index.
///
/// Write to this notifier to programmatically switch tabs — [Home] reads it
/// via [SolidScaffold.selectedIndex] and propagates changes back via
/// [SolidScaffold.onMenuSelected].
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => NavIndex.dashboard;

  /// Sets the active tab to [index].
  void setTab(int index) => state = index;
}

/// Provides the currently selected [SolidScaffold] tab index.
final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);
