# Phase 3: App Foundation and Design System - Research

**Researched:** 2026-02-19
**Domain:** Flutter theming, localization, typography, accessibility, Riverpod state management
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Visual identity & palette
- Background: very dark green (faded, near-black green) — inspired by Aya demo, not an exact replica
- Input fields and user message bubbles: regular forest green
- Primary buttons and interactive accents: forest green
- Small highlights, borders, logo accents: lime/yellow-green
- Text: white throughout
- Surfaces must respect WCAG accessibility contrast ratios (white text on forest green inputs needs careful checking)
- Reference: Aya demo screenshot — dark green background, lime border, forest green input field, white text

#### Typography & script support
- Primary font: Lato (Google Fonts)
- Fallback: system fonts for scripts Lato doesn't cover (Arabic, Thai, CJK, etc.)
- Full RTL layout mirroring for Arabic, Hebrew, and other RTL locales (navigation, buttons, layout all flip)
- Type scale: understated and clean — content-first, minimal headings (ChatGPT/Claude mobile style)
- Respect system font size preferences fully (dynamic type on iOS, font scale on Android) — no cap
- Body text minimum 16sp baseline

#### Localization scope
- Device locale auto-detection as default, with in-app language override in settings
- Fully localized date/time, number formatting following user's locale conventions
- Error message tone toggle: friendly & casual by default ("Hmm, something went wrong"), clear & direct as a setting option ("Translation failed. Check your input.")

#### Error message design
- Dedicated loading/onboarding screen when model is not yet loaded (not the main UI with disabled inputs)
- Error message tone: friendly & casual by default, with a settings toggle for clear & direct mode

### Claude's Discretion
- Number of UI languages to translate into (practical subset vs. all 70+)
- Fallback strategy for partially translated languages
- Error presentation style (inline banners vs. snackbars vs. context-dependent)
- Partial output handling on inference failure (show vs. discard)
- Exact color hex values within the described palette
- Loading skeleton and animation design
- Exact spacing and layout metrics

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UIUX-01 | Dark theme with Cohere-inspired green palette (forest green borders, lime/yellow-green accents on dark background) | ColorScheme manual construction; ThemeExtension for brand-specific colors; recommended hex values documented in Architecture Patterns |
| UIUX-02 | Clean, minimal visual style inspired by Tiny Aya demo aesthetic | Material 3 defaults (padding, elevation, shape) align well; Typography section covers minimal type scale |
| UIUX-03 | App UI language matches device locale | flutter_localizations + intl + ARB files; localeResolutionCallback for fallback; Riverpod locale notifier for in-app override |
| UIUX-04 | Tap targets are minimum 48x48dp (Android) / 44pt (iOS) | MaterialTapTargetSize.padded is the Flutter default on mobile; documented as automatic for Material widgets; custom targets need MinimumInteractionZone wrapper |
| UIUX-05 | Body text is minimum 16sp for legibility in travel scenarios | TextTheme bodyMedium override; no textScaler cap; verified against Flutter TextTheme defaults (which are 14sp — must override) |
| UIUX-06 | Clear error messages when model is not loaded, input is too long, or inference fails | AppStartupWidget pattern for model-not-loaded state; ErrorTone enum + Riverpod notifier for tone toggle; context-specific error strings in ARB files |
</phase_requirements>

## Summary

Phase 3 builds the complete Flutter app foundation from scratch: the Flutter project itself does not yet exist (no `pubspec.yaml`, no `lib/` directory — the worktree only has `.planning/` and `scripts/`). The work divides into five areas: (1) Flutter project bootstrap, (2) color palette and Material 3 theming, (3) typography with Google Fonts Lato and script fallbacks, (4) localization with ARB files and RTL support, and (5) settings persistence (locale override, error tone toggle) via Riverpod and SharedPreferences.

The critical accessibility risk is white-on-forest-green contrast. Forest green (#228B22) yields approximately 3.5:1 with white text — below the WCAG AA 4.5:1 threshold for normal text. The palette requires either a darker forest green for backgrounds or a reduced opacity approach so input field backgrounds don't violate contrast requirements. Large text (18sp+ bold, or 24sp+) needs only 3:1, which forest green can clear. Exact hex values must be validated with a contrast tool before finalizing.

The stack is well-understood and stable: Flutter stable (3.29+), Riverpod 3.x (with code-gen), flutter_localizations (SDK-bundled), google_fonts 8.x (with asset-bundling for offline use), and shared_preferences 2.5.x (using the new SharedPreferencesWithCache API). Material 3 is now the default in Flutter, which removes the `useMaterial3: true` flag requirement and gives the project a solid baseline to override.

**Primary recommendation:** Bootstrap the Flutter project first (`flutter create`), then layer the theme, fonts, and localization. Use `ColorScheme` with fully custom manual color assignments (not `fromSeed`) to precisely control the non-tonal green palette. Validate every surface/text pairing against WCAG AA before coding is complete.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_localizations | SDK-bundled | Material/Cupertino widget localization delegates | Official Flutter SDK package; zero separate installation |
| intl | `any` (matches SDK) | Date/time/number formatting; ARB message codegen | Required by flutter_localizations; same package |
| flutter_riverpod | `^3.2.1` | State management (theme mode, locale, error tone, app startup) | Project-established choice; Riverpod 3.x released Sep 2025 |
| riverpod_annotation | `^4.0.2` | Code-gen annotation for `@riverpod` providers | Companion to flutter_riverpod 3.x |
| riverpod_generator | `^4.0.3` | Build-time code generation for providers | Dev tool for riverpod_annotation |
| build_runner | `^2.10.5` | Drives drift_dev and riverpod_generator | Standard Dart codegen runner |
| google_fonts | `^8.0.2` | Lato font; textTheme integration | Official dart.dev publisher; 8.x released Feb 2026 |
| shared_preferences | `^2.5.4` | Persist locale override and error tone setting | Standard Flutter persistence for simple key-value settings |
| drift | `^2.31.0` | SQLite ORM (project-standard per CLAUDE.md) | Required per project spec; code-gen driven |
| drift_flutter | `^0.2.8` | Flutter-specific drift connection helper | Companion to drift 2.31.x |
| drift_dev | `^2.31.0` | Drift code generator | Dev dependency |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| path_provider | `^2.1.5` | File system paths for Drift database | Required by drift_flutter for DB location |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ColorScheme` manual | `ColorScheme.fromSeed` | `fromSeed` produces tonal palettes that conflict with the non-tonal flat green aesthetic; manual construction required |
| `SharedPreferencesWithCache` | `SharedPreferencesAsync` | Async variant has no cache; fine for infrequent reads but slower; WithCache is better for theme/locale read on every rebuild |
| `flutter_localizations` (SDK) | `easy_localization` package | easy_localization adds hot-reload support but is a third-party package; SDK-native approach is simpler and offline-safe |
| `ThemeExtension` custom colors | Separate `AppColors` const file | Both work; ThemeExtension integrates with `Theme.of(context)` and supports `lerp` for animation; const file is simpler but not theme-aware |

**Installation:**

```bash
flutter create --org com.yourorg --platforms=android,ios bittybot
# Then add to pubspec.yaml:
flutter pub add flutter_riverpod riverpod_annotation google_fonts shared_preferences drift drift_flutter path_provider
flutter pub add --dev riverpod_generator build_runner drift_dev
# In pubspec.yaml flutter section:
#   generate: true
# Create l10n.yaml in project root
```

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── main.dart                    # ProviderScope + AppStartupWidget entry
├── app.dart                     # MaterialApp with theme/locale watching
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Const color palette (hex values)
│   │   ├── app_theme.dart       # ThemeData factory (dark theme builder)
│   │   └── app_text_theme.dart  # TextTheme overrides with Lato
│   ├── l10n/                    # ARB files + generated AppLocalizations
│   │   ├── app_en.arb
│   │   ├── app_es.arb
│   │   ├── app_fr.arb
│   │   ├── app_ar.arb
│   │   ├── app_zh.arb
│   │   ├── app_ja.arb
│   │   └── app_localizations.dart  # (generated by flutter gen-l10n)
│   ├── error/
│   │   ├── error_tone.dart      # ErrorTone enum (friendly | direct)
│   │   └── error_messages.dart  # Tone-aware message resolver
│   └── db/
│       └── app_database.dart    # Drift database definition
├── features/
│   └── settings/
│       ├── settings_provider.dart  # locale + error tone Notifier
│       └── settings_screen.dart    # (stub for future settings UI)
└── widgets/
    └── app_startup_widget.dart  # Loading/error gate before main UI
```

### Pattern 1: Dark Green ColorScheme (Manual Construction)

**What:** Build `ColorScheme` with explicit values for every role instead of using `fromSeed`. This is required because the project palette is a non-tonal, flat-green aesthetic that `fromSeed` would distort into a Material tonal palette.

**When to use:** Any time the design system departs from Material tonal palettes.

**Recommended hex values** (verify contrast before finalizing):

| Role | Hex | Description |
|------|-----|-------------|
| `surface` | `#0A1A0A` | Near-black dark green background |
| `surfaceContainer` | `#0F2B0F` | Slightly lighter dark green (cards) |
| `primary` | `#2D6A2D` | Forest green (buttons, accents) |
| `onPrimary` | `#FFFFFF` | White text on forest green |
| `primaryContainer` | `#1B4D1B` | Darker forest green (input fields) |
| `onPrimaryContainer` | `#FFFFFF` | White text on input fields |
| `secondary` | `#8BC34A` | Lime/yellow-green (borders, highlights) |
| `onSecondary` | `#000000` | Dark text on lime (if lime used as bg) |
| `onSurface` | `#FFFFFF` | Primary text — white on dark bg |
| `onSurfaceVariant` | `#B0D0B0` | Muted text, icons |
| `outline` | `#8BC34A` | Lime borders (matches secondary) |
| `error` | `#CF6679` | Error state |
| `onError` | `#FFFFFF` | Text on error |

**CRITICAL — WCAG contrast check required:** The proposed `#FFFFFF` on `#2D6A2D` (forest green primary) needs verification. Forest green around `#228B22` gives ~3.5:1 contrast with white — below WCAG AA (4.5:1). A darker forest green like `#1B5E1B` (~4.6:1) or `#1A5C1A` should clear the threshold. Verify every surface/text pair before committing.

```dart
// Source: https://api.flutter.dev/flutter/material/ColorScheme-class.html
// lib/core/theme/app_colors.dart
abstract final class AppColors {
  static const nearBlackGreen = Color(0xFF0A1A0A);
  static const forestGreen = Color(0xFF1B5E1B);    // validate contrast
  static const forestGreenDark = Color(0xFF0F3D0F); // input bg
  static const limeGreen = Color(0xFF8BC34A);
  static const white = Color(0xFFFFFFFF);
  static const mutedGreen = Color(0xFFB0D0B0);
}

// lib/core/theme/app_theme.dart
ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      surface: AppColors.nearBlackGreen,
      onSurface: AppColors.white,
      primary: AppColors.forestGreen,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.forestGreenDark,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.limeGreen,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.forestGreenDark,
      onSecondaryContainer: AppColors.limeGreen,
      error: const Color(0xFFCF6679),
      onError: AppColors.white,
    ),
    textTheme: _buildTextTheme(),
    materialTapTargetSize: MaterialTapTargetSize.padded, // explicit, even if default
  );
}
```

### Pattern 2: Lato Text Theme with Script Fallbacks

**What:** Apply Lato as the base font across all TextTheme roles, with `fontFamilyFallback` pointing to system fonts for scripts Lato doesn't cover.

**Why:** `GoogleFonts.latoTextTheme()` replaces all roles at once. The `fontFamilyFallback` property in `TextStyle` specifies an ordered list of fallback families — Flutter's text engine tries each in order before falling back to the platform default.

**Offline requirement:** The app is offline-first. Lato must be bundled as assets, not fetched at runtime. Set `GoogleFonts.config.allowRuntimeFetching = false` and declare the `google_fonts/` asset folder.

```dart
// Source: https://pub.dev/packages/google_fonts (v8.0.2)
// lib/core/theme/app_text_theme.dart

TextTheme _buildTextTheme() {
  // GoogleFonts.latoTextTheme applies Lato to all roles.
  // fontFamilyFallback is set per-style for non-Latin scripts.
  final base = GoogleFonts.latoTextTheme();

  // Override bodyMedium to enforce 16sp minimum (default is 14sp)
  return base.copyWith(
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 18,
      fontFamilyFallback: _scriptFallbacks,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 16,                          // UIUX-05: minimum 16sp
      fontFamilyFallback: _scriptFallbacks,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 14,
      fontFamilyFallback: _scriptFallbacks,
    ),
  );
}

// System fonts that cover Arabic, Thai, CJK, etc.
// Flutter falls back to platform default after this list.
const _scriptFallbacks = <String>[
  'Noto Sans Arabic',    // Android ships with this; iOS uses system Arabic
  'Noto Sans Thai',
  'Noto Sans CJK SC',   // Simplified Chinese
  'Noto Sans CJK TC',   // Traditional Chinese
  'Noto Sans JP',        // Japanese
  'Noto Sans KR',        // Korean
];
```

**Note on `_scriptFallbacks` on iOS:** iOS uses system fonts (e.g. `.SFUI-Text`) which have broad Unicode coverage including Arabic. The named Noto fonts may not be present on iOS; Flutter's engine will skip names it doesn't find and fall through to the platform default, which is correct behavior. No action needed on iOS; the fallback list is advisory.

### Pattern 3: Localization Setup (ARB + Code-gen)

**What:** flutter_localizations (SDK-bundled) with `generate: true` in pubspec and `l10n.yaml` configuration. Code-gen produces `AppLocalizations` from `.arb` files.

**Recommended initial language set** (Claude's Discretion — justified below):

| Code | Language | Reason |
|------|----------|--------|
| `en` | English | Template/default |
| `es` | Spanish | ~500M speakers; high traveler volume |
| `fr` | French | Wide geographic coverage |
| `ar` | Arabic | RTL test case; 400M speakers |
| `zh` | Chinese (Simplified) | Largest language by speakers |
| `ja` | Japanese | Major travel market |
| `pt` | Portuguese | Brazil + Portugal; large speaker base |
| `de` | German | Major European market |
| `ko` | Korean | Active travel market |
| `hi` | Hindi | Rapidly growing mobile market |

Rationale: 10 languages covers the majority of global travelers. ARB files are plain JSON; adding more later is trivial — no architecture changes needed. Starting too broad slows initial delivery with translation overhead.

**Fallback strategy** (Claude's Discretion): Use `localeResolutionCallback` in MaterialApp to match language code only (ignore country/script variant) if exact locale not found, then fall back to English. This means `zh_TW` gets `zh` strings (Simplified), which is imperfect but workable for v1.

```dart
// Source: https://docs.flutter.dev/ui/internationalization
// pubspec.yaml additions:
// dependencies:
//   flutter_localizations:
//     sdk: flutter
//   intl: any
// flutter:
//   generate: true

// l10n.yaml (project root):
// arb-dir: lib/core/l10n
// template-arb-file: app_en.arb
// output-localization-file: app_localizations.dart
// synthetic-package: false

// lib/app.dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  localeResolutionCallback: (locale, supported) {
    if (locale == null) return const Locale('en');
    // Exact match
    if (supported.contains(locale)) return locale;
    // Language code match
    final languageMatch = supported
        .where((s) => s.languageCode == locale.languageCode)
        .firstOrNull;
    return languageMatch ?? const Locale('en');
  },
  locale: ref.watch(settingsProvider).locale, // nullable; null = device default
)
```

### Pattern 4: Settings Persistence with Riverpod + SharedPreferences

**What:** A single `SettingsNotifier` (Riverpod 3.x `@Riverpod` + `Notifier`) holds `AppSettings` (locale override + error tone). It reads from `SharedPreferencesWithCache` on init and writes back on every mutation.

**Why SharedPreferencesWithCache** (not Async): Settings are read every time MaterialApp rebuilds (locale, theme). The cache avoids async overhead on reads; mutations are the only async operations.

```dart
// lib/features/settings/settings_provider.dart

enum ErrorTone { friendly, direct }

class AppSettings {
  final Locale? localeOverride;  // null = follow device
  final ErrorTone errorTone;
  const AppSettings({this.localeOverride, this.errorTone = ErrorTone.friendly});
}

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  late SharedPreferencesWithCache _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    final localeCode = _prefs.getString('locale');
    final toneStr = _prefs.getString('error_tone');
    return AppSettings(
      localeOverride: localeCode != null ? Locale(localeCode) : null,
      errorTone: toneStr == 'direct' ? ErrorTone.direct : ErrorTone.friendly,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    final current = requireValue;
    if (locale == null) {
      await _prefs.remove('locale');
    } else {
      await _prefs.setString('locale', locale.languageCode);
    }
    state = AsyncValue.data(current.copyWith(localeOverride: locale));
  }

  Future<void> setErrorTone(ErrorTone tone) async {
    final current = requireValue;
    await _prefs.setString('error_tone', tone.name);
    state = AsyncValue.data(current.copyWith(errorTone: tone));
  }
}
```

### Pattern 5: App Startup / Model-Not-Loaded Screen

**What:** An `AppStartupWidget` gates the main UI behind an async initialization check. If the model is not yet downloaded/loaded, users see a dedicated loading/onboarding screen — not the main UI with disabled inputs.

**Note:** Phase 3 does not implement actual model loading (that is Phase 4). Phase 3 must build the *screen itself* and the *gate mechanism*. The `modelReadyProvider` will be a stub in Phase 3 (always returns `false`) and connected to real inference in Phase 4.

```dart
// Source: https://codewithandrea.com/articles/robust-app-initialization-riverpod/
// lib/widgets/app_startup_widget.dart

@Riverpod(keepAlive: true)
Future<void> appStartup(AppStartupRef ref) async {
  // Eagerly initialize settings (locale, error tone)
  await ref.watch(settingsProvider.future);
  // In Phase 4: await ref.watch(modelReadyProvider.future);
}

class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({super.key, required this.onLoaded});
  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(appStartupProvider).when(
      loading: () => const ModelLoadingScreen(),
      error: (e, st) => AppStartupErrorScreen(
        onRetry: () => ref.invalidate(appStartupProvider),
      ),
      data: (_) => onLoaded(context),
    );
  }
}
```

### Pattern 6: Error Message Tone Resolution

**What:** A helper that returns the correct string based on `ErrorTone`. ARB files contain both variants for each error key.

```dart
// lib/core/error/error_messages.dart
// ARB keys use suffix _friendly and _direct:
// "modelNotLoadedFriendly": "Hang on — the model is still warming up..."
// "modelNotLoadedDirect": "Model not loaded. Please wait for setup to complete."

String resolveError(BuildContext context, String baseKey, ErrorTone tone) {
  final l10n = AppLocalizations.of(context)!;
  final key = tone == ErrorTone.direct ? '${baseKey}Direct' : '${baseKey}Friendly';
  // ARB accessor via reflection is not possible; use switch or map
  // Implementation detail: define a method per error key
  return switch (baseKey) {
    'modelNotLoaded' => tone == ErrorTone.direct
        ? l10n.modelNotLoadedDirect
        : l10n.modelNotLoadedFriendly,
    'inputTooLong' => tone == ErrorTone.direct
        ? l10n.inputTooLongDirect
        : l10n.inputTooLongFriendly,
    'inferenceFailed' => tone == ErrorTone.direct
        ? l10n.inferenceFailedDirect
        : l10n.inferenceFailedFriendly,
    _ => l10n.genericErrorFriendly,
  };
}
```

**Error presentation style** (Claude's Discretion — recommendation): Use context-dependent approach:
- **Model not loaded / app startup errors:** Full-screen dedicated widget (not a snackbar)
- **Input too long:** Inline validation text below the input field (immediate, non-blocking)
- **Inference failures:** SnackBar with a "Retry" action (transient, dismissible)

This matches patterns from ChatGPT/Claude mobile (the structural reference).

### Anti-Patterns to Avoid

- **`useMaterial3: false`**: Material 3 is now the default in Flutter 3.16+. Opting out defeats the entire theme system.
- **`fromSeed` with green seed and overrides**: The tonal palette algorithm will fight the flat-green intent. Use the full manual `ColorScheme` constructor.
- **`textScaleFactor` cap**: The user decision says no cap on system font scale. Never set `MediaQuery.withClampedTextScaling` or `textScaleFactor: 1.0` overrides.
- **Hardcoded English strings in widgets**: Every user-visible string must go through `AppLocalizations`. Even error messages.
- **Fetching fonts at runtime**: The app is offline. `GoogleFonts.config.allowRuntimeFetching = false` must be set in `main()` before `runApp`.
- **`StateNotifierProvider` in Riverpod 3.x**: Moved to `flutter_riverpod/legacy.dart`. Use `Notifier` or `AsyncNotifier` with code-gen.
- **`SnackBar` for blocking errors**: The model-not-loaded state is not transient. It requires a full-screen gate (Pattern 5), not a dismissible snackbar.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font loading | Manual HTTP font fetch + caching | `google_fonts` 8.x with asset bundling | Asset bundling is zero-runtime-cost; correct fallback order handled by package |
| Localization | Custom JSON translation loader | `flutter_localizations` + `gen-l10n` | Type-safe generated accessors; date/number ICU formatting; RTL direction via GlobalWidgetsLocalizations |
| Settings persistence | Custom file-based serialization | `shared_preferences` 2.5.x (WithCache) | Handles platform NSUserDefaults/SharedPrefs; cache layer for sync reads |
| RTL mirroring | `if (isRtl) padding = EdgeInsets.only(right: ...)` | `EdgeInsetsDirectional`, `AlignmentDirectional`, `GlobalWidgetsLocalizations.delegate` | MaterialApp automatically flips layout when locale is RTL; directional widgets respect it |
| Color contrast checks | Eyeballing colors | WebAIM contrast checker before coding | WCAG math is not intuitive; forest green at full brightness fails AA for normal-sized text |
| App initialization gate | `bool isLoaded` flag in widget state | Riverpod `appStartupProvider` + `AppStartupWidget` | Handles loading/error/retry states cleanly; composable with routing |

**Key insight:** RTL layout mirroring is almost entirely free when `GlobalWidgetsLocalizations.delegate` is in `localizationsDelegates` and directional (not absolute) widgets are used from the start. Retrofitting RTL onto an LTR-assumed layout is painful; starting with `EdgeInsetsDirectional` costs nothing.

## Common Pitfalls

### Pitfall 1: White Text on Forest Green Fails WCAG AA
**What goes wrong:** `#FFFFFF` on `#228B22` (standard forest green) gives approximately 3.5:1 contrast ratio — below the 4.5:1 WCAG AA threshold for normal-sized text.
**Why it happens:** Forest green is a mid-range luminance color, not dark enough for white text at normal sizes.
**How to avoid:** Use a darker green. `#1B5E20` (Material green[900]) yields ~5.5:1 with white. For input fields (larger text), the 3:1 large text threshold may be acceptable — verify per surface.
**Warning signs:** Any forest green lighter than approximately `#1A601A` will fail for normal text.

### Pitfall 2: Riverpod 3.x Breaking Changes from 2.x
**What goes wrong:** Code written against Riverpod 2.x APIs fails to compile or behaves differently.
**Why it happens:** Riverpod 3.0 (Sep 2025) moved `StateNotifierProvider`, `StateProvider` to `legacy.dart`; removed all `Ref` subclasses; providers now rebuilt on every invalidation; `FutureProvider/StreamProvider` no longer support `null` values.
**How to avoid:** Use code-gen (`@riverpod` annotation) which generates correct 3.x API. Never use `StateNotifierProvider`. Use `Notifier`/`AsyncNotifier` with `@Riverpod(keepAlive: true)` for settings.
**Warning signs:** `StateNotifierProvider` import from `flutter_riverpod/flutter_riverpod.dart` will fail with import error.

### Pitfall 3: GoogleFonts Runtime Fetching in Offline App
**What goes wrong:** App throws network errors or shows wrong font on first launch when offline.
**Why it happens:** `google_fonts` default behavior attempts HTTP fetch from fonts.googleapis.com before checking assets.
**How to avoid:** In `main()`, set `GoogleFonts.config.allowRuntimeFetching = false` before `runApp`. Bundle Lato font files under `assets/google_fonts/` and declare in `pubspec.yaml`.
**Warning signs:** Works on emulator with network; fails on physical device in airplane mode.

### Pitfall 4: `synthetic-package: true` (l10n default) in Newer Flutter
**What goes wrong:** Generated `app_localizations.dart` goes into a synthetic package, import path is non-obvious, and the file is not committed to source.
**Why it happens:** Flutter changed the default `synthetic-package` setting across versions; in newer versions it defaults to generating in source.
**How to avoid:** Explicitly set `synthetic-package: false` in `l10n.yaml`. Generated file lands in `lib/core/l10n/` and is importable as a regular file. Commit the generated file.
**Warning signs:** `import 'package:flutter_gen/gen_l10n/app_localizations.dart'` not resolving.

### Pitfall 5: flutter_localizations Breaking Change (generate-i10n-source)
**What goes wrong:** Older tutorials show importing from a synthetic package (`flutter_gen`). Recent Flutter versions generate the localization files into source by default.
**Why it happens:** Flutter changed defaults around 3.27-3.29. [Official doc](https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source) covers this.
**How to avoid:** Always check Flutter version when following l10n tutorials. Use `synthetic-package: false` explicitly and import from the source path.
**Warning signs:** Build fails with "flutter_gen package not found."

### Pitfall 6: Missing Drift Setup Causes Phase 4 Bloat
**What goes wrong:** Phase 3 skips Drift database setup (since no chat history yet), then Phase 4 must set up Drift while implementing inference — increasing cognitive load during a complex phase.
**Why it happens:** Drift is listed as a project-standard DB (CLAUDE.md) but Phase 3 has no data requirements.
**How to avoid:** Create the Drift `AppDatabase` with zero tables in Phase 3. Add tables in later phases. The codegen infrastructure (build_runner, drift_dev) is already in place.
**Warning signs:** Phase 4 PRs include both inference logic AND database migration — unrelated changes in one commit.

## Code Examples

Verified patterns from official sources:

### pubspec.yaml (Complete for Phase 3)

```yaml
# Source: https://riverpod.dev/docs/introduction/getting_started
#         https://drift.simonbinder.eu/setup/
#         https://pub.dev/packages/google_fonts
#         https://docs.flutter.dev/ui/internationalization
name: bittybot
description: Fully offline multilingual chat and translation app.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^4.0.2
  google_fonts: ^8.0.2
  shared_preferences: ^2.5.4
  drift: ^2.31.0
  drift_flutter: ^0.2.8
  path_provider: ^2.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^4.0.3
  build_runner: ^2.10.5
  drift_dev: ^2.31.0

flutter:
  generate: true   # Enables flutter gen-l10n
  assets:
    - assets/google_fonts/   # Bundled Lato font files (offline)
```

### l10n.yaml (Project Root)

```yaml
# Source: https://docs.flutter.dev/ui/internationalization
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
nullable-getter: false
```

### Minimal ARB Template (app_en.arb)

```json
{
  "@@locale": "en",
  "appName": "BittyBot",
  "@appName": { "description": "Application name" },
  "modelNotLoadedFriendly": "Hang on — the model is still warming up. This only happens once!",
  "@modelNotLoadedFriendly": { "description": "Model loading; friendly tone" },
  "modelNotLoadedDirect": "Model not loaded. Please wait for setup to complete.",
  "@modelNotLoadedDirect": { "description": "Model loading; direct tone" },
  "inputTooLongFriendly": "Oops — that message is a bit too long. Try shortening it a little.",
  "@inputTooLongFriendly": { "description": "Input too long; friendly tone" },
  "inputTooLongDirect": "Input exceeds maximum length. Shorten your message and try again.",
  "@inputTooLongDirect": { "description": "Input too long; direct tone" },
  "inferenceFailedFriendly": "Hmm, something went wrong. Tap to retry.",
  "@inferenceFailedFriendly": { "description": "Inference failure; friendly tone" },
  "inferenceFailedDirect": "Translation failed. Please retry.",
  "@inferenceFailedDirect": { "description": "Inference failure; direct tone" },
  "genericErrorFriendly": "Something unexpected happened.",
  "@genericErrorFriendly": { "description": "Generic fallback error" }
}
```

### main.dart Entry Point

```dart
// Source: https://codewithandrea.com/articles/robust-app-initialization-riverpod/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // CRITICAL: disable runtime font fetching for offline app
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    const ProviderScope(
      child: BittyBotApp(),
    ),
  );
}
```

### MaterialApp with Theme and Locale Watching

```dart
// lib/app.dart
class BittyBotApp extends ConsumerWidget {
  const BittyBotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final locale = settingsAsync.valueOrNull?.localeOverride; // null = device default

    return MaterialApp(
      title: 'BittyBot',
      theme: buildDarkTheme(),         // Only dark theme
      themeMode: ThemeMode.dark,       // Force dark; no light mode
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,                  // null follows device; set for override
      localeResolutionCallback: _resolveLocale,
      home: AppStartupWidget(
        onLoaded: (_) => const MainShell(),
      ),
    );
  }

  Locale? _resolveLocale(Locale? locale, Iterable<Locale> supported) {
    if (locale == null) return const Locale('en');
    if (supported.contains(locale)) return locale;
    final match = supported.where((s) => s.languageCode == locale.languageCode).firstOrNull;
    return match ?? const Locale('en');
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `useMaterial3: true` flag | Material 3 is default; flag no longer needed | Flutter 3.16 | Remove from all new projects |
| `StateNotifierProvider` | `Notifier` / `AsyncNotifier` with `@riverpod` | Riverpod 3.0 (Sep 2025) | Old provider moved to `legacy.dart`; breaks on main import |
| `SharedPreferences.getInstance()` | `SharedPreferencesWithCache.create()` | shared_preferences 2.3.0 | Old API deprecated; new API has sync reads after init |
| `synthetic-package: true` (l10n) | Generated to source (`synthetic-package: false`) | Flutter 3.27+ | Import path changed; tutorials using `flutter_gen` are outdated |
| `Colors.green` tonal palette in `fromSeed` | Manual `ColorScheme` constructor | Always available; now required for non-tonal designs | `fromSeed` cannot produce flat, non-tonal green palettes |
| `textScaleFactor` | `MediaQuery.textScalerOf` / `TextScaler` | Flutter 3.12+ | `textScaleFactor` property is deprecated on `MediaQueryData` |

**Deprecated/outdated:**
- `StateNotifierProvider` and `StateProvider` (Riverpod): moved to `legacy.dart` in Riverpod 3.0
- `SharedPreferences.getInstance()`: will be deprecated; use `SharedPreferencesWithCache`
- `flutter_gen` synthetic package import path: use source import with `synthetic-package: false`

## Open Questions

1. **Exact hex values for forest green that clear WCAG AA**
   - What we know: Standard forest green (#228B22) gives ~3.5:1 with white; fails AA for normal text
   - What's unclear: The exact shade that feels "forest green" (not too dark) while clearing 4.5:1
   - Recommendation: Use #1B5E20 (Material green[900]) as the starting point; verify with WebAIM checker before coding; add WCAG check to the verification plan

2. **Riverpod 3.2.1 requirement for Flutter stable channel**
   - What we know: Riverpod docs note that 3.1.0+ may require Flutter beta channel due to `json_serializable` dependency conflicts
   - What's unclear: Whether the stable channel blocker is resolved in 3.2.1
   - Recommendation: Test `flutter pub get` on Flutter stable channel after project bootstrap; if blocked, pin to `flutter_riverpod: ^3.1.0`

3. **iOS system font coverage for Arabic**
   - What we know: iOS ships `.SFUI-Text` with wide Unicode coverage; Noto fonts in `fontFamilyFallback` are not available on iOS
   - What's unclear: Whether iOS system Arabic rendering is adequate without explicit Arabic font bundling
   - Recommendation: Test Arabic text rendering on iOS simulator (even without Metal GPU — UI-only testing works); if glyphs are missing, bundle `NotoNaskhArabic` as an asset

## Sources

### Primary (HIGH confidence)
- Flutter official docs (docs.flutter.dev/ui/internationalization) — localization setup, l10n.yaml, ARB format, MaterialApp delegates
- Flutter API reference (api.flutter.dev/flutter/material/ColorScheme-class.html) — ColorScheme properties and constructor
- Flutter API reference (api.flutter.dev/flutter/material/ThemeData-class.html) — ThemeData, materialTapTargetSize
- Riverpod docs (riverpod.dev/docs/introduction/getting_started) — v3.2.1 package versions, ProviderScope setup
- Riverpod docs (riverpod.dev/docs/whats_new) — Riverpod 3.0 breaking changes
- pub.dev/packages/google_fonts — version 8.0.2, offline asset bundling, latoTextTheme
- pub.dev/packages/shared_preferences — version 2.5.4, SharedPreferencesWithCache API
- drift.simonbinder.eu/setup/ — version 2.31.0, pubspec.yaml, table definition, database class

### Secondary (MEDIUM confidence)
- codewithandrea.com/articles/robust-app-initialization-riverpod/ — AppStartupWidget pattern; verified against Riverpod official patterns
- docs.flutter.dev/release/breaking-changes/material-3-default — Material 3 default confirmation
- docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source — synthetic-package change
- api.flutter.dev/flutter/painting/TextStyle/fontFamilyFallback.html — fontFamilyFallback behavior

### Tertiary (LOW confidence)
- WebSearch: approximate contrast ratio for white on forest green (~3.5:1) — not formally verified with exact hex; must validate with WebAIM tool before finalizing palette
- WebSearch: iOS system font coverage for Arabic — flag for physical device testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified directly against pub.dev and riverpod.dev official docs
- Architecture: HIGH — patterns verified against Flutter and Riverpod official documentation
- Color palette hex values: LOW — recommended values are educated starting points; WCAG validation against exact chosen values is required before implementation
- Pitfalls: HIGH — each pitfall sourced from official breaking-change docs or directly verified behavior

**Research date:** 2026-02-19
**Valid until:** 2026-03-19 (30 days; stable libraries)
