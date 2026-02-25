import 'inference_message.dart';

/// Abstract repository defining the inference contract consumed by
/// [ChatNotifier] and [TranslationNotifier].
///
/// The concrete implementation ([LlmService]) wraps the Dart isolate that
/// runs llama.cpp. Depending on this interface (not LlmService directly)
/// allows notifiers to be tested with fakes.
abstract class InferenceRepository {
  /// Enqueue a generation request and return a unique [requestId].
  ///
  /// Tokens arrive on [responseStream] as [TokenResponse] objects with the
  /// matching [requestId]. A [DoneResponse] signals completion.
  ///
  /// [nPredict] is the maximum number of tokens to generate.
  /// Use 128 for translation, 512 for chat.
  int generate({required String prompt, required int nPredict});

  /// Cooperatively stop the active generation identified by [requestId].
  ///
  /// The isolate finishes the current token then emits [DoneResponse] with
  /// [DoneResponse.stopped] == true.
  void stop(int requestId);

  /// Clears the model's KV cache.
  ///
  /// Must be called when starting a fresh chat session so the model does not
  /// carry over context from the previous conversation.
  /// After calling, the next [generate] must use
  /// [PromptBuilder.buildInitialPrompt] (not buildFollowUpPrompt).
  void clearContext();

  /// Whether a generation is currently in progress.
  bool get isGenerating;

  /// Broadcast stream of all inference responses (tokens, done, errors).
  ///
  /// Notifiers subscribe and filter by [requestId] to correlate responses
  /// with the request they issued.
  Stream<InferenceResponse> get responseStream;
}
