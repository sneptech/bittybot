import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';

/// Subtle warning banner shown when a session context approaches the
/// model's limit (~90% of nCtx=2048 tokens).
class ContextFullBanner extends StatelessWidget {
  const ContextFullBanner({
    super.key,
    required this.onNewSession,
    required this.l10n,
  });

  final VoidCallback onNewSession;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.secondaryContainer,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.contextFullBanner,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onNewSession,
            child: Text(
              l10n.newSession,
              style: textTheme.labelSmall?.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
