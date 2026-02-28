# S11-T4 Instructions for SageHill (Pane 5)

## Setup
```bash
cd /home/agent/git/bittybot && git pull origin master
```

Register with Agent Mail as SageHill:
```
register_agent(project_key="/home/agent/git/bittybot", program="codex-cli", model="gpt-5.2-codex", name="SageHill", task_description="S11-T4: camera button + translation_input_bar wiring")
```

## FILE 1: CREATE NEW FILE

Create: `lib/features/ocr/presentation/widgets/camera_button.dart`

First create the directory:
```bash
mkdir -p lib/features/ocr/presentation/widgets
```

Write this EXACT content:
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

## FILE 2: EDIT EXISTING FILE

Edit: `lib/features/translation/presentation/widgets/translation_input_bar.dart`

### EDIT 1: Add 4 new imports

After line 6 (after `import '../../application/translation_notifier.dart';`), add these 4 lines:

```dart
import 'package:image_picker/image_picker.dart';
import '../../../ocr/application/ocr_notifier.dart';
import '../../../ocr/presentation/ocr_capture_screen.dart';
import '../../../ocr/presentation/widgets/camera_button.dart';
```

### EDIT 2: Add _onCamera method

After the `_onStop` method (after line 46, after its closing brace), add:

```dart
  Future<void> _onCamera() async {
    final translationState = ref.read(translationProvider);
    final targetLang = translationState.targetLanguage;

    await ref.read(ocrProvider.notifier).captureAndRecognize(
      source: ImageSource.camera,
      targetLanguage: targetLang,
    );

    final ocrState = ref.read(ocrProvider);
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

    ref.read(ocrProvider.notifier).reset();

    if (result != null && result.trim().isNotEmpty) {
      _textController.text = result.trim();
    }
  }
```

### EDIT 3: Insert CameraButton in Row

In the Row children (around line 64), insert 2 widgets BEFORE the `Expanded` widget.

Current code:
```dart
              children: [
                Expanded(
```

Change to:
```dart
              children: [
                CameraButton(
                  onPressed: _onCamera,
                  enabled: state.isModelReady && !state.isTranslating,
                ),
                const SizedBox(width: 4),
                Expanded(
```

Row order becomes: CameraButton, SizedBox(4), Expanded(TextField), SizedBox(8), Send/Stop button.

## CRITICAL NOTE

The provider name is `ocrProvider` (NOT `ocrNotifierProvider`). This follows the riverpod codegen pattern: ChatNotifier -> chatProvider, TranslationNotifier -> translationProvider, OcrNotifier -> ocrProvider.

## Validation

```bash
export PATH="/home/agent/flutter/bin:$PATH"
dart analyze lib/
```

Should show: No issues found!

## After Done

Report back via Agent Mail to WindyRobin with the diff output.
