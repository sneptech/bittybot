# Sprint 10 — OCR Feature Design Plan

**Date:** 2026-02-28
**Author:** WindyRobin (Manager B)
**Status:** DESIGN — awaiting implementation sprint planning

---

## 1. Executive Summary

Add camera-to-translate functionality to BittyBot: users snap a photo of foreign text (signs, menus, documents), OCR extracts the text, and it feeds into the existing translation pipeline. The OCR engine must run fully offline on the Galaxy A25 (5.5 GB RAM) alongside the already-loaded LLM (1.85 GB PSS).

---

## 2. OCR Engine Evaluation

### 2.1 Google ML Kit Text Recognition v2 (RECOMMENDED)

| Dimension | Value |
|-----------|-------|
| **Flutter package** | `google_mlkit_text_recognition` v0.15.1 |
| **Scripts** | Latin (50+ langs), Chinese, Japanese, Korean, Devanagari |
| **Model delivery** | Bundled (~4 MB/script, ~20 MB total for all 5) OR unbundled via Play Services (~260 KB/script app size) |
| **Offline** | Fully offline, zero cloud calls |
| **RAM at inference** | ~11-20 MB additional heap |
| **Speed (mid-range Android)** | 50-300 ms per still image |
| **Min Android SDK** | 21 (declared), 23 (recommended) |
| **Architecture** | 64-bit only (arm64, x86_64) |
| **License** | MIT (Flutter package), Google ML Kit ToS (native SDK) |
| **API** | `TextRecognizer(script:) → processImage(InputImage) → RecognizedText` |
| **Result hierarchy** | RecognizedText → TextBlock → TextLine → TextElement → TextSymbol (with bounding boxes + confidence) |

**Strengths:**
- Negligible RAM impact (~11-20 MB vs 1.85 GB LLM) — no need to unload LLM
- Fast enough for real-time feel (<300 ms)
- Best-maintained Flutter plugin with simple API
- Bundled mode = zero download needed, works immediately
- Bounding box data enables text overlay highlighting

**Weaknesses:**
- Only 5 scripts — no Arabic, Thai, Cyrillic, Hebrew
- Non-Latin scripts require additional native dependencies in build.gradle/Podfile
- Handwriting recognition is limited (printed text only)
- Accuracy degrades below 16px character height

### 2.2 Tesseract OCR

| Dimension | Value |
|-----------|-------|
| **Flutter packages** | `flutter_tesseract_ocr` v0.4.30, `tesseract_ocr` v0.5.0 |
| **Languages** | 119 languages |
| **Model sizes** | tessdata_fast: 1-5 MB/lang; tessdata_best: 11-15 MB/lang |
| **Offline** | Fully offline |
| **RAM at inference** | 100-300 MB peak per recognition call |
| **Speed (mid-range Android)** | 3-8+ seconds per full-page image |
| **License** | Apache 2.0 |

**Strengths:**
- 119 languages covers virtually every script
- Small per-language model files (tessdata_fast)
- Apache 2.0 — no ToS restrictions

**Weaknesses:**
- 10-50x slower than ML Kit on mobile
- 100-300 MB peak RAM — significant with LLM loaded (total ~2.15 GB)
- Poor CJK accuracy vs ML Kit
- Flutter packages are unmaintained/unverified
- No real-time recognition capability
- Accuracy degrades severely on camera photos (optimized for scanned documents)

### 2.3 PaddleOCR (Baidu)

| Dimension | Value |
|-----------|-------|
| **Flutter packages** | `paddle_ocr` v0.0.5 (abandoned April 2021) |
| **Languages** | 80-106 (PP-OCRv4/v5) |
| **Model sizes** | Detection ~4.4 MB + Classification ~2.5 MB + Recognition ~10-15 MB/lang = **16-22 MB total** (mobile INT8 quantized) |
| **Offline** | Fully offline via Paddle-Lite or ONNX Runtime |
| **RAM at inference** | ~16-22 MB base + 10-15 MB per language pack (mobile models) |
| **Speed (mobile)** | ~200 ms on mid-range Android (PP-OCRv4 mobile) |
| **License** | Apache 2.0 |

**Strengths:**
- Best CJK accuracy of the three options
- Covers 80+ languages including Arabic, Cyrillic, Thai (scripts ML Kit lacks)
- Small mobile models (16-22 MB total, comparable to ML Kit)
- Fast on mobile (~200 ms, comparable to ML Kit)
- Apache 2.0 with no ToS restrictions

**Weaknesses:**
- No maintained Flutter package (only option is 5 years abandoned)
- Requires custom integration via ONNX Runtime Flutter package or native FFI
- Mobile deployment path marked "legacy" in PaddleOCR 3.x (but models themselves are production quality)
- Integration cost significantly higher than ML Kit

### 2.4 Decision: Phased Approach — ML Kit (Phase 1) + PaddleOCR (Phase 2)

**Phase 1 (v1.1): Google ML Kit Text Recognition v2**

Ship fast with 5 scripts (Latin, Chinese, Japanese, Korean, Devanagari), zero custom native code. Covers ~80% of BittyBot's 66 translation languages.

Rationale:
1. **Fastest path to shipping.** Well-maintained Flutter package, simple API, no custom native code.
2. **RAM friendly.** 11-20 MB — runs alongside the LLM with no model swapping.
3. **Bundled delivery.** ~20 MB in APK, works immediately offline.

**Phase 2 (v1.2): PaddleOCR via ONNX Runtime**

Add Arabic, Cyrillic, Thai, and other scripts as downloadable language packs. Requires converting PP-OCRv4 mobile models to ONNX format and writing a Dart service layer using the `onnxruntime` Flutter package.

Rationale:
1. **Fills the ML Kit gap.** Arabic, Cyrillic, Thai are important traveler scripts.
2. **Comparable performance.** PP-OCRv4 mobile: ~200ms, 16-22 MB — similar to ML Kit.
3. **Downloadable packs.** Users choose which language packs to install (10-15 MB each).
4. **ONNX Runtime** avoids the abandoned Paddle-Lite Flutter path — uses a maintained runtime.

**Tesseract is not recommended** due to slow speed (3-8s), high RAM (100-300 MB), and poor CJK accuracy. PaddleOCR mobile models outperform it on every dimension.

---

## 3. Model Download UX

### 3.1 Recommended: Bundle All Scripts in APK

Since bundled ML Kit models are only ~4 MB per script (~20 MB total for all 5), **bundle all scripts in the APK**. This eliminates any separate download flow.

**APK size impact:** Current APK is ~10 MB (debug, excluding model). Adding ~20 MB for all 5 OCR scripts is acceptable.

**Implementation:**
- Add all 5 native dependencies to `android/app/build.gradle`:
  ```gradle
  implementation 'com.google.mlkit:text-recognition'         // Latin (default)
  implementation 'com.google.mlkit:text-recognition-chinese'
  implementation 'com.google.mlkit:text-recognition-japanese'
  implementation 'com.google.mlkit:text-recognition-korean'
  implementation 'com.google.mlkit:text-recognition-devanagari'
  ```
- Add to `AndroidManifest.xml` for pre-download at install:
  ```xml
  <meta-data
      android:name="com.google.mlkit.vision.DEPENDENCIES"
      android:value="ocr,ocr_chinese,ocr_japanese,ocr_korean,ocr_devanagari" />
  ```
- iOS: Add corresponding pods to `ios/Podfile`.

### 3.2 Alternative: Unbundled + Settings Download (DEFERRED)

If APK size becomes a concern in the future:
- Ship with Latin only (built-in, ~4 MB)
- Add "OCR Language Packs" section to Settings screen
- Per-pack download via Google Play Services (~260 KB app size impact, model managed by Play Services)
- Show download status, toggle, delete per script

This is overkill for ~20 MB total and can be revisited if non-ML-Kit engines are added later.

---

## 4. Camera → OCR → Translate Flow

### 4.1 User Flow

```
Translation Screen (or Chat Screen)
  │
  ├── User taps 📷 camera button (in input bar)
  │
  ├── image_picker: Take Photo or Pick from Gallery
  │     └── Returns XFile (image path)
  │
  ├── (Optional) Crop/region selection
  │     └── image_cropper package or custom overlay
  │
  ├── OCR Processing (50-300ms)
  │     ├── Auto-detect script (or use target language hint)
  │     ├── TextRecognizer.processImage(InputImage)
  │     └── Extract text from RecognizedText.text
  │
  ├── Preview screen: show image + extracted text
  │     ├── User can edit extracted text
  │     ├── Tap "Translate" → insert into translation input
  │     └── Tap "Cancel" → discard
  │
  └── Text appears in translation input field
        └── User sends for translation (existing flow)
```

### 4.2 Camera Button Placement

**Translation Screen (primary):**
- Add camera icon button to `TranslationInputBar` (next to the send button)
- When input field is empty: show camera button prominently
- When input field has text: camera button still visible but secondary

**Chat Screen (secondary, Phase 2):**
- Add camera icon to `ChatInputBar` for photo → chat workflow
- "Describe what you see in this text" or "Translate this sign"

### 4.3 Script Auto-Detection

ML Kit `TextBlock.recognizedLanguages` returns detected language codes. Strategy:
1. **Default:** Use Latin recognizer (covers most scripts)
2. **Smart detect:** If target translation language is Chinese/Japanese/Korean/Hindi → use the corresponding script recognizer
3. **Fallback:** If Latin recognizer returns empty, try CJK recognizer (user may have pointed at Chinese text while in Latin mode)

### 4.4 Should the LLM Be Unloaded?

**No.** ML Kit uses only ~11-20 MB RAM at inference. The LLM (1.85 GB) stays loaded. Total memory during OCR: ~1.87 GB — well within the ~3.5 GB available on Galaxy A25.

---

## 5. File Structure

```
lib/features/ocr/
├── application/
│   ├── ocr_notifier.dart           # Riverpod notifier: manages OCR state machine
│   └── ocr_notifier.g.dart         # Generated provider
├── domain/
│   ├── ocr_result.dart             # Data class: extracted text, blocks, confidence
│   └── ocr_script.dart             # Enum mapping target languages → ML Kit scripts
└── presentation/
    ├── ocr_capture_screen.dart     # Full-screen: image preview + extracted text + edit
    └── widgets/
        ├── camera_button.dart      # Reusable camera icon for input bars
        └── text_overlay_painter.dart  # CustomPainter for bounding box overlays
```

### New Dependencies (pubspec.yaml)

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.15.1
  image_picker: ^1.1.2       # Camera + gallery image selection
  # Optional (Phase 2):
  # image_cropper: ^8.0.2    # Crop region before OCR
```

### Files Modified

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `google_mlkit_text_recognition`, `image_picker` |
| `android/app/build.gradle` | Add ML Kit text-recognition dependencies (all 5 scripts) |
| `android/app/src/main/AndroidManifest.xml` | Add `com.google.mlkit.vision.DEPENDENCIES` meta-data |
| `ios/Podfile` | Add GoogleMLKit text recognition pods |
| `lib/features/translation/presentation/widgets/translation_input_bar.dart` | Add camera button |
| `lib/features/chat/presentation/widgets/chat_input_bar.dart` | Add camera button (Phase 2) |
| `lib/features/settings/presentation/settings_screen.dart` | Add OCR section (Phase 2, if unbundled) |

---

## 6. OCR Notifier Design

```dart
// lib/features/ocr/application/ocr_notifier.dart

@riverpod
class OcrNotifier extends _$OcrNotifier {
  TextRecognizer? _recognizer;

  @override
  OcrState build() => const OcrState.idle();

  /// Pick image from camera or gallery, then run OCR.
  Future<void> captureAndRecognize({
    required ImageSource source,       // camera or gallery
    required String targetLanguage,    // hint for script selection
  }) async {
    state = const OcrState.capturing();

    // 1. Pick image
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,  // Cap resolution for OCR speed
      maxHeight: 1920,
    );
    if (image == null) {
      state = const OcrState.idle();
      return;
    }

    state = const OcrState.processing();

    // 2. Determine script from target language
    final script = OcrScript.fromTargetLanguage(targetLanguage);

    // 3. Run OCR
    _recognizer?.close();
    _recognizer = TextRecognizer(script: script.toMlKitScript());
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _recognizer!.processImage(inputImage);
    _recognizer!.close();
    _recognizer = null;

    if (recognizedText.text.isEmpty) {
      state = const OcrState.noTextFound();
      return;
    }

    state = OcrState.result(
      imagePath: image.path,
      extractedText: recognizedText.text,
      blocks: recognizedText.blocks,
    );
  }

  /// Clean up native resources.
  @override
  void dispose() {
    _recognizer?.close();
    super.dispose();
  }
}
```

### OcrState sealed class:

```dart
sealed class OcrState {
  const OcrState();
  const factory OcrState.idle() = OcrIdle;
  const factory OcrState.capturing() = OcrCapturing;
  const factory OcrState.processing() = OcrProcessing;
  const factory OcrState.noTextFound() = OcrNoTextFound;
  const factory OcrState.result({
    required String imagePath,
    required String extractedText,
    required List<TextBlock> blocks,
  }) = OcrResult;
}
```

---

## 7. RAM Management Strategy

### No Model Swapping Required

| Component | RAM Usage | When |
|-----------|-----------|------|
| LLM (Aya Q3_K_S) | 1.85 GB PSS | Always loaded |
| ML Kit OCR | ~11-20 MB | During recognition only |
| Camera preview | ~10-30 MB | During capture only |
| Image buffer | ~5-15 MB | Processing only |
| **Total during OCR** | **~1.90 GB** | **Well within 3.5 GB available** |

### Resource Lifecycle

1. `TextRecognizer` created on-demand when user taps camera button
2. `processImage()` runs (50-300ms)
3. `TextRecognizer.close()` called immediately after — releases native ML Kit resources
4. Image file cleaned up after text is extracted (or kept for preview)
5. No persistent memory footprint when OCR is not in use

### If RAM Becomes Tight (Future)

If future features increase base memory usage:
1. Call `TextRecognizer.close()` aggressively after each use (already planned)
2. Reduce image resolution cap (currently 1920x1920)
3. As last resort: unload LLM → run OCR → reload LLM (9-13s reload penalty)

---

## 8. Script-to-Language Mapping

```dart
// lib/features/ocr/domain/ocr_script.dart

enum OcrScript {
  latin,      // Default: English, Spanish, French, German, etc.
  chinese,    // Simplified + Traditional Chinese
  japanese,   // Japanese
  korean,     // Korean
  devanagari; // Hindi, Marathi, Nepali

  /// Map BittyBot target language name → OCR script.
  static OcrScript fromTargetLanguage(String targetLanguage) {
    return switch (targetLanguage.toLowerCase()) {
      'chinese' || 'chinese (simplified)' || 'chinese (traditional)' => OcrScript.chinese,
      'japanese' => OcrScript.japanese,
      'korean' => OcrScript.korean,
      'hindi' || 'marathi' || 'nepali' => OcrScript.devanagari,
      _ => OcrScript.latin,  // Default for all Latin-script languages
    };
  }

  TextRecognitionScript toMlKitScript() => switch (this) {
    OcrScript.latin => TextRecognitionScript.latin,
    OcrScript.chinese => TextRecognitionScript.chinese,
    OcrScript.japanese => TextRecognitionScript.japanese,
    OcrScript.korean => TextRecognitionScript.korean,
    OcrScript.devanagari => TextRecognitionScript.devanagari,
  };
}
```

---

## 9. Implementation Phases

### Phase A: Core OCR with ML Kit (1 sprint, v1.1)
1. Add `google_mlkit_text_recognition` + `image_picker` to pubspec.yaml
2. Add native dependencies to build.gradle + AndroidManifest.xml
3. Create `lib/features/ocr/` directory structure
4. Implement `OcrNotifier` + `OcrState` + `OcrScript`
5. Add camera button to `TranslationInputBar`
6. Create `OcrCaptureScreen` (image preview + extracted text + edit + translate)
7. Wire: camera -> image_picker -> OCR -> extracted text -> translation input

### Phase B: Polish + Chat Integration (1 sprint)
1. Bounding box overlay on preview image (TextBlock corners -> CustomPainter)
2. Add camera button to `ChatInputBar`
3. Script auto-detection fallback (try Latin, then CJK if empty)
4. Add localization keys for OCR UI strings (10 ARB files)
5. On-device testing on Galaxy A25 -- verify RAM, speed, accuracy

### Phase C: PaddleOCR Integration (1-2 sprints, v1.2)
1. Add `onnxruntime` Flutter package to pubspec.yaml
2. Convert PP-OCRv4 mobile models (det + cls + rec) to ONNX format
3. Create `lib/features/ocr/data/paddle_ocr_service.dart` -- ONNX inference wrapper
4. Add OCR Language Packs section to Settings screen (download, toggle, delete per language)
5. Create download flow for PaddleOCR language packs (follow model_distribution pattern)
6. Wire PaddleOCR as fallback for scripts not covered by ML Kit
7. Arabic, Cyrillic, Thai, Hebrew, Armenian, Georgian language packs

### Phase D: Future Enhancements (backlog)
1. Image cropping before OCR (image_cropper package)
2. Batch mode (multiple photos -> combined text)
3. Live camera OCR (real-time viewfinder text detection)
4. Handwriting recognition improvements

---

## 10. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ML Kit not available on Galaxy A25 (no Play Services) | Low | High | Galaxy A25 ships with Play Services. Fallback: bundled models don't require Play Services. |
| OCR accuracy poor on real-world photos | Medium | Medium | Cap image resolution, require good lighting in UI hints, allow manual text editing |
| APK size too large with bundled models | Low | Low | ~20 MB total. If needed, switch to unbundled (Play Services manages storage) |
| Missing Arabic/Thai OCR for travelers | Medium | Medium | Accepted for Phase A (ML Kit). PaddleOCR via ONNX Runtime planned for Phase C to fill the gap. |
| Camera permission denied | Medium | Low | Standard Flutter permission flow, explain why camera is needed |
| Image picker crashes on some devices | Low | Low | Try-catch with fallback error state, use proven image_picker package |

---

## 11. Dependencies & Compatibility

| Dependency | Version | Constraint |
|------------|---------|------------|
| `google_mlkit_text_recognition` | ^0.15.1 | Requires Dart SDK >= 3.8 (we have 3.10.4) |
| `image_picker` | ^1.1.2 | Android + iOS, well-maintained |
| Android `minSdkVersion` | 21 | Already 21 in our build.gradle |
| Android NDK | 29.0.14033849 | No conflict — ML Kit is a Gradle dependency, not NDK |
| `google_mlkit_commons` | Transitive | Shared dependency of ML Kit packages |

No conflicts with existing dependencies (flutter_riverpod 3.1.0, drift 2.31, llama_cpp_dart 0.2.2).

---

## 12. Open Questions for Human Review

1. **Should we bundle all 5 scripts or start with Latin only?** Recommendation: bundle all 5 (~20 MB total, negligible).
2. **Is crop-before-OCR needed for MVP or can it wait for Phase B?** Recommendation: defer to Phase B.
3. **Should the camera button also appear on the Chat screen for MVP?** Recommendation: translation only for Phase A, chat in Phase B.
4. **What UI language should OCR result editing use?** The extracted text is in the source language. The preview screen should show the raw text and let the user edit before sending to translate.
5. **Priority vs nCtx expansion?** nCtx already increased to 2048 in commit d98dcc9. OCR can proceed independently.
