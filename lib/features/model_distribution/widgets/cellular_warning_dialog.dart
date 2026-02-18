import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Dialog shown when the device is on a cellular connection and the user
/// attempts to download the ~2.14 GB language model.
///
/// Per user decision: the app does NOT block cellular downloads at the OS
/// level — it asks for explicit user confirmation so they understand the
/// data cost before proceeding.
///
/// Call [CellularWarningDialog.show] from a widget to display modally.
class CellularWarningDialog extends ConsumerWidget {
  const CellularWarningDialog({super.key});

  /// Shows the cellular warning as a modal [AlertDialog].
  ///
  /// The dialog is not dismissible via back-press or tapping outside —
  /// the user must choose one of the two explicit options.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const CellularWarningDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), // TODO(phase-3): design system
      title: const Text(
        'Download on cellular data?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18, // 18sp per spec
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'This download is ~2.14 GB. Continue on cellular?',
        style: TextStyle(
          color: Colors.white70, // TODO(phase-3): Replace with design system color
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Stay in CellularWarningState — notifier does not change state.
            // User can re-open on Wi-Fi to re-run preflight automatically.
            Navigator.of(context).pop();
          },
          child: const Text(
            'Wait for Wi-Fi',
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
            ref
                .read(modelDistributionProvider.notifier)
                .confirmCellularDownload();
          },
          child: const Text('Download now'),
        ),
      ],
    );
  }
}
