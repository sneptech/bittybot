# Sprint 12 — Web Fetch Rework Test Guide

**For:** Local Claude Code agent running autonomous on-device testing
**Branch:** `master`
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, Exynos 1280
**Commits:** `3e38ce9` (T1), `44c35d8` (T3), `25fbb35` + `3bb1c3f` (T2)

---

## What Changed

Sprint 12 reworked the web fetch feature across both Chat and Translation screens:

1. **Removed** the manual "web mode" toggle (globe button) from Chat
2. **Added** automatic URL detection — if the user sends a message starting with `http://` or `https://`, the app auto-detects it as a URL
3. **Hidden context** — scraped page content is NOT shown in the user's chat bubble. The user sees only the URL; the model receives the full scraped content + mode-appropriate prompt
4. **Added** web fetch to Translation screen (previously only available in Chat)
5. **Deleted** `web_mode_indicator.dart` widget
6. **Cleaned** 5 obsolete l10n key pairs from all 10 locale ARB files

### Files Changed
- `lib/features/chat/application/chat_notifier.dart` — added `hiddenContext` param to `sendMessage()` / `_processMessage()`
- `lib/features/chat/presentation/widgets/chat_input_bar.dart` — removed web mode toggle, added auto URL detection
- `lib/features/chat/presentation/widgets/web_mode_indicator.dart` — **DELETED**
- `lib/features/translation/application/translation_notifier.dart` — added `hiddenContext` param to `translate()` / `_processTranslation()`
- `lib/features/translation/presentation/widgets/translation_input_bar.dart` — added URL detection + `_handleWebFetch()`
- `lib/core/l10n/app_*.arb` (10 files) — removed obsolete web mode keys
- `lib/core/l10n/app_localizations*.dart` — regenerated

### Unchanged
- `lib/features/chat/data/web_fetch_service.dart` — no changes (still works the same)

---

## Build & Install

```bash
cd /home/agent/git/bittybot && git pull origin master
export PATH="/home/agent/flutter/bin:$PATH"
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Model is already on device (no re-download needed).

---

## Test Checklist

### TEST-1: Globe Button Removed

**Steps:**
1. Open the app → navigate to Chat screen

**Expected:**
- [ ] No globe/language icon button visible in the chat input bar
- [ ] No "Web mode" indicator chip anywhere
- [ ] Input bar shows: text field + send button (and camera button if on Translation screen)
- [ ] Layout is clean, no empty space where the globe button used to be

**Failure indicators:** Globe button still visible, WebModeIndicator chip appears, layout has gap/hole.

---

### TEST-2: Chat — Auto URL Detection

**Steps:**
1. Navigate to Chat screen
2. Ensure device has internet connectivity
3. Type or paste `https://example.com` into the input field
4. Tap Send

**Expected:**
- [ ] User chat bubble shows ONLY the URL: "https://example.com" (NOT the scraped page content)
- [ ] Brief loading indicator appears (snackbar "Fetching page...")
- [ ] AI response bubble appears with a concise explanation of the page content (e.g., "This is a placeholder web page maintained by IANA...")
- [ ] AI response does NOT start with "[Web: ...]" prefix
- [ ] Response is coherent and relates to the actual page content

**Failure indicators:** Scraped content visible in user bubble, `[Web: ...]` prefix in AI bubble, no fetch attempted, crash.

---

### TEST-3: Chat — Normal Text (Non-URL) Still Works

**Steps:**
1. On Chat screen, type "What is the capital of France?" (a normal non-URL message)
2. Tap Send

**Expected:**
- [ ] Message sent normally — no web fetch triggered
- [ ] Model responds with a normal chat answer
- [ ] No "Fetching page..." snackbar

**Failure indicators:** Normal text incorrectly treated as URL, web fetch triggered on non-URL text.

---

### TEST-4: Translation — Auto URL Detection

**Steps:**
1. Navigate to Translation screen
2. Set target language to French (or any non-English language)
3. Ensure device has internet connectivity
4. Type or paste `https://example.com` into the input field
5. Tap Send

**Expected:**
- [ ] User bubble shows ONLY the URL: "https://example.com"
- [ ] Brief loading indicator (snackbar "Fetching page...")
- [ ] AI response contains a TRANSLATION of the page content into the target language
- [ ] Response is translation only (no explanation, no English, just the translated content)
- [ ] Response does NOT start with "[Web: ...]" prefix

**Failure indicators:** URL not detected, normal translation of the literal string "https://example.com", scraped content visible in user bubble, response in English instead of target language.

---

### TEST-5: Translation — Normal Text Still Works

**Steps:**
1. On Translation screen, type "Good morning" (normal text)
2. Tap Send

**Expected:**
- [ ] Normal translation, no web fetch
- [ ] Translates to target language as usual

---

### TEST-6: Error Handling — No Internet

**Steps:**
1. Disable WiFi and mobile data on the device
2. On either Chat or Translation, paste a URL and tap Send

**Expected:**
- [ ] Snackbar shows "No internet connection"
- [ ] No message sent to the model
- [ ] No crash

**Steps (restore):**
3. Re-enable internet connectivity

---

### TEST-7: Error Handling — Invalid / Unreachable URL

**Steps:**
1. Ensure internet is connected
2. On Chat screen, type `https://thisdomaindoesnotexist12345.com` and tap Send

**Expected:**
- [ ] Error snackbar appears (network error or timeout)
- [ ] No message sent to the model
- [ ] Input is not cleared (user can retry)

---

### TEST-8: Error Handling — Empty Page

**Steps:**
1. Find a URL that returns valid HTTP but has no extractable text content
2. Paste it and tap Send

**Expected:**
- [ ] Snackbar shows "No text content found on this page"
- [ ] No message sent to the model

---

### TEST-9: Edge Cases

#### 9a: URL with `http://` (not https)
1. Paste `http://example.com` and send

**Expected:**
- [ ] Auto-detected as URL, web fetch triggered, works same as https

#### 9b: Text starting with "http" but not a URL
1. Type `https is a protocol` and send

**Expected:**
- [ ] Treated as URL (starts with `https`), web fetch attempted, error handling gracefully catches the invalid URL
- [ ] This is acceptable behavior — the detection is intentionally simple (`startsWith`)

#### 9c: URL with trailing whitespace
1. Paste `  https://example.com  ` (with spaces) and send

**Expected:**
- [ ] Trimmed, detected as URL, works correctly

---

### TEST-10: Regression — Existing Features

After exercising web fetch, verify these still work:

- [ ] Chat — normal multi-turn conversation
- [ ] Translation — normal text translation with streaming
- [ ] Language picker — opens, selects, resets session
- [ ] OCR camera button — visible on Translation screen, opens camera, extracts text (Sprint 11)
- [ ] Splash screen — dark background with icon on cold start
- [ ] Context full handling — still works (hard to trigger with nCtx=2048, may skip)

---

### TEST-11: Performance

**Steps:**
1. Use `adb shell dumpsys meminfo com.bittybot.bittybot` before and after web fetch
2. Measure time from Send tap to AI response start (TTFT for web fetch)

**Expected:**
- [ ] No significant RAM increase from web fetch (HTTP request is lightweight)
- [ ] Total time = fetch time + model TTFT (fetch should be <2s for simple pages)
- [ ] Model tok/s unchanged from Sprint 11 baseline (~2.5 tok/s)

---

## What Is NOT in This Sprint (Deferred)

Do NOT file bugs for these:

- No progress spinner in AI bubble while fetching (just snackbar) — future polish
- No URL validation beyond `startsWith('http')` — intentionally simple
- No multi-URL support (only first URL in message) — not needed
- No link preview / favicon / page title extraction — future feature
- OCR Phase B items (bounding boxes, chat camera button, script fallback, l10n) — separate sprint

---

## Reporting

Write results to `.planning/SPRINT-12-TEST-REPORT.md` using this format:

```markdown
# Sprint 12 — Web Fetch Rework Test Report

**Date:** YYYY-MM-DD
**Device:** Galaxy A25, Android 14
**Branch:** master
**Commits:** 3e38ce9, 44c35d8, 25fbb35, 3bb1c3f

## Results

| Test | Result | Notes |
|------|--------|-------|
| TEST-1 Globe removed | PASS/FAIL | ... |
| TEST-2 Chat URL detection | PASS/FAIL | ... |
| TEST-3 Chat normal text | PASS/FAIL | ... |
| TEST-4 Translation URL detection | PASS/FAIL | ... |
| TEST-5 Translation normal text | PASS/FAIL | ... |
| TEST-6 No internet | PASS/FAIL | ... |
| TEST-7 Invalid URL | PASS/FAIL | ... |
| TEST-8 Empty page | PASS/FAIL | ... |
| TEST-9a http:// | PASS/FAIL | ... |
| TEST-9b Non-URL http text | PASS/FAIL | ... |
| TEST-9c Trailing whitespace | PASS/FAIL | ... |
| TEST-10 Regression | PASS/FAIL | ... |
| TEST-11 Performance | PASS/FAIL | ... |

## Performance Readings

| Metric | Value | Notes |
|--------|-------|-------|
| Web fetch time (example.com) | ... | Time from send to AI response start |
| Chat TTFT (warm, after fetch) | ... | Should match Sprint 11 baseline |
| tok/s | ... | Should be ~2.5 |
| PSS (after fetch) | ... | Should match baseline |

## Bugs Found

(list any bugs with severity, steps to reproduce, expected vs actual)
```
