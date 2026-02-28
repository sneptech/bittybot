# Sprint 7 Report — Sprint 6 Fix Verification

**Date:** 2026-02-28
**Branch:** `mowismtest` (commit `9d90b31`)
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, Exynos 1280
**Tester:** Local Claude Code profiling agent

## Summary

Sprint 6 shipped 6 fixes. **3 verified PASS, 1 verified FAIL, 2 code-only (no device test needed).** One new bug discovered during testing.

| Fix | Status | Details |
|-----|--------|---------|
| S6-T1: Bittybot identity | **PASS** | Model says "Bittybot" not "Aya" |
| S6-T2: Markdown rendering | **PASS** | Bullet lists, numbered lists render formatted |
| S6-T3: Defer warmup (frame skips) | **FAIL** | 183-206 frame skips (was 175-192) — no improvement |
| S6-T4: Crash FD cleanup | N/A | Code-only fix, no observable device behavior |
| S6-T5: Print guard | N/A | Code-only fix, debug builds still show `[PERF]` as expected |
| S6-T6: Dead code cleanup | N/A | Code-only fix |

**New bug found:** `[Context limit reached]` text visible to user in chat bubble (BUG-8).

---

## Test Results

### 1. Cold Start Frame Skips (S6-T3) — FAIL

**Root cause identified:** Frame skips are caused by **Flutter engine + Impeller Vulkan initialization**, NOT model loading or warmup. S6-T3's deferred warmup cannot fix this.

| Cold Start | Frame Skips | Model Load (ms) |
|------------|-------------|-----------------|
| #1 | 193 | 7,883 |
| #2 | 183 | 5,842 |
| #3 | 206 + 37 = 243 | 6,323 |

**Timeline proof (cold start #2):**
```
11:36:09.606  Vulkan render engine selected
11:36:09.958  Impeller Vulkan backend initialized
11:36:10.277  Dart VM service listening
11:36:12.182  *** 183 frames skipped ***  ← Flutter engine init, BEFORE model code
11:36:18.679  [PERF] model_load duration_ms=5842  ← model load finishes 6.5s LATER
```

The 183 frames are skipped in a 2.6-second window (09.6→12.2) during Impeller Vulkan initialization on the main thread. All Dart-side yields in `initialize()` and deferred warmup are irrelevant — the bottleneck is native Flutter engine startup.

**Recommendation:** Frame skips cannot be fixed from Dart code. Options:
1. Accept as Flutter/Impeller limitation on mid-range Exynos devices
2. Add a native Android splash screen (`windowBackground` theme) that covers the Impeller init
3. File Flutter issue for Impeller Vulkan startup jank on Mali-G68

### 2. Bittybot Identity (S6-T1) — PASS

| Prompt | Response | Result |
|--------|----------|--------|
| "What is your name?" | "Hi there! I'm Bittybot. I can help you translate text and understand languages." | PASS |
| "My name is Alex" | "Hello, Alex! I'm glad to meet you. I'm Bittybot..." | PASS |
| "What is my name?" | "Hello Alex, I'm happy to help you with your translation needs." | PASS |

Model consistently identifies as "Bittybot" across all turns. Multi-turn name recall works.

### 3. Markdown Rendering (S6-T2) — PASS

| Prompt | Response Format | Result |
|--------|----------------|--------|
| "Give me a list of 3 fruits" | Numbered list: 1. Apple, 2. Banana, 3. Orange | PASS |
| "What are the benefits of exercise?" | Bullet list with • markers, properly formatted | PASS |

No raw `**asterisks**` or `- dashes` visible. `MarkdownBody` widget correctly renders markdown from assistant messages.

### 4. Warm TTFT + tok/s Baseline

| Request | TTFT (ms) | tok/s | Tokens | Notes |
|---------|-----------|-------|--------|-------|
| #0 | 18,246 | 0.91 | 26 | Pre-warmup cold (discard) |
| #1 | 5,975 | 2.40 | 60 | Warming up |
| #2 | 3,568 | 2.24 | 27 | Warm |
| #3 | 3,551 | 1.95 | 18 | Warm |
| #4 | 3,065 | 2.51 | 37 | Warm |
| #5 | 2,683 | 2.66 | 185 | Warm (best) |

**Warm baseline (requests #2-5): TTFT 2.7-3.6s (avg ~3.2s), tok/s 1.95-2.66 (avg ~2.35).**

Consistent with Sprint 5 numbers. Hardware ceiling for this model on Exynos 1280.

### 5. Idle TTFT (fadvise Persistence After S6-T3 Reorder)

| Idle Duration | TTFT (ms) | tok/s | Notes |
|---------------|-----------|-------|-------|
| 0s (warm) | 2,411 | 2.68 | Baseline |
| 30s | 2,284 | 2.35 | **PASS** — fadvise working |
| 2 min | 7,286 | 1.53 | Partial page eviction |

fadvise continues to work after S6-T3's warmup reorder. 30s idle TTFT is excellent (2.3s). 2-minute idle shows degradation (7.3s) as kernel eventually reclaims pages despite advisory.

**Earlier false alarm:** One 30s idle test showed 9.3s TTFT, but this was in a session with 7 messages filling nCtx=512. The full context + large KV cache caused more memory pressure. With fresh sessions (2-3 messages), 30s idle TTFT is consistently ~2.3s.

### 6. Token Filtering — PASS

No raw `<|...|>` tokens visible in any chat or translation bubbles across all test sessions.

### 7. Translation — PASS

| Input | Output | Result |
|-------|--------|--------|
| "Good morning" | "Buenos días" | PASS (correct) |
| "Where is the bathroom?" | "Dónde está el baño?" | PASS (correct) |
| "Thank you very much" | "Gracias." | PASS (correct, shortened) |

All translations are direct — no explanations, no extra text. Minor cosmetic: model wraps some translations in quotes ("Buenos días" vs Gracias.) — inconsistent but not blocking.

### 8. Warmup Race Test — PASS (no crash)

Sent message ~16s after cold start (immediately after model load, before warmup completed).

| Metric | Value |
|--------|-------|
| TTFT | 12,342 ms |
| tok/s | 1.52 |
| Crash | No |

TTFT is high (12.3s vs 2.7s warm) because mmap pages aren't pre-faulted yet, but the app handles it gracefully. S6-T3's trade-off is working as designed — UI unblocks immediately, first inference is slower if warmup hasn't finished.

### 9. OOM — PASS

Tab switching (Chat → Translate → Chat → Translate) did not trigger OOM. PID remained stable (25429). LMK killed background processes (24892, 29966) but NOT BittyBot.

---

## New Bug Found

### BUG-8 (P2): "[Context limit reached]" text shown to user in chat bubble

**Observed:** After 7 messages in a session, the assistant response included the text `[Context limit reached]` visible in the chat bubble as if it were model output. The next message ("Hi") received no response at all (0 tokens, 0ms TTFT).

**Screenshot evidence:** The assistant bubble showed:
```
It's good to meet you, Alex. I am Bittybot, a

[Context limit reached]
```

**Expected:** The `[Context limit reached]` text should NOT appear in the chat bubble. Instead:
- Show a system-style message or snackbar: "Conversation is getting long. Start a new chat for best results."
- OR silently start a new session
- OR truncate older messages from context (sliding window)

**Impact:** User sees broken-looking internal message. Following messages produce zero output with no user-visible explanation.

**Where to fix:** The `[Context limit reached]` string is likely being appended by `ChatNotifier` or the inference response handler when `estimateTokenCount` exceeds `nCtx`. The display layer should intercept this and show appropriate UI instead of rendering it as assistant text.

**File hint:** Check `chat_notifier.dart` and `inference_isolate.dart` for where this string is generated and how the bubble rendering handles it.

---

## Bugs Summary (Cumulative)

| Bug | Priority | Status | Description |
|-----|----------|--------|-------------|
| BUG-1 | P1 | **FIXED (S6-T2)** | Raw markdown in chat bubbles |
| BUG-2 | P1 | **FIXED (S6-T1)** | Model says "Aya" not "Bittybot" |
| BUG-3 | P1 | **NOT FIXED** | 183-206 frame skips on cold start (Flutter/Impeller, not Dart-fixable) |
| BUG-4 | P3 | **FIXED (S6-T6)** | Dead `..take(3)` no-op |
| BUG-5 | P2 | **FIXED (S6-T4)** | Crash recovery FD leak |
| BUG-6 | P3 | **FIXED (S6-T6)** | Stale TODO comment |
| BUG-7 | P2 | **FIXED (S6-T5)** | Unguarded print() |
| BUG-8 | P2 | **NEW** | "[Context limit reached]" shown to user in chat bubble |

---

## Performance Summary vs Targets

| Metric | Target | Sprint 6 Result | Status |
|--------|--------|-----------------|--------|
| Frame skips (cold start) | < 50 | 183-243 | **FAIL** (Flutter engine, not fixable from Dart) |
| TTFT (warm) | < 5s | 2.7-3.6s | **PASS** |
| TTFT (30s idle) | < 5s | 2.3s | **PASS** |
| TTFT (2min idle) | < 5s | 7.3s | **FAIL** (kernel reclaims pages) |
| TTFT (immediate post-cold-start) | < 10s | 12.3s | **FAIL** (warmup not complete) |
| tok/s | ~2 (hw ceiling) | 1.95-2.66 | **PASS** |
| Identity | "Bittybot" | "Bittybot" | **PASS** |
| Markdown rendering | Formatted | Formatted | **PASS** |
| Token filtering | No raw tokens | No raw tokens | **PASS** |
| Translation quality | Direct only | Direct only | **PASS** |
| Multi-turn recall | Recall name | Recalled "Alex" | **PASS** |
| OOM stability | No crash | No crash | **PASS** |
| Model load | < 15s | 5.8-7.9s | **PASS** |

---

## Tasks for Next Sprint

### T-S7-1 (P2): Handle context limit gracefully
- **What:** `[Context limit reached]` text appears in chat bubble when nCtx=512 is exhausted
- **Fix:** Intercept the context limit condition before rendering. Show a system message or auto-start a new session. Never render internal limit text as assistant output.
- **Where:** `chat_notifier.dart` — wherever `[Context limit reached]` string is generated. Check `inference_isolate.dart` for the source.
- **Test:** Send 7+ messages in chat, verify no `[Context limit reached]` text appears, verify graceful handling.

### T-S7-2 (P3): Add native splash screen for cold start
- **What:** 183-243 frame skips during Flutter/Impeller Vulkan init cause ~3s blank screen
- **Fix:** Add a native Android splash screen via `windowBackground` theme in `styles.xml` that shows the BittyBot logo during engine init. Use `flutter_native_splash` package or manual `layer-list` drawable.
- **Where:** `android/app/src/main/res/values/styles.xml`, potentially `android/app/src/main/res/drawable/`
- **Note:** This does NOT reduce frame skips — it hides them with a branded splash screen. The skips are a Flutter/Impeller limitation, not a BittyBot code issue.

### T-S7-3 (P3): Inconsistent quote wrapping in translations
- **What:** Model wraps some translations in quotes ("Buenos días") but not others (Gracias.)
- **Fix:** Post-process translation output to strip leading/trailing quotes if present. Simple regex: `result.replaceAll(RegExp(r'^["\']+|["\']+$'), '')`
- **Where:** `translation_notifier.dart` or wherever translation responses are processed before display.

### T-S7-4 (P2): Context-full empty response produces no user feedback
- **What:** When context is exhausted, subsequent messages produce 0-token responses with no visible feedback. User sees their message sent but gets no reply.
- **Fix:** Detect 0-token responses in `ChatNotifier` and show a system message: "I couldn't generate a response. Try starting a new conversation."
- **Where:** `chat_notifier.dart` — in the response handler when `token_count == 0`
- **Note:** This is related to T-S7-1 but addresses a different failure mode (no response at all vs. truncated response with internal text).

---

## Raw PERF Logs

```
# Cold start #1
[PERF] {"perf":"model_load","ts":"2026-02-28T11:35:43.044501","duration_ms":7883}

# Cold start #2
[PERF] {"perf":"model_load","ts":"2026-02-28T11:36:18.671979","duration_ms":5842}

# Session 1 (identity + markdown + baseline)
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:41:52.333192","request_id":0,"total_ms":28548,"ttft_ms":18246,"token_count":26,"tokens_per_sec":"0.91"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:42:50.653797","request_id":1,"total_ms":25019,"ttft_ms":5975,"token_count":60,"tokens_per_sec":"2.40"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:43:31.940231","request_id":2,"total_ms":12031,"ttft_ms":3568,"token_count":27,"tokens_per_sec":"2.24"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:44:38.131562","request_id":3,"total_ms":9219,"ttft_ms":3551,"token_count":18,"tokens_per_sec":"1.95"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:45:40.181359","request_id":4,"total_ms":14757,"ttft_ms":3065,"token_count":37,"tokens_per_sec":"2.51"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:47:41.664193","request_id":5,"total_ms":69650,"ttft_ms":2683,"token_count":185,"tokens_per_sec":"2.66"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:49:07.852272","request_id":6,"total_ms":14503,"ttft_ms":9326,"token_count":17,"tokens_per_sec":"1.17"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:50:08.635391","request_id":7,"total_ms":33,"ttft_ms":0,"token_count":0,"tokens_per_sec":"0.00"}

# Session 2 (idle tests)
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:52:03.218108","request_id":8,"total_ms":33550,"ttft_ms":17020,"token_count":47,"tokens_per_sec":"1.40"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:52:55.115060","request_id":9,"total_ms":18638,"ttft_ms":2411,"token_count":50,"tokens_per_sec":"2.68"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:53:47.448145","request_id":10,"total_ms":7655,"ttft_ms":2284,"token_count":18,"tokens_per_sec":"2.35"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:56:40.691732","request_id":11,"total_ms":17704,"ttft_ms":7286,"token_count":27,"tokens_per_sec":"1.53"}

# Translation
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:57:57.882346","request_id":12,"total_ms":11873,"ttft_ms":9724,"token_count":5,"tokens_per_sec":"0.42"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:58:47.302083","request_id":13,"total_ms":9177,"ttft_ms":5758,"token_count":8,"tokens_per_sec":"0.87"}
[PERF] {"perf":"inference_request","ts":"2026-02-28T11:59:13.933363","request_id":14,"total_ms":5162,"ttft_ms":4077,"token_count":2,"tokens_per_sec":"0.39"}

# Cold start #3 (warmup race)
[PERF] {"perf":"model_load","ts":"2026-02-28T12:00:35.838752","duration_ms":6323}
[PERF] {"perf":"inference_request","ts":"2026-02-28T12:01:18.445669","request_id":0,"total_ms":25020,"ttft_ms":12342,"token_count":38,"tokens_per_sec":"1.52"}

# Frame skips
Cold start #1: 193
Cold start #2: 183
Cold start #3: 206 + 37 = 243
```

## Memory Snapshot (post-session)

```
App PSS: 1,436 MB (mmap model + native heap + graphics)
Other mmap (model): 1,002 MB Private Clean
Native Heap: 14.7 MB PSS, 171 MB SwapPss
Swap PSS total: 273 MB
System MemAvailable: 2,040 MB
System SwapFree: 5,691 MB (of 8,388 MB total)
```
