import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../data/chat_repository.dart';
import '../data/chat_repository_impl.dart';

part 'chat_repository_provider.g.dart';

/// Provides the single [AppDatabase] instance for the lifetime of the app.
///
/// [keepAlive: true] ensures the database connection is never closed while
/// the app is running. [ref.onDispose] closes it on provider teardown
/// (e.g., during test cleanup).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Provides [ChatRepository] backed by the app's [AppDatabase].
///
/// Consumers (ChatNotifier, session drawer) depend on the abstract
/// [ChatRepository] interface — never on [DriftChatRepository] directly.
///
/// [keepAlive: true] keeps the repository alive for the full app session so
/// callers do not recreate it on each watch cycle.
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftChatRepository(db);
}
