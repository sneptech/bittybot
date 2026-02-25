import '../domain/chat_message.dart';
import '../domain/chat_session.dart';

/// Abstract repository for chat persistence.
///
/// Implementations are injected via Riverpod; callers depend on this
/// interface rather than the Drift-backed [DriftChatRepository] directly.
abstract class ChatRepository {
  // ---------------------------------------------------------------------------
  // Session CRUD
  // ---------------------------------------------------------------------------

  /// Creates a new chat session and returns the persisted domain object.
  Future<ChatSession> createSession({required String mode, String? title});

  /// Returns the session with [id], or null if it does not exist.
  Future<ChatSession?> getSession(int id);

  /// Updates the title of an existing session.
  Future<void> updateSessionTitle(int sessionId, String title);

  /// Deletes a session and all its messages.
  Future<void> deleteSession(int sessionId);

  /// Reactive stream of all sessions ordered by [updatedAt] descending
  /// (most-recently-active first) — suitable for the session drawer list.
  Stream<List<ChatSession>> watchAllSessions();

  // ---------------------------------------------------------------------------
  // Message CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a new message and returns the persisted domain object.
  ///
  /// Also touches the parent session's [updatedAt] timestamp so it floats to
  /// the top of the drawer list.
  Future<ChatMessage> insertMessage({
    required int sessionId,
    required String role,
    required String content,
    bool isTruncated = false,
  });

  /// Replaces the content of an existing message (e.g., when streaming
  /// appends all tokens into the assistant message row).
  Future<void> updateMessageContent(int messageId, String content);

  /// Marks a message as truncated (user stopped generation).
  Future<void> markMessageTruncated(int messageId);

  /// Returns all messages for [sessionId] ordered by [createdAt] ascending.
  Future<List<ChatMessage>> getMessagesForSession(int sessionId);

  /// Reactive stream of messages for [sessionId] ordered chronologically.
  /// Auto-updates when new messages are inserted during streaming.
  Stream<List<ChatMessage>> watchMessagesForSession(int sessionId);

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  /// Deletes all sessions and messages (used by "Clear all history" setting).
  Future<void> deleteAllSessions();

  /// Deletes sessions older than [cutoff] and their messages.
  ///
  /// Returns the number of sessions deleted.
  Future<int> deleteSessionsOlderThan(DateTime cutoff);
}
