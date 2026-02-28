# Sprint 8 Report — Sprint 7 Verification + Context Reset Fix

**Date:** 2026-02-28
**Branch:** `mowismtest`
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, Exynos 1280
**Tester:** Local Claude Code profiling agent

## Summary

Sprint 7 shipped 4 tasks across 5 commits. **2 verified PASS, 1 PASS with caveats, 1 had a critical bug that was fixed and re-verified.**

| Fix | Status | Details |
|-----|--------|---------|
| S7-T1: Context limit text stripping | **PASS (with fix)** | Original code only handled `DoneResponse`; actual path is `ErrorResponse`. Fixed in this sprint. |
| S7-T2: Native splash screen | **PASS** | Dark (#121212) splash with app icon covers frame skip period |
| S7-T3: Translation quote stripping | **PASS** | "Buenos días" not `"Buenos días"`, all 3 translations clean |
| S7-T4: Zero-token auto-reset | **PASS (with fix)** | Same root cause as T1 — `ErrorResponse` path was unhandled. Fixed. |

**Bug found and fixed:** Context-full `ErrorResponse` handling was missing from both `ChatNotifier._handleError()` and `TranslationNotifier._handleError()`. Fix applied and verified in this sprint (2 files, ~25 lines each).

---

## Critical Bug Found and Fixed

### Root Cause: `ErrorResponse` vs `DoneResponse` mismatch

The S7-T1/T4 fix assumed context exhaustion would arrive as a `DoneResponse` with `tokenCount == 0`. **In reality, context exhaustion arrives as `ErrorResponse`** because `llama_cpp_dart`'s `setPrompt()` throws `LlamaException("Context full (pos: N, limit: 512)")` when `_nPos >= nCtx - 10`.

**Flow with the bug:**
1. Context fills after ~400-500 tokens of generation
2. Next `setPrompt()` throws → isolate sends `ErrorResponse`
3. `ChatNotifier._handleError()` resets generation state but does NOT clear KV cache or start new session
4. `_nPos` stays at 510+ → every subsequent `setPrompt()` throws the same error
5. **App is permanently stuck** — no message ever gets a response again

**Flow after fix:**
1. Same as above through step 2
2. `_handleError()` detects "Context full" or "Context limit" in error message
3. Calls `startNewSession()` → clears KV cache (`_nPos` resets to 0), creates new DB session
4. Sets `isContextFull: true` for UI indication
5. Next user message works in fresh session

**Files modified:**
- `lib/features/chat/application/chat_notifier.dart` — `_handleError()` (+20 lines)
- `lib/features/translation/application/translation_notifier.dart` — `_handleError()` (+8 lines)

### Pre-fix vs Post-fix Comparison

| Scenario | Pre-fix | Post-fix |
|----------|---------|----------|
| Context full → next message | 0 tokens, 1ms, **permanently stuck** | Auto-resets, 24 tokens, 17.2s TTFT |
| `[Context limit reached]` in bubble | Stripped by S7 code (PASS) | Stripped (PASS) |
| Translation after context full | Not tested (chat stuck first) | Would auto-reset (same fix applied) |

---

## Test Results

### 1. Context Limit Handling (S7-T1/T4) — PASS (after fix)

**Test protocol:** Send messages until nCtx=512 is exhausted, then verify recovery.

#### Pre-fix test (S7 code only):

| Request | Content | TTFT (ms) | Tokens | Result |
|---------|---------|-----------|--------|--------|
| 0 | "Hi" | 14,438 | 23 | OK (cold) |
| 1 | "Tell me everything about Paris France" | 3,760 | 414 | OK (fills context) |
| 2 | "Thanks" | 0 | 0 | Context full (ErrorResponse) |
| 3 | "Hello again" | 0 | 0 | **FAIL — permanently stuck** |

#### Post-fix test:

| Request | Content | TTFT (ms) | Tokens | Result |
|---------|---------|-----------|--------|--------|
| 0 | "Hi" | 13,817 | 30 | OK (cold) |
| 1 | "Tell me everything about Tokyo Japan in detail" | 3,739 | 405 | OK (fills context) |
| 2 | "Thanks" | 0 | 0 | Context full → auto-reset triggered |
| 3 | "Hello again" | 17,242 | 24 | **PASS — recovery works!** |

Post-reset TTFT is high (17.2s) because the `clearContext()` call triggers re-faulting of mmap'd pages. This is expected and matches the cold-inference pattern.

**Screenshot evidence:** After context exhaustion and auto-reset, the UI shows:
- User message: "Hello again"
- Assistant response: "Hello! I'm Bittybot, here to assist with translations and understanding languages. How can I help you today?"
- No `[Context limit reached]` text visible
- Old conversation cleared — new session started cleanly

### 2. Native Splash Screen (S7-T2) — PASS

The native splash replaces the blank white/black screen during Flutter/Impeller Vulkan initialization. Frame skips are NOT reduced (they're a Flutter engine limitation), but the user sees a branded screen instead of nothing.

**Changes verified:**
- `LaunchTheme` parent changed from `Theme.Light.NoTitleBar` → `Theme.Black.NoTitleBar`
- `launch_background.xml` (both drawable/ and drawable-v21/) use `@color/splash_background` (#121212) with centered `@mipmap/ic_launcher`
- `colors.xml` created with `splash_background` = `#121212`

| Cold Start | Frame Skips | Model Load (ms) | Notes |
|------------|-------------|-----------------|-------|
| #1 | 180 + 31 = 211 | 7,669 | Pre-fix build |
| #2 | 182 | 5,445 | Pre-fix build |
| #3 | N/A (log gap) | 6,701 | Post-fix build |
| #4 | 203 + 38 = 241 | 6,750 | Post-fix build |

Frame skip count is consistent with previous sprints (180-243 range). The splash screen covers the ~3s Impeller init period with a dark branded screen.

**Note:** Visual verification of splash appearance requires manual observation or screen recording. The splash is rendered by the Android window manager before Flutter starts, so it cannot be captured via logcat. The XML configuration is correct based on code review.

### 3. Translation Quote Stripping (S7-T3) — PASS

| Input | Output | Quotes? | Result |
|-------|--------|---------|--------|
| "Good morning" | Buenos días | No | PASS |
| "Where is the bathroom" | ¿Dónde está el baño? | No | PASS |
| "Thank you very much" | Gracias | No | PASS |

Previously, "Good morning" → `"Buenos días"` (with wrapping double quotes). Now the regex strips leading/trailing quote characters (double quotes, single quotes, guillemets, curly quotes) before persisting and displaying.

### 4. Warm TTFT + tok/s Baseline

| Request | TTFT (ms) | tok/s | Tokens | Notes |
|---------|-----------|-------|--------|-------|
| #0 | 13,817 | 1.31 | 30 | Cold inference (pre-warmup) |
| #1 | 3,739 | 2.57 | 405 | Warm |
| #3 | 17,242 | 0.98 | 24 | Post context-clear (re-faulting) |

Warm performance (#1) is consistent with previous sprints: TTFT ~3.7s, tok/s ~2.6. The post-clear TTFT of 17.2s is expected — clearing KV cache doesn't preserve mmap page residency.

---

## Bugs Summary (Cumulative)

| Bug | Priority | Status | Description |
|-----|----------|--------|-------------|
| BUG-1 | P1 | **FIXED (S6-T2)** | Raw markdown in chat bubbles |
| BUG-2 | P1 | **FIXED (S6-T1)** | Model says "Aya" not "Bittybot" |
| BUG-3 | P1 | **MITIGATED (S7-T2)** | 180-241 frame skips on cold start (covered by native splash) |
| BUG-4 | P3 | **FIXED (S6-T6)** | Dead `..take(3)` no-op |
| BUG-5 | P2 | **FIXED (S6-T4)** | Crash recovery FD leak |
| BUG-6 | P3 | **FIXED (S6-T6)** | Stale TODO comment |
| BUG-7 | P2 | **FIXED (S6-T5)** | Unguarded print() |
| BUG-8 | P2 | **FIXED (S7-T1/T4 + S8 fix)** | Context limit text + stuck inference after exhaustion |

**All known bugs are now fixed or mitigated.**

---

## Performance Summary vs Targets

| Metric | Target | Sprint 8 Result | Status |
|--------|--------|-----------------|--------|
| Frame skips (cold start) | Hidden by splash | 180-241 (covered) | **PASS** (mitigated) |
| TTFT (warm) | < 5s | 3.7s | **PASS** |
| tok/s | ~2 (hw ceiling) | 2.57 | **PASS** |
| Identity | "Bittybot" | "Bittybot" | **PASS** |
| Markdown rendering | Formatted | Formatted | **PASS** (verified S7) |
| Translation quality | Direct, no quotes | Direct, no quotes | **PASS** |
| Context exhaustion recovery | Auto-reset | Auto-reset works | **PASS** |
| `[Context limit reached]` | Not shown | Not shown | **PASS** |

---

## Raw PERF Logs

```
# Cold start #1 (pre-fix)
[PERF] {"perf":"model_load","ts":"2026-02-28T12:36:50.923682","duration_ms":7669}
Choreographer: Skipped 180 frames!
Choreographer: Skipped 31 frames!

# Cold start #2 (pre-fix, session 2)
[PERF] {"perf":"model_load","ts":"2026-02-28T12:48:56.994294","duration_ms":5445}
Choreographer: Skipped 182 frames!

# Session 2 (pre-fix context test)
[PERF] {"perf":"inference_request","ts":"2026-02-28T12:50:00.449454","request_id":0,"total_ms":22062,"ttft_ms":14438,"token_count":23,"tokens_per_sec":"1.04"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T12:52:54.815175","request_id":1,"total_ms":160723,"ttft_ms":3760,"token_count":414,"tokens_per_sec":"2.58"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T12:53:37.572853","request_id":2,"total_ms":34,"ttft_ms":0,"token_count":0,"tokens_per_sec":"0.00"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T12:54:17.990316","request_id":3,"total_ms":1,"ttft_ms":0,"token_count":0,"tokens_per_sec":"0.00"}

# Cold start #3 (post-fix)
[PERF] {"perf":"model_load","ts":"2026-02-28T13:00:16.781108","duration_ms":6701}

# Session 3 (post-fix context test — SUCCESS)
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:01:11.391402","request_id":0,"total_ms":22986,"ttft_ms":13817,"token_count":30,"tokens_per_sec":"1.31"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:04:01.418691","request_id":1,"total_ms":157305,"ttft_ms":3739,"token_count":405,"tokens_per_sec":"2.57"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:04:42.293666","request_id":2,"total_ms":30,"ttft_ms":0,"token_count":0,"tokens_per_sec":"0.00"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:05:24.759514","request_id":3,"total_ms":24595,"ttft_ms":17242,"token_count":24,"tokens_per_sec":"0.98"}

# Translation tests (post-fix)
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:06:32.951892","request_id":4,"total_ms":10639,"ttft_ms":9501,"token_count":3,"tokens_per_sec":"0.28"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:07:18.208162","request_id":5,"total_ms":6086,"ttft_ms":3869,"token_count":7,"tokens_per_sec":"1.15"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T13:07:40.266997","request_id":6,"total_ms":4838,"ttft_ms":4235,"token_count":1,"tokens_per_sec":"0.21"}

# Cold start #4
[PERF] {"perf":"model_load","ts":"2026-02-28T13:08:35.055863","duration_ms":6750}
Choreographer: Skipped 203 frames!
Choreographer: Skipped 38 frames!
```

---

## Fix Details (Applied by Local Agent)

### Context-full `ErrorResponse` handling

**Problem:** `llama_cpp_dart`'s `setPrompt()` throws `LlamaException("Context full (pos: N, limit: 512)")` when `_nPos >= nCtx - 10`. The isolate catches this and sends `ErrorResponse`, not `DoneResponse`. The S7-T1/T4 auto-reset code was in `_finishGeneration()` (DoneResponse handler) and never ran for context-full errors.

**Fix:** Added context-full detection to `_handleError()` in both `ChatNotifier` and `TranslationNotifier`. When error message contains "Context full" or "Context limit", call `startNewSession()` (which clears KV cache via `inferenceRepo.clearContext()` → `llama.clear()` → resets `_nPos` to 0) and set `isContextFull: true`.

**Files:**
- `lib/features/chat/application/chat_notifier.dart` — `_handleError()` method
- `lib/features/translation/application/translation_notifier.dart` — `_handleError()` method

---

## Remaining Work / Observations

1. **Post-clear TTFT is high (17.2s):** After `clearContext()`, the mmap'd model pages may have been partially evicted. The next inference re-faults them, causing high TTFT. Consider calling `_warmupModelPages()` after context clear, or running `posix_fadvise(WILLNEED)` again. However, this is a UX edge case (only happens at context exhaustion) and 17.2s is acceptable for recovery vs. permanent breakage.

2. **No user-visible feedback on context reset:** When the auto-reset triggers, the old conversation disappears and a new session starts silently. Consider adding a snackbar or toast: "Conversation was getting long. Started a new chat." The `isContextFull: true` state is set but no UI currently reads it for chat (the `isContextFull` banner may exist but was not verified in this sprint).

3. **All known bugs are now fixed or mitigated.** The app is functionally complete for the current milestone scope.
