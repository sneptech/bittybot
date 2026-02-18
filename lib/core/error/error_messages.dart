// Error message resolver — single entry point for all user-facing error strings.
//
// Each error type has both a friendly and direct variant, selected based on
// the active [ErrorTone] from user settings.
//
// Recommended presentation per error type (for consuming code in later phases):
//   modelNotLoaded  — Full-screen gate (AppStartupWidget handles this)
//   inputTooLong    — Inline validation text below input field
//   inferenceFailed — SnackBar with retry action
//   generic         — SnackBar
//
// This file only resolves the message string; presentation is the caller's
// responsibility.

import 'package:bittybot/core/error/error_tone.dart';
import 'package:bittybot/core/l10n/app_localizations.dart';

/// Categorises all user-visible error scenarios in BittyBot.
///
/// Adding a new variant here requires adding both tone variants to the
/// [resolveErrorMessage] switch — the Dart analyzer will flag missing cases.
enum AppError {
  /// The on-device model has not finished loading yet.
  /// Presentation: full-screen gate before any inference is attempted.
  modelNotLoaded,

  /// The user's text input exceeds the model's context window limit.
  /// Presentation: inline validation text below the input field.
  inputTooLong,

  /// Inference or translation ran but produced an error result.
  /// Presentation: SnackBar with a retry action button.
  inferenceFailed,

  /// Catch-all for unexpected errors not covered by the above.
  /// Presentation: SnackBar.
  generic,
}

/// Resolves the localized error message for the given [error] and [tone].
///
/// Uses [AppLocalizations] to fetch the correct string. Each error has
/// both a friendly and direct variant in the ARB files, ensuring consistent
/// tone across the entire app regardless of where the error originates.
///
/// Example usage:
/// ```dart
/// final message = resolveErrorMessage(
///   AppLocalizations.of(context),
///   AppError.inferenceFailed,
///   settings.errorTone,
/// );
/// ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
/// ```
String resolveErrorMessage(
  AppLocalizations l10n,
  AppError error,
  ErrorTone tone,
) {
  return switch ((error, tone)) {
    (AppError.modelNotLoaded, ErrorTone.friendly) =>
      l10n.modelNotLoadedFriendly,
    (AppError.modelNotLoaded, ErrorTone.direct) => l10n.modelNotLoadedDirect,
    (AppError.inputTooLong, ErrorTone.friendly) => l10n.inputTooLongFriendly,
    (AppError.inputTooLong, ErrorTone.direct) => l10n.inputTooLongDirect,
    (AppError.inferenceFailed, ErrorTone.friendly) =>
      l10n.inferenceFailedFriendly,
    (AppError.inferenceFailed, ErrorTone.direct) => l10n.inferenceFailedDirect,
    (AppError.generic, ErrorTone.friendly) => l10n.genericErrorFriendly,
    (AppError.generic, ErrorTone.direct) => l10n.genericErrorDirect,
  };
}
