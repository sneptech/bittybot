import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:llama_cpp_dart/src/llama_cpp.dart' as ffi;

// Native callback for llama.cpp logging
void _logCallback(int level, Pointer<Char> text, Pointer<Void> userData) {
  final msg = text.cast<Utf8>().toDartString().trimRight();
  if (msg.isNotEmpty) {
    print('LLAMA[$level]: $msg');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('debug: model load with logging', (tester) async {
    print('Opening library...');
    final dylib = DynamicLibrary.open('libmtmd.so');
    final lib = ffi.llama_cpp(dylib);

    print('Setting up log callback...');
    final logCallbackPtr = Pointer.fromFunction<
        Void Function(UnsignedInt, Pointer<Char>, Pointer<Void>)>(
      _logCallback,
    );
    lib.llama_log_set(logCallbackPtr, nullptr);
    print('Log callback installed');

    print('Initializing backend...');
    lib.llama_backend_init();
    print('Backend initialized');

    const modelPath = '/data/local/tmp/tiny-aya-global-q4_k_m.gguf';
    print('Loading model from $modelPath...');

    var params = lib.llama_model_default_params();
    params.n_gpu_layers = 0;
    params.use_mmap = false;

    final pathPtr = modelPath.toNativeUtf8().cast<Char>();
    final model = lib.llama_load_model_from_file(pathPtr, params);
    malloc.free(pathPtr);

    if (model == nullptr) {
      print('MODEL LOAD FAILED (returned null)');
    } else {
      print('MODEL LOADED SUCCESSFULLY!');
      lib.llama_free_model(model);
    }

    print('=== DONE ===');
    expect(true, isTrue);
  }, timeout: Timeout.none);
}
