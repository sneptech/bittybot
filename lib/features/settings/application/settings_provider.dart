import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bittybot/core/error/error_tone.dart';

part 'settings_provider.g.dart';

/// Immutable value object holding all user-configurable app settings.
///
/// [localeOverride] — null means follow the device locale; a non-null
/// [Locale] overrides the device default (e.g. Locale('ar') for Arabic).
///
/// [errorTone] — controls the tone of all user-facing error messages.
/// Defaults to [ErrorTone.friendly].
///
/// [targetLanguage] — the last-used translation target language name (e.g.,
/// 'Spanish'). Persisted across app restarts per TRNS-05.
///
/// [recentTargetLanguages] — rolling list of up to 3 recently used target
/// language names (most-recent first). Used for quick-access in the language
/// picker.
class AppSettings {
  final Locale? localeOverride;
  final ErrorTone errorTone;
  final String targetLanguage;
  final List<String> recentTargetLanguages;

  const AppSettings({
    this.localeOverride,
    this.errorTone = ErrorTone.friendly,
    this.targetLanguage = 'Spanish',
    this.recentTargetLanguages = const [],
  });

  /// Returns a new [AppSettings] with the given fields replaced.
  ///
  /// To clear the locale override (revert to device locale), pass
  /// `localeOverride: () => null`.
  AppSettings copyWith({
    Locale? Function()? localeOverride,
    ErrorTone? errorTone,
    String? targetLanguage,
    List<String>? recentTargetLanguages,
  }) {
    return AppSettings(
      localeOverride:
          localeOverride != null ? localeOverride() : this.localeOverride,
      errorTone: errorTone ?? this.errorTone,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      recentTargetLanguages:
          recentTargetLanguages ?? this.recentTargetLanguages,
    );
  }
}

/// Riverpod AsyncNotifier that persists locale override and error tone
/// via [SharedPreferencesWithCache].
///
/// Kept alive so settings are never disposed while the app is running,
/// even when no widgets are actively listening.
///
/// Usage:
/// ```dart
/// // Read settings
/// final settings = await ref.watch(settingsProvider.future);
///
/// // Mutations (call from notifier or gesture handlers)
/// ref.read(settingsProvider.notifier).setLocale(Locale('ar'));
/// ref.read(settingsProvider.notifier).setErrorTone(ErrorTone.direct);
/// ```
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  late SharedPreferencesWithCache _prefs;

  static const _kLocaleKey = 'locale';
  static const _kErrorToneKey = 'error_tone';
  static const _kTargetLanguageKey = 'target_language';
  static const _kRecentTargetLanguagesKey = 'recent_target_languages';

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );

    final localeCode = _prefs.getString(_kLocaleKey);
    final toneStr = _prefs.getString(_kErrorToneKey);
    final targetLang = _prefs.getString(_kTargetLanguageKey);
    final recentLangs =
        _prefs.getStringList(_kRecentTargetLanguagesKey) ?? [];

    return AppSettings(
      localeOverride: localeCode != null ? Locale(localeCode) : null,
      errorTone:
          toneStr == 'direct' ? ErrorTone.direct : ErrorTone.friendly,
      targetLanguage: targetLang ?? 'Spanish',
      recentTargetLanguages: recentLangs,
    );
  }

  /// Sets the locale override and persists it to SharedPreferences.
  ///
  /// Pass [null] to remove the override and revert to the device locale.
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_kLocaleKey);
    } else {
      await _prefs.setString(_kLocaleKey, locale.languageCode);
    }

    final current = state.value ?? const AppSettings();
    state = AsyncValue.data(current.copyWith(localeOverride: () => locale));
  }

  /// Sets the error tone and persists it to SharedPreferences.
  Future<void> setErrorTone(ErrorTone tone) async {
    await _prefs.setString(
      _kErrorToneKey,
      tone == ErrorTone.direct ? 'direct' : 'friendly',
    );

    final current = state.value ?? const AppSettings();
    state = AsyncValue.data(current.copyWith(errorTone: tone));
  }

  /// Sets the target translation language and persists it to SharedPreferences.
  ///
  /// Also updates the rolling [AppSettings.recentTargetLanguages] list
  /// (max 3, most-recent first, de-duplicated).
  Future<void> setTargetLanguage(String language) async {
    await _prefs.setString(_kTargetLanguageKey, language);

    // Update rolling recent list: prepend, remove duplicates, cap at 3.
    final current = state.value ?? const AppSettings();
    final updated = [language, ...current.recentTargetLanguages]
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList()
      ..take(3);
    final recent = updated.length > 3 ? updated.sublist(0, 3) : updated;
    await _prefs.setStringList(_kRecentTargetLanguagesKey, recent);

    state = AsyncValue.data(
      current.copyWith(
        targetLanguage: language,
        recentTargetLanguages: recent,
      ),
    );
  }
}
