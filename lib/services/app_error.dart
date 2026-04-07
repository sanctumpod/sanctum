/// Application-level error types for Sanctum.
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

/// Typed errors returned by [PodService] and surfaced to the UI.
///
/// Throw these instead of raw exceptions so the UI can show human-readable
/// messages without leaking implementation details.
enum AppError implements Exception {
  /// The device has no internet connection or the Pod server is unreachable.
  networkError,

  /// The user's OAuth2 token has expired and they must re-authenticate.
  authExpired,

  /// A requested Pod file was not found — it may have been deleted externally.
  fileNotFound,

  /// A Pod file was found but its Turtle content could not be parsed.
  parseError,

  /// Any other unexpected error.
  unknownError,
}

/// Human-readable messages for each [AppError] value.
extension AppErrorMessage on AppError {
  /// Returns a message suitable for display in a [SnackBar].
  String get userMessage => switch (this) {
        AppError.networkError =>
          'No connection — check your internet and try again.',
        AppError.authExpired =>
          'Session expired — please log in again.',
        AppError.fileNotFound =>
          'Data not found — it may have been deleted.',
        AppError.parseError =>
          'Could not read this record — it may be corrupted.',
        AppError.unknownError =>
          'Something went wrong. Please try again.',
      };
}
