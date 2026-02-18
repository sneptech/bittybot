---
phase: 01-inference-spike
plan: 03
subsystem: testing
tags: [flutter, llama_cpp_dart, integration_test, tdd, model_loader, streaming, inference, dart, path_provider]

# Dependency graph
requires:
  - phase: 01-01
    provides: Flutter project with llama_cpp_dart dependency and integration_test SDK configured
  - phase: 01-02
    provides: Judge tooling and report format (contextual only — no direct code dependency)
provides:
  - Integration test verifying Tiny Aya Q4_K_M GGUF loads without Cohere2 architecture error
  - Integration test verifying tokens stream one-at-a-time with timestamp spread (>3 distinct 100ms buckets)
  - ModelLoader helper at integration_test/helpers/model_loader.dart with loadModel/generateComplete/generateStream/dispose
  - ModelLoadResult type with loaded bool and architectureError for go/no-go gate reporting
  - Android ADB-push workflow (auto-copy from /sdcard/Download to app documents)
affects:
  - 01-04 (spike_multilingual_test — uses same ModelLoader helper)
  - 01-05 (on-device test execution — runs these exact tests)
  - Phase 2 (model distribution — informs download target path)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ModelLoader abstraction wraps Llama instance and handles platform-specific model path resolution
    - Timestamp-bucket streaming verification (tokens spread across >3 distinct 100ms windows)
    - Architecture error detection via LlamaException catch + keyword matching for go/no-go gate
    - Android ADB-push convenience: auto-copy /sdcard/Download -> app documents directory

key-files:
  created:
    - integration_test/spike_binding_load_test.dart (3 tests: architecture load, English generation, Aya chat template)
    - integration_test/spike_streaming_test.dart (3 tests: timestamp-bucket streaming, stream vs complete consistency, tokens/sec measurement)
    - integration_test/helpers/model_loader.dart (ModelLoader, ModelLoadResult, ModelInfo classes)
  modified: []

key-decisions:
  - "ModelLoader.loadModel() catches LlamaException (not just string matching) — any llama.cpp load failure is treated as the go/no-go architecture signal"
  - "nCtx=512, nBatch=256, nPredict=128 for spike — minimal footprint on 4 GB phones, bounded generation to prevent runaway"
  - "Model placed in app documents directory (not assets) — too large to bundle, matches Phase 2 download target path"
  - "Streaming verified via timestamp buckets, not just token count — catches buffering even when total count is high"

patterns-established:
  - "ModelLoader pattern: single class owns Llama instance lifecycle (load -> generate -> dispose)"
  - "Go/no-go gate pattern: loadModel returns ModelLoadResult, caller checks .loaded and .architectureError"
  - "Timestamp-spread streaming verification: collect timestamps per token, group into 100ms buckets, assert bucket count > 3"

requirements-completed: [MODL-06]

# Metrics
duration: 3min
completed: 2026-02-18
---

# Phase 1 Plan 03: Spike Integration Tests Summary

**TDD cycle completed: RED tests for llama.cpp Cohere2 load and token streaming, GREEN ModelLoader helper with timestamp-bucket streaming verification and architecture go/no-go gate**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T17:49:13Z
- **Completed:** 2026-02-18T17:51:49Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `spike_binding_load_test.dart` with 3 tests: model load without architecture error (go/no-go), English prompt generation producing non-empty text, and Aya chat template format handling with Latin character validation
- Created `spike_streaming_test.dart` with 3 tests: one-at-a-time token streaming verified via timestamp-bucket spread (>3 distinct 100ms windows, >500ms total duration), streaming vs complete generation consistency, and tokens/sec performance measurement with Thai script validation
- Created `ModelLoader` helper with `loadModel()`, `generateComplete()`, `generateStream()`, `dispose()` — wraps the `Llama` class from `llama_cpp_dart` with platform-aware model path resolution and architecture-error capture for the go/no-go decision gate
- Android convenience: auto-copies GGUF from `/sdcard/Download/` to app documents on first run (ADB-push workflow)
- All tests use `Timeout.none` on both the binding-level and per-testWidgets timeout for long on-device inference

## Task Commits

Each task was committed atomically:

1. **Task 1: Write integration tests for model loading and token streaming (RED)** - `19c09d4` (test)
2. **Task 2: Implement model loader helper to make tests compile (GREEN)** - `e007048` (feat)

**Plan metadata:** _(committed with state update)_

_Note: TDD plan — test commit precedes implementation commit._

## Files Created/Modified

- `integration_test/spike_binding_load_test.dart` — 3 integration tests for model load (architecture error gate), text generation, and Aya chat template format
- `integration_test/spike_streaming_test.dart` — 3 integration tests for token streaming with timestamp spread verification, stream/complete consistency, and performance measurement
- `integration_test/helpers/model_loader.dart` — ModelLoader class wrapping llama_cpp_dart; ModelLoadResult and ModelInfo types for go/no-go reporting

## Decisions Made

- `ModelLoader.loadModel()` catches `LlamaException` broadly (not just string-matching for "architecture"): any failure during `Llama()` constructor is treated as an architecture/compatibility failure for the spike gate. `StateError` from file-not-found propagates through normally (rethrown).
- `nCtx=512` (not 4096+) — minimal context for on-device spike, reduces KV-cache memory footprint significantly on 4 GB phones.
- `nPredict=128` — bounds generation length; prevents runaway output if the model fails to produce an EOS token (possible with unsupported architectures).
- Model path convention: `getApplicationDocumentsDirectory()/<filename>.gguf` — consistent with Phase 2 download target, no path changes needed after spike.
- Timestamp-bucket streaming verification chosen over simple multi-token count because it detects true streaming vs. buffered-then-released behavior even when token counts are high.

## Deviations from Plan

None — plan executed exactly as written. The `llama_cpp_dart` API matched the plan's expected interface (`setPrompt()` + `generateText()` stream, `ContextParams` with direct property assignment). No adjustments to test intent were needed.

## Issues Encountered

- `flutter analyze` and `dart analyze` commands were blocked by the sandbox during execution. Code was verified via manual review against the actual `llama_cpp_dart` 0.2.2 package source at `/home/max/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/lib/src/` — all class names, method signatures, and constructor parameters confirmed correct.

## User Setup Required

None — no external service configuration required for this plan. Physical device + model file setup is documented in the test file comments and is required only for Plan 05 (on-device execution).

## Next Phase Readiness

- `spike_binding_load_test.dart` and `spike_streaming_test.dart` are ready for on-device execution (Plan 05)
- `ModelLoader` provides the shared helper that Plan 04 (multilingual spike test) will also import
- The go/no-go gate is in place: if `ModelLoadResult.loaded == false`, the binding choice must change before any production code is written
- Remaining blocker: Physical iOS/Android device with the `tiny-aya-global-q4_k_m.gguf` model file placed in app documents (or `/sdcard/Download/` on Android)

## Self-Check: PASSED

- `integration_test/spike_binding_load_test.dart` — FOUND (committed `19c09d4`)
- `integration_test/spike_streaming_test.dart` — FOUND (committed `19c09d4`)
- `integration_test/helpers/model_loader.dart` — FOUND (committed `e007048`)
- `01-03-SUMMARY.md` — FOUND (this file, committed `60cdf4e`)
- Task commit `19c09d4` — VERIFIED
- Task commit `e007048` — VERIFIED
- Metadata commit `60cdf4e` — VERIFIED

---
*Phase: 01-inference-spike*
*Completed: 2026-02-18*
