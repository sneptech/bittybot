import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_provider.dart';
import 'widgets/app_startup_widget.dart';
import 'widgets/main_shell.dart';

/// Root of the BittyBot widget tree.
///
/// Responsibilities:
/// - Provides the dark green [ThemeData] via [buildDarkTheme].
/// - Forces [ThemeMode.dark] — no light theme variant.
/// - Wires [AppLocalizations] delegates and supported locales.
/// - Reads [settingsProvider] to apply the user's locale override (null = device default).
/// - Hosts [AppStartupWidget] as the entry-point screen, which gates the UI
///   behind the startup initialisation sequence.
class BittyBotApp extends ConsumerWidget {
  const BittyBotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read settings without watching startup dependencies — we only want the
    // locale override, and [settingsProvider] is keepAlive so it is always
    // available after first load. Use .value (not .valueOrNull — see STATE.md)
    // to access the current data nullable on AsyncValue in Riverpod 3.1.0.
    final settingsAsync = ref.watch(settingsProvider);
    final localeOverride = settingsAsync.value?.localeOverride;

    return MaterialApp(
      // -----------------------------------------------------------------------
      // Theme
      // -----------------------------------------------------------------------
      theme: buildDarkTheme(),
      // Force dark mode — BittyBot is dark-only; no light theme variant.
      themeMode: ThemeMode.dark,

      // -----------------------------------------------------------------------
      // Localisation
      // -----------------------------------------------------------------------
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // null = follow device locale; non-null overrides the device default.
      locale: localeOverride,

      // Locale resolution: exact match → language-code match → English fallback.
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) return const Locale('en');

        // 1. Exact match (language + country)
        for (final supported in supportedLocales) {
          if (supported == deviceLocale) return supported;
        }

        // 2. Language-code match (ignore country/script)
        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }

        // 3. English fallback
        return const Locale('en');
      },

      // -----------------------------------------------------------------------
      // Home
      // -----------------------------------------------------------------------
      home: AppStartupWidget(
        onLoaded: (_) => const MainShell(),
      ),
    );
  }
}
