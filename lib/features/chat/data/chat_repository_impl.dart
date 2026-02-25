import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart' as db;
import '../domain/chat_message.dart';
import '../domain/chat_session.dart';
import 'chat_repository.dart';

/// Drift-backed implementation of [ChatRepository].
///
/// Receives [AppDatabase] via constructor for dependency injection.
/// Uses prefixed import `db` to disambiguate Drift-generated [db.ChatSession]
/// and [db.ChatMessage] row types from domain value objects.
class DriftChatRepository implements ChatRepository {
  final db.AppDatabase _db;

  const DriftChatRepository(this._db);

  // ---------------------------------------------------------------------------
  // Session CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<ChatSession> createSession({
    required String mode,
    String? title,
  }) async {
    final now = DateTime.now();
    final companion = db.ChatSessionsCompanion.insert(
      mode: mode,
      title: title == null ? const Value.absent() : Value(title),
      createdAt: now,
      updatedAt: now,
    );
    final id = await _db.into(_db.chatSessions).insert(companion);
    final row = await (_db.select(_db.chatSessions)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    return _mapSession(row);
  }

  @override
  Future<ChatSession?> getSession(int id) async {
    final row = await (_db.select(_db.chatSessions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapSession(row);
  }

  @override
  Future<void> updateSessionTitle(int sessionId, String title) async {
    await (_db.update(_db.chatSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(
          db.ChatSessionsCompanion(
            title: Value(title),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    // Delete child messages first to satisfy the foreign key constraint.
    await (_db.delete(_db.chatMessages)
          ..where((m) => m.sessionId.equals(sessionId)))
        .go();
    await (_db.delete(_db.chatSessions)
          ..where((s) => s.id.equals(sessionId)))
        .go();
  }

  @override
  Stream<List<ChatSession>> watchAllSessions() {
    return (_db.select(_db.chatSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_mapSession).toList());
  }

  // ---------------------------------------------------------------------------
  // Message CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<ChatMessage> insertMessage({
    required int sessionId,
    required String role,
    required String content,
    bool isTruncated = false,
  }) async {
    final now = DateTime.now();
    final companion = db.ChatMessagesCompanion.insert(
      sessionId: sessionId,
      role: role,
      content: content,
      isTruncated: Value(isTruncated),
      createdAt: now,
    );
    final id = await _db.into(_db.chatMessages).insert(companion);

    // Touch the session's updatedAt so it rises to the top of the drawer list.
    await (_db.update(_db.chatSessions)
          ..where((s) => s.id.equals(sessionId)))
        .write(db.ChatSessionsCompanion(updatedAt: Value(now)));

    final row = await (_db.select(_db.chatMessages)
          ..where((m) => m.id.equals(id)))
        .getSingle();
    return _mapMessage(row);
  }

  @override
  Future<void> updateMessageContent(int messageId, String content) async {
    await (_db.update(_db.chatMessages)
          ..where((m) => m.id.equals(messageId)))
        .write(db.ChatMessagesCompanion(content: Value(content)));
  }

  @override
  Future<void> markMessageTruncated(int messageId) async {
    await (_db.update(_db.chatMessages)
          ..where((m) => m.id.equals(messageId)))
        .write(const db.ChatMessagesCompanion(isTruncated: Value(true)));
  }

  @override
  Future<List<ChatMessage>> getMessagesForSession(int sessionId) async {
    final rows = await (_db.select(_db.chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
    return rows.map(_mapMessage).toList();
  }

  @override
  Stream<List<ChatMessage>> watchMessagesForSession(int sessionId) {
    return (_db.select(_db.chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapMessage).toList());
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteAllSessions() async {
    await _db.delete(_db.chatMessages).go();
    await _db.delete(_db.chatSessions).go();
  }

  @override
  Future<int> deleteSessionsOlderThan(DateTime cutoff) async {
    // Find session IDs older than cutoff.
    final oldSessions = await (_db.select(_db.chatSessions)
          ..where((s) => s.createdAt.isSmallerThanValue(cutoff)))
        .get();

    if (oldSessions.isEmpty) return 0;

    final oldIds = oldSessions.map((s) => s.id).toList();

    // Delete messages for those sessions.
    await (_db.delete(_db.chatMessages)
          ..where((m) => m.sessionId.isIn(oldIds)))
        .go();

    // Delete the sessions themselves.
    await (_db.delete(_db.chatSessions)
          ..where((s) => s.id.isIn(oldIds)))
        .go();

    return oldSessions.length;
  }

  // ---------------------------------------------------------------------------
  // Private mappers — convert Drift-generated row types to domain value objects
  // ---------------------------------------------------------------------------

  ChatSession _mapSession(db.ChatSession row) => ChatSession(
    id: row.id,
    title: row.title,
    mode: row.mode,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ChatMessage _mapMessage(db.ChatMessage row) => ChatMessage(
    id: row.id,
    sessionId: row.sessionId,
    role: row.role,
    content: row.content,
    isTruncated: row.isTruncated,
    createdAt: row.createdAt,
  );
}
