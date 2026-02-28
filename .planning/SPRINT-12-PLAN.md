# Sprint 12 — Web Fetch Rework

**Date:** 2026-02-28
**Branch:** `master`
**Spec:** `.planning/SPRINT-11-TEST-REPORT.md` → "Web Fetch Rework Spec" section

---

## Goal

Remove the manual "web mode" toggle from Chat. Add automatic URL detection to **both** Chat and Translation screens. Hide scraped content from user bubbles. Use mode-appropriate prompts.

---

## Task Breakdown

### S12-T1: Chat Notifier — Hidden Context Support (Pane 3, RoseFinch)

**File:** `lib/features/chat/application/chat_notifier.dart`

**Change:** Add optional `hiddenContext` parameter to `sendMessage()` and `_processMessage()`.

When `hiddenContext` is non-null:
- Persist the user-visible text (just the URL) to DB as the user message → visible in chat bubble
- Build the LLM prompt using `hiddenContext` instead of the user text
- The model sees the full context (scraped page + instructions), the user sees only the URL

**Specific edits:**
1. `sendMessage(String text)` → `sendMessage(String text, {String? hiddenContext})`
2. `_processMessage(String text)` → `_processMessage(String text, {String? hiddenContext})`
3. Where `sendMessage` calls `_processMessage`, pass through `hiddenContext`
4. Where `sendMessage` queues messages, store hiddenContext with the queue entry (change `_messageQueue` from `Queue<String>` to `Queue<({String text, String? hiddenContext})>`)
5. In `_processMessage`, where the prompt is built for inference, if `hiddenContext != null`, use `hiddenContext` as the prompt content instead of `text`

**Commit:** `feat(chat): [S12-T1] add hidden context support to chat notifier`

---

### S12-T2: Chat Input Bar — Auto URL Detection + Cleanup (Pane 4, RoseFinch, BLOCKED on T1)

**Files:**
- `lib/features/chat/presentation/widgets/chat_input_bar.dart` (edit)
- `lib/features/chat/presentation/widgets/web_mode_indicator.dart` (DELETE)
- `lib/core/l10n/app_*.arb` (10 files — remove obsolete keys)

**Changes to chat_input_bar.dart:**

1. **Remove** the `_isWebMode` state variable (line 33)
2. **Remove** the globe IconButton (lines 126-141 approximately)
3. **Remove** the `WebModeIndicator` widget usage (lines 119-122)
4. **Remove** the import of `web_mode_indicator.dart`
5. **Modify `_onSend()`**: Before calling `chatProvider.sendMessage()`, check if trimmed text starts with `http://` or `https://`. If yes, route to `_handleWebFetch(text)` automatically. If no, route to normal `sendMessage(text)`.
6. **Modify `_handleWebFetch()`**:
   - Keep connectivity check, "Fetching page..." snackbar, `fetchAndExtract()` call, and all error handling
   - Change the message construction: instead of `'[Web: $url]\n\n$prompt\n\n$content'`, construct:
     ```dart
     final hiddenContext = 'The user shared a web page. Here is the page content:\n\n$content\n\nExplain to the user what this page is about. Be concise.';
     ref.read(chatProvider.notifier).sendMessage(url, hiddenContext: hiddenContext);
     ```
   - The user bubble shows ONLY the URL. The hidden context goes to the model.

**Delete:** `lib/features/chat/presentation/widgets/web_mode_indicator.dart` (entire file)

**L10n cleanup (all 10 ARB files):** Remove these keys:
- `webSearchMode` / `@webSearchMode`
- `switchToWebSearch` / `@switchToWebSearch`
- `switchToChat` / `@switchToChat`
- `webSearchInputHint` / `@webSearchInputHint`
- `webSearchPrompt` / `@webSearchPrompt`

Keep these keys (still used for error handling):
- `noInternetConnection`, `fetchingPage`
- `webErrorInvalidUrl`, `webErrorHttpStatus`, `webErrorEmptyContent`, `webErrorNetwork`, `webErrorTimeout`

**Commit:** `feat(chat): [S12-T2] auto URL detection, remove manual web mode toggle`

---

### S12-T3: Translation Side — URL Detection + Web Fetch (Pane 5, WindyRobin)

**Files:**
- `lib/features/translation/application/translation_notifier.dart` (edit)
- `lib/features/translation/presentation/widgets/translation_input_bar.dart` (edit)

**Changes to translation_notifier.dart:**

1. `translate(String text)` → `translate(String text, {String? hiddenContext})`
2. `_processTranslation(String text)` → `_processTranslation(String text, {String? hiddenContext})`
3. Pass `hiddenContext` through from `translate` → `_processTranslation`
4. Update the queue (if translation queues like chat does) to carry hiddenContext
5. In `_processTranslation`, where the prompt is built, if `hiddenContext != null`, use it as the source text for the translation prompt instead of `text`

**Changes to translation_input_bar.dart:**

1. Add imports: `web_fetch_service.dart`, `web_fetch_provider.dart`, `connectivity_plus`
2. Modify `_onSend()`: Check if trimmed text starts with `http://` or `https://`. If yes, route to new `_handleWebFetch(text)` method. If no, existing `translate(text)` call.
3. Add `_handleWebFetch(String url)` method (modeled after chat_input_bar's version):
   - Check connectivity
   - Show "Fetching page..." snackbar
   - Call `webFetchService.fetchAndExtract(url)`
   - Construct hidden context:
     ```dart
     final targetLang = ref.read(translationProvider).targetLanguage;
     final hiddenContext = 'The user shared a web page. Here is the page content:\n\n$content\n\nTranslate the main content of this page to $targetLang. Output ONLY the translation.';
     ref.read(translationProvider.notifier).translate(url, hiddenContext: hiddenContext);
     ```
   - Handle errors with same snackbar pattern as chat

**Commit:** `feat(translation): [S12-T3] add URL detection and web fetch to translation`

---

## Dependency Graph

```
S12-T1 (Pane 3) ──blocks──> S12-T2 (Pane 4)
S12-T3 (Pane 5) ── independent, can start immediately
```

T1 and T3 run in PARALLEL. T2 starts after T1 completes.

---

## Manager Assignments

| Task | Manager | Worker Pane | Blocked By |
|------|---------|-------------|------------|
| S12-T1 | RoseFinch | Pane 3 | — |
| S12-T2 | RoseFinch | Pane 4 | T1 |
| S12-T3 | WindyRobin | Pane 5 | — |

---

## Verification

After all tasks:
```bash
export PATH="/home/agent/flutter/bin:$PATH"
cd /home/agent/git/bittybot
dart analyze lib/
flutter test
```

Both must pass clean.
