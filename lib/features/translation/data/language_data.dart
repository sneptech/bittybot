import 'package:flutter/widgets.dart';

import '../domain/supported_language.dart';

// ---------------------------------------------------------------------------
// Complete list of 66 Tiny Aya Global supported languages
// ---------------------------------------------------------------------------
//
// Source: CohereLabs/tiny-aya-global model card on HuggingFace.
// Sorted alphabetically by English name for deterministic display order.
// Country codes are ISO 3166-1 alpha-2 for use with country_flags package.

/// Complete list of languages supported by the Tiny Aya Global model.
///
/// 66 entries sorted alphabetically by [SupportedLanguage.englishName].
/// Use [kPopularLanguages] to pin frequently-used languages at the top of
/// the language picker.
const List<SupportedLanguage> kSupportedLanguages = [
  // A
  SupportedLanguage(englishName: 'Amharic', code: 'am', primaryCountryCode: 'ET'),
  SupportedLanguage(englishName: 'Arabic', code: 'ar', primaryCountryCode: 'SA'),
  // B
  SupportedLanguage(englishName: 'Basque', code: 'eu', primaryCountryCode: 'ES'),
  SupportedLanguage(englishName: 'Bengali', code: 'bn', primaryCountryCode: 'BD'),
  SupportedLanguage(englishName: 'Bulgarian', code: 'bg', primaryCountryCode: 'BG'),
  SupportedLanguage(englishName: 'Burmese', code: 'my', primaryCountryCode: 'MM'),
  // C
  SupportedLanguage(englishName: 'Catalan', code: 'ca', primaryCountryCode: 'ES'),
  SupportedLanguage(englishName: 'Chinese', code: 'zh', primaryCountryCode: 'CN'),
  SupportedLanguage(englishName: 'Croatian', code: 'hr', primaryCountryCode: 'HR'),
  SupportedLanguage(englishName: 'Czech', code: 'cs', primaryCountryCode: 'CZ'),
  // D
  SupportedLanguage(englishName: 'Danish', code: 'da', primaryCountryCode: 'DK'),
  SupportedLanguage(englishName: 'Dutch', code: 'nl', primaryCountryCode: 'NL'),
  // E
  SupportedLanguage(englishName: 'English', code: 'en', primaryCountryCode: 'US'),
  SupportedLanguage(englishName: 'Estonian', code: 'et', primaryCountryCode: 'EE'),
  // F
  SupportedLanguage(englishName: 'Finnish', code: 'fi', primaryCountryCode: 'FI'),
  SupportedLanguage(englishName: 'French', code: 'fr', primaryCountryCode: 'FR'),
  // G
  SupportedLanguage(englishName: 'Galician', code: 'gl', primaryCountryCode: 'ES'),
  SupportedLanguage(englishName: 'German', code: 'de', primaryCountryCode: 'DE'),
  SupportedLanguage(englishName: 'Greek', code: 'el', primaryCountryCode: 'GR'),
  SupportedLanguage(englishName: 'Gujarati', code: 'gu', primaryCountryCode: 'IN'),
  // H
  SupportedLanguage(englishName: 'Hausa', code: 'ha', primaryCountryCode: 'NG'),
  SupportedLanguage(englishName: 'Hebrew', code: 'he', primaryCountryCode: 'IL'),
  SupportedLanguage(englishName: 'Hindi', code: 'hi', primaryCountryCode: 'IN'),
  SupportedLanguage(englishName: 'Hungarian', code: 'hu', primaryCountryCode: 'HU'),
  // I
  SupportedLanguage(englishName: 'Igbo', code: 'ig', primaryCountryCode: 'NG'),
  SupportedLanguage(englishName: 'Indonesian', code: 'id', primaryCountryCode: 'ID'),
  SupportedLanguage(englishName: 'Irish', code: 'ga', primaryCountryCode: 'IE'),
  SupportedLanguage(englishName: 'Italian', code: 'it', primaryCountryCode: 'IT'),
  // J
  SupportedLanguage(englishName: 'Japanese', code: 'ja', primaryCountryCode: 'JP'),
  SupportedLanguage(englishName: 'Javanese', code: 'jv', primaryCountryCode: 'ID'),
  // K
  SupportedLanguage(englishName: 'Khmer', code: 'km', primaryCountryCode: 'KH'),
  SupportedLanguage(englishName: 'Korean', code: 'ko', primaryCountryCode: 'KR'),
  // L
  SupportedLanguage(englishName: 'Lao', code: 'lo', primaryCountryCode: 'LA'),
  SupportedLanguage(englishName: 'Latvian', code: 'lv', primaryCountryCode: 'LV'),
  SupportedLanguage(englishName: 'Lithuanian', code: 'lt', primaryCountryCode: 'LT'),
  // M
  SupportedLanguage(englishName: 'Malagasy', code: 'mg', primaryCountryCode: 'MG'),
  SupportedLanguage(englishName: 'Malay', code: 'ms', primaryCountryCode: 'MY'),
  SupportedLanguage(englishName: 'Maltese', code: 'mt', primaryCountryCode: 'MT'),
  SupportedLanguage(englishName: 'Marathi', code: 'mr', primaryCountryCode: 'IN'),
  // N
  SupportedLanguage(englishName: 'Nepali', code: 'ne', primaryCountryCode: 'NP'),
  SupportedLanguage(englishName: 'Norwegian', code: 'no', primaryCountryCode: 'NO'),
  // P
  SupportedLanguage(englishName: 'Persian', code: 'fa', primaryCountryCode: 'IR'),
  SupportedLanguage(englishName: 'Polish', code: 'pl', primaryCountryCode: 'PL'),
  SupportedLanguage(englishName: 'Portuguese', code: 'pt', primaryCountryCode: 'PT'),
  SupportedLanguage(englishName: 'Punjabi', code: 'pa', primaryCountryCode: 'IN'),
  // R
  SupportedLanguage(englishName: 'Romanian', code: 'ro', primaryCountryCode: 'RO'),
  SupportedLanguage(englishName: 'Russian', code: 'ru', primaryCountryCode: 'RU'),
  // S
  SupportedLanguage(englishName: 'Serbian', code: 'sr', primaryCountryCode: 'RS'),
  SupportedLanguage(englishName: 'Shona', code: 'sn', primaryCountryCode: 'ZW'),
  SupportedLanguage(englishName: 'Slovak', code: 'sk', primaryCountryCode: 'SK'),
  SupportedLanguage(englishName: 'Slovenian', code: 'sl', primaryCountryCode: 'SI'),
  SupportedLanguage(englishName: 'Spanish', code: 'es', primaryCountryCode: 'ES'),
  SupportedLanguage(englishName: 'Swahili', code: 'sw', primaryCountryCode: 'TZ'),
  SupportedLanguage(englishName: 'Swedish', code: 'sv', primaryCountryCode: 'SE'),
  // T
  SupportedLanguage(englishName: 'Tagalog', code: 'tl', primaryCountryCode: 'PH'),
  SupportedLanguage(englishName: 'Tamil', code: 'ta', primaryCountryCode: 'IN'),
  SupportedLanguage(englishName: 'Telugu', code: 'te', primaryCountryCode: 'IN'),
  SupportedLanguage(englishName: 'Thai', code: 'th', primaryCountryCode: 'TH'),
  SupportedLanguage(englishName: 'Turkish', code: 'tr', primaryCountryCode: 'TR'),
  // U
  SupportedLanguage(englishName: 'Ukrainian', code: 'uk', primaryCountryCode: 'UA'),
  SupportedLanguage(englishName: 'Urdu', code: 'ur', primaryCountryCode: 'PK'),
  // W
  SupportedLanguage(englishName: 'Welsh', code: 'cy', primaryCountryCode: 'GB'),
  SupportedLanguage(englishName: 'Wolof', code: 'wo', primaryCountryCode: 'SN'),
  // X
  SupportedLanguage(englishName: 'Xhosa', code: 'xh', primaryCountryCode: 'ZA'),
  // Y
  SupportedLanguage(englishName: 'Yoruba', code: 'yo', primaryCountryCode: 'NG'),
  // Z
  SupportedLanguage(englishName: 'Zulu', code: 'zu', primaryCountryCode: 'ZA'),
];

// ---------------------------------------------------------------------------
// Popular languages — pinned at top of language picker
// ---------------------------------------------------------------------------

/// Top 10 languages by global speaker count.
///
/// These are pinned at the top of the language picker above the full
/// alphabetical list. Values correspond to [SupportedLanguage.englishName].
const List<String> kPopularLanguages = [
  'Spanish',
  'French',
  'Arabic',
  'Chinese',
  'Hindi',
  'Portuguese',
  'Russian',
  'Japanese',
  'German',
  'Korean',
];

// ---------------------------------------------------------------------------
// Country code variants
// ---------------------------------------------------------------------------

/// Maps ISO 639-1 language codes to device locale country code overrides.
///
/// When the device locale's country code matches an entry here, the flag
/// for that country is shown instead of [SupportedLanguage.primaryCountryCode].
///
/// Example: Spanish on a device with locale `es_MX` → Mexico flag ('MX')
/// instead of the default Spain flag ('ES').
const Map<String, Map<String, String>> kLanguageCountryVariants = {
  'es': {'MX': 'MX', 'CO': 'CO', 'AR': 'AR', 'CL': 'CL', 'PE': 'PE', 'VE': 'VE'},
  'pt': {'BR': 'BR'},
  'en': {'US': 'US', 'AU': 'AU', 'CA': 'CA', 'NZ': 'NZ'},
  'fr': {'CA': 'CA', 'BE': 'BE', 'CH': 'CH'},
  'zh': {'TW': 'TW', 'HK': 'HK'},
  'ar': {'EG': 'EG', 'MA': 'MA', 'DZ': 'DZ', 'TN': 'TN', 'IQ': 'IQ', 'JO': 'JO', 'LB': 'LB'},
  'ta': {'LK': 'LK'},
  'bn': {'IN': 'IN'},
  'sw': {'KE': 'KE'},
};

// ---------------------------------------------------------------------------
// Country code resolver
// ---------------------------------------------------------------------------

/// Resolves the best country code for a flag icon given the device locale.
///
/// Checks if [deviceLocale]'s country code is a known variant for
/// [lang]'s ISO code. If so, returns the variant country code; otherwise
/// returns [SupportedLanguage.primaryCountryCode].
///
/// Example:
/// ```dart
/// resolveCountryCode(kSupportedLanguages[50], const Locale('es', 'MX'))
/// // → 'MX' (Mexico flag for Spanish on Mexican device)
/// ```
String resolveCountryCode(SupportedLanguage lang, Locale deviceLocale) {
  final variants = kLanguageCountryVariants[lang.code];
  if (variants == null) return lang.primaryCountryCode;

  final deviceCountry = deviceLocale.countryCode;
  if (deviceCountry == null) return lang.primaryCountryCode;

  return variants[deviceCountry] ?? lang.primaryCountryCode;
}
