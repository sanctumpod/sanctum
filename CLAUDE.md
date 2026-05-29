---
name: sanctum-project-skill
description: "Architecture memory for Project Sanctum — a Flutter + SOLID Pods personal finance app. Load this before every Claude Code session. Contains non-negotiable architecture rules, design tokens, folder structure, sprint state, and known unknowns. Violating these rules introduces bugs that are expensive to fix."
---

# Project Sanctum — Architecture & Development Guide

## What This Project Is

**Sanctum** is a Flutter personal finance app that stores all user data in SOLID Pods (user-controlled, privacy-first data vaults). It follows the healthpod reference implementation exactly. When in doubt about how to do something, check healthpod first.

- **Repository:** https://github.com/sanctumpod/sanctum
- **Reference app:** https://github.com/anusii/healthpod
- **Sprint planning (Notion):** https://www.notion.so/311beb727f16807dabc0e20f4b101f82
- **Pod provider:** https://solidcommunity.au
- **Target platforms:** Android, iOS, Web (mobile-first)

---

## ⛔ NON-NEGOTIABLE ARCHITECTURE RULES

Violating any of these rules introduces hard-to-debug auth or data corruption issues. Claude Code must not deviate from these rules under any circumstances.

### Authentication
- **NEVER** import or call `solid_auth` directly — it is a transitive dependency only
- **ALWAYS** use `SolidAuthHandler.instance.configure(SolidAuthConfig(...))` in the root widget's `initState`
- **ALWAYS** wrap the home screen in `SolidLogin()` from `solidui`
- `SolidAuthHandler` manages the full OAuth2 flow internally — do not reimplement it
- Auth pattern mirrors `healthpod.dart` and `home.dart` exactly — read those files before writing auth code

### Pod Data Layer
- **NEVER** create or maintain a `manifest.ttl` file — use directory listing instead
- **ALWAYS** use `getDirUrl()` + `getResourcesInContainer()` from `solidpod` for directory discovery
- All RDF/Turtle logic is **strictly isolated inside `PodService`** — no other file imports `rdflib` or constructs Turtle strings
- Encrypted Pod file extension: `.enc.ttl` (not `.ttl`, not `.json`)
- App directory on Pod: `sanctum` (not `Sanctum`, not `sanctumpod`)
- `writePod()` creates directories automatically on first write — do not pre-create directories

### Dependencies
- **NEVER** add a dependency to `pubspec.yaml` that is not already present
- **NEVER** upgrade existing dependency versions without explicit instruction
- The current `pubspec.yaml` already contains all required dependencies for all 6 sprints
- If you think a new dependency is needed, flag it as a comment — do not add it

### Folder Structure
- Follow healthpod's flat `lib/` structure — do NOT invent feature folders without instruction
- Required files and their locations:

```
lib/
├── main.dart                    # Entry point — ProviderScope + app launch only
├── sanctum.dart                 # Root widget — mirrors healthpod.dart exactly
├── home.dart                    # SolidScaffold with 4 menu items — mirrors healthpod home.dart
├── constants/
│   └── app.dart                 # App-level constants (appTitle, appDirectory, etc.)
├── theme/
│   └── app_theme.dart           # ThemeData definition — ALL colour tokens live here
├── screens/
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── budgets_screen.dart
│   └── bills_screen.dart
├── services/
│   └── pod_service.dart         # ALL RDF/Turtle logic — isolated here only
├── models/
│   ├── transaction.dart
│   ├── budget.dart
│   └── bill_reminder.dart
└── providers/
    └── settings.dart            # Riverpod providers — mirrors healthpod pattern
```

### Navigation
- Use `SolidScaffold` from `solidui` with **exactly 4 `SolidMenuItem`s**: Dashboard, Transactions, Budgets, Bills
- `SolidScaffold` handles responsive nav automatically (side rail ≥800px, hamburger drawer <800px)
- **Do NOT** add a custom bottom navigation bar — this conflicts with SolidScaffold
- **Do NOT** add `narrowScreenThreshold` customisation unless explicitly instructed

---

## 🎨 DESIGN TOKENS

All colours must be defined in `lib/theme/app_theme.dart` as a `ThemeData` object and referenced via `Theme.of(context)`. **Never hardcode hex values anywhere else in the codebase.**

### Colour Palette (Sanctum Dark — Revolut-inspired)

```dart
// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class SanctumTheme {
  // ── Core Backgrounds ──────────────────────────────────────────────
  static const Color backgroundPrimary   = Color(0xFF0A0E27);  // Deep navy — main scaffold bg
  static const Color backgroundSurface   = Color(0xFF141829);  // Slightly lighter — nav rail bg
  static const Color backgroundCard      = Color(0xFF1C2035);  // Card surfaces
  static const Color backgroundElevated  = Color(0xFF242840);  // Elevated cards, dialogs

  // ── Brand Colours ─────────────────────────────────────────────────
  static const Color accentIndigo        = Color(0xFF4F56F1);  // Primary accent — Revolut indigo (extracted from Figma)
  static const Color accentBlue          = Color(0xFF0666EB);  // Interactive blue (extracted from Figma)
  static const Color accentBlueSurface   = Color(0xFFE6F0FD);  // Blue surface tint (extracted from Figma)

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary         = Color(0xFFFFFFFF);  // White — primary headings, amounts
  static const Color textSecondary       = Color(0xFFB0B8C8);  // Muted — labels, subtitles
  static const Color textTertiary        = Color(0xFF75808A);  // Dimmed — timestamps, hints (from Figma)
  static const Color textOnAccent        = Color(0xFFFFFFFF);  // Text on accent-coloured buttons

  // ── Semantic Colours ──────────────────────────────────────────────
  static const Color semanticSuccess     = Color(0xFF00BE90);  // Green — budget under limit (from Figma)
  static const Color semanticWarning     = Color(0xFFF59E0B);  // Amber — budget 75–99%
  static const Color semanticError       = Color(0xFFEF4444);  // Red — budget over limit
  static const Color semanticPink        = Color(0xFFE950A4);  // Pink — spend indicator (from Figma)

  // ── Card & Border ─────────────────────────────────────────────────
  static const Color cardBorder          = Color(0xFF2A2F4A);  // Subtle card border
  static const double cardRadius         = 18.0;               // From Figma: 18px border radius
  static const double cardElevation      = 0.0;                // Use shadows, not Material elevation

  // ── Typography ────────────────────────────────────────────────────
  // Font family: Inter (Regular 400, Medium 500, SemiBold 600) — extracted from Figma
  // Note: Inter is not bundled in Flutter by default. Add to pubspec assets or use google_fonts.
  // ⚠️ UNKNOWN: Confirm Inter font bundling approach before generating font-dependent code.

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
      displayLarge:  TextStyle(color: textPrimary,    fontFamily: 'Inter', fontWeight: FontWeight.w600),
      displayMedium: TextStyle(color: textPrimary,    fontFamily: 'Inter', fontWeight: FontWeight.w600),
      titleLarge:    TextStyle(color: textPrimary,    fontFamily: 'Inter', fontWeight: FontWeight.w600),
      titleMedium:   TextStyle(color: textPrimary,    fontFamily: 'Inter', fontWeight: FontWeight.w500),
      bodyLarge:     TextStyle(color: textPrimary,    fontFamily: 'Inter', fontWeight: FontWeight.w400),
      bodyMedium:    TextStyle(color: textSecondary,  fontFamily: 'Inter', fontWeight: FontWeight.w400),
      bodySmall:     TextStyle(color: textTertiary,   fontFamily: 'Inter', fontWeight: FontWeight.w400),
      labelLarge:    TextStyle(color: textOnAccent,   fontFamily: 'Inter', fontWeight: FontWeight.w500),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}
```

### ⚠️ Theming Unknown
SolidScaffold's nav rail and AppBar surfaces have not yet been audited against this ThemeData. Until `flutter run` confirms which surfaces respect `Theme.of(context)`, do not assume the nav rail background will be `backgroundSurface`. Flag any surface that appears wrong after running.

---

## 📦 DATA MODELS

Three core Dart classes. Never change field names — they map to RDF predicates.

```dart
// Transaction
String id;        // UUID
double amount;    // positive number
String merchant;  // e.g. "Woolworths"
String category;  // e.g. "Groceries"
DateTime date;
String? notes;

// Budget
String id;
String category;
double monthlyLimit;
String month;     // format: "2026-03" (ISO year-month)

// BillReminder
String id;
String name;
double amount;
DateTime dueDate;
String recurrence;  // "one-off" | "monthly"
bool isPaid;
```

### Pod File Structure
```
sanctum/
├── transactions/
│   └── tx_<uuid>.enc.ttl
├── budgets/
│   └── budget_<uuid>.enc.ttl
└── reminders/
    └── reminder_<uuid>.enc.ttl
```

**No `manifest.ttl`.** Directory listing via `getResourcesInContainer()` replaces it.

---

## 🏃 SPRINT STATE

### Sprint 1 — Foundation (Weeks 1–2)
| Task | Code | Status |
|------|------|--------|
| `pubspec.yaml` with all Sprint 1–6 deps | S1.3.1 | ✅ DONE |
| `SolidScaffold` with 4 menu items | S1.4.1 | ❌ NOT DONE |
| `SolidLogin` rendering correctly | S1.4.2 | ❌ NOT DONE (login button only) |
| Riverpod `ProviderScope` at root | S1.4.3 | ❌ NOT DONE |
| `app_theme.dart` with `ThemeData` | S1.4.4 | ❌ NOT DONE |

**Sprint 1 must be completed before Sprint 2 auth work begins. S2.1.1 depends on S1.4.1.**

### Sprint 2 — Authentication & Onboarding (Weeks 3–4) — NOT STARTED
| Task | Code | Depends On |
|------|------|-----------|
| Wire "Connect My Vault" to `SolidLogin()` | S2.1.1 | S1.4.1 |
| Token persistence with `flutter_secure_storage` | S2.2.1 | S2.1.1 |
| Build 3 onboarding screens | S2.3.1 | S2.2.1 |

### Sprints 3–6 — NOT STARTED
See Notion sprint planning for full task breakdown.

---

## 🏗️ ARCHITECTURE RULES BY SPRINT

### Sprint 1–2 (Active)
- `sanctum.dart`: configure `SolidAuthHandler` in `initState`, build `SolidLogin` wrapping `home.dart`
- `home.dart`: build `SolidScaffold` with 4 `SolidMenuItem`s, read `webId` from `SolidAuthHandler` for `statusBar`
- `main.dart`: wrap in `ProviderScope`, call `SanctumTheme.darkTheme` on `MaterialApp`
- `SolidAuthConfig` params: `appTitle: 'SANCTUM'`, `appDirectory: 'sanctum'`, `defaultServerUrl: 'https://solidcommunity.au'`

### Sprint 3 (Pod Read/Write — future)
- All Turtle serialization and parsing lives in `lib/services/pod_service.dart` ONLY
- RDF prefix: `@prefix fin: <http://sanctum.app/finance#> .`
- XSD prefix: `@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .`
- Parse using `rdflib`'s `Graph()` — never use regex on Turtle strings
- Use `getDirUrl()` + `getResourcesInContainer()` — never maintain a manifest

### Sprint 4–5 (UI — future)
- Riverpod providers: `transactionListProvider`, `budgetListProvider`, `billReminderListProvider` (all `AsyncNotifier`)
- Derived providers: `spendingByCategory`, `budgetProgressProvider`
- Never call `PodService` directly from widgets — always via Riverpod providers

---

## 🚫 COMMON MISTAKES — NEVER DO THESE

```dart
// ❌ WRONG — calls solid_auth directly
import 'package:solid_auth/solid_auth.dart';
await solidAuthenticate(serverUrl, context);

// ✅ CORRECT — use SolidAuthHandler
SolidAuthHandler.instance.configure(SolidAuthConfig(...));
// Then wrap home in SolidLogin()

// ❌ WRONG — maintains manifest
await writePod('sanctum/manifest.ttl', manifestContent);

// ✅ CORRECT — directory listing
final dirUrl = await getDirUrl('sanctum/transactions');
final resources = await getResourcesInContainer(dirUrl);

// ❌ WRONG — hardcoded colour
Container(color: Color(0xFF4F56F1), ...)

// ✅ CORRECT — theme token
Container(color: Theme.of(context).colorScheme.primary, ...)

// ❌ WRONG — adds new dependency
dependencies:
  provider: ^6.0.0   // NOT in pubspec.yaml — do not add

// ❌ WRONG — RDF logic outside PodService
// In transactions_screen.dart:
final g = Graph();  // NEVER — RDF only in pod_service.dart

// ❌ WRONG — feature folder not in agreed structure
lib/features/transactions/...  // NOT the agreed pattern

// ❌ WRONG — custom bottom nav
BottomNavigationBar(...)  // SolidScaffold handles nav — do not add this
```

---

## ⚠️ KNOWN UNKNOWNS — DO NOT ASSUME

These decisions are not yet validated. Flag them rather than guessing:

1. **SolidScaffold theming surfaces**: Which nav rail / AppBar surfaces respect `ThemeData`? Not yet audited. After `flutter run`, note which surfaces need manual colour overrides.
2. **Inter font bundling**: Is Inter bundled via `pubspec.yaml` assets or `google_fonts`? Check `pubspec.yaml` before generating any font-specific code.
3. **`SolidLogin` customisation params**: Exact parameter names for `appImage`, `appLogo`, `appLink` in the current `solidui 0.1.0` API — verify against the package source before using.
4. **Platform-specific OAuth callback**: Web requires `web/callback.html`, Android requires `AndroidManifest.xml` queries block — not yet confirmed as configured.

---

## 📐 SPRINT 1 COMPLETION CHECKLIST

When asked to complete Sprint 1, produce these files in order:

1. `lib/constants/app.dart` — define `kAppTitle`, `kAppDirectory`, `kDefaultServerUrl`, `kAppVersion`
2. `lib/theme/app_theme.dart` — full `SanctumTheme` class as defined above
3. `lib/sanctum.dart` — root widget with `SolidAuthHandler.instance.configure(...)` in `initState`, wrapping `SolidLogin(child: Home())`
4. `lib/home.dart` — `SolidScaffold` with 4 `SolidMenuItem`s (Dashboard, Transactions, Budgets, Bills), each pointing to a placeholder screen
5. `lib/main.dart` — `ProviderScope` at root, `MaterialApp(theme: SanctumTheme.darkTheme, home: Sanctum())`
6. `lib/screens/dashboard_screen.dart` — placeholder with centred "Dashboard" label
7. `lib/screens/transactions_screen.dart` — placeholder
8. `lib/screens/budgets_screen.dart` — placeholder
9. `lib/screens/bills_screen.dart` — placeholder

**Style requirements for every generated file:**
- Full GPL v3 file header (see CODING STYLE STANDARDS above)
- `library;` directive after header, before imports
- Three import groups separated by blank lines
- Single quotes throughout
- Trailing commas on all multi-line argument lists
- `///` doc comments on all public classes and methods
- All inline comments end with a full stop

**Do not generate any other files unless explicitly asked. Do not add files not in this list.**

---

## 📝 CODING STYLE STANDARDS (SUPERVISOR REQUIREMENTS)

These standards are mandatory. They match the togaware/healthpod codebase. Claude Code must apply them to every file it generates without exception. Source: https://survivor.togaware.com/gnulinux/flutter-style.html

### File Header (Required on Every .dart File)

Every Dart file must begin with this exact header structure:

```dart
/// [One-line description of what this file provides].
//
// Time-stamp: <[leave blank — updated by editor]>
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
```

The `library;` directive is **always** on its own line immediately after the header, before any imports.

### Import Ordering (Three Groups, Blank Line Between Each)

```dart
// Group 1: Flutter/Dart SDK imports.
import 'package:flutter/material.dart';

// Group 2: Third-party package imports (alphabetical within group).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidui/solidui.dart';

// Group 3: Local package imports (alphabetical within group).
import 'package:sanctum/home.dart';
import 'package:sanctum/theme/app_theme.dart';
```

Never mix groups. Never omit the blank lines between groups.

### String Literals
- **Always use single quotes**: `'hello'` not `"hello"`
- Exception only when the string itself contains a single quote: `"it's fine"`

### Trailing Commas
- **Always** add a trailing comma on the last item of any multi-line argument list, parameter list, or collection literal:

```dart
// ✅ CORRECT
SolidScaffold(
  menu: [
    SolidMenuItem(...),
    SolidMenuItem(...),  // trailing comma
  ],
  appBar: SolidAppBar(...),  // trailing comma
);

// ❌ WRONG — missing trailing commas
SolidScaffold(
  menu: [...],
  appBar: SolidAppBar(...)
);
```

### Comments
- Doc comments on public classes and methods use `///` (triple-slash)
- Inline implementation comments use `//` (double-slash)
- All comments end with a full stop (period): `// Load the transactions.` not `// Load the transactions`
- One blank line between a comment and the next non-comment code block
- Section-separating comments are permitted: `// Initialise settings.`

### Class and Method Documentation
Every public class and every public method must have a `///` doc comment:

```dart
/// Root widget for the Sanctum app.
///
/// Configures [SolidAuthHandler] and wraps the app in [SolidLogin].
class Sanctum extends ConsumerStatefulWidget {

  /// Loads all transactions from the user's Pod.
  ///
  /// Returns an empty list if the directory does not yet exist.
  Future<List<Transaction>> loadAllTransactions() async {
```

### Const Constructors
- Prefer `const` constructors wherever possible: `const SizedBox(height: 16)`
- Use `const` on widget instantiations that have no dynamic data

### Avoid Print
- **Never** use `print()` — use a proper logger or `debugPrint()` only
- All `print()` calls will fail the linter (`avoid_print: true`)

### Line Length and Formatting
- Run `dart format` before every commit — do not manually format
- Maximum line length follows dart format defaults (no manual wrapping needed)
- Never add `// ignore:` directives without explicit instruction

### analysis_options.yaml (Required Linter Rules)
The project must include these linter rules (already present — do not modify):

```yaml
linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    require_trailing_commas: true
    prefer_const_constructors: true
```

---

## 🔍 REFERENCE FILES TO READ BEFORE CODING

Before writing any auth or scaffold code, read these healthpod source files:
- `healthpod/lib/healthpod.dart` — how `SolidAuthHandler` is configured
- `healthpod/lib/home.dart` — how `SolidScaffold` and `SolidMenuItem` are used
- `healthpod/lib/utils/create_solid_login.dart` — how `SolidLogin` is constructed

These are your ground truth. Sanctum's `sanctum.dart`, `home.dart`, and login setup must mirror them structurally.

---

## gstack

- Use `/browse` from gstack for **all web browsing** — never use `mcp__claude-in-chrome__*` tools
- Available skills: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`
