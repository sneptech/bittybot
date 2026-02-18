---
phase: 01-inference-spike
plan: 05
subsystem: testing
tags: [flutter, android, ios, integration_test, llama_cpp_dart, ndk, page_alignment, hardware]

# Dependency graph
requires:
  - phase: 01-03
    provides: Integration tests for model load, streaming
  - phase: 01-04
    provides: Multilingual test suite and report writer

provides:
  - Android build config corrected (compileSdk=36, NDK 29.0.14033849)
  - 16KB alignment verified on Flutter runtime .so files (align 2**16)
  - Critical finding: libmtmd.so not auto-bundled in APK — requires AAR build step
  - Critical finding: llama_cpp_dart is NOT a Flutter plugin (no native auto-bundling)
  - Partial Task 1 automation; awaiting physical device for full test run

affects:
  - Phase 2 (model distribution — needs to account for native library AAR dependency)
  - Phase 3 (app foundation — Android native library must be bundled via AAR)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - NDK version must match highest requirement across all plugins (not lowest or hardcoded)
    - llama_cpp_dart requires AAR pre-build step for Android native library distribution
    - Flutter release APK does NOT auto-bundle llama_cpp_dart native library (libmtmd.so)

key-files:
  created: []
  modified:
    - android/app/build.gradle.kts

key-decisions:
  - "compileSdk upgraded to 36 (background_downloader, integration_test, path_provider_android require >=36)"
  - "ndkVersion changed to 29.0.14033849 (llama_cpp_dart requires NDK 29; NDK 29 maintains 16KB page alignment)"
  - "libmtmd.so (llama_cpp_dart native library) is NOT auto-bundled in APK — requires separate AAR build from android/ directory"
  - "16KB alignment verified: libapp.so and libflutter.so show align 2**16 (64KB), exceeds 2**14 requirement"

patterns-established: []

requirements-completed: [MODL-06]

# Metrics
duration: partial (stopped at checkpoint)
completed: 2026-02-18
---

# Phase 1 Plan 05: On-Device Hardware Verification Summary

**Android build config fixed (compileSdk=36, NDK 29) and 16KB alignment verified for Flutter libs; llama_cpp_dart native library (libmtmd.so) not auto-bundled — requires AAR build step before on-device testing**

## Performance

- **Duration:** partial execution (stopped at checkpoint:human-verify)
- **Started:** 2026-02-18T20:02:59Z
- **Completed:** 2026-02-18T20:35:00Z (approximate)
- **Tasks:** 1 of 3 (partial — Task 1 automated portion complete; Task 2 is human checkpoint; Task 3 awaiting results)
- **Files modified:** 1

## Accomplishments

- Fixed Android build configuration: `compileSdk` upgraded from 35 to 36 and `ndkVersion` from unpinned `28.0.12674087` (not installed) to `29.0.14033849` (highest available, satisfying llama_cpp_dart's NDK 29 requirement)
- Release APK builds successfully: `flutter build apk --release` produces a 42.6MB APK
- 16KB page alignment verified for Flutter runtime libraries: `libapp.so` and `libflutter.so` show `align 2**16` (64KB LOAD segment alignment), which exceeds the Play Store 16KB minimum requirement
- Critical discovery documented: `llama_cpp_dart` is NOT a Flutter plugin — it has no `flutter.plugin` section in pubspec.yaml and does not auto-bundle native code into the APK. `libmtmd.so` must be pre-built from the `android/` directory as an AAR and added to the project

## Task Commits

1. **Task 1 (partial): Android build config fix** - `23416ed` (fix)
2. **Task 2: iOS device verification** - PENDING (checkpoint:human-verify)
3. **Task 3: Judge evaluation and report** - PENDING (awaiting device results)

## Files Created/Modified

- `android/app/build.gradle.kts` — Updated `compileSdk` from 35 to 36 and `ndkVersion` from `28.0.12674087` to `29.0.14033849`

## Decisions Made

- NDK pinned to `29.0.14033849` rather than the originally planned `28.0.12674087` because:
  1. `28.0.12674087` is not installed on the development machine
  2. `llama_cpp_dart-0.2.2`'s `android/llamalib/build.gradle` pins to NDK `29.0.13846066`
  3. NDK 29 maintains 16KB page alignment support (this requirement is about alignment flags, not NDK major version)
- `compileSdk` upgraded to 36 because three plugins require it: `background_downloader`, `integration_test`, `path_provider_android`
- `libmtmd.so` (the llama_cpp_dart native library) requires a manual AAR build step from `~/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/android/` before on-device tests can run

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated Android compileSdk from 35 to 36**
- **Found during:** Task 1 (Android build attempt)
- **Issue:** `flutter build apk --release` failed: three plugins (background_downloader, integration_test, path_provider_android) require compileSdk >= 36
- **Fix:** Updated `compileSdk = 36` in `android/app/build.gradle.kts`
- **Files modified:** `android/app/build.gradle.kts`
- **Verification:** Release APK builds successfully (42.6MB)
- **Committed in:** `23416ed` (Task 1 commit)

**2. [Rule 3 - Blocking] Updated Android ndkVersion to 29.0.14033849**
- **Found during:** Task 1 (Android build attempt)
- **Issue:** Planned NDK `28.0.12674087` not installed on development machine; build failed; `llama_cpp_dart`'s Android module uses NDK 29
- **Fix:** Updated `ndkVersion = "29.0.14033849"` (highest installed NDK, compatible with all plugin requirements)
- **Files modified:** `android/app/build.gradle.kts`
- **Verification:** Release APK builds successfully; NDK 29 maintains 16KB page alignment
- **Committed in:** `23416ed` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - Blocking)
**Impact on plan:** Build config must match installed NDK versions. NDK 29 is a superset of NDK 28 for 16KB alignment purposes. No scope creep.

## Critical Finding: libmtmd.so Not Auto-Bundled

**This affects the on-device test execution plan.**

`llama_cpp_dart` is a pure Dart FFI package, NOT a Flutter plugin. It uses `DynamicLibrary.open("libmtmd.so")` at runtime but does NOT register a plugin that would cause Flutter tooling to auto-build and bundle the native library.

**What this means:**
- `flutter build apk --release` produces an APK without `libmtmd.so`
- Running `flutter test integration_test/ --timeout none` on an Android device will crash at the point where `Llama()` is constructed — `DynamicLibrary.open("libmtmd.so")` will fail with "library not found"
- The llama_cpp_dart `android/` directory contains an `build-android-aar.sh` script that builds the AAR manually

**Required steps before on-device testing:**
1. Build the AAR from `~/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/android/`:
   ```bash
   cd ~/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/android
   ./build-android-aar.sh
   ```
2. Copy the resulting `llamalib-release.aar` to `android/app/libs/`
3. Add the libs dependency to `android/app/build.gradle.kts`
4. Then run the integration tests

**Alternatively:** The llama_cpp_dart issue tracker may have a pre-built AAR download, or the package may require a different integration approach (e.g., via a pub.dev plugin that wraps it).

**Go/No-Go Impact:** This issue is pre-test. The actual Cohere2 architecture support question remains open. The iOS XCFramework binary in the dist/ directory showed no `cohere` or `cohere2` architecture strings (checked via `strings`), but this is inconclusive because architecture names may not appear as simple strings in the compiled binary.

## Issues Encountered

- Android device not connected during execution — Task 1 integration tests could not be run. Build config was fixed and alignment verified on the APK level.
- iOS physical device testing blocked on checkpoint (requires human).

## User Setup Required

Before on-device testing can proceed:
1. **Android AAR build:** The native library for Android must be pre-built. See "Critical Finding" section above.
2. **Model file on device:** `tiny-aya-global-q4_k_m.gguf` must be available at `/sdcard/Download/` on the Android device (the test auto-copies it to app documents)
3. **iOS device:** Physical iOS device required with model file in app Documents directory

## Next Phase Readiness

- Android build configuration is correct and APK builds successfully
- Flutter runtime libraries meet 16KB page alignment requirement
- BLOCKING: `libmtmd.so` native library must be built and bundled before Android integration tests can run
- BLOCKING: Physical iOS/Android devices with model file required for actual test execution
- The go/no-go decision on Cohere2 support remains OPEN pending hardware test results

---
*Phase: 01-inference-spike*
*Status: PARTIAL — stopped at checkpoint:human-verify*
*Completed (partial): 2026-02-18*
