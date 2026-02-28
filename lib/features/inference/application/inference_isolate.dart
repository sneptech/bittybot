import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../data/native_memory_advisor.dart';
import '../domain/inference_message.dart';

/// Regex patterns for Aya model special tokens.
/// Matches both `<|TOKEN_NAME|>` and `|<TOKEN_NAME>|` formats.
final _specialTokenPattern = RegExp(r'<\|[A-Z_]+\|>|\|<[A-Z_]+>\|');

/// Strip special tokens from model output before sending to UI.
String filterInferenceToken(String token) {
  return token.replaceAll(_specialTokenPattern, '');
}

/// Returns false when filtering removed all visible text from a token.
bool shouldSendFilteredToken(String filteredToken) {
  return filteredToken.isNotEmpty;
}

/// Pre-fault mmap'd model pages into RAM by reading the file sequentially.
///
/// With mmap enabled, the OS lazily loads model pages on first access.
/// Reading through the entire file forces all pages into RAM upfront,
/// trading ~10-20s of load time for consistent TTFT on the first inference.
Future<void> _warmupModelPages(String modelPath) async {
  try {
    final raf = File(modelPath).openSync(mode: FileMode.read);
    final buffer = Uint8List(65536); // 64 KB read buffer
    var bytesRead = 0;
    var nextYieldAt = 64 * 1024 * 1024;
    try {
      int n;
      while ((n = raf.readIntoSync(buffer)) > 0) {
        bytesRead += n;

        // Yield every 64 MB to reduce I/O contention with the UI isolate.
        if (bytesRead >= nextYieldAt) {
          await Future<void>.delayed(Duration.zero);
          nextYieldAt += 64 * 1024 * 1024;
        }

        // Reading triggers page faults — no processing needed
      }
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    // Non-fatal — model is still usable, just may page-fault during inference
  }
}

/// Top-level entry point for the inference worker isolate.
///
/// This function is the [Isolate.spawn] target. It owns the [Llama] FFI
/// instance for the full app session — the model is loaded once and stays
/// resident until [ShutdownCommand] is received.
///
/// **Threading model:** All code in this function runs on the worker isolate's
/// single-threaded event loop. The [SendPort.send] calls in the [generateText]
/// async* stream yield control, which allows [StopCommand] messages to be
/// delivered between token yields (cooperative stop).
///
/// **Anti-patterns to avoid:**
/// - Do NOT import Flutter plugins (path_provider, etc.) — they require the
///   main isolate's platform channel binding.
/// - Do NOT call [Isolate.exit] — let the ReceivePort close naturally.
/// - Do NOT let the [Llama] object leave this isolate — it wraps FFI pointers.
void inferenceIsolateMain(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // Send our command port back to the main isolate so it can talk to us.
  mainSendPort.send(receivePort.sendPort);

  Llama? llama;

  // The _stopped flag is in the listen closure scope so that both the
  // GenerateCommand handler and the StopCommand handler can see the same
  // variable. Dart isolate event loops are single-threaded — the await for
  // loop in the generate handler yields between each token, letting stop
  // commands arrive and flip this flag cooperatively.
  bool stopped = false;
  int advisoryFd = -1;
  String? modelPath;

  receivePort.listen((message) async {
    if (message is LoadModelCommand) {
      try {
        final modelParams = ModelParams()
          ..nGpuLayers = 0
          ..mainGpu = -1
          ..useMemorymap = true;

        final contextParams = ContextParams()
          ..nCtx = message.nCtx
          ..nBatch = message.nBatch
          ..nUbatch = message.nBatch
          ..nThreads = message.nThreads
          ..nPredict =
              -1; // We control token count manually per GenerateCommand

        llama = Llama(
          message.modelPath,
          modelParams: modelParams,
          contextParams: contextParams,
          verbose: false,
        );
        modelPath = message.modelPath;

        // Unblock the UI immediately — warmup runs in the background.
        mainSendPort.send(const ModelReadyResponse());

        // Pre-fault mmap'd pages so first inference doesn't page-fault
        await _warmupModelPages(message.modelPath);
        // Advise OS to keep model pages resident for lower TTFT variance.
        try {
          final fileLength = File(message.modelPath).lengthSync();
          advisoryFd = adviseWillNeed(message.modelPath, fileLength);
        } catch (_) {
          advisoryFd = -1;
        }
      } catch (e) {
        mainSendPort.send(ErrorResponse(requestId: -1, message: e.toString()));
      }
    } else if (message is GenerateCommand) {
      if (llama == null) {
        mainSendPort.send(
          ErrorResponse(
            requestId: message.requestId,
            message: 'Model not loaded. Send LoadModelCommand first.',
          ),
        );
        return;
      }

      stopped = false;
      int tokenCount = 0;
      final stopwatch = Stopwatch()..start();

      try {
        llama!.setPrompt(message.prompt);

        await for (final token in llama!.generateText()) {
          if (stopped) break;

          final filteredToken = filterInferenceToken(token);
          if (shouldSendFilteredToken(filteredToken)) {
            mainSendPort.send(
              TokenResponse(requestId: message.requestId, token: filteredToken),
            );
          }

          tokenCount++;
          if (tokenCount >= message.nPredict) break;
        }

        stopwatch.stop();
        mainSendPort.send(
          DoneResponse(
            requestId: message.requestId,
            stopped: stopped,
            generationTimeMs: stopwatch.elapsedMilliseconds,
            tokenCount: tokenCount,
          ),
        );
      } catch (e) {
        mainSendPort.send(
          ErrorResponse(requestId: message.requestId, message: e.toString()),
        );
      }
    } else if (message is StopCommand) {
      // Flip the flag. The generate loop checks this between token yields.
      stopped = true;
    } else if (message is ClearContextCommand) {
      // Wipe KV cache — used when starting a new chat session.
      // Fire-and-forget: no response sent.
      try {
        llama?.clear();
      } catch (_) {
        // Ignore clear errors — if llama is null, there's nothing to clear.
      }
      // Re-advise OS to keep model pages resident after KV cache clear.
      // Without this, mmap pages may be partially evicted, causing ~17s TTFT
      // on the next inference instead of ~3-5s.
      if (modelPath != null) {
        try {
          closeNativeFd(advisoryFd);
          final fileLength = File(modelPath!).lengthSync();
          advisoryFd = adviseWillNeed(modelPath!, fileLength);
        } catch (_) {
          advisoryFd = -1;
        }
      }
    } else if (message is ShutdownCommand) {
      closeNativeFd(advisoryFd);
      advisoryFd = -1;
      llama?.dispose();
      llama = null;
      receivePort.close(); // Closing the port terminates the isolate naturally.
    }
  });
}
