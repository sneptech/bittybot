// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BittyBot';

  @override
  String get modelNotLoadedFriendly =>
      'Hang on — the model is still warming up. This only happens once!';

  @override
  String get modelNotLoadedDirect =>
      'Model not loaded. Please wait for setup to complete.';

  @override
  String get inputTooLongFriendly =>
      'Oops — that message is a bit too long. Try shortening it a little.';

  @override
  String get inputTooLongDirect =>
      'Input exceeds maximum length. Shorten your message and try again.';

  @override
  String get inferenceFailedFriendly =>
      'Hmm, something went wrong. Tap to retry.';

  @override
  String get inferenceFailedDirect => 'Translation failed. Please retry.';

  @override
  String get genericErrorFriendly => 'Something unexpected happened.';
}
