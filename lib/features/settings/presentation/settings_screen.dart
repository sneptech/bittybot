import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/application/chat_notifier.dart';
import '../../chat/application/chat_repository_provider.dart';
import '../application/settings_provider.dart';

/// Screen for chat-specific settings and history maintenance actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAllHistory),
        content: Text(l10n.clearAllHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.clearAllHistoryAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(chatRepositoryProvider).deleteAllSessions();
    ref.invalidate(chatProvider);

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final settingsAsync = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
          children: [
            _SectionHeader(text: l10n.chatSettings),
            SwitchListTile(
              value: settings.autoClearEnabled,
              onChanged: settingsNotifier.setAutoClearEnabled,
              title: Text(
                l10n.autoClearHistory,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                l10n.autoClearDescription,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              activeThumbColor: AppColors.secondary,
            ),
            if (settings.autoClearEnabled)
              ListTile(
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  16,
                  0,
                  16,
                  0,
                ),
                title: Text(
                  l10n.autoClearPeriod,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                trailing: DropdownButton<int>(
                  value: settings.autoClearDays,
                  dropdownColor: AppColors.surfaceContainer,
                  items: [7, 30, 90]
                      .map(
                        (days) => DropdownMenuItem<int>(
                          value: days,
                          child: Text(
                            l10n.daysCount(days),
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (days) {
                    if (days == null) return;
                    settingsNotifier.setAutoClearDays(days);
                  },
                ),
              ),
            const Divider(height: 24),
            _SectionHeader(text: l10n.dangerZone),
            ListTile(
              contentPadding: const EdgeInsetsDirectional.fromSTEB(
                16,
                0,
                16,
                0,
              ),
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                l10n.clearAllHistory,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
              ),
              onTap: () => _showClearAllDialog(context, ref),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        text,
        style: textTheme.titleSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
