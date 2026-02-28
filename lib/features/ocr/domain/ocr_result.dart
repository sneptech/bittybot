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
