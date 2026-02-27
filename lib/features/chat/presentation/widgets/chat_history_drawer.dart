import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/chat_notifier.dart';
import '../../application/chat_repository_provider.dart';
import '../../application/chat_sessions_provider.dart';
import '../../domain/chat_session.dart';
import '../../../settings/presentation/settings_screen.dart';

/// Drawer listing persisted chat sessions.
///
/// Shows chat-only sessions (filtered by [chatSessionsProvider]), lets users
/// switch sessions, start a new chat, and delete sessions with confirmation.
class ChatHistoryDrawer extends ConsumerWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final activeSessionId = ref.watch(
      chatProvider.select((state) => state.activeSession?.id),
    );
    final isGenerating = ref.watch(
      chatProvider.select((state) => state.isGenerating),
    );

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              onOpenSettings: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              onNewChat: isGenerating
                  ? null
                  : () {
                      Navigator.pop(context);
                      ref.read(chatProvider.notifier).startNewSession();
                    },
            ),
            Divider(
              height: 1,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          24,
                          16,
                          24,
                          16,
                        ),
                        child: Text(
                          l10n.chatHistoryEmpty,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final title = _sessionTitle(session, l10n);
                      final subtitle = _formatRelativeTime(
                        context,
                        session.updatedAt,
                      );

                      return Dismissible(
                        key: ValueKey('chat-session-${session.id}'),
                        direction: isGenerating
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            2,
                            12,
                            2,
                          ),
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          alignment: AlignmentDirectional.centerEnd,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppColors.onError,
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDeleteDialog(context),
                        onDismissed: (_) async {
                          final chatRepo = ref.read(chatRepositoryProvider);
                          await chatRepo.deleteSession(session.id);

                          if (activeSessionId == session.id) {
                            int? replacementSessionId;
                            for (final candidate in sessions) {
                              if (candidate.id != session.id) {
                                replacementSessionId = candidate.id;
                                break;
                              }
                            }

                            if (replacementSessionId != null) {
                              await ref
                                  .read(chatProvider.notifier)
                                  .loadSession(replacementSessionId);
                              return;
                            }

                            final newSession = await chatRepo.createSession(
                              mode: 'chat',
                            );
                            await ref
                                .read(chatProvider.notifier)
                                .loadSession(newSession.id);
                          }
                        },
                        child: ListTile(
                          selected: session.id == activeSessionId,
                          selectedTileColor: AppColors.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            4,
                            12,
                            4,
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          onTap: isGenerating
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  ref
                                      .read(chatProvider.notifier)
                                      .loadSession(session.id);
                                },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      24,
                      16,
                      24,
                      16,
                    ),
                    child: Text(
                      l10n.genericErrorDirect,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onOpenSettings, required this.onNewChat});

  final VoidCallback onOpenSettings;
  final VoidCallback? onNewChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.chatHistory,
              style: textTheme.titleLarge?.copyWith(color: AppColors.onSurface),
            ),
          ),
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            color: AppColors.onSurfaceVariant,
          ),
          IconButton(
            onPressed: onNewChat,
            icon: const Icon(Icons.edit_square),
            tooltip: l10n.newChat,
            color: onNewChat == null
                ? AppColors.onSurfaceVariant
                : AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

String _sessionTitle(ChatSession session, AppLocalizations l10n) {
  final title = session.title?.trim();
  if (title == null || title.isEmpty) return l10n.newChat;
  return title;
}

Future<bool> _confirmDeleteDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);

  return (await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteSession),
          content: Text(l10n.deleteSessionConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.ok),
            ),
          ],
        ),
      )) ??
      false;
}

String _formatRelativeTime(BuildContext context, DateTime timestamp) {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final localTimestamp = timestamp.toLocal();
  final difference = now.difference(localTimestamp);

  if (difference.isNegative || difference.inMinutes < 1) {
    return l10n.justNow;
  }

  if (difference.inHours < 1) {
    return l10n.minutesAgo(difference.inMinutes);
  }

  final nowDate = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(
    localTimestamp.year,
    localTimestamp.month,
    localTimestamp.day,
  );
  final dayDiff = nowDate.difference(messageDate).inDays;

  if (dayDiff == 0) {
    return l10n.hoursAgo(difference.inHours);
  }

  if (dayDiff == 1) {
    return l10n.yesterday;
  }

  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMd(locale).format(localTimestamp);
}
