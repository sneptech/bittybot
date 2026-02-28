# Sprint 8 Retest Report — 2026-02-28

**Branch:** `mowismtest`
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, Exynos 1280
**Model:** Q3_K_S (~1.55 GB), already on device from Sprint 4+
**Build:** debug APK, commits through `03e8708`

---

## Summary

Two S8 polish items tested on device. One new bug discovered.

| Item | Result | Details |
|------|--------|---------|
| S8-T1: Post-clear TTFT (re-fadvise) | **FAIL** | 19.9s / 14.0s (target was ~3-5s) |
| S8-T2: Context reset snackbar/banner | **PASS** | Banner visible on context exhaustion, not on manual new session |
| ErrorResponse auto-reset (S8 base fix) | **PASS** | App recovers, new session starts, model responds |
| **NEW BUG-9** | Translation stuck after context exhaustion | Typing indicator stuck indefinitely, no inference fires |

---

## S8-T1: Post-Clear TTFT — FAIL

**Goal:** After context exhaustion auto-reset, TTFT should drop from 17.2s to ~3-5s via `posix_fadvise(WILLNEED)` re-advise.

**Code verified:** `inference_isolate.dart:185-196` — after `llama.clear()`, closes old advisory fd, re-runs `adviseWillNeed(modelPath, fileLength)`. Code is correct.

**On-device results:**

| Test | Post-Clear TTFT | tok/s | Tokens |
|------|----------------|-------|--------|
| Context reset #1 | **19,936 ms** | 1.14 | 41 |
| Context reset #2 | **13,985 ms** | 1.25 | 31 |

**Baseline comparison:**
- Sprint 8 Report (no re-fadvise): 17,200 ms
- Sprint 8 Retest (with re-fadvise): 14,000–19,900 ms
- Target: 3,000–5,000 ms

**Root cause analysis:** `posix_fadvise(POSIX_FADV_WILLNEED)` is advisory only — the kernel is not obligated to act on it. On this device (5.5 GB RAM, ~2 GB used by model mmap), the kernel's memory pressure from other apps and system services causes page eviction faster than the advisory can maintain residency. The `llama.clear()` call itself doesn't evict pages, but the ~3 minutes of inference before clear allowed enough background activity to evict pages.

**Recommendation:** `posix_fadvise` alone is insufficient for TTFT recovery on this hardware. Options:
1. `mlock()` via FFI (pin model pages — requires checking Android ulimit)
2. Background warmup after clear (sequential read like startup warmup)
3. Accept the ~14-20s post-clear TTFT as a hardware limitation — it's a rare event (only triggers after ~7+ chat messages or ~17+ translations)

---

## S8-T2: Context Reset UX — PASS

**Two UX elements present:**

1. **`ContextFullBanner`** (persistent Material banner from Sprint 7):
   - Text: "Session is getting long. Start a new session for best results."
   - Action: "New session" button
   - Appears at top of screen on context exhaustion
   - **Visible in both Chat and Translation tabs**

2. **`SnackBar`** (Sprint 8 addition):
   - Text: "Conversation was getting long. Started a new chat."
   - Duration: 4 seconds, auto-dismiss
   - Chat tab only (not wired for translation)
   - Note: SnackBar likely appeared and auto-dismissed during testing wait periods; banner was the visible element in screenshots

**False-positive check:** Manually creating a new session via the + icon does NOT show the banner. **PASS** — banner only triggers on context exhaustion auto-reset.

---

## ErrorResponse Auto-Reset — PASS (re-confirmed)

Already verified in Sprint 8 Report, re-confirmed here:

- Context fills after ~443 tokens (chat mode, nPredict=512)
- Next message triggers `ErrorResponse` with "Context full" → `_handleError()` detects it → `startNewSession()` called
- KV cache cleared, new session starts, next message generates a response
- Consistent across 2 test iterations

**Context exhaustion PERF signature:**
```
request_id:1  total_ms:5    ttft_ms:0  token_count:0  (context full - instant)
request_id:4  total_ms:41   ttft_ms:0  token_count:0  (context full - instant)
request_id:22 total_ms:2    ttft_ms:0  token_count:0  (translation context full)
```

---

## NEW BUG-9: Translation Context Exhaustion Recovery Stuck

**Severity: P2**
**Steps to reproduce:**
1. Open Translation tab (Spanish)
2. Send ~17 translations (each ~30-50 tokens context usage)
3. Context exhaustion triggers on ~17th translation (request 22, 0 tokens)
4. `ContextFullBanner` appears correctly
5. Typing indicator (three dots) appears — suggests auto-retry of queued translation
6. **Typing indicator never resolves** — stuck indefinitely (waited 5+ minutes)
7. No new `[PERF] inference_request` event fires
8. Tapping "New session" on banner does not fix it
9. App is not crashed (no ANR, responsive to other taps) but translation is non-functional

**Likely root cause:** `TranslationNotifier._handleError()` calls `startNewSession()` which clears context, but the queued translation message may have been sent to the isolate before the clear completed, or the notifier's `isGenerating` state is not reset properly after the error. The UI shows the typing indicator because `isGenerating: true` was never set back to `false`.

**Files to investigate:**
- `lib/features/translation/application/translation_notifier.dart` — `_handleError()` method, `startNewSession()`, `isGenerating` state management
- `lib/features/inference/data/inference_repository.dart` — `clearContext()` race with pending `generate()` calls

**Workaround:** Force-stop and relaunch the app.

---

## Regression Check — ALL PASS

| Check | Result | Details |
|-------|--------|---------|
| Warm TTFT | **PASS** | 2.65–3.62s (target <5s) |
| tok/s | **PASS** | 2.19–2.52 (hardware ceiling ~2.5) |
| Identity | **PASS** | "I'm Bittybot, your friendly language assistant" |
| Multi-turn recall | **PASS** | "Alex" recalled correctly |
| Markdown rendering | **PASS** | Numbered list rendered as formatted list |
| Token filtering | **PASS** | No raw `<|...|>` tokens in any bubble |
| Translation (pre-exhaustion) | **PASS** | Direct translations, no quotes, no explanations |
| Native splash | **PASS** | Dark splash screen shown on cold start |
| No OOM | **PASS** | App stable through entire test session |
| Frame skips | 202 | Known issue — Flutter/Impeller Vulkan init (not model-related) |

### Warm TTFT Baseline (regression session, 6 messages)

| Request | TTFT (ms) | tok/s | Tokens | Note |
|---------|-----------|-------|--------|------|
| 0 | 13,048 | 1.11 | 22 | Cold (first after model load) |
| 1 | 2,865 | 2.20 | 20 | Warm |
| 2 | 2,652 | 2.47 | 33 | Warm |
| 3 | 3,623 | 2.19 | 28 | Warm |
| 4 | 2,979 | 2.50 | 47 | Warm |
| 5 | 2,860 | 2.52 | 74 | Warm |

**Warm average:** TTFT 2.99s, tok/s 2.38

### Translation Performance (pre-exhaustion, requests 6-21)

| Request | TTFT (ms) | tok/s | Tokens | Note |
|---------|-----------|-------|--------|------|
| 6 | 11,457 | 0.99 | 17 | First after chat context clear (cold) |
| 7 | 5,785 | 1.17 | 11 | Warming |
| 8 | 4,809 | 1.40 | 12 | |
| 9 | 4,470 | 1.60 | 14 | |
| 10 | 4,940 | 1.60 | 15 | |
| 11 | 4,705 | 1.52 | 13 | |
| 12 | 3,066 | 1.19 | 6 | |
| 13 | 3,605 | 1.84 | 15 | |
| 14 | 3,557 | 1.56 | 11 | |
| 15 | 3,277 | 1.01 | 5 | |
| 16 | 5,413 | 1.01 | 8 | |
| 17 | 3,071 | 1.40 | 8 | |
| 18 | 3,708 | 1.70 | 13 | |
| 19 | 2,970 | 1.73 | 11 | |
| 20 | 3,442 | 1.62 | 11 | |
| 21 | 2,801 | 0.36 | 1 | Near context limit |

**Translation warm average (requests 12-20):** TTFT 3.68s, tok/s 1.43

---

## Memory Snapshot

```
TOTAL PSS:  2,052,048 KB (~2.0 GB)
TOTAL RSS:  1,907,823 KB (~1.9 GB)
TOTAL SWAP: 177,750 KB (~174 MB)

Breakdown:
  Native Heap:    78,776 KB (llama.cpp runtime)
  Other mmap:  1,613,739 KB (model file mmap ~1.55 GB)
  Graphics:       50,643 KB (EGL + GL)
  Java Heap:       4,208 KB
  Code:           12,768 KB
  Stack:             580 KB
```

---

## Model Load

| Metric | Value |
|--------|-------|
| Load time (session 1) | 7,379 ms |
| Load time (session 2) | 7,052 ms |
| Frame skips | 202 |

---

## All PERF Events — Session 1 (Context Exhaustion Tests)

```
model_load:      duration_ms=7379
request_id:0     total_ms=176255  ttft_ms=15468  tokens=443  tok/s=2.51  (chat: Tokyo, cold)
request_id:1     total_ms=5       ttft_ms=0      tokens=0    tok/s=0.00  (context full)
request_id:2     total_ms=35937   ttft_ms=19936  tokens=41   tok/s=1.14  (post-clear #1 TTFT)
request_id:3     total_ms=156037  ttft_ms=7150   tokens=391  tok/s=2.51  (chat: Rome)
request_id:4     total_ms=41      ttft_ms=0      tokens=0    tok/s=0.00  (context full)
request_id:5     total_ms=24828   ttft_ms=13985  tokens=31   tok/s=1.25  (post-clear #2 TTFT)
request_id:6-21  (translations, see table above)
request_id:22    total_ms=2       ttft_ms=0      tokens=0    tok/s=0.00  (translation context full)
```

## All PERF Events — Session 2 (Regression Checks)

```
model_load:      duration_ms=7052
request_id:0     total_ms=19807   ttft_ms=13048  tokens=22   tok/s=1.11  (identity, cold)
request_id:1     total_ms=9084    ttft_ms=2865   tokens=20   tok/s=2.20  (name intro)
request_id:2     total_ms=13384   ttft_ms=2652   tokens=33   tok/s=2.47  (name recall)
request_id:3     total_ms=12760   ttft_ms=3623   tokens=28   tok/s=2.19  (fruits list)
request_id:4     total_ms=18801   ttft_ms=2979   tokens=47   tok/s=2.50  (how are you)
request_id:5     total_ms=29341   ttft_ms=2860   tokens=74   tok/s=2.52  (about cats)
```
