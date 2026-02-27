import 'package:flutter/foundation.dart';

/// Commands sent from the main isolate to the inference worker isolate.
///
/// All fields must be primitive types (int, String, bool) to safely cross
/// the Dart isolate boundary via SendPort.
@immutable
sealed class InferenceCommand {
  const InferenceCommand();
}

/// Load the GGUF model file at the given absolute path.
///
/// Must be sent before any [GenerateCommand]. The isolate responds with
/// [ModelReadyResponse] on success or [ErrorResponse] (requestId=-1) on failure.
final class LoadModelCommand extends InferenceCommand {
  /// Absolute path to the GGUF model file.
  final String modelPath;

  /// Context window size in tokens. Default 2048 for production.
  final int nCtx;

  /// Batch size for prompt processing. Default 256.
  final int nBatch;

  /// Number of inference threads. Default 4 for mid-range phones.
  final int nThreads;

  const LoadModelCommand({
    required this.modelPath,
    this.nCtx = 512,
    this.nBatch = 256,
    this.nThreads = 4,
  });
}

/// Generate a response for the given prompt.
///
/// The isolate streams [TokenResponse] messages followed by a single
/// [DoneResponse] when generation completes or is stopped.
final class GenerateCommand extends InferenceCommand {
  /// Unique identifier for this request. Echoed in all response messages.
  final int requestId;

  /// The full prompt string (Aya chat template format from PromptBuilder).
  final String prompt;

  /// Maximum tokens to generate. 128 for translation, 512 for chat.
  final int nPredict;

  const GenerateCommand({
    required this.requestId,
    required this.prompt,
    required this.nPredict,
  });
}

/// Stop the current generation cooperatively.
///
/// The isolate checks this flag between tokens. After receiving StopCommand,
/// the current [GenerateCommand] will emit [DoneResponse] with stopped=true.
final class StopCommand extends InferenceCommand {
  /// Must match the requestId of the active [GenerateCommand].
  final int requestId;

  const StopCommand({required this.requestId});
}

/// Clear the KV cache. Use when starting a new chat session.
///
/// Sends no response. After this, the next [GenerateCommand] must use
/// [PromptBuilder.buildInitialPrompt] (not buildFollowUpPrompt), as the
/// context is empty.
final class ClearContextCommand extends InferenceCommand {
  const ClearContextCommand();
}

/// Gracefully shut down the inference isolate and dispose the Llama instance.
///
/// After sending this command, the SendPort becomes invalid. The isolate
/// will not send any response.
final class ShutdownCommand extends InferenceCommand {
  const ShutdownCommand();
}

// ---------------------------------------------------------------------------

/// Responses sent from the inference worker isolate to the main isolate.
///
/// All fields must be primitive types (int, String, bool) to safely cross
/// the Dart isolate boundary via SendPort.
@immutable
sealed class InferenceResponse {
  const InferenceResponse();
}

/// Model loaded successfully — isolate is ready to accept [GenerateCommand].
final class ModelReadyResponse extends InferenceResponse {
  const ModelReadyResponse();
}

/// A single generated token fragment from an active generation request.
final class TokenResponse extends InferenceResponse {
  /// Matches the requestId of the originating [GenerateCommand].
  final int requestId;

  /// The token string fragment (may be partial UTF-8; the package handles this).
  final String token;

  const TokenResponse({required this.requestId, required this.token});
}

/// Generation complete. Emitted after all tokens for a request have been sent.
final class DoneResponse extends InferenceResponse {
  /// Matches the requestId of the originating [GenerateCommand].
  final int requestId;

  /// True if stopped by a [StopCommand]; false if naturally completed.
  final bool stopped;

  /// Total generation wall-clock time in milliseconds (measured on isolate).
  final int generationTimeMs;

  /// Number of loop iterations emitted by the isolate generation loop.
  final int tokenCount;

  const DoneResponse({
    required this.requestId,
    required this.stopped,
    this.generationTimeMs = 0,
    this.tokenCount = 0,
  });
}

/// An error occurred in the worker isolate.
final class ErrorResponse extends InferenceResponse {
  /// -1 for model load errors; otherwise matches the requestId of the
  /// [GenerateCommand] that caused the error.
  final int requestId;

  /// Human-readable error description (from exception.toString()).
  final String message;

  const ErrorResponse({required this.requestId, required this.message});
}
