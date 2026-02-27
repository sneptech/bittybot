import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/chat_session.dart';
import 'chat_repository_provider.dart';

part 'chat_sessions_provider.g.dart';

/// Reactive stream of chat sessions for the history drawer.
///
/// Filters out non-chat sessions (for example, translation sessions) so the
/// drawer only renders conversation history from chat mode.
///
/// Upstream ordering from `watchAllSessions()` is preserved (`updatedAt`
/// descending), so the most recently active chat appears first.
@riverpod
Stream<List<ChatSession>> chatSessions(Ref ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchAllSessions().map(
    (sessions) => sessions.where((session) => session.mode == 'chat').toList(),
  );
}
