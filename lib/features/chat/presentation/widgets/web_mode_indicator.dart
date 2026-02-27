import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact chip shown above chat input when web-search mode is active.
class WebModeIndicator extends StatelessWidget {
  const WebModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 14,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.webSearchMode,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
