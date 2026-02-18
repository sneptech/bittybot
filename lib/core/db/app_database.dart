import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Empty Drift database stub for Phase 3.
///
/// Phase 4 will add chat session and message tables.
/// The [driftDatabase] function from drift_flutter handles platform-specific
/// database location automatically (documents dir on iOS/Android).
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'bittybot');
  }
}
