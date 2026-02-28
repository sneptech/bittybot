# Sprint 9 Plan — BUG-9 Fix + S8-T1 Closure

**Date:** 2026-02-28
**Branch:** `mowismtest`
**Orchestrator:** BlueMountain

---

## Summary

One bug fix (BUG-9) and one item closure (S8-T1 won't-fix).

---

## S9-T1: Fix BUG-9 — Translation stuck after context exhaustion (P2)

**Assigned to:** RoseFinch → Codex worker
**File:** `lib/features/translation/application/translation_notifier.dart`

### Root Cause

`startNewSession()` (line 194-206) does not reset `isTranslating: false`. When `_handleError()` detects a context-full error (line 418-424), it calls `startNewSession()` and returns early — skipping the general error path (line 438-443) that would set `isTranslating: false`. Result: UI typing indicator stuck permanently.

Chat's `startNewSession()` (`chat_notifier.dart:204`) correctly sets `isGenerating: false`. Translation's doesn't.

### Fix

In `startNewSession()`, add `isTranslating: false` to the `copyWith` call:

```dart
Future<void> startNewSession() async {
    _pendingQueue.clear();
    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.clearContext();
    state = state.copyWith(
      sourceText: '',
      translatedText: '',
      isTranslating: false,    // ← ADD THIS LINE
      isContextFull: false,
      turnCount: 0,
      clearActiveSession: true,
      clearActiveRequestId: true,
    );
  }
```

That's the only change needed. One line.

### Validation

- `dart analyze lib/` — must pass with no issues
- `flutter test` — all tests must pass

---

## S8-T1 Closure: Post-clear TTFT — Won't Fix (Hardware Limitation)

**No code changes.** S8-T1 (re-fadvise after context clear) is closed as won't-fix.

**Rationale:** On-device retest showed post-clear TTFT of 14-20s vs target 3-5s. `posix_fadvise(WILLNEED)` is advisory-only; the kernel on this 5.5 GB device ignores it under memory pressure. The code is correct but the hardware can't honor the advisory. This is a rare event (only after ~7+ chat messages or ~17+ translations exhaust nCtx=512).

**Future option:** Background sequential warmup read after clear (like startup warmup) could force page residency, but adds 10-20s of blocking I/O. Not worth it for this edge case.

---

## Post-Fix

After BUG-9 fix:
1. Commit with message: `fix(translation): [BUG-9] reset isTranslating on startNewSession`
2. Push to `origin/mowismtest`
3. Human retests on device
