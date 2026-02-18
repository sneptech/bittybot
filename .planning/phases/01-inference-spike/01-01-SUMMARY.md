---
phase: 01-inference-spike
plan: 01
subsystem: infra
tags: [flutter, llama_cpp_dart, background_downloader, path_provider, integration_test, android, ios, language-corpus, dart]

# Dependency graph
requires: []
provides:
  - Flutter project at /home/max/git/bittybot with all dependencies resolved
  - Android NDK r28+ configuration (28.0.12674087) for 16KB page compliance
  - iOS physical device configuration with Extended Virtual Addressing entitlement
  - iOS Podfile with Metal framework linkage and simulator arch exclusion
  - 70-language test corpus at integration_test/helpers/language_corpus.dart
  - Aya chat template prompt format established
  - Script validator RegExp for all 19 Unicode script families
affects:
  - 01-02 (spike_binding_load_test)
  - 01-03 (spike_streaming_test)
  - 01-04 (spike_multilingual_test)
  - 01-05 (spike_judge_tools)
  - All subsequent phases (project foundation)

# Tech tracking
tech-stack:
  added:
    - llama_cpp_dart ^0.2.2 (primary Flutter llama.cpp binding)
    - background_downloader ^9.5.2 (GGUF download with iOS/Android background limits)
    - path_provider ^2.1.5 (on-device file path resolution)
    - integration_test (SDK) (on-device test runner)
    - flutter_test (SDK) (test assertions)
  patterns:
    - Aya chat template format: <|START_OF_TURN_TOKEN|><|USER_TOKEN|>...<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>
    - Script family categorization with per-family Unicode RegExp validators
    - Priority-tiered language test corpus (mustHave vs standard)
    - Cantonese-forcing prompt with explicit particle validation

key-files:
  created:
    - pubspec.yaml (Flutter project with all production and dev dependencies)
    - lib/main.dart (minimal BittyBotApp scaffold for integration_test)
    - android/app/build.gradle.kts (NDK r28+ and minSdk 24)
    - android/gradle.properties (R8 enabled)
    - ios/Podfile (platform 14.0, Metal framework, simulator exclusion)
    - ios/Runner/Runner.entitlements (extended-virtual-addressing)
    - ios/Runner.xcodeproj/project.pbxproj (CODE_SIGN_ENTITLEMENTS for all configs)
    - integration_test/helpers/language_corpus.dart (70-language corpus)
  modified:
    - test/widget_test.dart (updated to reference BittyBotApp)

key-decisions:
  - "llama_cpp_dart ^0.2.2 selected as primary binding (most recently updated, tracks llama.cpp master)"
  - "background_downloader ^9.5.2 for GGUF download (handles iOS 4-hour and Android 9-minute background limits)"
  - "Android NDK pinned to 28.0.12674087 for mandatory 16KB page alignment (Play Store May 31, 2026 deadline)"
  - "iOS minimum deployment target set to 14.0 (matches llama_cpp_dart iOS requirements)"
  - "All iOS simulator archs excluded (arm64 x86_64) — Metal GPU unavailable in Simulator"
  - "Cantonese tested separately from Mandarin with explicit particle validation (㗎, 囉, 喇, 嘅, 咁, 咋, 㖖)"
  - "70 languages total: 4 mustHave with 18 prompts each, 66 standard with 3 prompts each"

patterns-established:
  - "Aya chat template: wrap source in <|START_OF_TURN_TOKEN|><|USER_TOKEN|>...<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>"
  - "Script validation: each language has a RegExp matching its Unicode block(s)"
  - "Cantonese forcing: always include explicit Cantonese-vs-Mandarin disclaimer in prompt"
  - "Travel phrase categories: directions, food, emergency, greetings, prices, basic"

requirements-completed: [MODL-06]

# Metrics
duration: 8min
completed: 2026-02-18
---

# Phase 1 Plan 01: Bootstrap and Language Corpus Summary

**Flutter project bootstrapped with NDK r28+/iOS EVA toolchain, plus a 70-language Aya test corpus with 18 Cantonese-forcing travel prompts explicitly distinct from Mandarin**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-18T17:34:26Z
- **Completed:** 2026-02-18T17:42:10Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Created Flutter project with all dependencies: llama_cpp_dart, background_downloader, path_provider, integration_test, flutter_test — all resolved via `flutter pub get`
- Configured Android for NDK r28+ (28.0.12674087) with minSdk 24 for 16KB page alignment compliance required by Play Store (May 31, 2026 deadline)
- Configured iOS with Extended Virtual Addressing entitlement, Metal framework linkage, physical-device-only targeting (simulator archs excluded), deployment target 14.0
- Created 70-language corpus at `integration_test/helpers/language_corpus.dart` covering all Aya-supported languages: 4 mustHave languages with 18 travel prompts each, 66 standard languages with 3 reference sentences each
- Cantonese explicitly separate from Mandarin with Cantonese-forcing instruction and particle validation regex `[㗎囉喇嘅咁咋㖖]`
- All 19 Unicode script families have dedicated RegExp validators

## Task Commits

Each task was committed atomically:

1. **Task 1: Flutter project + platform toolchain configuration** - `876cc45` (feat)
2. **Task 2: 70-language test corpus** - `428cc35` (feat)

**Plan metadata:** _(committed with state update)_

## Files Created/Modified

- `pubspec.yaml` — Flutter project with llama_cpp_dart, background_downloader, path_provider, integration_test
- `lib/main.dart` — Minimal BittyBotApp scaffold required for integration_test
- `android/app/build.gradle.kts` — NDK r28+ (28.0.12674087), compileSdk 35, minSdk 24
- `android/gradle.properties` — android.enableR8=true added
- `ios/Podfile` — platform 14.0, Metal framework in post_install hook, simulator arch exclusion
- `ios/Runner/Runner.entitlements` — extended-virtual-addressing entitlement
- `ios/Runner.xcodeproj/project.pbxproj` — CODE_SIGN_ENTITLEMENTS for Debug, Release, Profile configs; Runner.entitlements file reference added
- `integration_test/helpers/language_corpus.dart` — 70-language corpus (1,125 lines)
- `test/widget_test.dart` — Updated to reference BittyBotApp (not deleted MyApp)

## Decisions Made

- Used `llama_cpp_dart ^0.2.2` as primary binding (actively maintained, most recent submodule updates, explicit async streaming API via `generateText()`)
- NDK pinned to exact version `28.0.12674087` rather than using `flutter.ndkVersion` variable (which may not be r28+)
- iOS deployment target `14.0` (not 13.0 from flutter create default) — required by llama_cpp_dart
- Excluded ALL simulator architectures (`arm64 x86_64`) — Metal GPU unavailable in Simulator, so no simulator builds planned for spike
- Cantonese receives a fully explicit forcing prompt mentioning it is "NOT Mandarin Chinese" to prevent model conflation
- English travel phrases use paraphrase-style prompts to verify model can generate natural English responses

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid syntax in generated lib/main.dart**
- **Found during:** Task 1 (Create Flutter project)
- **Issue:** `flutter create` generated `colorScheme: .fromSeed(...)` and `mainAxisAlignment: .center` — invalid Dart syntax (static member access without class name). File would fail to compile.
- **Fix:** Replaced the entire file with a clean minimal `BittyBotApp` scaffold referencing `ColorScheme.fromSeed(...)` and `MainAxisAlignment.center` correctly.
- **Files modified:** `lib/main.dart`
- **Verification:** `flutter analyze lib/` reports no issues
- **Committed in:** 876cc45 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed broken widget_test.dart referencing deleted MyApp class**
- **Found during:** Task 1 (Create Flutter project) — discovered during `flutter analyze`
- **Issue:** After replacing `main.dart` with `BittyBotApp`, the generated `test/widget_test.dart` still referenced `MyApp` — compile error: "The name 'MyApp' isn't a class"
- **Fix:** Rewrote `widget_test.dart` to use `BittyBotApp` and updated test assertions to match the new scaffold
- **Files modified:** `test/widget_test.dart`
- **Verification:** `flutter analyze lib/ integration_test/ test/` reports no issues
- **Committed in:** 876cc45 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs in generated code)
**Impact on plan:** Both bugs were in `flutter create`-generated code and required immediate fixing for compilation. No scope creep.

## Issues Encountered

- The `tool/lib/coherence_rubric.dart` and `tool/lib/result_types.dart` (pre-existing files from prior context-gathering session) produce `unnecessary_library_name` info-level warnings in `flutter analyze`. These are pre-existing, out-of-scope files. The plan specifies "warnings acceptable" for `flutter analyze`, and these are info-level (not errors or warnings). Logged for awareness; not fixed as they are out of scope for this task.

## User Setup Required

None - no external service configuration required for this plan.

## Next Phase Readiness

- Flutter project is compilable and dependency-resolved — ready for integration test development (Plans 02–05)
- Language corpus provides all test data for multilingual spike tests (Plan 04)
- Android NDK r28+ and iOS EVA configuration are correct for on-device builds
- Remaining blocker: Physical iOS device and Android device needed for actual test execution (Plans 02–04)
- Critical unknown: Whether `llama_cpp_dart` 0.2.2's bundled llama.cpp includes the Tiny Aya tokenizer PR (Feb 16, 2026) — resolved by Plan 02 spike test

---
*Phase: 01-inference-spike*
*Completed: 2026-02-18*
