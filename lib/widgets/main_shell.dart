import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';

/// Placeholder main shell — replaced by real navigation shell in Phase 5/6.
///
/// Shown when [appStartupProvider] completes successfully. Provides a minimal
/// scaffold with the app name in the [AppBar] and a centred placeholder body.
///
/// RTL-ready:
/// - All padding uses [EdgeInsetsDirectional] (not [EdgeInsets]).
/// - [AppBar] title position follows the localisation direction automatically.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Center(
          child: Text(
            l10n.loading,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
