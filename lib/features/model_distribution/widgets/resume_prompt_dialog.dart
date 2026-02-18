import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final progressPercent = (progressFraction * 100).round();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), // TODO(phase-3): design system
      title: const Text(
        'Resume download?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18, // 18sp per spec
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BittyBot needs this language model to translate and chat offline.',
            style: TextStyle(
              color: Colors.white70, // TODO(phase-3): Replace with design system color
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Download is $progressPercent% complete',
            style: TextStyle(
              color: Colors.grey[300], // TODO(phase-3): Replace with design system color
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
              backgroundColor: const Color(0xFF3A3A3A),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2D6A4F), // TODO(phase-3): Replace with design system forest green
              ),
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
              // retryDownload() increments failureCount then calls _runPreflight()
              // which will see no saved progress and start fresh.
              // Use ref inside the callback directly — it is still valid.
              ref.read(modelDistributionProvider.notifier).retryDownload();
            }
          },
          child: const Text(
            'Start over',
            style: TextStyle(
              color: Colors.white54, // TODO(phase-3): Replace with design system color
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF2D6A4F), // TODO(phase-3): design system forest green
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(modelDistributionProvider.notifier).confirmResume();
          },
          child: const Text('Resume'),
        ),
      ],
    );
  }
}
