import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/error_messages.dart';
import '../core/error/error_tone.dart';
import '../core/l10n/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../features/settings/application/settings_provider.dart';

/// Full-screen error display shown when app startup fails.
///
/// Displayed by [AppStartupWidget] when [appStartupProvider] enters the
/// error state. Uses [resolveErrorMessage] with [AppError.modelNotLoaded]
/// for the error text — this is the most common startup failure scenario.
///
/// If settings failed to load (the error cause), the tone defaults to
/// [ErrorTone.friendly] as a safe fallback.
///
/// The [onRetry] callback should call `ref.invalidate(appStartupProvider)`
/// to restart the startup sequence.
class AppStartupErrorScreen extends ConsumerWidget {
  const AppStartupErrorScreen({
    required this.onRetry,
    this.error,
    super.key,
  });

  /// Called when the user taps the retry button.
  /// Callers should invalidate [appStartupProvider] to restart startup.
  final VoidCallback onRetry;

  /// Optional error object for future diagnostic use (not displayed to user).
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    // Use tone from settings if available; fall back to friendly if settings
    // failed to load (which is the cause of this error screen in most cases).
    final tone = ref.watch(settingsProvider).value?.errorTone ?? ErrorTone.friendly;

    final errorMessage = resolveErrorMessage(l10n, AppError.modelNotLoaded, tone);

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
                // Error icon — uses error colour from theme.
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                // Error heading from localizations.
                Text(
                  l10n.modelLoadingError,
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Tone-appropriate error message.
                Text(
                  errorMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Retry button — minimum 48×48dp tap target (UIUX-04).
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
