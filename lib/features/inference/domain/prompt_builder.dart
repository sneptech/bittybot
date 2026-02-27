/// Constructs prompts in the Aya chat template format for llama_cpp_dart.
///
/// The Aya chat template:
/// ```
/// <|START_OF_TURN_TOKEN|><|USER_TOKEN|>{message}<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>
/// ```
///
/// Key design principle: The KV cache is stateful. [buildInitialPrompt] is used
/// for the FIRST message in a session. [buildFollowUpPrompt] is used for ALL
/// subsequent messages — it appends only the new user turn. DO NOT reconstruct
/// full history on every turn; Llama.setPrompt() appends to the cached context.
class PromptBuilder {
  // Aya special token constants.
  static const _startOfTurn = '<|START_OF_TURN_TOKEN|>';
  static const _userToken = '<|USER_TOKEN|>';
  static const _chatbotToken = '<|CHATBOT_TOKEN|>';
  static const _endOfTurn = '<|END_OF_TURN_TOKEN|>';

  /// System prompt for translation mode.
  ///
  /// Ultra-short and directive — the 3.35B model ignores complex instructions.
  /// Must produce ONLY the translated text, nothing else.
  static const translationSystemPrompt =
      'You are a translation machine. Output ONLY the translation, nothing else. '
      'No explanations, no notes, no extra words.';

  /// System prompt for chat mode.
  ///
  /// Short and directive — anchors on translation/language help while
  /// softly steering away from off-topic requests.
  static const chatSystemPrompt =
      'You are a translator and language assistant. Help people translate '
      'text and understand languages. If asked about other topics, mention '
      'that translation is your strength.';

  /// Builds the initial prompt for the first message of a new session.
  ///
  /// Prepends the [systemPrompt] to [userMessage] inside the user turn tokens.
  /// The model begins generating from the trailing chatbot token.
  ///
  /// Format:
  /// `<|START_OF_TURN_TOKEN|><|USER_TOKEN|>{systemPrompt}\n\n{userMessage}<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>`
  ///
  /// Call this only for the FIRST message. For subsequent turns, use
  /// [buildFollowUpPrompt] to avoid re-injecting the system prompt.
  static String buildInitialPrompt({
    required String systemPrompt,
    required String userMessage,
  }) {
    return '$_startOfTurn$_userToken$systemPrompt\n\n$userMessage$_endOfTurn$_startOfTurn$_chatbotToken';
  }

  /// Builds an incremental prompt for follow-up messages in an existing session.
  ///
  /// Does NOT include the system prompt — the KV cache already contains it from
  /// the initial turn. Does NOT reconstruct prior history — Llama.setPrompt()
  /// appends to the existing context.
  ///
  /// Format:
  /// `<|START_OF_TURN_TOKEN|><|USER_TOKEN|>{userMessage}<|END_OF_TURN_TOKEN|><|START_OF_TURN_TOKEN|><|CHATBOT_TOKEN|>`
  static String buildFollowUpPrompt(String userMessage) {
    return '$_startOfTurn$_userToken$userMessage$_endOfTurn$_startOfTurn$_chatbotToken';
  }

  /// Convenience wrapper for the first translation in a new session.
  ///
  /// Calls [buildInitialPrompt] with [translationSystemPrompt] and formats
  /// the user message as `Translate to {targetLanguage}: {text}`.
  static String buildTranslationPrompt({
    required String text,
    required String targetLanguage,
  }) {
    return buildInitialPrompt(
      systemPrompt: translationSystemPrompt,
      userMessage: 'Translate to $targetLanguage: $text',
    );
  }

  /// Convenience wrapper for subsequent translations within the same session.
  ///
  /// Calls [buildFollowUpPrompt] for subsequent translations to avoid
  /// re-injecting the system prompt into an active KV cache.
  static String buildFollowUpTranslationPrompt({
    required String text,
    required String targetLanguage,
  }) {
    return buildFollowUpPrompt('Translate to $targetLanguage: $text');
  }

  /// Rough token count estimation for context-full detection.
  ///
  /// Uses the conservative estimate of ~2 chars per token (CJK worst case).
  /// Returns (text.length / 2) rounded up.
  ///
  /// This is intentionally over-estimates — it is better to prompt the user
  /// to start a new session slightly early than to silently overflow the
  /// context window and degrade output quality.
  ///
  /// The caller should compare this against a threshold (e.g., 90% of nCtx=2048)
  /// to trigger the "start new session" UI flow.
  static int estimateTokenCount(String text) {
    // Conservative estimate: ~2 chars per token (CJK scripts are densest).
    // Latin scripts are ~4 chars/token, but we use the higher estimate
    // (lower chars/token = more tokens estimated = earlier context-full warning).
    return (text.length / 2).ceil();
  }
}
