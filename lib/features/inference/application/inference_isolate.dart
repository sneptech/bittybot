import 'dart:isolate';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../domain/inference_message.dart';

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

  receivePort.listen((message) async {
    if (message is LoadModelCommand) {
      try {
        final modelParams = ModelParams()
          ..nGpuLayers = 0
          ..mainGpu = -1
          ..useMemorymap = false;

        final contextParams = ContextParams()
          ..nCtx = message.nCtx
          ..nBatch = message.nBatch
          ..nUbatch = message.nBatch
          ..nPredict = -1; // We control token count manually per GenerateCommand

        llama = Llama(
          message.modelPath,
          modelParams: modelParams,
          contextParams: contextParams,
          verbose: false,
        );

        mainSendPort.send(const ModelReadyResponse());
      } catch (e) {
        mainSendPort.send(ErrorResponse(requestId: -1, message: e.toString()));
      }
    } else if (message is GenerateCommand) {
      if (llama == null) {
        mainSendPort.send(ErrorResponse(
          requestId: message.requestId,
          message: 'Model not loaded. Send LoadModelCommand first.',
        ));
        return;
      }

      stopped = false;
      int tokenCount = 0;

      try {
        llama!.setPrompt(message.prompt);

        await for (final token in llama!.generateText()) {
          if (stopped) break;

          mainSendPort.send(TokenResponse(
            requestId: message.requestId,
            token: token,
          ));

          tokenCount++;
          if (tokenCount >= message.nPredict) break;
        }

        mainSendPort.send(DoneResponse(
          requestId: message.requestId,
          stopped: stopped,
        ));
      } catch (e) {
        mainSendPort.send(ErrorResponse(
          requestId: message.requestId,
          message: e.toString(),
        ));
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
    } else if (message is ShutdownCommand) {
      llama?.dispose();
      llama = null;
      receivePort.close(); // Closing the port terminates the isolate naturally.
    }
  });
}
