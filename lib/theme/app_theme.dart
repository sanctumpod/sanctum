/// Theme definitions for the Sanctum application.
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

/// Provides the Sanctum application theme definitions.
///
/// Use [SanctumTheme.darkTheme] for the primary dark theme.
/// All colour tokens are defined here — never hardcode hex values elsewhere.
class SanctumTheme {
  // Prevent instantiation.
  SanctumTheme._();

  // -- Core Backgrounds -------------------------------------------------------

  /// Deep navy — main scaffold background.
  static const Color backgroundPrimary = Color(0xFF080C20);

  /// Slightly lighter — nav rail background.
  static const Color backgroundSurface = Color(0xFF0F1328);

  /// Card surfaces.
  static const Color backgroundCard = Color(0xFF181D36);

  /// Elevated cards and dialogs.
  static const Color backgroundElevated = Color(0xFF212642);

  // -- Brand Colours ----------------------------------------------------------

  /// Primary accent — Revolut indigo (extracted from Figma).
  static const Color accentIndigo = Color(0xFF4F56F1);

  /// Interactive blue (extracted from Figma).
  static const Color accentBlue = Color(0xFF0666EB);

  /// Blue surface tint (extracted from Figma).
  static const Color accentBlueSurface = Color(0xFFE6F0FD);

  // -- Text -------------------------------------------------------------------

  /// White — primary headings and amounts.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Muted — labels and subtitles.
  static const Color textSecondary = Color(0xFFB0B8C8);

  /// Dimmed — timestamps and hints (from Figma).
  static const Color textTertiary = Color(0xFF5B6880);

  /// Text on accent-coloured buttons.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // -- Semantic Colours -------------------------------------------------------

  /// Green — budget under limit (from Figma).
  static const Color semanticSuccess = Color(0xFF00BE90);

  /// Amber — budget 75–99%.
  static const Color semanticWarning = Color(0xFFF59E0B);

  /// Red — budget over limit.
  static const Color semanticError = Color(0xFFEF4444);

  /// Pink — spend indicator (from Figma).
  static const Color semanticPink = Color(0xFFE950A4);

  // -- Card & Border ----------------------------------------------------------

  /// Subtle card border.
  static const Color cardBorder = Color(0xFF252A48);

  /// Card border radius from Figma: 18 px.
  static const double cardRadius = 18.0;

  /// Use shadows, not Material elevation.
  static const double cardElevation = 0.0;

  // -- Category Palette -------------------------------------------------------

  /// Rotating palette for category chart segments and icon badges.
  ///
  /// Cycle using `index % categoryColors.length` when iterating categories.
  static const List<Color> categoryColors = [
    Color(0xFF4F56F1), // Indigo
    Color(0xFF00BE90), // Teal
    Color(0xFFE950A4), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF0666EB), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
  ];

  /// Returns the [IconData] that best represents [category].
  static IconData categoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'groceries' => Icons.local_grocery_store_outlined,
      'transport' => Icons.directions_car_outlined,
      'utilities' => Icons.bolt_outlined,
      'dining' => Icons.restaurant_outlined,
      'health' => Icons.favorite_outline,
      'entertainment' => Icons.movie_outlined,
      _ => Icons.category_outlined,
    };
  }

  /// Returns a deterministic [Color] from [categoryColors] for [category].
  ///
  /// The colour is stable for a given category name across rebuilds.
  static Color categoryColor(String category) {
    final index = category.hashCode.abs() % categoryColors.length;
    return categoryColors[index];
  }

  // -- Theme ------------------------------------------------------------------

  /// The primary dark theme for the Sanctum application.
  ///
  /// References all colour tokens defined above.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundPrimary,
        colorScheme: const ColorScheme.dark(
          primary: accentIndigo,
          secondary: accentBlue,
          surface: backgroundSurface,
          onPrimary: textOnAccent,
          onSecondary: textOnAccent,
          onSurface: textPrimary,
          error: semanticError,
        ),
        cardTheme: CardThemeData(
          color: backgroundCard,
          elevation: cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: const BorderSide(color: cardBorder, width: 1),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
          displayMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: textTertiary,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            color: textOnAccent,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelSmall: TextStyle(
            color: textTertiary,
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundPrimary,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentIndigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: semanticError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: semanticError, width: 2),
          ),
          labelStyle: const TextStyle(color: textTertiary),
          hintStyle: const TextStyle(color: textTertiary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentIndigo,
            foregroundColor: textOnAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.1,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentIndigo,
          foregroundColor: textOnAccent,
          elevation: 0,
          shape: CircleBorder(),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accentIndigo,
          linearTrackColor: cardBorder,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: backgroundElevated,
          labelStyle: const TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          side: const BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accentIndigo.withValues(alpha: 0.2);
              }
              return backgroundCard;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return accentIndigo;
              return textTertiary;
            }),
            side: WidgetStateProperty.all(
              const BorderSide(color: cardBorder),
            ),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minLeadingWidth: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: cardBorder,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: backgroundElevated,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
