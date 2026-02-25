import 'dart:async';
import 'dart:isolate';

import '../domain/inference_message.dart';
import 'inference_isolate.dart';

/// Manages the inference worker isolate lifecycle and provides a clean API
/// for sending inference requests and receiving streaming tokens.
///
/// This is a plain Dart class — the Riverpod provider wrapper is in Plan 04.
///
/// **Lifecycle:**
/// 1. Construct with [LlmService(modelPath: ...)].
/// 2. Call [start] to spawn the isolate and load the model.
/// 3. Use [generate] to start streaming, [stop] to halt, [clearContext] to
///    reset KV cache between sessions.
/// 4. Call [dispose] to shut down gracefully.
///
/// **Crash recovery:** A circuit breaker tracks consecutive isolate crashes.
/// After [_maxAutoRetries] (3) failures, further auto-respawn is disabled and
/// an [ErrorResponse] is emitted to [responseStream] so the UI can surface
/// a recoverable error to the user.
class LlmService {
  final String _modelPath;

  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;

  /// Separate port for isolate error notifications (unhandled exceptions/OOM).
  /// [Isolate.addErrorListener] sends [List] messages, not [InferenceResponse],
  /// so we use a dedicated port to keep the message handling clean.
  ReceivePort? _errorPort;

  StreamController<InferenceResponse>? _responseController;

  int _nextRequestId = 0;
  int _consecutiveCrashCount = 0;
  bool _isGenerating = false;

  static const int _maxAutoRetries = 3;

  LlmService({required String modelPath}) : _modelPath = modelPath;

  // ---------------------------------------------------------------------------
  // Public read-only state

  /// Stream of all [InferenceResponse] messages from the worker isolate.
  ///
  /// Callers filter by [InferenceResponse] subtype and match [requestId] to
  /// correlate tokens with the originating [generate] call.
  Stream<InferenceResponse> get responseStream {
    _responseController ??=
        StreamController<InferenceResponse>.broadcast();
    return _responseController!.stream;
  }

  /// Whether a [GenerateCommand] is currently in flight.
  bool get isGenerating => _isGenerating;

  /// Best-effort liveness check for the worker isolate.
  ///
  /// Returns false after an OS background kill or crash. Used by
  /// modelReadyProvider (Plan 04) to detect stale isolates and trigger reload.
  bool get isAlive => _isolate != null && _commandPort != null;

  // ---------------------------------------------------------------------------
  // Lifecycle

  /// Spawns the inference worker isolate, loads the model, and waits for
  /// [ModelReadyResponse].
  ///
  /// Resets the crash counter on successful model load. Throws if the worker
  /// sends [ErrorResponse] during model loading.
  Future<void> start() async {
    // Ensure a fresh controller is available for this start cycle.
    if (_responseController == null || _responseController!.isClosed) {
      _responseController =
          StreamController<InferenceResponse>.broadcast();
    }

    _responsePort = ReceivePort();
    _errorPort = ReceivePort();

    // Spawn worker and establish the command channel using a Completer so we
    // can use a single .listen() for both the initial SendPort handshake and
    // all subsequent InferenceResponse messages.
    final sendPortCompleter = Completer<SendPort>();

    _responsePort!.listen((message) {
      if (message is SendPort) {
        if (!sendPortCompleter.isCompleted) {
          sendPortCompleter.complete(message);
        }
      } else if (message is InferenceResponse) {
        // Track generation state locally before forwarding.
        if (message is DoneResponse) {
          _isGenerating = false;
          _consecutiveCrashCount = 0;
        } else if (message is ErrorResponse) {
          _isGenerating = false;
        }

        if (!(_responseController?.isClosed ?? true)) {
          _responseController!.add(message);
        }
      }
    });

    // Error port receives [errorMessage, stackTrace] List from the isolate
    // when an unhandled exception or OOM occurs.
    _errorPort!.listen((_) => _handleCrash());

    _isolate = await Isolate.spawn(
      inferenceIsolateMain,
      _responsePort!.sendPort,
    );

    // Wire isolate-level errors to the dedicated error port.
    _isolate!.addErrorListener(_errorPort!.sendPort);

    _commandPort = await sendPortCompleter.future;

    // Send LoadModelCommand and wait for ModelReadyResponse (or error).
    _commandPort!.send(LoadModelCommand(modelPath: _modelPath));

    await responseStream.firstWhere(
      (msg) => msg is ModelReadyResponse || msg is ErrorResponse,
    ).then((msg) {
      if (msg is ErrorResponse) {
        throw Exception('Model load failed: ${msg.message}');
      }
      _consecutiveCrashCount = 0;
    });
  }

  // ---------------------------------------------------------------------------
  // Inference API

  /// Starts a generation request.
  ///
  /// Returns the [requestId] assigned to this request. Callers use this ID to
  /// match [TokenResponse] and [DoneResponse] messages on [responseStream].
  int generate({required String prompt, required int nPredict}) {
    final requestId = _nextRequestId++;
    _isGenerating = true;
    _commandPort!.send(GenerateCommand(
      requestId: requestId,
      prompt: prompt,
      nPredict: nPredict,
    ));
    return requestId;
  }

  /// Cooperatively halts the active generation.
  ///
  /// The worker checks the stop flag between token yields. A [DoneResponse]
  /// with [DoneResponse.stopped] == true will be emitted after the current
  /// token batch completes.
  void stop(int requestId) {
    _commandPort?.send(StopCommand(requestId: requestId));
  }

  /// Clears the KV cache on the worker isolate.
  ///
  /// Call this when starting a new chat session so that the model context is
  /// reset. The next [GenerateCommand] must use the full initial prompt
  /// (including system prompt) rather than a KV-cache follow-up.
  void clearContext() {
    _commandPort?.send(const ClearContextCommand());
  }

  // ---------------------------------------------------------------------------
  // Shutdown

  /// Shuts down the worker isolate and releases all resources.
  Future<void> dispose() async {
    _isGenerating = false;

    // Ask the worker to dispose FFI resources cleanly before we kill it.
    _commandPort?.send(const ShutdownCommand());
    _commandPort = null;

    // Give the worker a moment to clean up, then force-kill.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    _errorPort?.close();
    _errorPort = null;

    _responsePort?.close();
    _responsePort = null;

    await _responseController?.close();
    _responseController = null;
  }

  // ---------------------------------------------------------------------------
  // Crash recovery (internal)

  /// Called when the worker isolate crashes (unhandled exception or OOM).
  ///
  /// Increments the crash counter. If under [_maxAutoRetries], disposes the
  /// current isolate and respawns. If over the limit, emits a permanent error
  /// and stops retrying to avoid infinite crash loops.
  Future<void> _handleCrash() async {
    _isGenerating = false;
    _consecutiveCrashCount++;

    if (_consecutiveCrashCount <= _maxAutoRetries) {
      // Clean up remnants of the crashed isolate before respawning.
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _commandPort = null;

      _errorPort?.close();
      _errorPort = null;

      _responsePort?.close();
      _responsePort = null;

      try {
        await start();
      } catch (e) {
        // start() itself failed — surface as error and let the counter
        // eventually trip the circuit breaker on the next crash.
        if (!(_responseController?.isClosed ?? true)) {
          _responseController!.add(ErrorResponse(
            requestId: -1,
            message: 'Isolate restart failed: $e',
          ));
        }
      }
    } else {
      if (!(_responseController?.isClosed ?? true)) {
        _responseController!.add(const ErrorResponse(
          requestId: -1,
          message: 'Model crashed repeatedly. Please restart the app.',
        ));
      }
    }
  }
}
