import 'package:flutter/foundation.dart';

/// Immutable value object representing a language supported by the Tiny Aya model.
///
/// Used in the language picker to display flag icons, localized names, and
/// to drive [TranslationNotifier.setTargetLanguage].
@immutable
class SupportedLanguage {
  /// English name of the language (e.g., 'Spanish').
  ///
  /// Used as the key for [TranslationNotifier.setTargetLanguage] and as the
  /// fallback name when localization is unavailable.
  final String englishName;

  /// ISO 639-1 language code (e.g., 'es').
  ///
  /// Used by flutter_localized_locales for
  /// `LocaleNames.of(context).nameOf(code)` to display the language name
  /// in the device locale.
  final String code;

  /// ISO 3166-1 alpha-2 country code for the primary flag icon (e.g., 'ES').
  ///
  /// Used by country_flags `CountryFlag.fromCountryCode(primaryCountryCode)`.
  /// For languages without a dedicated country (e.g., Catalan), the most
  /// prominent host country is used.
  final String primaryCountryCode;

  const SupportedLanguage({
    required this.englishName,
    required this.code,
    required this.primaryCountryCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportedLanguage &&
          runtimeType == other.runtimeType &&
          englishName == other.englishName &&
          code == other.code &&
          primaryCountryCode == other.primaryCountryCode;

  @override
  int get hashCode =>
      englishName.hashCode ^ code.hashCode ^ primaryCountryCode.hashCode;

  @override
  String toString() =>
      'SupportedLanguage(englishName: $englishName, code: $code, primaryCountryCode: $primaryCountryCode)';
}
