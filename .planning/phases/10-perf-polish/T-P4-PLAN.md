# T-P4: Fix Main Thread Blocking & Slow Inference — Execution Plan

**Author:** SwiftSpring (Planner)
**Implementer:** SageHill (Worker, Pane 5) — after T-P0 is reviewed and approved
**Reviewer:** SwiftSpring (Pane 2)
**Priority:** CRITICAL
**Depends on:** T-P0 (profiling infrastructure must be in place first)

---

## Overview

On-device testing revealed two critical performance issues:
1. **10s input delay after model download** — chat input is unresponsive for ~10s
2. **Slow inference in chat mode** — glacially slow despite fast performance in translation testing

This plan diagnoses root causes using the T-P0 profiling infrastructure and implements targeted fixes.

---

## Problem Analysis

### Problem 1: 10s Input Delay After Download

**Trace through the code path:**

1. Model download completes → `ModelDistributionNotifier` sets `LoadingModelState`
2. `ModelGateWidget` (model_gate_widget.dart:51-53) switches to `AppStartupWidget → MainShell`
3. `AppStartupWidget` awaits `appStartupProvider` (settings only — fast, <100ms)
4. `MainShell` renders tabs. Chat/Translation screens watch `modelReadyProvider`
5. `ModelReady.build()` (llm_service_provider.dart:31-57) calls `LlmService.start()`
6. `LlmService.start()` (llm_service.dart:75-135):
   - `Isolate.spawn()` — spawns worker isolate (fast, <50ms)
   - Sends `LoadModelCommand` to isolate
   - `await responseStream.firstWhere(...)` — waits for `ModelReadyResponse`
7. In isolate (inference_isolate.dart:39-59):
   - `Llama()` constructor loads 2GB GGUF model with `useMemorymap=false`
   - This is the ~10s bottleneck — reading 2GB from flash into RAM

**Diagnosis:** The 10s delay IS the model load time on the isolate. The main thread is NOT blocked (it's an `await` in an async provider). The input is correctly disabled via `isModelReady: false`. However:
- The user perceives this as "unresponsive" because there's no loading indicator on the chat input
- The `ModelGateWidget` already transitioned away from `DownloadScreen`, so there's no "Loading model..." UI

**Root cause:** Missing UX feedback during model load phase. The input field is disabled but there's no visual indicator that the model is loading.

**Fix approach:**
- This is mostly a UX issue. The model load time itself is inherent to loading a 2GB model.
- However, we should verify with T-P0 profiling that nothing unexpected is happening
- Ensure `modelReadyProvider` resolves promptly after Llama() returns
- Add profiling to measure exact time breakdown

### Problem 2: Slow Inference in Chat Mode

**Comparison of chat vs. translation parameters:**

| Parameter | Translation | Chat | Impact |
|-----------|------------|------|--------|
| `nPredict` | 128 | 512 | Max tokens only — doesn't affect per-token speed |
| Prompt length | Short (1 sentence) | Long (system prompt + multi-turn history) | Longer prompt → more KV cache → slower attention |
| `nCtx` | 2048 | 2048 | Same |
| `nBatch` | 256 | 256 | Same |
| `nThreads` | Not set | Not set | Uses library default — may be suboptimal |

**Key suspect: Per-token UI rebuilds**

In `ChatNotifier._onResponse()` (chat_notifier.dart:366-373):
```dart
case TokenResponse(:final requestId, :final token):
  if (requestId != state.activeRequestId) return;
  state = state.copyWith(
    currentResponse: state.currentResponse + token,
  );
```

Every single token triggers:
1. New `ChatState` allocation
2. Riverpod state notification
3. Widget tree rebuild (ChatScreen → ChatBubbleList → individual bubbles)
4. Scroll-to-bottom animation

If the model generates 10-30 tokens/sec, that's 10-30 full widget rebuilds per second. The `ChatBubbleList` rebuilds the entire bubble list on each token. Combined with scroll animations, this can cause jank that BACK-PRESSURES the isolate via the event loop.

**Additional suspect: String concatenation in hot path**

`state.currentResponse + token` creates a new String on every token. For a 512-token response, that's 512 string allocations of increasing size (O(n²) total copies).

**Translation comparison:** Translation mode has the SAME per-token update pattern but:
- Only 128 tokens max (vs 512)
- Word-level batching in the bubble display (groups tokens before rendering)
- Simpler widget tree (single translation bubble vs scrollable list)

---

## File Plan

| Action | File | Purpose |
|--------|------|---------|
| MODIFY | `lib/features/chat/application/chat_notifier.dart` | Token batching, StringBuffer optimization |
| MODIFY | `lib/features/inference/application/llm_service.dart` | Verify no main-thread blocking (should already be clean from T-P0) |
| MODIFY | `lib/features/inference/application/inference_isolate.dart` | Add nThreads param, verify generate loop efficiency |
| MODIFY | `lib/features/inference/domain/inference_message.dart` | Add nThreads to LoadModelCommand |
| POSSIBLY MODIFY | `lib/features/inference/application/llm_service_provider.dart` | Pass nThreads if needed |
| NEW | `test/features/chat/application/chat_notifier_batching_test.dart` | Test token batching behavior |

---

## Fix 1: Token Batching in ChatNotifier (PRIMARY FIX)

### Problem
Per-token `state = state.copyWith(...)` causes 10-30 widget rebuilds/sec.

### Solution
Buffer tokens in a `StringBuffer` and flush to state on a 50ms timer. This reduces rebuilds from ~30/sec to ~20/sec while maintaining smooth streaming appearance.

### Implementation

In `chat_notifier.dart`, add:

#### New fields (in ChatNotifier class body, after `_turnCount`):

```dart
/// Buffer for accumulating tokens between UI flushes.
/// Flushed to state every [_kTokenBatchInterval] or on generation complete.
final StringBuffer _tokenBuffer = StringBuffer();

/// Timer that flushes buffered tokens to state at a fixed interval.
Timer? _batchTimer;

/// Interval between token buffer flushes to UI state.
static const Duration _kTokenBatchInterval = Duration(milliseconds: 50);
```

#### Modified `_onResponse` handler:

Replace the `TokenResponse` case (lines 367-373):

```dart
case TokenResponse(:final requestId, :final token):
  if (requestId != state.activeRequestId) return;
  _tokenBuffer.write(token);
  _scheduleBatchFlush();
```

#### New helper methods:

```dart
/// Schedules a batch flush if one isn't already pending.
void _scheduleBatchFlush() {
  if (_batchTimer?.isActive ?? false) return;
  _batchTimer = Timer(_kTokenBatchInterval, _flushTokenBuffer);
}

/// Flushes accumulated tokens from buffer to state, triggering a single rebuild.
void _flushTokenBuffer() {
  if (_tokenBuffer.isEmpty) return;
  final buffered = _tokenBuffer.toString();
  _tokenBuffer.clear();
  state = state.copyWith(
    currentResponse: state.currentResponse + buffered,
  );
}
```

#### Modified `_finishGeneration`:

Before persisting the assistant message, flush any remaining buffered tokens:

```dart
Future<void> _finishGeneration({required bool stopped}) async {
  // Flush any remaining buffered tokens before finalizing.
  _batchTimer?.cancel();
  _flushTokenBuffer();

  final session = state.activeSession;
  // ... rest of existing code ...
}
```

#### Modified `_handleError`:

Same flush pattern:

```dart
Future<void> _handleError(String message) async {
  // Flush any remaining buffered tokens.
  _batchTimer?.cancel();
  _flushTokenBuffer();

  // ... rest of existing code ...
}
```

#### Cleanup in `build()`:

Add timer cancellation to the `ref.onDispose` callback:

```dart
ref.onDispose(() {
  _responseSubscription?.cancel();
  _batchTimer?.cancel();  // <-- ADD
});
```

#### Also: In `startNewSession()` and `startNewSessionWithCarryForward()`:

Clear the buffer:
```dart
_tokenBuffer.clear();
_batchTimer?.cancel();
```

---

## Fix 2: Add nThreads Parameter to Isolate Configuration

### Problem
`ContextParams` doesn't set `nThreads`. The llama_cpp_dart default may use too many or too few threads for the target device (Samsung Galaxy A25 has 8 cores: 2 big + 6 little).

### Solution
Add `nThreads` parameter to `LoadModelCommand` and pass it through to `ContextParams`.

### Implementation

#### In `inference_message.dart`, modify `LoadModelCommand`:

```dart
final class LoadModelCommand extends InferenceCommand {
  final String modelPath;
  final int nCtx;
  final int nBatch;

  /// Number of threads for inference. Default 4 (good balance for
  /// mid-range phones with big.LITTLE architecture).
  final int nThreads;

  const LoadModelCommand({
    required this.modelPath,
    this.nCtx = 2048,
    this.nBatch = 256,
    this.nThreads = 4,
  });
}
```

#### In `inference_isolate.dart`, use nThreads:

```dart
final contextParams = ContextParams()
  ..nCtx = message.nCtx
  ..nBatch = message.nBatch
  ..nUbatch = message.nBatch
  ..nThreads = message.nThreads      // <-- ADD
  ..nPredict = -1;
```

**Note:** Check if `ContextParams` has `nThreads` field. If not, check `ModelParams` or `SamplingParams`. The llama_cpp_dart API may expose this differently. SageHill should investigate the actual API surface.

---

## Fix 3: Profile and Verify Model Load Path (INVESTIGATION)

### Purpose
Use T-P0 profiling to confirm the model load is purely on the isolate and nothing blocks the main thread.

### Steps (Investigation, not code changes)

1. After T-P0 is merged, run the app on device
2. Check `[PERF] model_load` log line for duration
3. Check DevTools Timeline for `model_load` span — verify it's on the isolate, not main thread
4. If model load is >15s, investigate:
   - Is `useMemorymap = false` causing excessive IO? (Required for Android SELinux, so can't change)
   - Is the model file path resolution slow?
   - Is `Llama()` constructor doing synchronous work before spawning internal threads?

### Expected findings
Model load should be 8-15s on Galaxy A25 for a 2GB GGUF file. This is inherent to the hardware. The fix is UX (loading indicator), not code optimization.

---

## Fix 4: Verify Inference Speed with Profiling (MEASURE BEFORE TUNING)

### Steps

1. After T-P0 and Fix 1 (batching) are merged, run the app on device
2. Send a simple chat message (e.g., "Hello, how are you?")
3. Check `[PERF] inference_request` log line for:
   - `ttft_ms` — time to first token (target: <2000ms)
   - `tokens_per_sec` — generation rate (target: >5 tok/s)
   - `total_ms` — total generation time
4. Compare with translation mode (send same text as translation)
5. If chat is significantly slower:
   - Check if prompt length is the issue (multi-turn history fills KV cache)
   - Check if `nBatch` tuning helps
   - Profile with different `nThreads` values (2, 4, 6, 8)

### If tokens/sec < 5 after batching:
- Try `nBatch = 128` (smaller batches = faster per-batch, less memory pressure)
- Try `nThreads = 4` explicitly (avoid over-subscribing on little cores)
- Consider reducing `nCtx` to 1024 for chat mode if memory is the bottleneck

---

## Test Plan

### File: `test/features/chat/application/chat_notifier_batching_test.dart`

Write these tests FIRST (TDD):

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
// Mocks and imports as needed

void main() {
  group('Token batching', () {
    test('multiple rapid tokens result in fewer state updates than token count', () {
      // Send 20 tokens rapidly
      // Verify state was updated fewer than 20 times
      // (exact count depends on timer resolution, but should be < 20)
    });

    test('buffered tokens are flushed on generation complete', () {
      // Send 5 tokens without waiting for batch timer
      // Then send DoneResponse
      // Verify final currentResponse contains all 5 tokens
      // Verify final message in state.messages contains all tokens
    });

    test('buffered tokens are flushed on error', () {
      // Send 3 tokens then ErrorResponse
      // Verify accumulated tokens are persisted as truncated message
    });

    test('token buffer is cleared on new session', () {
      // Accumulate tokens in buffer
      // Call startNewSession()
      // Verify buffer is empty and no stale tokens leak
    });

    test('batch timer is cancelled on dispose', () {
      // Start generation, accumulate tokens
      // Dispose the notifier
      // Verify no late state updates (no "setState after dispose" errors)
    });
  });
}
```

**Note:** These tests need mock `InferenceRepository` and `ChatRepository`. SageHill should check if existing test infrastructure provides these mocks, or create minimal fakes.

---

## Implementation Order

SageHill must follow this sequence:

### Step 1: Verify T-P0 is working
Run the app (or tests) and confirm profiling metrics are being recorded.

### Step 2: Write batching tests
Create `test/features/chat/application/chat_notifier_batching_test.dart`. Tests should fail initially.

### Step 3: Implement token batching (Fix 1)
Modify `chat_notifier.dart` with StringBuffer + Timer batching. Run tests — they should pass.

### Step 4: Add nThreads parameter (Fix 2)
Modify `inference_message.dart` and `inference_isolate.dart`. Verify `ContextParams` API supports nThreads.

### Step 5: Validate
```bash
cd /home/agent/git/bittybot && export PATH="/home/agent/flutter/bin:$PATH"
dart analyze lib/
dart test test/features/chat/application/
dart test test/core/diagnostics/
```

### Step 6: Report profiling results
After on-device testing (Fix 3 and Fix 4), report:
- Model load time (from `[PERF] model_load`)
- TTFT and tokens/sec (from `[PERF] inference_request`)
- Whether batching improved perceived speed
- Whether nThreads tuning made a difference

---

## File Reservations

SageHill should already hold reservations on inference files from T-P0. Additional reservations needed:

```
file_reservation_paths(
  project_key="/home/agent/git/bittybot",
  agent_name="SageHill",
  paths=[
    "lib/features/chat/application/chat_notifier.dart",
    "test/features/chat/application/chat_notifier_batching_test.dart"
  ],
  ttl_seconds=3600,
  exclusive=true,
  reason="T-P4 token batching"
)
```

---

## Acceptance Criteria

### Must-have (code changes):
- [ ] Token batching implemented — state updates every 50ms instead of per-token
- [ ] `StringBuffer` used for token accumulation (no O(n²) string concat)
- [ ] Buffer flushed on DoneResponse, ErrorResponse, new session, and dispose
- [ ] `nThreads` parameter added to `LoadModelCommand` with default of 4
- [ ] `dart analyze lib/` — zero issues
- [ ] Batching unit tests pass

### Measured on device (requires physical phone — may defer):
- [ ] Model load time < 15s (profiling confirms)
- [ ] Time-to-first-token < 2s after send
- [ ] Token generation rate > 5 tokens/sec
- [ ] Main thread frame time stays < 16ms during inference (no jank)
- [ ] Chat input feels responsive (tokens appear smoothly, not stuttery)

### Nice-to-have (if time permits):
- [ ] `nBatch` and `nThreads` tuning results documented
- [ ] Comparison data: chat mode vs translation mode token rates

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Batching timer introduces visible latency in token display | 50ms is imperceptible; user sees ~20 updates/sec which is smooth |
| `StringBuffer` not clearing properly on edge cases | Tests cover all cleanup paths (done, error, new session, dispose) |
| `nThreads=4` may not be optimal for all devices | This is a sensible default; can be tuned later per-device |
| Existing tests may break due to batching timing | Run full test suite before and after; batching is transparent to most tests |
| `ContextParams.nThreads` may not exist in llama_cpp_dart API | SageHill should check API; if not available, skip Fix 2 and note it |
