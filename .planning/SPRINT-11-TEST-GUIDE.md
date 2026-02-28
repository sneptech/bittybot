# Sprint 11 — OCR Feature Test Guide

**For:** Local Claude Code agent running autonomous on-device testing
**Branch:** `master`
**Device:** Samsung Galaxy A25 (SM-A256E), Android 14, 5.5 GB RAM, Exynos 1280
**Commits:** `828dafe` (T1-T3), `3935405` (T4), `cc8e971` (cleanup)

---

## What Was Added

Sprint 11 implements OCR Phase A: camera-to-translate using Google ML Kit Text Recognition v2. Users tap a camera button on the Translation screen, take a photo of text, ML Kit extracts the text offline, user previews/edits it, then sends it to translation.

### New Files (6)
- `lib/features/ocr/domain/ocr_script.dart` — enum mapping languages to ML Kit scripts
- `lib/features/ocr/domain/ocr_result.dart` — data class for OCR results
- `lib/features/ocr/application/ocr_notifier.dart` — Riverpod notifier managing OCR state machine
- `lib/features/ocr/application/ocr_notifier.g.dart` — generated provider
- `lib/features/ocr/presentation/ocr_capture_screen.dart` — preview screen with image + editable text
- `lib/features/ocr/presentation/widgets/camera_button.dart` — camera icon button widget

### Modified Files (4)
- `pubspec.yaml` — added `google_mlkit_text_recognition: ^0.15.1`, `image_picker: ^1.1.2`
- `android/app/build.gradle.kts` — added ML Kit native deps (all 5 scripts)
- `android/app/src/main/AndroidManifest.xml` — added `com.google.mlkit.vision.DEPENDENCIES` meta-data
- `lib/features/translation/presentation/widgets/translation_input_bar.dart` — added camera button + OCR wiring

---

## Build & Install

```bash
cd /home/agent/git/bittybot && git pull origin master
export PATH="/home/agent/flutter/bin:$PATH"
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Model is already on device (Aya Expanse Q3_K_S, no re-download needed).

---

## Test Checklist

### TEST-1: Camera Button Visibility and State

**Steps:**
1. Open the app → navigate to Translation screen
2. Wait for model to load (status indicator shows ready)

**Expected:**
- [ ] Camera button (camera_alt icon) is visible to the LEFT of the text input field
- [ ] Camera button is ENABLED (AppColors.secondary color) when model is ready
- [ ] Camera button is DISABLED (greyed out) while model is loading
- [ ] Camera button is DISABLED during active translation (while streaming)
- [ ] Layout is correct: Camera → TextField → Send/Stop, no overflow or clipping

**Failure indicators:** Button missing, button overlapping text field, button enabled before model ready.

---

### TEST-2: Camera Capture → OCR → Preview (Latin Script)

**Steps:**
1. Set target language to any Latin-script language (English, Spanish, French, etc.)
2. Tap the camera button
3. Take a photo of printed English text (book page, sign, screen, packaging)
4. Wait for OCR processing

**Expected:**
- [ ] image_picker opens camera view successfully
- [ ] After capture, OcrCaptureScreen appears with:
  - Image preview at top (≤40% screen height, contained fit)
  - Extracted text in editable TextField below
  - "Cancel" and "Translate" buttons at bottom
- [ ] OCR processing completes in <300ms (should feel instant)
- [ ] Extracted text is reasonably accurate for printed text
- [ ] Text is editable — user can correct OCR errors

**Failure indicators:** Camera fails to open, black screen, crash after capture, empty text on clear image, processing takes >2 seconds.

---

### TEST-3: Preview → Translate Flow

**Steps:**
1. Complete TEST-2 (have OCR preview screen open with extracted text)
2. Optionally edit the extracted text
3. Tap "Translate"

**Expected:**
- [ ] Screen pops back to Translation screen
- [ ] Extracted (or edited) text appears in the translation input field
- [ ] Text is ready to send — user can tap Send to translate it
- [ ] No duplicate text or garbled content

**Steps (Cancel path):**
1. Complete TEST-2
2. Tap "Cancel" instead

**Expected:**
- [ ] Screen pops back to Translation screen
- [ ] Input field is UNCHANGED (no text inserted)

**Failure indicators:** Text not populated after Translate, text populated after Cancel, navigation crash.

---

### TEST-4: CJK Script Recognition

**Steps:**
1. Set target language to Chinese (Simplified or Traditional)
2. Tap camera button → photograph Chinese text
3. Repeat with Japanese (set target to Japanese) and Korean (set target to Korean)

**Expected:**
- [ ] Chinese text recognized with correct script recognizer
- [ ] Japanese text recognized (kanji + kana)
- [ ] Korean text recognized (hangul)
- [ ] Script selection is automatic based on target language

**Note:** The correct ML Kit script is selected via `OcrScript.fromTargetLanguage()` based on the current target translation language. If target is Chinese → Chinese recognizer is used, etc.

**Failure indicators:** CJK text returns empty/garbage, Latin recognizer used for CJK text, crash on non-Latin script.

---

### TEST-5: Devanagari Script Recognition

**Steps:**
1. Set target language to Hindi
2. Tap camera button → photograph Hindi/Devanagari text

**Expected:**
- [ ] Devanagari text recognized
- [ ] No crash (the ML Kit enum uses `devanagiri` — already handled in code)

**Failure indicators:** Crash on Devanagari, empty result on clear Devanagari text.

---

### TEST-6: Edge Cases

#### 6a: Cancel Image Picker
1. Tap camera button
2. Press back / cancel WITHOUT taking a photo

**Expected:**
- [ ] Returns to Translation screen normally
- [ ] No crash, no state corruption
- [ ] Camera button still works for next attempt

#### 6b: No Text in Image
1. Tap camera button
2. Take a photo of something with NO text (blank wall, sky, solid color)

**Expected:**
- [ ] Handles gracefully — either shows empty preview or "no text found" state
- [ ] No crash

#### 6c: Poor Quality Image
1. Tap camera button
2. Take a blurry photo or photo of very small text (<16px character height)

**Expected:**
- [ ] May return partial/garbled text — this is acceptable
- [ ] No crash or freeze
- [ ] User can edit the text in preview before translating

#### 6d: Very Long Extracted Text
1. Photograph a full page of dense text

**Expected:**
- [ ] All text appears in the editable field
- [ ] TextField is scrollable
- [ ] No truncation or overflow
- [ ] Translate button still works with long text

---

### TEST-7: RAM and Stability

**Steps:**
1. Use `adb shell dumpsys meminfo com.bittybot.bittybot` before and after OCR
2. Perform 3-5 OCR captures in succession
3. After OCR, send a normal translation to verify LLM is still loaded

**Expected:**
- [ ] RAM increase during OCR is minimal (~11-20 MB, temporary)
- [ ] RAM returns to baseline after OCR completes (TextRecognizer is closed)
- [ ] LLM stays loaded — no reload needed after OCR
- [ ] Translation works normally after OCR usage
- [ ] No OOM crash after repeated OCR captures
- [ ] App does not freeze or ANR during OCR processing

**Failure indicators:** LLM unloaded, translation fails after OCR, app crash, sustained memory increase after multiple OCR uses.

---

### TEST-8: Regression — Existing Features

After exercising the OCR feature, verify these still work:

- [ ] Chat screen — send message, receive streaming response
- [ ] Translation — type text, translate, see streaming result
- [ ] Language picker — opens, selects language, resets session
- [ ] Context full banner — appears when context approaches limit
- [ ] Web fetch — paste URL in chat, content fetched and summarized
- [ ] Splash screen — dark background with icon on cold start

---

## What Is NOT in This Sprint (Phase B / Future)

Do NOT file bugs for these — they are intentionally deferred:

- No bounding box overlay on the preview image (Phase B)
- No camera button on Chat screen (Phase B)
- No automatic script fallback (try Latin then CJK if empty) (Phase B)
- No localized UI strings — "Extracted Text", "Cancel", "Translate", "Edit extracted text..." are hardcoded English (Phase B)
- No image cropping before OCR (Phase D)
- No batch mode / multiple photos (Phase D)
- No live camera OCR / viewfinder (Phase D)

---

## Reporting

Write results to `.planning/SPRINT-11-TEST-REPORT.md` using this format:

```markdown
# Sprint 11 — OCR Test Report

**Date:** YYYY-MM-DD
**Device:** Galaxy A25, Android 14
**Branch:** master
**Commit:** cc8e971

## Results

| Test | Result | Notes |
|------|--------|-------|
| TEST-1 Camera button | PASS/FAIL | ... |
| TEST-2 Latin OCR | PASS/FAIL | ... |
| TEST-3 Preview flow | PASS/FAIL | ... |
| TEST-4 CJK scripts | PASS/FAIL | ... |
| TEST-5 Devanagari | PASS/FAIL | ... |
| TEST-6a Cancel picker | PASS/FAIL | ... |
| TEST-6b No text | PASS/FAIL | ... |
| TEST-6c Poor quality | PASS/FAIL | ... |
| TEST-6d Long text | PASS/FAIL | ... |
| TEST-7 RAM/stability | PASS/FAIL | ... |
| TEST-8 Regression | PASS/FAIL | ... |

## Memory Readings

| Moment | PSS (MB) | Notes |
|--------|----------|-------|
| Before OCR | ... | Baseline with LLM loaded |
| During OCR | ... | Peak during recognition |
| After OCR | ... | Should return to baseline |

## Bugs Found

### BUG-XX: Title
- **Severity:** Critical/High/Medium/Low
- **Steps to reproduce:** ...
- **Expected:** ...
- **Actual:** ...
- **Logs:** (adb logcat output if relevant)

## OCR Accuracy Observations

| Script | Source Material | Accuracy | Notes |
|--------|---------------|----------|-------|
| Latin | ... | Good/Fair/Poor | ... |
| Chinese | ... | Good/Fair/Poor | ... |
| Japanese | ... | Good/Fair/Poor | ... |
| Korean | ... | Good/Fair/Poor | ... |
| Devanagari | ... | Good/Fair/Poor | ... |
```
