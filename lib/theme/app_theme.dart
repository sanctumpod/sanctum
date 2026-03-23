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

  // -- Core Backgrounds ----------------------------------------------------

  /// Deep navy — main scaffold background.
  static const Color backgroundPrimary = Color(0xFF0A0E27);

  /// Slightly lighter — nav rail background.
  static const Color backgroundSurface = Color(0xFF141829);

  /// Card surfaces.
  static const Color backgroundCard = Color(0xFF1C2035);

  /// Elevated cards and dialogs.
  static const Color backgroundElevated = Color(0xFF242840);

  // -- Brand Colours -------------------------------------------------------

  /// Primary accent — Revolut indigo (extracted from Figma).
  static const Color accentIndigo = Color(0xFF4F56F1);

  /// Interactive blue (extracted from Figma).
  static const Color accentBlue = Color(0xFF0666EB);

  /// Blue surface tint (extracted from Figma).
  static const Color accentBlueSurface = Color(0xFFE6F0FD);

  // -- Text ----------------------------------------------------------------

  /// White — primary headings and amounts.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Muted — labels and subtitles.
  static const Color textSecondary = Color(0xFFB0B8C8);

  /// Dimmed — timestamps and hints (from Figma).
  static const Color textTertiary = Color(0xFF75808A);

  /// Text on accent-coloured buttons.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // -- Semantic Colours ----------------------------------------------------

  /// Green — budget under limit (from Figma).
  static const Color semanticSuccess = Color(0xFF00BE90);

  /// Amber — budget 75–99%.
  static const Color semanticWarning = Color(0xFFF59E0B);

  /// Red — budget over limit.
  static const Color semanticError = Color(0xFFEF4444);

  /// Pink — spend indicator (from Figma).
  static const Color semanticPink = Color(0xFFE950A4);

  // -- Card & Border -------------------------------------------------------

  /// Subtle card border.
  static const Color cardBorder = Color(0xFF2A2F4A);

  /// Card border radius from Figma: 18 px.
  static const double cardRadius = 18.0;

  /// Use shadows, not Material elevation.
  static const double cardElevation = 0.0;

  // -- Theme ---------------------------------------------------------------

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
        ),
        cardTheme: CardTheme(
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
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          displayMedium: TextStyle(
            color: textPrimary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: textTertiary,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: textOnAccent,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundPrimary,
          foregroundColor: textPrimary,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentIndigo, width: 2),
          ),
          labelStyle: const TextStyle(color: textTertiary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentIndigo,
            foregroundColor: textOnAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      );
}
