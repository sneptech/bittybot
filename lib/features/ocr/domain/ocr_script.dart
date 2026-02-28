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
    OcrScript.devanagari => TextRecognitionScript.devanagiri,
  };
}
