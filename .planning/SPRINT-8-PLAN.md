# Sprint 8 Plan — Post-Clear TTFT Optimization + Context Reset UX

**Date:** 2026-02-28
**Branch:** `mowismtest`
**Basis:** Sprint 8 Report (on-device retest of Sprint 7 + ErrorResponse fix)

---

## Summary

All 8 known bugs are fixed. The app is functionally complete. Sprint 8 addresses two polish items identified during Sprint 8 testing:

1. **Post-context-clear TTFT is 17.2s** — After `clearContext()`, mmap pages are partially evicted. Re-running `posix_fadvise(WILLNEED)` or calling `_warmupModelPages()` after clear should bring recovery TTFT down to ~3-5s.
2. **No user feedback on context reset** — When auto-reset triggers (context exhaustion), the old conversation disappears silently. `isContextFull: true` is set but no UI reads it. Need a snackbar/toast.

---

## Task Assignments

### RoseFinch (Pane 1) → Worker Pane 3: S8-T1 (Post-clear TTFT optimization)

**Goal:** After `clearContext()` triggers on context exhaustion, re-run `posix_fadvise(WILLNEED)` so the next inference doesn't need to re-fault all mmap pages (17.2s → ~3-5s).

**Investigation required — read ALL these files before composing worker instructions:**
- `lib/features/inference/application/inference_isolate.dart` — Find where `posix_fadvise` / `adviseWillNeed()` is called during startup. Find where `ClearContextCommand` is handled. Understand the model path and advisoryFd lifecycle.
- `lib/features/inference/data/native_memory_advisor.dart` — Understand the FFI bindings: `adviseWillNeed(path)` opens the file, calls fadvise, returns fd. `closeNativeFd(fd)` closes it.
- `lib/features/chat/application/chat_notifier.dart` — Find `startNewSession()` and trace what `clearContext()` does (goes through `InferenceRepository` → isolate `ClearContextCommand`).
- `lib/features/inference/data/inference_repository.dart` — Trace `clearContext()` to understand the command flow.

**Key questions to answer before writing worker instructions:**
1. Is the advisory fd from startup still open? If so, does `clearContext()` invalidate it?
2. Can we call `adviseWillNeed()` again from the isolate after clearing context? Or do we need a new command type?
3. Should the re-fadvise happen in the isolate (best) or from the main thread (via repository)?
4. Does `_warmupModelPages()` still exist? Could we call it after clear instead of/in addition to re-fadvise?

**Expected approach (verify by reading code first):**
- In the isolate's `ClearContextCommand` handler, after clearing KV cache (`llama.clear()`), call `adviseWillNeed(modelPath)` to re-advise the kernel. Close the old advisory fd if needed, store the new one.
- This should be non-fatal (try/catch) — context clear must succeed even if re-fadvise fails.

### WindyRobin (Pane 2) → Worker Pane 5: S8-T2 (Context reset snackbar)

**Goal:** When context exhaustion triggers an auto-reset, show a user-visible snackbar: "Conversation was getting long. Started a new chat."

**Investigation required — read ALL these files before composing worker instructions:**
- `lib/features/chat/application/chat_notifier.dart` — Find `isContextFull` in the state. Understand when/where it's set to `true`. Find the state class (likely `ChatState` or similar).
- `lib/features/chat/presentation/chat_screen.dart` — Understand the chat screen widget. Find where state is consumed via `ref.watch()` or `ref.listen()`. This is where the snackbar trigger should go.
- `lib/features/chat/presentation/widgets/` — Check for existing snackbar patterns or notification widgets.
- `lib/features/translation/presentation/translation_screen.dart` — Check if there's a similar pattern for snackbar/feedback that can be reused.

**Key questions to answer before writing worker instructions:**
1. What is the exact state class and field name for `isContextFull`?
2. Is there a `ref.listen()` pattern already in chat_screen.dart that triggers side effects (snackbar, etc.)?
3. Should the snackbar also appear in translation mode? (Check if `TranslationNotifier` also sets `isContextFull`.)
4. What's the exact text? Suggestion: "Conversation was getting long. Started a new chat for best results."
5. Should the snackbar have an action button (e.g., "OK" or "Undo")? Probably just a dismissible info snackbar.

**Expected approach (verify by reading code first):**
- Add a `ref.listen()` on the chat provider in `ChatScreen.build()` that watches for `isContextFull` transitioning from `false` to `true`.
- When detected, show a `SnackBar` with the message.
- Use the app's existing theme colors for the snackbar.
- Reset `isContextFull` after showing (or let the new session's `startNewSession()` handle it).

---

## Process Reminders

**Managers: INVESTIGATE DEEPLY before writing Codex instructions.**
1. Read every file listed above
2. Trace the code flow end-to-end
3. Answer every key question
4. Only THEN compose explicit, complete worker instructions with exact file paths, exact code changes, and exact commands
5. Send worker instructions via `ntm send` (Codex can't read Agent Mail)
6. Review worker output via `git diff`
7. Commit, push, report

**Codex workers cannot read Agent Mail.** All instructions must be in the `ntm send` message. Be explicit: exact file paths, exact line numbers, exact before/after code, exact commands to run.

---

## Commit Style

- `perf(inference): [S8-T1] re-fadvise after context clear for faster recovery`
- `feat(chat): [S8-T2] show snackbar on context reset`
