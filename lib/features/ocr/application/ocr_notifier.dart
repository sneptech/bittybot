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
