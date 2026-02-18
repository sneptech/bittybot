import 'dart:io';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';

/// Result returned by [ModelLoader.loadModel].
class ModelLoadResult {
  /// True when the model was successfully initialised.
  final bool loaded;

  /// Non-null when llama.cpp reported an architecture-related error.
  /// Indicates the bundled llama.cpp version does not support the Cohere2
  /// architecture and the binding choice must be reconsidered.
  final String? architectureError;

  /// Basic model metadata, available when [loaded] is true.
  final ModelInfo? modelInfo;

  ModelLoadResult({
    required this.loaded,
    this.architectureError,
    this.modelInfo,
  });
}

/// Basic metadata about the loaded model.
class ModelInfo {
  /// Context size the model was initialised with.
  final int contextSize;

  /// Absolute path to the GGUF file on device.
  final String modelPath;

  ModelInfo({required this.contextSize, required this.modelPath});
}

/// Shared helper for Phase 1 spike integration tests.
///
/// Resolves the on-device model file, creates a [Llama] instance with minimal
/// context (512 tokens) to reduce memory pressure on 4 GB phones, and exposes
/// complete and streaming generation methods.
///
/// **Pre-requisite:** The GGUF model must be placed on the device before running
/// the integration tests:
/// - Android: `adb push tiny-aya-global-q4_k_m.gguf /sdcard/Download/`
///   (loader copies it to the app documents directory automatically)
/// - iOS: Use Xcode Device Manager to copy to the app's Documents folder.
class ModelLoader {
  static const String _modelFilename = 'tiny-aya-global-q4_k_m.gguf';

  /// Context size kept intentionally small to reduce memory pressure on devices
  /// with 4 GB RAM.
  static const int _nCtx = 512;

  /// Maximum tokens to generate per call.  -1 would be unlimited; 128 is
  /// sufficient for spike verification and avoids runaway generation.
  static const int _nPredict = 128;

  Llama? _llama;
  String? _modelPath;

  /// Resolves the GGUF file path on the current platform.
  ///
  /// Checks the app's documents directory first.  On Android it additionally
  /// looks in /sdcard/Download and copies the file across on first run.
  Future<String> _resolveModelPath() async {
    if (_modelPath != null) return _modelPath!;

    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/$_modelFilename');

    if (!modelFile.existsSync()) {
      if (Platform.isAndroid) {
        // Try multiple locations in order of preference.
        // /data/local/tmp/ is readable by debug apps without storage permissions.
        // /sdcard/Download/ requires external storage permission (blocked on Android 11+).
        final searchPaths = [
          '/data/local/tmp/$_modelFilename',
          '/sdcard/Download/$_modelFilename',
        ];

        File? sourceFile;
        for (final path in searchPaths) {
          final candidate = File(path);
          if (candidate.existsSync()) {
            sourceFile = candidate;
            break;
          }
        }

        if (sourceFile != null) {
          await sourceFile.copy(modelFile.path);
        } else {
          throw StateError(
            'Model file not found.\n'
            'Expected: ${modelFile.path}\n'
            'Also checked: ${searchPaths.join(", ")}\n'
            'Run: adb push $_modelFilename /data/local/tmp/',
          );
        }
      } else {
        throw StateError(
          'Model file not found at ${modelFile.path}\n'
          'iOS: Use Xcode Device Manager to copy $_modelFilename '
          "to the app's Documents folder.",
        );
      }
    }

    _modelPath = modelFile.path;
    return _modelPath!;
  }

  /// Loads the model and returns a [ModelLoadResult] describing the outcome.
  ///
  /// On success, [ModelLoadResult.loaded] is true and [ModelLoadResult.modelInfo]
  /// is populated.
  ///
  /// If llama.cpp does not recognise the model architecture (Cohere2), the
  /// error is captured in [ModelLoadResult.architectureError] and [loaded] is
  /// false — this is the go/no-go signal for the binding decision.
  Future<ModelLoadResult> loadModel() async {
    try {
      final path = await _resolveModelPath();

      final contextParams = ContextParams()
        ..nCtx = _nCtx
        ..nBatch = 256
        ..nUbatch = 256
        ..nPredict = _nPredict;

      // Llama constructor is synchronous and throws on failure.
      _llama = Llama(
        path,
        modelParams: ModelParams(),
        contextParams: contextParams,
        verbose: true, // log llama.cpp internals for spike debugging
      );

      return ModelLoadResult(
        loaded: true,
        modelInfo: ModelInfo(
          contextSize: _nCtx,
          modelPath: path,
        ),
      );
    } catch (e) {
      final errorStr = e.toString();

      // Detect architecture-specific failures.
      final isArchitectureError = errorStr.contains('architecture') ||
          errorStr.contains('unknown model') ||
          errorStr.contains('not supported') ||
          errorStr.contains('LlamaException');

      if (isArchitectureError) {
        return ModelLoadResult(
          loaded: false,
          architectureError: errorStr,
        );
      }

      rethrow;
    }
  }

  /// Returns the full generated text for [prompt] as a single string.
  ///
  /// Calls [loadModel] must precede this method.
  Future<String> generateComplete(String prompt) async {
    _ensureLoaded();
    _llama!.setPrompt(prompt);
    final tokens = <String>[];
    await for (final text in _llama!.generateText()) {
      tokens.add(text);
    }
    return tokens.join();
  }

  /// Yields tokens one-at-a-time as they are generated for [prompt].
  ///
  /// Calls [loadModel] must precede this method.
  Stream<String> generateStream(String prompt) async* {
    _ensureLoaded();
    _llama!.setPrompt(prompt);
    await for (final text in _llama!.generateText()) {
      yield text;
    }
  }

  void _ensureLoaded() {
    if (_llama == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
  }

  /// Releases the llama.cpp context and model from memory.
  void dispose() {
    _llama?.dispose();
    _llama = null;
  }
}
