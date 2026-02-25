import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Chat session groups messages together by conversation.
class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Null means auto-derived from first message content by ChatNotifier.
  TextColumn get title => text().nullable()();

  /// 'chat' or 'translation'
  TextColumn get mode => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Individual message within a chat session.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key reference to ChatSessions.id.
  IntColumn get sessionId => integer().references(ChatSessions, #id)();

  /// 'user' or 'assistant'
  TextColumn get role => text()();

  TextColumn get content => text()();

  /// True if the user stopped generation before completion (truncated output).
  BoolColumn get isTruncated =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}

/// Drift database for BittyBot.
///
/// Schema version 1 (Phase 3): empty stub.
/// Schema version 2 (Phase 4): adds ChatSessions and ChatMessages tables.
///
/// The [driftDatabase] function from drift_flutter handles platform-specific
/// database location automatically (documents dir on iOS/Android).
@DriftDatabase(tables: [ChatSessions, ChatMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        // Phase 3 had no tables; Phase 4 adds sessions + messages.
        await m.createTable(chatSessions);
        await m.createTable(chatMessages);
      }
    },
    beforeOpen: (details) async {
      // WAL mode enables concurrent reads during inference (worker isolate
      // may be reading while main thread writes a new message).
      await customStatement('PRAGMA journal_mode=WAL');
      // Enforce referential integrity between ChatMessages and ChatSessions.
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'bittybot');
  }

  /// Watch all messages for a session ordered chronologically.
  /// Auto-updates when new messages are inserted.
  Stream<List<ChatMessage>> watchMessagesForSession(int sessionId) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }
}
