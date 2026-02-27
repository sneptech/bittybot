// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_messages_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive stream of messages for a given chat session.
///
/// Used by [ChatBubbleList] to render persisted messages and react to live
/// inserts while the model is streaming.
///
/// Pass the active [sessionId] from [ChatState.activeSession?.id].

@ProviderFor(chatSessionMessages)
final chatSessionMessagesProvider = ChatSessionMessagesFamily._();

/// Reactive stream of messages for a given chat session.
///
/// Used by [ChatBubbleList] to render persisted messages and react to live
/// inserts while the model is streaming.
///
/// Pass the active [sessionId] from [ChatState.activeSession?.id].

final class ChatSessionMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  /// Reactive stream of messages for a given chat session.
  ///
  /// Used by [ChatBubbleList] to render persisted messages and react to live
  /// inserts while the model is streaming.
  ///
  /// Pass the active [sessionId] from [ChatState.activeSession?.id].
  ChatSessionMessagesProvider._({
    required ChatSessionMessagesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'chatSessionMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatSessionMessagesHash();

  @override
  String toString() {
    return r'chatSessionMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as int;
    return chatSessionMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSessionMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSessionMessagesHash() =>
    r'9d3ace7d4a8036f605e0c47ff9d52b5dabb774e9';

/// Reactive stream of messages for a given chat session.
///
/// Used by [ChatBubbleList] to render persisted messages and react to live
/// inserts while the model is streaming.
///
/// Pass the active [sessionId] from [ChatState.activeSession?.id].

final class ChatSessionMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, int> {
  ChatSessionMessagesFamily._()
    : super(
        retry: null,
        name: r'chatSessionMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reactive stream of messages for a given chat session.
  ///
  /// Used by [ChatBubbleList] to render persisted messages and react to live
  /// inserts while the model is streaming.
  ///
  /// Pass the active [sessionId] from [ChatState.activeSession?.id].

  ChatSessionMessagesProvider call(int sessionId) =>
      ChatSessionMessagesProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'chatSessionMessagesProvider';
}
