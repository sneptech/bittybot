import '../../chat/data/chat_repository.dart';
import 'settings_provider.dart';

/// Runs startup auto-clear based on persisted user settings.
///
/// Returns the number of sessions deleted.
Future<int> runAutoClearIfEnabled({
  required AppSettings settings,
  required ChatRepository chatRepo,
}) async {
  if (!settings.autoClearEnabled) return 0;

  final cutoff = DateTime.now().subtract(
    Duration(days: settings.autoClearDays),
  );
  return chatRepo.deleteSessionsOlderThan(cutoff);
}
