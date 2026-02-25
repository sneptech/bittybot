import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../chat/application/chat_repository_provider.dart';
import '../../chat/domain/chat_message.dart';

part 'session_messages_provider.g.dart';

/// Reactive stream of messages for a given translation session.
///
/// Used by TranslationScreen to display the bubble list. Auto-updates
/// when new messages are inserted during translation streaming.
///
/// Pass the [sessionId] from [TranslationState.activeSession.id].
///
/// Example:
/// ```dart
/// final sessionId = ref.watch(
///   translationNotifierProvider.select((s) => s.activeSession?.id),
/// );
/// if (sessionId != null) {
///   final messages = ref.watch(sessionMessagesProvider(sessionId));
/// }
/// ```
@riverpod
Stream<List<ChatMessage>> sessionMessages(Ref ref, int sessionId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchMessagesForSession(sessionId);
}
