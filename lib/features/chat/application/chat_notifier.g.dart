// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ChatNotifier)
final chatProvider = ChatNotifierProvider._();

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
final class ChatNotifierProvider
    extends $NotifierProvider<ChatNotifier, ChatState> {
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
  ChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotifierHash();

  @$internal
  @override
  ChatNotifier create() => ChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }
}

String _$chatNotifierHash() => r'4e30d298999b5bd115184176a86db8a1ce8bbd5e';

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

abstract class _$ChatNotifier extends $Notifier<ChatState> {
  ChatState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
