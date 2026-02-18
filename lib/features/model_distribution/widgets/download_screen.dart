import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model_distribution_state.dart';
import '../providers.dart';
import 'cellular_warning_dialog.dart';
import 'resume_prompt_dialog.dart';

// ─── Placeholder colours ──────────────────────────────────────────────────────
// All colours below are placeholders. Phase 3 defines the design system.

/// Dark background for the download screen.
const _kBackground = Color(0xFF121212); // TODO(phase-3): Replace with design system color

/// Forest green used for the progress bar and action buttons.
const _kForestGreen = Color(0xFF2D6A4F); // TODO(phase-3): Replace with design system color

/// Primary text colour on the dark background.
const _kTextPrimary = Colors.white; // TODO(phase-3): Replace with design system color

/// Secondary/explanatory text colour.
const _kTextSecondary = Color(0xFFB0B0B0); // TODO(phase-3): Replace with design system color

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
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Downloading language model for offline use',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14, // 14sp per spec
                  ),
                ),
                const SizedBox(height: 40),
                _buildStateContent(modelState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    // TODO(phase-3): Replace placeholder with Image.asset('assets/logo_greyscale.png', width: 120)
    // when the user supplies the logo asset.
    return const Icon(
      Icons.smart_toy,
      size: 80,
      color: Colors.grey, // Greyscale placeholder; Phase 3 provides real asset
    );
  }

  // ─── State-specific content ────────────────────────────────────────────────

  Widget _buildStateContent(ModelDistributionState state) {
    return switch (state) {
      CheckingModelState() => _buildSpinner('Checking for language model...'),
      PreflightState() => _buildSpinner('Preparing download...'),
      ResumePromptState(progressFraction: final fraction) =>
        _buildProgressBar(fraction, downloadedBytes: 0, totalBytes: 0,
            networkSpeedMBps: 0, timeRemaining: null, isBackground: true),
      CellularWarningState() => _buildSpinner('Awaiting your choice...'),
      InsufficientStorageState(
        neededBytes: final needed,
        availableBytes: final available
      ) =>
        _buildStorageError(needed, available),
      DownloadingState(
        progressFraction: final fraction,
        downloadedBytes: final downloaded,
        totalBytes: final total,
        networkSpeedMBps: final speed,
        timeRemaining: final eta
      ) =>
        _buildProgressBar(fraction,
            downloadedBytes: downloaded,
            totalBytes: total,
            networkSpeedMBps: speed,
            timeRemaining: eta),
      VerifyingState() => _buildSpinner('Verifying download...'),
      LowMemoryWarningState(availableMB: final memMB) =>
        _buildLowMemoryWarning(memMB),
      // LoadingModelState and ModelReadyState should not appear on this screen —
      // Plan 03 routing will have navigated away. Show fallbacks in case.
      LoadingModelState() => _buildSpinner('Loading language model...'),
      ModelReadyState() => _buildSpinner('Ready!'),
      ErrorState(message: final msg, failureCount: final count) =>
        _buildError(msg, count),
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
            valueColor: AlwaysStoppedAnimation<Color>(_kForestGreen),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kTextSecondary, fontSize: 14),
        ),
      ],
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────────────────

  Widget _buildProgressBar(
    double progressFraction, {
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
            backgroundColor: const Color(0xFF3A3A3A),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_kForestGreen),
          ),
        ),
        if (!isBackground) ...[
          const SizedBox(height: 12),
          Text(
            '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 12, // 12sp per spec
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatSpeed(networkSpeedMBps)} - ${_formatDuration(timeRemaining)} remaining',
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 12, // 12sp per spec
            ),
          ),
        ],
      ],
    );
  }

  // ─── Insufficient storage error ───────────────────────────────────────────

  Widget _buildStorageError(int neededBytes, int availableBytes) {
    final neededGB = (neededBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final availableGB =
        (availableBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

    return _buildCard(
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.amber,
      title: 'Not enough storage',
      message:
          'BittyBot needs $neededGB GB free. You have $availableGB GB available.',
      buttonLabel: 'Free up space and try again',
      onButton: () =>
          ref.read(modelDistributionProvider.notifier).retryDownload(),
    );
  }

  // ─── Low memory warning ───────────────────────────────────────────────────

  Widget _buildLowMemoryWarning(int availableMB) {
    return _buildCard(
      icon: Icons.memory,
      iconColor: Colors.amber,
      title: 'Low memory warning',
      message:
          'Your device has $availableMB MB of RAM. Performance may be poor or '
          'the app may not function at all on this device.',
      buttonLabel: 'Continue anyway',
      onButton: () => ref
          .read(modelDistributionProvider.notifier)
          .acknowledgeMemoryWarning(),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(String message, int failureCount) {
    return _buildCard(
      icon: Icons.error_outline,
      iconColor: Colors.red,
      title: 'Download failed',
      // message already includes troubleshooting hints when failureCount >= 3
      message: message,
      buttonLabel: 'Try again',
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
            color: _kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kTextSecondary,
            fontSize: 14, // 14sp per spec
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kForestGreen,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
  String _formatDuration(Duration? d) {
    if (d == null || d.isNegative) return 'Calculating...';
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
    if (d.inMinutes >= 1) {
      final minutes = d.inMinutes;
      final seconds = d.inSeconds.remainder(60);
      return '${minutes}m ${seconds}s';
    }
    return '${d.inSeconds}s';
  }

  /// Formats [mbps] as "X.X MB/s".
  String _formatSpeed(double mbps) {
    if (mbps <= 0) return '0.0 MB/s';
    return '${mbps.toStringAsFixed(1)} MB/s';
  }
}
