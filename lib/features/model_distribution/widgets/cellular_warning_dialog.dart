import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../model_constants.dart';
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
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.downloadOnCellularDataTitle,
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 18, // 18sp per spec
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        l10n.downloadOnCellularDataMessage(ModelConstants.fileSizeDisplayGB),
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
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
          child: Text(
            l10n.waitForWifi,
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
            ref
                .read(modelDistributionProvider.notifier)
                .confirmCellularDownload();
          },
          child: Text(l10n.downloadNow),
        ),
      ],
    );
  }
}
