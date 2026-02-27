import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../inference/data/inference_repository_impl.dart';
import '../../inference/domain/inference_message.dart';
import '../../inference/domain/inference_repository.dart';
import '../../inference/domain/prompt_builder.dart';
import '../../inference/application/llm_service_provider.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/chat_session.dart';
import 'chat_repository_provider.dart';

part 'chat_notifier.g.dart';

/// nCtx used for context-full detection threshold.
const int _kNCtx = 2048;

/// Percentage of nCtx at which context is considered full (90%).
const double _kContextFullThreshold = 0.9;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable state for [ChatNotifier].
///
/// Held by the Riverpod notifier; the UI rebuilds when any field changes.
@immutable
class ChatState {
  /// The currently active chat session, or null before a session is created.
  final ChatSession? activeSession;

  /// All messages loaded for the active session (user + assistant).
  final List<ChatMessage> messages;

  /// Accumulated token stream from the in-progress generation.
  /// Empty when [isGenerating] is false.
  final String currentResponse;

  /// True while the inference isolate is generating tokens.
  final bool isGenerating;

  /// True when [modelReadyProvider] has resolved — input should be
  /// disabled in the UI until this becomes true.
  final bool isModelReady;

  /// True when the accumulated prompt text approaches ~90% of nCtx=2048.
  /// The UI (Phase 6) shows a "Start new session" prompt banner when this
  /// is true. Does NOT auto-start a session — that requires user action via
  /// [ChatNotifier.startNewSessionWithCarryForward].
  final bool isContextFull;

  /// The requestId of the active [GenerateCommand]. Used to match
  /// [TokenResponse] and [DoneResponse] messages from the inference stream.
  /// Null when not generating.
  final int? activeRequestId;

  const ChatState({
    this.activeSession,
    this.messages = const [],
    this.currentResponse = '',
    this.isGenerating = false,
    this.isModelReady = false,
    this.isContextFull = false,
    this.activeRequestId,
  });

  ChatState copyWith({
    ChatSession? activeSession,
    List<ChatMessage>? messages,
    String? currentResponse,
    bool? isGenerating,
    bool? isModelReady,
    bool? isContextFull,
    int? activeRequestId,
    bool clearActiveSession = false,
    bool clearActiveRequestId = false,
  }) {
    return ChatState(
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      messages: messages ?? this.messages,
      currentResponse: currentResponse ?? this.currentResponse,
      isGenerating: isGenerating ?? this.isGenerating,
      isModelReady: isModelReady ?? this.isModelReady,
      isContextFull: isContextFull ?? this.isContextFull,
      activeRequestId: clearActiveRequestId
          ? null
          : (activeRequestId ?? this.activeRequestId),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages multi-turn conversation state for the chat feature.
///
/// Responsibilities:
/// - Loads/creates chat sessions from [ChatRepository].
/// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
/// - Sends generation requests to [InferenceRepository].
/// - Streams tokens to [ChatState.currentResponse] as they arrive.
/// - Queues messages sent during active generation; auto-dequeues on done.
/// - Persists all messages to Drift DB via [ChatRepository].
/// - Detects context-full condition and signals UI via [ChatState.isContextFull].
/// - Supports cooperative stop via [InferenceRepository.stop].
///
/// Use `@riverpod` (auto-dispose) — chat state is loaded from DB on each
/// screen entry. The DB is the source of truth; in-memory state is ephemeral.
@riverpod
class ChatNotifier extends _$ChatNotifier {
  /// FIFO queue of messages waiting for the current generation to finish.
  final Queue<String> _pendingQueue = Queue<String>();

  /// Active subscription to the inference response stream.
  /// Cancelled on notifier disposal.
  StreamSubscription<InferenceResponse>? _responseSubscription;

  /// Counts user turns sent in this notifier's lifetime.
  ///
  /// 0 means the KV cache is empty — [PromptBuilder.buildInitialPrompt] must
  /// be used. >0 means [PromptBuilder.buildFollowUpPrompt] should be used
  /// (the model's KV cache already has the system prompt).
  int _turnCount = 0;

  /// Buffer for accumulating tokens between UI flushes.
  final StringBuffer _tokenBuffer = StringBuffer();

  /// Timer that flushes buffered tokens to state at a fixed interval.
  Timer? _batchTimer;

  /// Interval between token buffer flushes to UI state.
  static const Duration _kTokenBatchInterval = Duration(milliseconds: 50);

  @override
  ChatState build() {
    // Watch modelReadyProvider so the notifier rebuilds when the model
    // transitions from loading -> ready (updates isModelReady in state).
    final modelAsync = ref.watch(modelReadyProvider);
    final isModelReady = modelAsync.hasValue;

    // Cancel the stream subscription on notifier disposal to prevent
    // delivering callbacks to a dead object.
    ref.onDispose(() {
      _responseSubscription?.cancel();
      _batchTimer?.cancel();
    });

    return ChatState(isModelReady: isModelReady);
  }

  // ---------------------------------------------------------------------------
  // Public interface
  // ---------------------------------------------------------------------------

  /// Loads an existing session and its messages from the DB.
  ///
  /// Does NOT replay messages into the KV cache — that would overflow nCtx=2048
  /// for long conversations. Messages are shown in the UI from DB, but the model
  /// starts with a fresh context. The next [sendMessage] will use
  /// [PromptBuilder.buildInitialPrompt].
  Future<void> loadSession(int sessionId) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final session = await chatRepo.getSession(sessionId);
    if (session == null) return;

    final messages = await chatRepo.getMessagesForSession(sessionId);

    // Fresh KV cache for this session load — buildInitialPrompt on next send.
    _turnCount = 0;

    state = state.copyWith(
      activeSession: session,
      messages: messages,
      currentResponse: '',
      isGenerating: false,
      isContextFull: false,
      clearActiveRequestId: true,
    );
  }

  /// Creates a new empty chat session and clears the KV cache.
  Future<void> startNewSession() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final session = await chatRepo.createSession(mode: 'chat');

    // Clear the model's KV cache so the next message is treated as
    // the start of a fresh conversation.
    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.clearContext();

    _turnCount = 0;
    _pendingQueue.clear();
    _batchTimer?.cancel();
    _tokenBuffer.clear();

    state = state.copyWith(
      activeSession: session,
      messages: const [],
      currentResponse: '',
      isGenerating: false,
      isContextFull: false,
      clearActiveRequestId: true,
    );
  }

  /// Sends a user message.
  ///
  /// If a generation is currently in progress, the message is queued and will
  /// be processed automatically when the current generation completes.
  Future<void> sendMessage(String text) async {
    if (state.isGenerating) {
      _pendingQueue.add(text);
      return;
    }
    await _processMessage(text);
  }

  /// Cooperatively stops the active generation.
  ///
  /// The inference isolate finishes the current token, then emits
  /// [DoneResponse] with [DoneResponse.stopped] == true. The response
  /// listener marks the accumulated output as truncated and persists it.
  void stopGeneration() {
    if (!state.isGenerating || state.activeRequestId == null) return;

    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    inferenceRepo.stop(state.activeRequestId!);
  }

  /// Starts a new session, carrying forward the last 3 user–assistant exchanges.
  ///
  /// Called by the UI when the user accepts the "Start new session" prompt
  /// shown when [ChatState.isContextFull] is true.
  ///
  /// The last 3 exchanges (up to 6 messages) are inserted into the new session
  /// in DB and seeded into the KV cache via an initial prompt that summarises
  /// them, giving the model continuity of recent context.
  Future<void> startNewSessionWithCarryForward() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final inferenceRepo = ref.read(inferenceRepositoryProvider);

    // Extract up to 3 user-assistant exchange pairs (6 messages) from the end.
    final allMessages = state.messages;
    final carryMessages = allMessages.length > 6
        ? allMessages.sublist(allMessages.length - 6)
        : List<ChatMessage>.from(allMessages);

    // Create new session.
    final newSession = await chatRepo.createSession(mode: 'chat');

    // Clear the KV cache.
    inferenceRepo.clearContext();

    // Copy carried-forward messages into the new session in DB.
    final List<ChatMessage> newMessages = [];
    for (final msg in carryMessages) {
      final inserted = await chatRepo.insertMessage(
        sessionId: newSession.id,
        role: msg.role,
        content: msg.content,
      );
      newMessages.add(inserted);
    }

    _turnCount = 0;
    _pendingQueue.clear();
    _batchTimer?.cancel();
    _tokenBuffer.clear();

    state = state.copyWith(
      activeSession: newSession,
      messages: newMessages,
      currentResponse: '',
      isGenerating: false,
      isContextFull: false,
      clearActiveRequestId: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Core message processing pipeline.
  ///
  /// 1. Ensures an active session exists (creates one if not).
  /// 2. Persists the user message to DB.
  /// 3. Builds the Aya-formatted prompt (initial vs. follow-up).
  /// 4. Checks context-full threshold before sending.
  /// 5. Registers the response stream listener (once per notifier lifetime).
  /// 6. Issues the [GenerateCommand] via [InferenceRepository.generate].
  Future<void> _processMessage(String text) async {
    // Ensure we have an active session.
    ChatSession session = state.activeSession ??
        await ref.read(chatRepositoryProvider).createSession(mode: 'chat');

    final chatRepo = ref.read(chatRepositoryProvider);

    // Persist user message.
    final userMessage = await chatRepo.insertMessage(
      sessionId: session.id,
      role: 'user',
      content: text,
    );

    // Build prompt (initial for first turn, follow-up thereafter).
    final String prompt;
    if (_turnCount == 0) {
      prompt = PromptBuilder.buildInitialPrompt(
        systemPrompt: PromptBuilder.chatSystemPrompt,
        userMessage: text,
      );
    } else {
      prompt = PromptBuilder.buildFollowUpPrompt(text);
    }

    // Context-full detection: estimate tokens for the prompt being sent.
    // If we're approaching 90% of nCtx, flag it — the UI will show the
    // "Start new session" banner on the NEXT render after this message.
    final estimatedTokens = PromptBuilder.estimateTokenCount(prompt);
    final isContextFull =
        estimatedTokens >= (_kNCtx * _kContextFullThreshold).toInt();

    // Update UI state before launching generation.
    state = state.copyWith(
      activeSession: session,
      messages: [...state.messages, userMessage],
      currentResponse: '',
      isGenerating: true,
      isContextFull: isContextFull,
    );

    // Register the response stream listener once for this notifier's lifetime.
    _setupResponseListenerIfNeeded();

    // Issue the generation request.
    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    final requestId = inferenceRepo.generate(
      prompt: prompt,
      nPredict: 512, // 512 tokens for chat per locked decision
    );

    state = state.copyWith(activeRequestId: requestId);

    // Increment turn count so subsequent messages use buildFollowUpPrompt.
    _turnCount++;
  }

  /// Registers the inference response stream listener.
  ///
  /// Called lazily on the first [_processMessage]. The subscription lives
  /// for the notifier's lifetime (cancelled in [build] via [ref.onDispose]).
  void _setupResponseListenerIfNeeded() {
    if (_responseSubscription != null) return;

    final inferenceRepo = ref.read(inferenceRepositoryProvider);
    _responseSubscription = inferenceRepo.responseStream.listen(
      _onResponse,
      onError: (Object error) {
        // Stream-level error (rare; most errors arrive as ErrorResponse).
        state = state.copyWith(
          isGenerating: false,
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
        // Ignore tokens for stale requests (e.g., from a previous notifier
        // lifecycle that was interrupted).
        if (requestId != state.activeRequestId) return;
        _tokenBuffer.write(token);
        _scheduleBatchFlush();

      case DoneResponse(:final requestId, :final stopped):
        if (requestId != state.activeRequestId) return;
        await _finishGeneration(stopped: stopped);

      case ErrorResponse(:final requestId, :final message):
        // requestId == -1 for model load errors; otherwise matches the request.
        if (requestId != state.activeRequestId && requestId != -1) return;
        await _handleError(message);

      case ModelReadyResponse():
        // ModelReadyResponse is handled by modelReadyProvider, not here.
        break;
    }
  }

  /// Persists the completed assistant message and resets generation state.
  Future<void> _finishGeneration({required bool stopped}) async {
    _batchTimer?.cancel();
    _flushTokenBuffer();

    final session = state.activeSession;
    if (session == null) return;

    final content = state.currentResponse;
    final chatRepo = ref.read(chatRepositoryProvider);

    // Persist the assistant message.
    final assistantMessage = await chatRepo.insertMessage(
      sessionId: session.id,
      role: 'assistant',
      content: content,
      isTruncated: stopped,
    );

    // Auto-derive session title from first user message if not yet set.
    if (session.title == null && state.messages.isNotEmpty) {
      final firstUserMsg = state.messages.firstWhere(
        (m) => m.role == 'user',
        orElse: () => state.messages.first,
      );
      final title = firstUserMsg.content.substring(
        0,
        min(50, firstUserMsg.content.length),
      );
      await chatRepo.updateSessionTitle(session.id, title);
    }

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      currentResponse: '',
      isGenerating: false,
      clearActiveRequestId: true,
    );

    _dequeueNextIfAny();
  }

  /// Handles an error from the inference stream.
  Future<void> _handleError(String message) async {
    _batchTimer?.cancel();
    _flushTokenBuffer();

    // If there is accumulated partial output, persist it as truncated.
    final session = state.activeSession;
    if (session != null && state.currentResponse.isNotEmpty) {
      final chatRepo = ref.read(chatRepositoryProvider);
      final assistantMessage = await chatRepo.insertMessage(
        sessionId: session.id,
        role: 'assistant',
        content: state.currentResponse,
        isTruncated: true,
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
      );
    }

    state = state.copyWith(
      currentResponse: '',
      isGenerating: false,
      clearActiveRequestId: true,
    );

    _dequeueNextIfAny();
  }

  /// Dequeues and processes the next pending message, if any.
  Future<void> _dequeueNextIfAny() async {
    if (_pendingQueue.isNotEmpty) {
      final next = _pendingQueue.removeFirst();
      await _processMessage(next);
    }
  }

  /// Schedules a buffer flush if one is not already pending.
  void _scheduleBatchFlush() {
    if (_batchTimer?.isActive ?? false) return;
    _batchTimer = Timer(_kTokenBatchInterval, _flushTokenBuffer);
  }

  /// Flushes buffered tokens to state, triggering at most one rebuild.
  void _flushTokenBuffer() {
    if (_tokenBuffer.isEmpty) return;
    final buffered = _tokenBuffer.toString();
    _tokenBuffer.clear();
    state = state.copyWith(
      currentResponse: state.currentResponse + buffered,
    );
  }
}
