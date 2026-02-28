import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../chat/application/chat_repository_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_session.dart';
import '../../inference/application/llm_service_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../inference/data/inference_repository_impl.dart';
import '../../inference/domain/inference_message.dart';
import '../../inference/domain/inference_repository.dart';
import '../../inference/domain/prompt_builder.dart';

part 'translation_notifier.g.dart';

/// nCtx used for context-full detection threshold.
const int _kNCtx = 2048;

/// Percentage of nCtx at which context is considered full (90%).
const double _kContextFullThreshold = 0.9;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable state for [TranslationNotifier].
@immutable
class TranslationState {
  /// The source text currently being (or last) translated.
  final String sourceText;

  /// Accumulated token stream from in-progress generation.
  /// Contains the final translation when [isTranslating] is false.
  final String translatedText;

  /// Source language name, e.g. "English".
  final String sourceLanguage;

  /// Target language name, e.g. "Spanish".
  final String targetLanguage;

  /// True while the inference isolate is generating translation tokens.
  final bool isTranslating;

  /// True when [modelReadyProvider] has resolved — input should be
  /// disabled in the UI until this becomes true.
  final bool isModelReady;

  /// True when the accumulated prompt text approaches ~90% of nCtx=2048.
  /// The UI (Phase 5) shows a "Start new session" banner when true.
  final bool isContextFull;

  /// The requestId of the active [GenerateCommand].
  final int? activeRequestId;

  /// The current translation session in DB (accumulates context per language pair).
  /// Null until the first [translate] call.
  final ChatSession? activeSession;

  /// Number of translations issued in this session.
  ///
  /// 0 means [PromptBuilder.buildTranslationPrompt] (initial) must be used.
  /// >0 means [PromptBuilder.buildFollowUpTranslationPrompt] should be used.
  final int turnCount;

  const TranslationState({
    this.sourceText = '',
    this.translatedText = '',
    this.sourceLanguage = 'English',
    this.targetLanguage = 'Spanish',
    this.isTranslating = false,
    this.isModelReady = false,
    this.isContextFull = false,
    this.activeRequestId,
    this.activeSession,
    this.turnCount = 0,
  });

  TranslationState copyWith({
    String? sourceText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    bool? isTranslating,
    bool? isModelReady,
    bool? isContextFull,
    int? activeRequestId,
    ChatSession? activeSession,
    int? turnCount,
    bool clearActiveRequestId = false,
    bool clearActiveSession = false,
  }) {
    return TranslationState(
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isTranslating: isTranslating ?? this.isTranslating,
      isModelReady: isModelReady ?? this.isModelReady,
      isContextFull: isContextFull ?? this.isContextFull,
      activeRequestId: clearActiveRequestId
          ? null
          : (activeRequestId ?? this.activeRequestId),
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      turnCount: turnCount ?? this.turnCount,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages translation request state.
///
/// Responsibilities:
/// - Accepts translation requests for a configured language pair.
/// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
/// - Sends generation requests to [InferenceRepository] with nPredict=128.
/// - Streams tokens to [TranslationState.translatedText] as they arrive.
/// - Queues new requests behind active generation; auto-dequeues on done.
/// - Persists all translations to Drift DB via [ChatRepository] for history.
/// - Accumulates context within the same language pair session for terminology
///   consistency. Language pair change or swap resets the session and KV cache.
/// - Detects context-full condition via [TranslationState.isContextFull].
/// - Supports cooperative stop via [InferenceRepository.stop].
///
/// [keepAlive: true] so the last-used language pair persists across navigation
/// (TRNS-05 requirement: language pair selection survives screen changes).
@Riverpod(keepAlive: true)
class TranslationNotifier extends _$TranslationNotifier {
  /// FIFO queue of translation texts waiting for the current generation.
  final Queue<({String text, String? hiddenContext})> _pendingQueue = Queue<({String text, String? hiddenContext})>();

  /// Active subscription to the inference response stream.
  StreamSubscription<InferenceResponse>? _responseSubscription;

  @override
  TranslationState build() {
    final modelAsync = ref.watch(modelReadyProvider);
    final isModelReady = modelAsync.hasValue;

    // Read persisted target language from settings (TRNS-05).
    final settingsAsync = ref.watch(settingsProvider);
    final targetLanguage = settingsAsync.value?.targetLanguage ?? 'Spanish';

    ref.onDispose(() {
      _responseSubscription?.cancel();
    });

    return TranslationState(
      isModelReady: isModelReady,
      targetLanguage: targetLanguage,
    );
  }

  // ---------------------------------------------------------------------------
  // Public interface
  // ---------------------------------------------------------------------------

  /// Sets the source language.
  ///
  /// If the language pair changes, a new translation session is started
  /// (clearing KV cache) so terminology is consistent for the new pair.
  Future<void> setSourceLanguage(String language) async {
    if (language == state.sourceLanguage) return;
    state = state.copyWith(sourceLanguage: language);
    await _resetSession();
  }

  /// Sets the target language.
  ///
  /// Same session reset as [setSourceLanguage] — different target means
  /// different terminology expectations. Also persists to settings for
  /// app restart persistence (TRNS-05).
  Future<void> setTargetLanguage(String language) async {
    if (language == state.targetLanguage) return;
    state = state.copyWith(targetLanguage: language);
    // Persist to settings for TRNS-05 (app restart persistence).
    ref.read(settingsProvider.notifier).setTargetLanguage(language);
    await _resetSession();
  }

  /// Starts a fresh translation session.
  ///
  /// Saves the current session (already persisted in DB), clears the KV
  /// cache and in-memory state. The next [translate] call creates a new DB
  /// session. Called by the "new session" (+) button in the translation
  /// screen top bar.
  Future<void> startNewSession() async {
    _pendingQueue.clear();
    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.clearContext();
    state = state.copyWith(
      sourceText: '',
      translatedText: '',
      isTranslating: false,
      isContextFull: false,
      turnCount: 0,
      clearActiveSession: true,
      clearActiveRequestId: true,
    );
  }

  /// Swaps source and target languages.
  ///
  /// Resets the session — after swapping, the KV cache context is no longer
  /// consistent with the new direction.
  Future<void> swapLanguages() async {
    final prev = state.sourceLanguage;
    state = state.copyWith(
      sourceLanguage: state.targetLanguage,
      targetLanguage: prev,
    );
    await _resetSession();
  }

  /// Translates [text] from [TranslationState.sourceLanguage] to
  /// [TranslationState.targetLanguage].
  ///
  /// If a translation is currently in progress, the request is queued and
  /// processed automatically when the active generation completes.
  Future<void> translate(String text, {String? hiddenContext}) async {
    if (!state.isModelReady) return;

    if (state.isTranslating) {
      _pendingQueue.add((text: text, hiddenContext: hiddenContext));
      return;
    }

    await _processTranslation(text, hiddenContext: hiddenContext);
  }

  /// Cooperatively stops the active translation.
  ///
  /// The inference isolate finishes the current token, then emits
  /// [DoneResponse] with [DoneResponse.stopped] == true. The listener marks
  /// the partial output as truncated and persists it.
  void stopTranslation() {
    if (!state.isTranslating || state.activeRequestId == null) return;

    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.stop(state.activeRequestId!);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Resets the translation session and clears the KV cache.
  ///
  /// Called when the language pair changes. Creates a fresh DB session so
  /// history for the new pair is separate. Clears the model's KV cache so
  /// the next translation uses [buildTranslationPrompt] (initial with system
  /// prompt) rather than [buildFollowUpTranslationPrompt].
  Future<void> _resetSession() async {
    _pendingQueue.clear();

    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.clearContext();

    state = state.copyWith(
      translatedText: '',
      isContextFull: false,
      turnCount: 0,
      clearActiveSession: true,
      clearActiveRequestId: true,
    );
  }

  /// Core translation processing pipeline.
  ///
  /// 1. Ensures an active translation session exists.
  /// 2. Persists the source text as a user message in DB.
  /// 3. Builds the Aya-formatted prompt (initial vs. follow-up).
  /// 4. Checks context-full threshold.
  /// 5. Registers the response stream listener (once per notifier lifetime).
  /// 6. Issues the [GenerateCommand] with nPredict=128 (translation limit).
  Future<void> _processTranslation(String text, {String? hiddenContext}) async {
    final chatRepo = ref.read(chatRepositoryProvider);

    // Ensure we have an active translation session.
    ChatSession session = state.activeSession ??
        await chatRepo.createSession(mode: 'translation');

    // Persist the source text as a user message.
    await chatRepo.insertMessage(
      sessionId: session.id,
      role: 'user',
      content: text,
    );

    // Use hidden context (e.g. scraped web page) for prompt if provided,
    // otherwise use the user's text directly.
    final promptText = hiddenContext ?? text;

    // Build prompt — initial for first translation in pair, follow-up thereafter.
    final String prompt;
    if (state.turnCount == 0) {
      prompt = PromptBuilder.buildTranslationPrompt(
        text: promptText,
        targetLanguage: state.targetLanguage,
      );
    } else {
      prompt = PromptBuilder.buildFollowUpTranslationPrompt(
        text: promptText,
        targetLanguage: state.targetLanguage,
      );
    }

    // Context-full detection.
    final estimatedTokens = PromptBuilder.estimateTokenCount(prompt);
    final isContextFull =
        estimatedTokens >= (_kNCtx * _kContextFullThreshold).toInt();

    // Update state before generation.
    state = state.copyWith(
      sourceText: text,
      translatedText: '',
      isTranslating: true,
      isContextFull: isContextFull,
      activeSession: session,
    );

    // Register stream listener once.
    _setupResponseListenerIfNeeded();

    // Issue generation request — 128 tokens for translation per locked decision.
    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    final requestId = inferenceRepo.generate(
      prompt: prompt,
      nPredict: 128,
    );

    state = state.copyWith(
      activeRequestId: requestId,
      turnCount: state.turnCount + 1,
    );
  }

  /// Registers the inference response stream listener.
  ///
  /// Called lazily on the first [_processTranslation]. Lives for the
  /// notifier's lifetime (keepAlive — only disposed on provider override in tests).
  void _setupResponseListenerIfNeeded() {
    if (_responseSubscription != null) return;

    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    _responseSubscription = inferenceRepo.responseStream.listen(
      _onResponse,
      onError: (Object error) {
        state = state.copyWith(
          isTranslating: false,
          clearActiveRequestId: true,
        );
        _dequeueNextIfAny();
      },
    );
  }

  /// Handles a single [InferenceResponse] from the stream.
  Future<void> _onResponse(InferenceResponse response) async {
    switch (response) {
      case TokenResponse(:final requestId, :final token):
        if (requestId != state.activeRequestId) return;
        state = state.copyWith(
          translatedText: state.translatedText + token,
        );

      case DoneResponse(:final requestId, :final stopped):
        if (requestId != state.activeRequestId) return;
        await _finishTranslation(stopped: stopped);

      case ErrorResponse(:final requestId, :final message):
        if (requestId != state.activeRequestId && requestId != -1) return;
        await _handleError(message);

      case ModelReadyResponse():
        break;
    }
  }

  /// Persists the completed translation and resets generation state.
  Future<void> _finishTranslation({required bool stopped}) async {
    final session = state.activeSession;
    if (session == null) return;

    // Strip leading/trailing quote characters the model sometimes wraps around translations.
    final content = state.translatedText
        .replaceAll(
            RegExp(r'^["\x27\u00AB\u00BB\u201C\u201D\u2018\u2019]+|["\x27\u00AB\u00BB\u201C\u201D\u2018\u2019]+$'),
            '')
        .trim();

    final chatRepo = ref.read(chatRepositoryProvider);

    // Persist the assistant (translation) message.
    await chatRepo.insertMessage(
      sessionId: session.id,
      role: 'assistant',
      content: content,
      isTruncated: stopped,
    );

    state = state.copyWith(
      translatedText: content,
      isTranslating: false,
      clearActiveRequestId: true,
    );

    _dequeueNextIfAny();
  }

  /// Handles an error from the inference stream.
  Future<void> _handleError(String message) async {
    // Context-full errors arrive as ErrorResponse (setPrompt throws
    // LlamaException("Context full ...") when _nPos >= nCtx-10).
    // Auto-reset so translation can continue.
    final isContextFullError = message.contains('Context full') ||
        message.contains('Context limit');
    if (isContextFullError) {
      await startNewSession();
      state = state.copyWith(isContextFull: true);
      return;
    }

    // Persist partial output if any.
    final session = state.activeSession;
    if (session != null && state.translatedText.isNotEmpty) {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.insertMessage(
        sessionId: session.id,
        role: 'assistant',
        content: state.translatedText,
        isTruncated: true,
      );
    }

    state = state.copyWith(
      isTranslating: false,
      clearActiveRequestId: true,
    );

    _dequeueNextIfAny();
  }

  /// Dequeues and processes the next pending translation, if any.
  Future<void> _dequeueNextIfAny() async {
    if (_pendingQueue.isNotEmpty) {
      final next = _pendingQueue.removeFirst();
      await _processTranslation(next.text, hiddenContext: next.hiddenContext);
    }
  }
}
