import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';

/// Full-screen loading display shown while the app startup is initialising.
///
/// Displayed by [AppStartupWidget] when [appStartupProvider] is in the
/// loading state (settings not yet loaded, or future phases: model loading).
///
/// Design (UIUX-02 — minimal, no heavy decoration):
/// - [AppColors.surface] background (near-black green).
/// - Centred column: app name, loading title, body message, progress indicator.
/// - [CircularProgressIndicator] uses the lime/secondary accent colour.
/// - All padding via [EdgeInsetsDirectional] for RTL correctness.
class ModelLoadingScreen extends StatelessWidget {
  const ModelLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App brand name — const string, same in all languages.
                Text(
                  'BittyBot',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Loading title from localizations.
                Text(
                  l10n.modelLoadingTitle,
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Loading body message from localizations.
                Text(
                  l10n.modelLoadingMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Lime/secondary accent progress indicator.
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
