import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/chat_message.dart';
import 'chat_repository_provider.dart';

part 'chat_session_messages_provider.g.dart';

/// Reactive stream of messages for a given chat session.
///
/// Used by [ChatBubbleList] to render persisted messages and react to live
/// inserts while the model is streaming.
///
/// Pass the active [sessionId] from [ChatState.activeSession?.id].
@riverpod
Stream<List<ChatMessage>> chatSessionMessages(Ref ref, int sessionId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchMessagesForSession(sessionId);
}
