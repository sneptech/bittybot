# Sprint 11 — OCR Implementation (Phase A: Core ML Kit)

**Date:** 2026-02-28
**Author:** BlueMountain (Orchestrator)
**Design doc:** `.planning/SPRINT-10-OCR-DESIGN.md`

---

## Goal

Add camera-to-translate: user taps camera button → picks image → ML Kit OCR extracts text → previews with edit → sends to translation input. Fully offline, 5 scripts bundled.

---

## Task Assignment

### RoseFinch (Pane 1) → delegates to Panes 3 + 4

**S11-T1: Dependencies + Android config** (Pane 3)
- Add to `pubspec.yaml` under `# Sprint 11: OCR`:
  ```yaml
  google_mlkit_text_recognition: ^0.15.1
  image_picker: ^1.1.2
  ```
- Add ML Kit native deps to `android/app/build.gradle.kts` — add `dependencies { }` block after `flutter { }`:
  ```kotlin
  dependencies {
      implementation("com.google.mlkit:text-recognition:16.0.1")
      implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
      implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
      implementation("com.google.mlkit:text-recognition-korean:16.0.1")
      implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
  }
  ```
- Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`, after the `flutterEmbedding` meta-data:
  ```xml
  <!-- ML Kit OCR: pre-download models at install -->
  <meta-data
      android:name="com.google.mlkit.vision.DEPENDENCIES"
      android:value="ocr,ocr_chinese,ocr_japanese,ocr_korean,ocr_devanagari" />
  ```
- Run `cd /home/agent/git/bittybot && export PATH="/home/agent/flutter/bin:$PATH" && flutter pub get`
- Run `dart analyze lib/` to verify no issues

**S11-T2: Domain + Application layer** (Pane 4)
- Create `lib/features/ocr/domain/ocr_script.dart`:
  ```dart
  import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

  enum OcrScript {
    latin,
    chinese,
    japanese,
    korean,
    devanagari;

    static OcrScript fromTargetLanguage(String targetLanguage) {
      return switch (targetLanguage.toLowerCase()) {
        'chinese' || 'chinese (simplified)' || 'chinese (traditional)' => OcrScript.chinese,
        'japanese' => OcrScript.japanese,
        'korean' => OcrScript.korean,
        'hindi' || 'marathi' || 'nepali' => OcrScript.devanagari,
        _ => OcrScript.latin,
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
- Create `lib/features/ocr/domain/ocr_result.dart`:
  ```dart
  import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

  class OcrResult {
    const OcrResult({
      required this.imagePath,
      required this.extractedText,
      required this.blocks,
    });

    final String imagePath;
    final String extractedText;
    final List<TextBlock> blocks;
  }
  ```
- Create `lib/features/ocr/application/ocr_notifier.dart`:
  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../domain/ocr_result.dart';
  import '../domain/ocr_script.dart';

  part 'ocr_notifier.g.dart';

  sealed class OcrState {
    const OcrState();
  }

  class OcrIdle extends OcrState {
    const OcrIdle();
  }

  class OcrCapturing extends OcrState {
    const OcrCapturing();
  }

  class OcrProcessing extends OcrState {
    const OcrProcessing();
  }

  class OcrNoTextFound extends OcrState {
    const OcrNoTextFound();
  }

  class OcrComplete extends OcrState {
    const OcrComplete({required this.result});
    final OcrResult result;
  }

  class OcrError extends OcrState {
    const OcrError({required this.message});
    final String message;
  }

  @riverpod
  class OcrNotifier extends _$OcrNotifier {
    TextRecognizer? _recognizer;

    @override
    OcrState build() => const OcrIdle();

    Future<void> captureAndRecognize({
      required ImageSource source,
      required String targetLanguage,
    }) async {
      state = const OcrCapturing();

      try {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (image == null) {
          state = const OcrIdle();
          return;
        }

        state = const OcrProcessing();

        final script = OcrScript.fromTargetLanguage(targetLanguage);
        _recognizer?.close();
        _recognizer = TextRecognizer(script: script.toMlKitScript());
        final inputImage = InputImage.fromFilePath(image.path);
        final recognizedText = await _recognizer!.processImage(inputImage);
        _recognizer!.close();
        _recognizer = null;

        if (recognizedText.text.isEmpty) {
          state = const OcrNoTextFound();
          return;
        }

        state = OcrComplete(
          result: OcrResult(
            imagePath: image.path,
            extractedText: recognizedText.text,
            blocks: recognizedText.blocks,
          ),
        );
      } catch (e) {
        _recognizer?.close();
        _recognizer = null;
        state = OcrError(message: e.toString());
      }
    }

    void reset() {
      _recognizer?.close();
      _recognizer = null;
      state = const OcrIdle();
    }
  }
  ```
- Run codegen: `cd /home/agent/git/bittybot && export PATH="/home/agent/flutter/bin:$PATH" && dart run build_runner build --delete-conflicting-outputs`
- Run `dart analyze lib/` to verify

**S11-T3: OcrCaptureScreen** (Pane 3, after T1)
- Create `lib/features/ocr/presentation/ocr_capture_screen.dart` — full screen that:
  - Takes `imagePath`, `extractedText`, `blocks` as constructor params (passed from OcrComplete state)
  - Shows image preview at top (Image.file, fit BoxFit.contain, max 40% height)
  - Below: editable TextField showing extracted text (multi-line, pre-filled)
  - Bottom: "Translate" ElevatedButton + "Cancel" TextButton
  - On Translate: pops screen and returns the edited text as Navigator result
  - On Cancel: pops with null
  - AppBar title: "Extracted Text" (hardcoded English for now)
  - Use existing AppColors theme

---

### WindyRobin (Pane 2) → delegates to Pane 5

**S11-T4: Camera button + TranslationInputBar wiring** (Pane 5)
- Create `lib/features/ocr/presentation/widgets/camera_button.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../../../core/theme/app_colors.dart';

  class CameraButton extends StatelessWidget {
    const CameraButton({super.key, required this.onPressed, this.enabled = true});

    final VoidCallback onPressed;
    final bool enabled;

    @override
    Widget build(BuildContext context) {
      return IconButton(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.camera_alt),
        color: enabled ? AppColors.secondary : AppColors.onSurfaceVariant,
        tooltip: 'Scan text from image',
      );
    }
  }
  ```
- Edit `lib/features/translation/presentation/widgets/translation_input_bar.dart`:
  1. Add imports at top:
     ```dart
     import 'package:image_picker/image_picker.dart';
     import '../../../ocr/application/ocr_notifier.dart';
     import '../../../ocr/presentation/ocr_capture_screen.dart';
     import '../../../ocr/presentation/widgets/camera_button.dart';
     ```
  2. Add method `_onCamera` in `_TranslationInputBarState`:
     ```dart
     Future<void> _onCamera() async {
       final translationState = ref.read(translationProvider);
       final targetLang = translationState.targetLanguage;

       await ref.read(ocrNotifierProvider.notifier).captureAndRecognize(
         source: ImageSource.camera,
         targetLanguage: targetLang,
       );

       final ocrState = ref.read(ocrNotifierProvider);
       if (ocrState is! OcrComplete) return;

       if (!mounted) return;
       final result = await Navigator.push<String>(
         context,
         MaterialPageRoute(
           builder: (_) => OcrCaptureScreen(
             imagePath: ocrState.result.imagePath,
             extractedText: ocrState.result.extractedText,
             blocks: ocrState.result.blocks,
           ),
         ),
       );

       ref.read(ocrNotifierProvider.notifier).reset();

       if (result != null && result.trim().isNotEmpty) {
         _textController.text = result.trim();
       }
     }
     ```
  3. In the `Row` children, insert `CameraButton` BEFORE the `Expanded` TextField:
     ```dart
     CameraButton(
       onPressed: _onCamera,
       enabled: state.isModelReady && !state.isTranslating,
     ),
     const SizedBox(width: 4),
     ```
     So the row order becomes: CameraButton → SizedBox(4) → Expanded(TextField) → SizedBox(8) → Send/Stop button.

---

## Dependency Order

1. **S11-T1** (deps + Android config) — MUST complete first (flutter pub get needed)
2. **S11-T2** (domain + notifier) — can start after T1 (needs google_mlkit import)
3. **S11-T3** (capture screen) — can start after T2 (needs OcrResult import)
4. **S11-T4** (camera button + wiring) — can start after T2 (needs ocrNotifierProvider import); also needs T3 for OcrCaptureScreen import

**Parallel strategy:**
- Pane 3: T1 → T3 (sequential)
- Pane 4: T2 (after T1 completes, wait for pub get)
- Pane 5: T4 (after T2 + T3 complete)

In practice: RoseFinch dispatches T1 to Pane 3, waits for pub get, then dispatches T2 to Pane 4 and T3 to Pane 3 in parallel. WindyRobin dispatches T4 to Pane 5 after RoseFinch confirms T2+T3 done.

---

## Validation

After all tasks complete:
- `flutter pub get` — clean
- `dart run build_runner build --delete-conflicting-outputs` — generates `ocr_notifier.g.dart`
- `dart analyze lib/` — no issues
- `flutter test` — all existing tests pass (no new tests this sprint)

---

## Files Created (6 new)

| File | Task |
|------|------|
| `lib/features/ocr/domain/ocr_script.dart` | S11-T2 |
| `lib/features/ocr/domain/ocr_result.dart` | S11-T2 |
| `lib/features/ocr/application/ocr_notifier.dart` | S11-T2 |
| `lib/features/ocr/application/ocr_notifier.g.dart` | S11-T2 (generated) |
| `lib/features/ocr/presentation/ocr_capture_screen.dart` | S11-T3 |
| `lib/features/ocr/presentation/widgets/camera_button.dart` | S11-T4 |

## Files Modified (4)

| File | Task |
|------|------|
| `pubspec.yaml` | S11-T1 |
| `android/app/build.gradle.kts` | S11-T1 |
| `android/app/src/main/AndroidManifest.xml` | S11-T1 |
| `lib/features/translation/presentation/widgets/translation_input_bar.dart` | S11-T4 |
