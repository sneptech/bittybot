---
phase: 04-core-inference-architecture
plan: "02"
subsystem: inference
tags: [dart-isolate, llama-cpp-dart, ffi, stream, crash-recovery, circuit-breaker]

# Dependency graph
requires:
  - phase: 04-core-inference-architecture/04-01
    provides: InferenceCommand/InferenceResponse sealed class hierarchies

provides:
  - inferenceIsolateMain top-level function (worker isolate entry point, owns Llama FFI)
  - LlmService class (isolate lifecycle, generate API, crash circuit breaker)

affects:
  - 04-03 (ChatNotifier — uses LlmService.generate/stop/clearContext)
  - 04-04 (modelReadyProvider — wraps LlmService.start() in Riverpod)
  - 05-translation-ui
  - 06-chat-ui

# Tech tracking
tech-stack:
  added: []  # No new packages — dart:isolate is stdlib
  patterns:
    - Completer<SendPort> for two-phase isolate handshake in single .listen()
    - Dedicated _errorPort for addErrorListener (List messages, not InferenceResponse)
    - Cooperative stop via _stopped flag in listen closure scope (not GenerateCommand local)
    - Manual nPredict token counting in await-for loop (ContextParams.nPredict is construction-time only)
    - Crash circuit breaker: _consecutiveCrashCount <= 3 auto-restart, else surface error

key-files:
  created:
    - lib/features/inference/application/inference_isolate.dart
    - lib/features/inference/application/llm_service.dart
  modified: []

key-decisions:
  - "Separate _errorPort for addErrorListener: Isolate.addErrorListener sends List<dynamic> messages, not InferenceResponse — mixing them in _responsePort would require type-guarding List. Dedicated port keeps the listener clean."
  - "Manual nPredict token counting: ContextParams.nPredict is set at Llama construction time. Since the model is loaded once per session, we set nPredict=-1 at load and count tokens ourselves in the await-for loop using GenerateCommand.nPredict."
  - "Cooperative stop via closure-scope _stopped: The flag lives in the receivePort.listen closure so both the GenerateCommand async handler and the StopCommand handler can see the same variable."

patterns-established:
  - "Pattern: Completer<SendPort> + single .listen() for Dart isolate port handshake — avoids .first consuming the stream"
  - "Pattern: Separate ReceivePort for Isolate.addErrorListener vs InferenceResponse messages"
  - "Pattern: Crash circuit breaker with _consecutiveCrashCount — reset on DoneResponse (success), increment on crash"
  - "Pattern: _isGenerating flag tracks active generation across the LlmService API boundary"

requirements-completed: [MODL-05]

# Metrics
duration: 3min
completed: 2026-02-25
---

# Phase 4 Plan 02: Inference Isolate and LlmService Summary

**Dart isolate worker owning the Llama FFI instance with streaming token delivery, cooperative stop, and 3-retry crash circuit breaker**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-02-25T04:47:35Z
- **Completed:** 2026-02-25T04:50:12Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments

- Created `inferenceIsolateMain` top-level function that owns the `Llama` FFI instance for the full app session, handles all 5 `InferenceCommand` types, and streams tokens via `SendPort`
- Implemented cooperative stop via a `_stopped` flag in the `receivePort.listen` closure scope — accessible from both `GenerateCommand` and `StopCommand` handlers without mutex/lock
- Built `LlmService` with a crash circuit breaker that auto-restarts the isolate up to 3 times before surfacing a permanent `ErrorResponse` to prevent infinite crash loops

## Task Commits

Each task was committed atomically:

1. **Task 1: Inference isolate entry point** - `76c1b27` (feat)
2. **Task 2: LlmService isolate lifecycle manager** - `1799e08` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `lib/features/inference/application/inference_isolate.dart` - Top-level `inferenceIsolateMain` function: handles `LoadModelCommand` (creates Llama with Phase 1 params), `GenerateCommand` (streams tokens with nPredict counting), `StopCommand` (sets `_stopped` flag), `ClearContextCommand` (calls `llama.clear()`), `ShutdownCommand` (disposes and closes port)
- `lib/features/inference/application/llm_service.dart` - `LlmService` class: spawns isolate, two-phase port handshake via `Completer<SendPort>`, broadcast `responseStream`, `generate`/`stop`/`clearContext` API, `_handleCrash` with circuit breaker threshold of 3

## Decisions Made

- **Separate `_errorPort` for `addErrorListener`:** `Isolate.addErrorListener` sends `List<dynamic>` messages (not `InferenceResponse`), so mixing them in `_responsePort` would require type-guarding `List` in the listener. A dedicated `_errorPort` keeps message handling clean — crash detection routes to `_handleCrash()`, inference responses route to `_responseController`.
- **Manual `nPredict` token counting:** `ContextParams.nPredict` is set at `Llama` construction time (stored as `_nPredict` field). Since the model is loaded once per session with `nPredict = -1` (unlimited), we count generated tokens ourselves in the `await for` loop and break when `tokenCount >= command.nPredict`. This allows per-request `nPredict` without rebuilding the model.
- **Cooperative stop via closure-scope `_stopped`:** The `stopped` flag lives in the `receivePort.listen` closure so both the async `GenerateCommand` handler and the synchronous `StopCommand` handler see the same variable. Dart's single-threaded isolate event loop ensures the stop command arrives between token yields.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `_handleCrash` unused warning — missing error port wiring**
- **Found during:** Task 2 (dart analyze after writing LlmService)
- **Issue:** Initial draft used `_isolate!.addErrorListener(_responsePort!.sendPort)` — this sends `List<dynamic>` crash data into the response port. The listener only handled `SendPort` and `InferenceResponse`, so crash messages were silently dropped and `_handleCrash()` was unreachable. Dart analyzer reported `unused_element` warning.
- **Fix:** Added a separate `_errorPort = ReceivePort()` for error events. Wired `_errorPort!.listen((_) => _handleCrash())` and `_isolate!.addErrorListener(_errorPort!.sendPort)`. Also added `_errorPort` cleanup in both `dispose()` and `_handleCrash()`.
- **Files modified:** `lib/features/inference/application/llm_service.dart`
- **Verification:** `dart analyze` returned "No issues found" after fix
- **Committed in:** `1799e08` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — logic error discovered during analysis)
**Impact on plan:** Auto-fix required for crash recovery to function. Without it, isolate crashes would be silently ignored and the circuit breaker would never fire.

## Issues Encountered

None — both files compiled and analyzed cleanly on first attempt after the error port fix.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `inferenceIsolateMain` and `LlmService` are ready for Plan 04's Riverpod provider wrapper (`modelReadyProvider`)
- `LlmService.generate()` returns `requestId` — callers match tokens via `responseStream.where((r) => r.requestId == id)`
- `LlmService.isAlive` provides liveness check for OS background kill detection
- The `lib/features/inference/application/` directory is now established; Plan 04 will add `model_ready_provider.dart` here

## Self-Check: PASSED

- FOUND: lib/features/inference/application/inference_isolate.dart
- FOUND: lib/features/inference/application/llm_service.dart
- FOUND: .planning/phases/04-core-inference-architecture/04-02-SUMMARY.md
- FOUND commit: 76c1b27 (Task 1 — inference isolate)
- FOUND commit: 1799e08 (Task 2 — LlmService)

---
*Phase: 04-core-inference-architecture*
*Completed: 2026-02-25*
