import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../model_constants.dart';
import '../model_distribution_state.dart';
import '../providers.dart';
import 'cellular_warning_dialog.dart';
import 'resume_prompt_dialog.dart';

// ─── Download screen ─────────────────────────────────────────────────────────

/// Full-screen download screen shown on first launch until the model is ready.
///
/// Watches [modelDistributionProvider] and renders the appropriate UI for
/// each [ModelDistributionState] variant. An exhaustive switch ensures that
/// new states added to the sealed class produce a compile error here.
///
/// Navigation away from this screen is handled by Plan 03 (app routing). This
/// widget does NOT push/pop — it just shows the relevant state UI.
class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  /// Tracks whether a dialog is currently visible to avoid double-showing
  /// dialogs on rapid state rebuilds.
  bool _dialogVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modelState = ref.watch(modelDistributionProvider);

    // Show dialogs via post-frame callback to avoid setState-during-build
    if (modelState is CellularWarningState && !_dialogVisible) {
      _dialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await CellularWarningDialog.show(context);
          if (mounted) setState(() => _dialogVisible = false);
        }
      });
    } else if (modelState is ResumePromptState && !_dialogVisible) {
      _dialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await ResumePromptDialog.show(
            context,
            progressFraction: modelState.progressFraction,
          );
          if (mounted) setState(() => _dialogVisible = false);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                Text(
                  l10n.downloadingLanguageModelForOfflineUse(
                    ModelConstants.fileSizeDisplayGB,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14, // 14sp per spec
                  ),
                ),
                const SizedBox(height: 40),
                _buildStateContent(modelState, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    // TODO: Replace placeholder with Image.asset() when a logo asset is added.
    // No logo asset currently exists in the project (only assets/icon.png).
    return Icon(Icons.smart_toy, size: 80, color: AppColors.onSurfaceVariant);
  }

  // ─── State-specific content ────────────────────────────────────────────────

  Widget _buildStateContent(
    ModelDistributionState state,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      CheckingModelState() => _buildSpinner(l10n.checkingForLanguageModel),
      PreflightState() => _buildSpinner(l10n.preparingDownload),
      ResumePromptState(progressFraction: final fraction) => _buildProgressBar(
        fraction,
        l10n: l10n,
        downloadedBytes: 0,
        totalBytes: 0,
        networkSpeedMBps: 0,
        timeRemaining: null,
        isBackground: true,
      ),
      CellularWarningState() => _buildSpinner(l10n.awaitingYourChoice),
      InsufficientStorageState(
        neededBytes: final needed,
        availableBytes: final available,
      ) =>
        _buildStorageError(needed, available, l10n),
      DownloadingState(
        progressFraction: final fraction,
        downloadedBytes: final downloaded,
        totalBytes: final total,
        networkSpeedMBps: final speed,
        timeRemaining: final eta,
      ) =>
        _buildProgressBar(
          fraction,
          l10n: l10n,
          downloadedBytes: downloaded,
          totalBytes: total,
          networkSpeedMBps: speed,
          timeRemaining: eta,
        ),
      VerifyingState() => _buildSpinner(l10n.verifyingDownload),
      LowMemoryWarningState(availableMB: final memMB) => _buildLowMemoryWarning(
        memMB,
        l10n,
      ),
      // LoadingModelState and ModelReadyState should not appear on this screen —
      // Plan 03 routing will have navigated away. Show fallbacks in case.
      LoadingModelState() => _buildSpinner(l10n.loadingLanguageModel),
      ModelReadyState() => _buildSpinner(l10n.readyStatus),
      ErrorState(
        kind: final kind,
        message: final msg,
        failureCount: final count,
      ) =>
        _buildError(msg, count, l10n, kind),
    };
  }

  // ─── Spinner ──────────────────────────────────────────────────────────────

  Widget _buildSpinner(String label) {
    return Column(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────────────────

  Widget _buildProgressBar(
    double progressFraction, {
    required AppLocalizations l10n,
    required int downloadedBytes,
    required int totalBytes,
    required double networkSpeedMBps,
    required Duration? timeRemaining,
    bool isBackground = false,
  }) {
    // progress < 0 is a sentinel value (unknown) — use indeterminate bar
    final value = progressFraction >= 0 ? progressFraction : null;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        if (!isBackground) ...[
          const SizedBox(height: 12),
          Text(
            '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12, // 12sp per spec
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.downloadSpeedAndRemaining(
              _formatSpeed(networkSpeedMBps),
              _formatDuration(timeRemaining, l10n),
            ),
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12, // 12sp per spec
            ),
          ),
        ],
      ],
    );
  }

  // ─── Insufficient storage error ───────────────────────────────────────────

  Widget _buildStorageError(
    int neededBytes,
    int availableBytes,
    AppLocalizations l10n,
  ) {
    final neededGB = (neededBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final availableGB = (availableBytes / (1024 * 1024 * 1024)).toStringAsFixed(
      1,
    );

    return _buildCard(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      title: l10n.notEnoughStorage,
      message: l10n.storageRequirementMessage(neededGB, availableGB),
      buttonLabel: l10n.freeUpSpaceAndTryAgain,
      onButton: () =>
          ref.read(modelDistributionProvider.notifier).retryDownload(),
    );
  }

  // ─── Low memory warning ───────────────────────────────────────────────────

  Widget _buildLowMemoryWarning(int availableMB, AppLocalizations l10n) {
    return _buildCard(
      icon: Icons.memory,
      iconColor: AppColors.warning,
      title: l10n.lowMemoryWarning,
      message: l10n.lowMemoryWarningMessage(availableMB),
      buttonLabel: l10n.continueAnyway,
      onButton: () => ref
          .read(modelDistributionProvider.notifier)
          .acknowledgeMemoryWarning(),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(
    String message,
    int failureCount,
    AppLocalizations l10n,
    DownloadErrorKind kind,
  ) {
    final localizedMessage = switch (kind) {
      DownloadErrorKind.noInternet => l10n.downloadErrorNoInternet,
      DownloadErrorKind.downloadFailed =>
        message.isNotEmpty ? message : l10n.downloadErrorFailed,
      DownloadErrorKind.notFound => l10n.downloadErrorNotFound,
      DownloadErrorKind.verificationFailed =>
        l10n.downloadErrorVerificationFailed,
    };

    return _buildCard(
      icon: Icons.error_outline,
      iconColor: AppColors.error,
      title: l10n.downloadFailed,
      // message may include library exception details for downloadFailed.
      message: localizedMessage,
      buttonLabel: l10n.retry,
      onButton: () =>
          ref.read(modelDistributionProvider.notifier).retryDownload(),
    );
  }

  // ─── Shared card layout ───────────────────────────────────────────────────

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    return Column(
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14, // 14sp per spec
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onSurface,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 32,
              vertical: 14,
            ),
          ),
          onPressed: onButton,
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  // ─── Formatting helpers ───────────────────────────────────────────────────

  /// Formats [bytes] as "X.X MB" or "X.XX GB" for the progress display.
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Formats [d] as "Xh Ym", "Ym Zs", or "Calculating..." if null/negative.
  String _formatDuration(Duration? d, AppLocalizations l10n) {
    if (d == null || d.isNegative) return l10n.calculating;
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return l10n.durationHoursMinutes(hours, minutes);
    }
    if (d.inMinutes >= 1) {
      final minutes = d.inMinutes;
      final seconds = d.inSeconds.remainder(60);
      return l10n.durationMinutesSeconds(minutes, seconds);
    }
    return l10n.durationSeconds(d.inSeconds);
  }

  /// Formats [mbps] as "X.X MB/s".
  String _formatSpeed(double mbps) {
    if (mbps <= 0) return '0.0 MB/s';
    return '${mbps.toStringAsFixed(1)} MB/s';
  }
}
