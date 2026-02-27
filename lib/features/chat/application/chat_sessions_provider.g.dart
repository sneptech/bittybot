// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_sessions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive stream of chat sessions for the history drawer.
///
/// Filters out non-chat sessions (for example, translation sessions) so the
/// drawer only renders conversation history from chat mode.
///
/// Upstream ordering from `watchAllSessions()` is preserved (`updatedAt`
/// descending), so the most recently active chat appears first.

@ProviderFor(chatSessions)
final chatSessionsProvider = ChatSessionsProvider._();

/// Reactive stream of chat sessions for the history drawer.
///
/// Filters out non-chat sessions (for example, translation sessions) so the
/// drawer only renders conversation history from chat mode.
///
/// Upstream ordering from `watchAllSessions()` is preserved (`updatedAt`
/// descending), so the most recently active chat appears first.

final class ChatSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatSession>>,
          List<ChatSession>,
          Stream<List<ChatSession>>
        >
    with
        $FutureModifier<List<ChatSession>>,
        $StreamProvider<List<ChatSession>> {
  /// Reactive stream of chat sessions for the history drawer.
  ///
  /// Filters out non-chat sessions (for example, translation sessions) so the
  /// drawer only renders conversation history from chat mode.
  ///
  /// Upstream ordering from `watchAllSessions()` is preserved (`updatedAt`
  /// descending), so the most recently active chat appears first.
  ChatSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatSession>> create(Ref ref) {
    return chatSessions(ref);
  }
}

String _$chatSessionsHash() => r'6f1862cc05e3c21b54ed32e93ec723fca1a0726c';
