import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers.dart';

/// Shared preferences key for clearing saved progress on "Start over".
const _kProgressKey = 'model_download_progress';

/// Dialog shown when a partial download was detected from a previous session.
///
/// Per user decision: BittyBot NEVER auto-resumes a previous download on
/// reopen. The user is always asked to confirm because resuming a 2.14 GB
/// download is a meaningful action (especially on cellular).
///
/// Call [ResumePromptDialog.show] from a widget to display modally.
class ResumePromptDialog extends ConsumerWidget {
  const ResumePromptDialog({
    super.key,
    required this.progressFraction,
  });

  /// Fraction of the download already completed (0.0–1.0).
  /// Shown as a percentage in the dialog body text.
  final double progressFraction;

  /// Shows the resume prompt as a modal [AlertDialog].
  ///
  /// The dialog is not dismissible via back-press or tapping outside —
  /// the user must choose one of the two explicit options.
  static Future<void> show(
    BuildContext context, {
    required double progressFraction,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ResumePromptDialog(
        progressFraction: progressFraction,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressPercent = (progressFraction * 100).round();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.resumeDownloadTitle,
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 18, // 18sp per spec
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.modelRequiredOfflineMessage,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.downloadProgressComplete(progressPercent),
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar showing saved fraction
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Clear saved progress — "Start over" begins from 0%
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_kProgressKey);
            if (context.mounted) {
              Navigator.of(context).pop();
              ref.read(modelDistributionProvider.notifier).startOverDownload();
            }
          },
          child: Text(
            l10n.startOver,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onSurface,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(modelDistributionProvider.notifier).confirmResume();
          },
          child: Text(l10n.resumeAction),
        ),
      ],
    );
  }
}
