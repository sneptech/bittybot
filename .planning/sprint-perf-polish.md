# Sprint: Performance & Polish

**Started:** 2026-02-27
**Trigger:** On-device testing revealed 6 issues
**Goal:** Make the app snappy, filter raw tokens, fix UX, add profiling for TDD

## Issues from On-Device Testing

| # | Issue | Severity | Category |
|---|-------|----------|----------|
| 1 | Download progress bar oscillates back and forth | HIGH | Bug |
| 2 | Chat input unresponsive for ~10s after model download | CRITICAL | Performance |
| 3 | Model responses glacially slow (was fast in translation testing) | CRITICAL | Performance |
| 4 | Raw special tokens visible (`\|<START_RESPONSE>\|`) | HIGH | Bug |
| 5 | Generic bot icon instead of BittyBot logo on download screen | LOW | UX |
| 6 | Need profiling/monitoring infrastructure for TDD | HIGH | Infra |

## Task Breakdown

### T-P0: Profiling & Monitoring Infrastructure
**Assigned to:** SwiftSpring (plan) → SageHill (implement)
**Priority:** FIRST — all performance work depends on this
**Files:**
- NEW: `lib/core/diagnostics/performance_monitor.dart`
- NEW: `lib/core/diagnostics/inference_profiler.dart`
- MODIFY: `lib/features/inference/application/inference_isolate.dart` (add timing events)
- MODIFY: `lib/features/inference/application/llm_service.dart` (add timing events)
- NEW: `test/core/diagnostics/performance_monitor_test.dart`

**Requirements:**
- Track model load time (start→ModelReadyResponse)
- Track per-request inference: time-to-first-token, tokens/sec, total time
- Track download progress callback frequency and values
- Output must be readable by monitoring tooling (structured log or file)
- Use Flutter `Timeline` events for DevTools integration
- Add a debug overlay or log endpoint that local Claude Code can query
- TDD: write tests first, then implement

**Acceptance:**
- `dart analyze lib/` clean
- Unit tests pass for profiling hooks
- Model load time measurable
- Token generation rate measurable

---

### T-P1: Filter Special Tokens from Output
**Assigned to:** PearlBadger (implement) → RoseFinch (review)
**Priority:** HIGH — quick fix
**Files:**
- MODIFY: `lib/features/inference/application/inference_isolate.dart`
- NEW: `test/features/inference/application/token_filter_test.dart`

**Problem:** Raw Aya special tokens like `<|START_OF_TURN_TOKEN|>`, `<|END_OF_TURN_TOKEN|>`, `<|CHATBOT_TOKEN|>`, `<|USER_TOKEN|>`, and any `<|...|>` pattern are shown to the user in chat output.

**Fix:**
- In `inference_isolate.dart`, before sending `TokenResponse` to main isolate, filter the token:
  ```dart
  // Strip Aya special tokens from output
  static final _specialTokenPattern = RegExp(r'<\|[A-Z_]+\|>');

  String _filterToken(String token) {
    return token.replaceAll(_specialTokenPattern, '');
  }
  ```
- Apply filter before `mainSendPort.send(TokenResponse(...))`
- If filtered result is empty string, skip sending that token
- Also filter any `|<...>|` variant pattern (user reported `|<START_RESPONSE>|`)

**TDD:**
- Write test: special tokens are stripped
- Write test: normal text passes through unchanged
- Write test: mixed token+text is cleaned (e.g., `<|END_OF_TURN_TOKEN|>Hello` → `Hello`)
- Write test: empty result after filtering is not sent

---

### T-P2: Replace Bot Icon with BittyBot Logo
**Assigned to:** TopazPond (implement) → RoseFinch (review)
**Priority:** LOW — quick fix
**Files:**
- MODIFY: `pubspec.yaml` (add `- assets/icon.png` to assets list)
- MODIFY: `lib/features/model_distribution/widgets/download_screen.dart` (replace `_buildLogo`)

**Current code** (download_screen.dart ~line 94-98):
```dart
Widget _buildLogo() {
  // TODO: Replace placeholder with Image.asset() when a logo asset is added.
  return Icon(Icons.smart_toy, size: 80, color: AppColors.onSurfaceVariant);
}
```

**Fix:**
```dart
Widget _buildLogo() {
  return Image.asset(
    'assets/icon.png',
    width: 80,
    height: 80,
  );
}
```

**Also:** Add to `pubspec.yaml` assets section:
```yaml
assets:
  - assets/google_fonts/
  - assets/icon.png
```

---

### T-P3: Fix Download Progress Bar Oscillation
**Assigned to:** PearlBadger (after T-P1) → RoseFinch (review)
**Priority:** HIGH
**Files:**
- MODIFY: `lib/features/model_distribution/application/model_distribution_notifier.dart`
- NEW: `test/features/model_distribution/progress_callback_test.dart`

**Problem:** Progress bar jumps between actual progress and ~30% of that value every other second.

**Investigation points:**
- `_onProgressCallback(TaskProgressUpdate update)` — is `update.progress` oscillating?
- Is SharedPreferences `_lastPersistedProgress` being read back and overwriting live progress?
- Is the `background_downloader` reporting from multiple download tasks?
- Is state being rebuilt from persisted progress during active download?

**Likely fix:**
- Add monotonic progress enforcement: `if (newProgress < state.progressFraction) return;`
- Or add a progress smoothing/debounce: only update state if progress increased
- Add logging to track raw callback values

**TDD:**
- Test: progress never decreases
- Test: rapid callbacks don't cause oscillation
- Test: resume from persisted progress works correctly

---

### T-P4: Fix Main Thread Blocking & Slow Inference
**Assigned to:** SageHill (after T-P0) → SwiftSpring (review)
**Priority:** CRITICAL
**Files:**
- MODIFY: `lib/features/inference/application/llm_service.dart`
- MODIFY: `lib/features/inference/application/inference_isolate.dart`
- MODIFY: `lib/features/chat/application/chat_notifier.dart`
- POSSIBLY: `lib/features/inference/application/llm_service_provider.dart`

**Problem 1 — Input delay:** After model download completes, tapping the chat input does nothing for ~10s. This suggests model loading blocks the main thread OR the `ModelGateWidget` holds the input disabled too long.

**Problem 2 — Slow inference:** Responses are glacially slow despite being fast in earlier translation testing (nPredict=128). Chat uses nPredict=512, but that should only affect max length, not speed.

**Investigation:**
1. Profile model load: is any part synchronous on main thread before isolate spawn?
2. Profile `LlmService.start()`: what happens between calling start and ModelReadyResponse?
3. Check if `Llama()` constructor or `ModelParams` setup does synchronous work
4. Profile token generation: measure tokens/sec and compare with translation mode
5. Check if KV cache or context size parameters differ between chat and translation
6. Check if the isolate communication (SendPort/ReceivePort) has latency
7. Check if UI rebuilds per-token are causing jank (should profile with DevTools)

**Potential fixes:**
- Move any synchronous model prep to the isolate
- Reduce UI rebuild frequency (batch token updates, e.g., update state every 50ms instead of per-token)
- Check `nBatch` and `nCtx` parameters — may need tuning for chat mode
- Verify `use_mmap=false` isn't causing excessive I/O
- Consider `nThreads` parameter optimization for the device

**TDD (using T-P0 profiling):**
- Model load time < 15s (acceptable for 2GB model on mid-range phone)
- Time-to-first-token < 2s after send
- Token generation rate > 5 tokens/sec
- Main thread frame time stays < 16ms during inference

---

## Task Dependencies

```
T-P0 (Profiling) ──┐
                    ├── T-P4 (Performance: blocking + slow inference)
                    │
T-P1 (Token filter) ─── independent, parallel
T-P2 (Bot icon) ──────── independent, parallel
T-P3 (Progress bar) ──── can start parallel, profiling helps but not required
```

## Agent Assignments

| Task | Worker | Review Manager | Panes |
|------|--------|---------------|-------|
| T-P0 | SageHill | SwiftSpring | 5 → 2 |
| T-P1 | PearlBadger | RoseFinch | 3 → 1 |
| T-P2 | TopazPond | RoseFinch | 4 → 1 |
| T-P3 | PearlBadger (after T-P1) | RoseFinch | 3 → 1 |
| T-P4 | SageHill (after T-P0) | SwiftSpring | 5 → 2 |

## File Reservations

| Agent | Files | Reason |
|-------|-------|--------|
| PearlBadger | `lib/features/inference/application/inference_isolate.dart`, `lib/features/model_distribution/application/model_distribution_notifier.dart` | T-P1, T-P3 |
| TopazPond | `pubspec.yaml`, `lib/features/model_distribution/widgets/download_screen.dart` | T-P2 |
| SageHill | `lib/core/diagnostics/**`, `lib/features/inference/application/llm_service.dart`, `lib/features/chat/application/chat_notifier.dart` | T-P0, T-P4 |

## Success Criteria

1. No special tokens visible in chat or translation output
2. BittyBot logo shown on download screen
3. Download progress bar moves monotonically forward
4. Chat input responsive within 1-2s of model load
5. Token generation rate comparable to earlier translation testing
6. All fixes have unit tests
7. Profiling data readable by monitoring tooling
8. `dart analyze lib/` — zero issues
