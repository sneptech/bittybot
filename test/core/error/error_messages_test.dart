import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bittybot/core/error/error_messages.dart';
import 'package:bittybot/core/error/error_tone.dart';
import 'package:bittybot/core/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    // Load the English localization directly without a widget tree.
    // AppLocalizations.delegate.load() is synchronous for generated delegates
    // (uses SynchronousFuture), so the await completes immediately.
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('resolveErrorMessage', () {
    test('modelNotLoaded friendly returns warm warming-up message', () {
      final msg = resolveErrorMessage(l10n, AppError.modelNotLoaded, ErrorTone.friendly);
      // English: "Hang on — the model is still warming up. This only happens once!"
      expect(msg, contains('warming up'));
    });

    test('modelNotLoaded direct returns clear not-loaded message', () {
      final msg = resolveErrorMessage(l10n, AppError.modelNotLoaded, ErrorTone.direct);
      // English: "Model not loaded. Please wait for setup to complete."
      expect(msg.toLowerCase(), contains('not loaded'));
    });

    test('inputTooLong friendly returns gentle message', () {
      final msg = resolveErrorMessage(l10n, AppError.inputTooLong, ErrorTone.friendly);
      // English: "Oops — that message is a bit too long. Try shortening it a little."
      expect(msg, isNotEmpty);
    });

    test('inputTooLong direct returns concise validation message', () {
      final msg = resolveErrorMessage(l10n, AppError.inputTooLong, ErrorTone.direct);
      // English: "Input exceeds maximum length. Shorten your message and try again."
      expect(msg, isNotEmpty);
    });

    test('inferenceFailed friendly returns actionable message', () {
      final msg = resolveErrorMessage(l10n, AppError.inferenceFailed, ErrorTone.friendly);
      // English: "Hmm, something went wrong. Tap to retry."
      expect(msg, isNotEmpty);
    });

    test('inferenceFailed direct returns retry message', () {
      final msg = resolveErrorMessage(l10n, AppError.inferenceFailed, ErrorTone.direct);
      // English: "Translation failed. Please retry."
      expect(msg.toLowerCase(), contains('retry'));
    });

    test('generic friendly returns non-empty message', () {
      final msg = resolveErrorMessage(l10n, AppError.generic, ErrorTone.friendly);
      // English: "Something unexpected happened. Give it another try?"
      expect(msg, isNotEmpty);
    });

    test('generic direct returns non-empty message', () {
      final msg = resolveErrorMessage(l10n, AppError.generic, ErrorTone.direct);
      // English: "An error occurred. Please try again."
      expect(msg, isNotEmpty);
    });

    test('all AppError x ErrorTone combinations return non-empty strings', () {
      for (final error in AppError.values) {
        for (final tone in ErrorTone.values) {
          final msg = resolveErrorMessage(l10n, error, tone);
          expect(
            msg,
            isNotEmpty,
            reason: '$error + $tone should produce a non-empty message',
          );
        }
      }
    });
  });
}
