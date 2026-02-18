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
class AppSettings {
  final Locale? localeOverride;
  final ErrorTone errorTone;

  const AppSettings({
    this.localeOverride,
    this.errorTone = ErrorTone.friendly,
  });

  /// Returns a new [AppSettings] with the given fields replaced.
  ///
  /// To clear the locale override (revert to device locale), pass
  /// `localeOverride: () => null`.
  AppSettings copyWith({
    Locale? Function()? localeOverride,
    ErrorTone? errorTone,
  }) {
    return AppSettings(
      localeOverride:
          localeOverride != null ? localeOverride() : this.localeOverride,
      errorTone: errorTone ?? this.errorTone,
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

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );

    final localeCode = _prefs.getString(_kLocaleKey);
    final toneStr = _prefs.getString(_kErrorToneKey);

    return AppSettings(
      localeOverride: localeCode != null ? Locale(localeCode) : null,
      errorTone:
          toneStr == 'direct' ? ErrorTone.direct : ErrorTone.friendly,
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
}
