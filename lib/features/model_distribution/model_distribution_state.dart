import 'package:flutter/foundation.dart';

/// Sealed class covering the entire model distribution lifecycle.
///
/// The state machine drives both the first-launch download flow and every
/// subsequent launch's model-load flow. All states are exhaustive — the UI
/// can switch on [ModelDistributionState] without a default case.
///
/// State transition overview:
/// ```
/// CheckingModelState
///   ├─ (model present & valid) → LowMemoryWarningState / LoadingModelState
///   ├─ (model present & invalid/corrupted) → PreflightState (re-download)
///   └─ (model absent, partial download saved) → ResumePromptState
///
/// PreflightState
///   ├─ (storage insufficient) → InsufficientStorageState
///   ├─ (cellular detected) → CellularWarningState
///   └─ (wifi / user confirmed) → DownloadingState
///
/// DownloadingState → VerifyingState → LowMemoryWarningState / LoadingModelState
///
/// LoadingModelState → ModelReadyState
///
/// (any step) → ErrorState (on failure)
/// ```
@immutable
sealed class ModelDistributionState {
  const ModelDistributionState();
}

/// App just launched. Checking whether the model file exists on disk and
/// whether its SHA-256 matches [ModelConstants.sha256Hash].
final class CheckingModelState extends ModelDistributionState {
  const CheckingModelState();
}

/// Pre-flight checks in progress ("Preparing download..." spinner state).
/// Verifying available storage and network connectivity before starting download.
final class PreflightState extends ModelDistributionState {
  const PreflightState();
}

/// A partial download was detected from a previous session.
/// The app is waiting for the user to confirm whether to resume.
///
/// [progressFraction] is `0.0`–`1.0` and reflects the saved progress so the
/// resume dialog can display "You're 60% of the way there".
final class ResumePromptState extends ModelDistributionState {
  const ResumePromptState({required this.progressFraction});

  /// Fraction of the download already completed (e.g. `0.60` = 60%).
  final double progressFraction;
}

/// Device is on a cellular connection. Waiting for explicit user confirmation
/// before starting the ~2.14 GB download over mobile data.
final class CellularWarningState extends ModelDistributionState {
  const CellularWarningState();
}

/// Not enough free disk space to download and store the model.
/// Both values are in bytes and are shown to the user in the error UI.
final class InsufficientStorageState extends ModelDistributionState {
  const InsufficientStorageState({
    required this.neededBytes,
    required this.availableBytes,
  });

  /// How many bytes are required (model + buffer).
  final int neededBytes;

  /// How many bytes are currently available on the device.
  final int availableBytes;
}

/// Active download in progress.
///
/// All fields are updated on each progress callback from [background_downloader].
/// [timeRemaining] is `null` until the download speed stabilises.
final class DownloadingState extends ModelDistributionState {
  const DownloadingState({
    required this.progressFraction,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.networkSpeedMBps,
    required this.timeRemaining,
  });

  /// Download progress from `0.0` (not started) to `1.0` (complete).
  final double progressFraction;

  /// Bytes received so far.
  final int downloadedBytes;

  /// Total expected bytes (falls back to [ModelConstants.fileSizeBytes] if unknown).
  final int totalBytes;

  /// Current transfer speed in megabytes per second.
  final double networkSpeedMBps;

  /// Estimated time remaining, or `null` if not yet calculable.
  final Duration? timeRemaining;
}

/// Download complete. Running the chunked SHA-256 integrity check off the UI thread.
/// This typically takes 5–15 seconds on mobile for a 2.14 GB file.
final class VerifyingState extends ModelDistributionState {
  const VerifyingState();
}

/// Device RAM is below [ModelConstants.lowMemoryThresholdMB].
/// The user is warned that performance may be degraded but can still proceed.
final class LowMemoryWarningState extends ModelDistributionState {
  const LowMemoryWarningState({required this.availableMB});

  /// Device physical RAM in megabytes.
  final int availableMB;
}

/// Model file verified. Loading the GGUF into the llama.cpp inference runtime.
/// The UI shows the greyscale logo and disabled text input during this state.
///
/// Phase 4 wires the actual [llama_cpp_dart] load call. Phase 2 establishes
/// this state as the contract between model distribution and inference.
final class LoadingModelState extends ModelDistributionState {
  const LoadingModelState();
}

/// Model fully loaded and inference is ready.
///
/// This is the terminal "happy path" state. The UI transitions from the
/// greyscale logo to the full-colour logo to signal readiness.
final class ModelReadyState extends ModelDistributionState {
  const ModelReadyState();
}

/// A recoverable error occurred during download or verification.
///
/// [failureCount] drives progressive error escalation:
/// - 1–2 failures: simple "Try again" button
/// - 3+ failures: troubleshooting hints shown below the retry button
final class ErrorState extends ModelDistributionState {
  const ErrorState({
    required this.message,
    required this.failureCount,
  });

  /// Human-readable error message shown in the UI.
  final String message;

  /// How many consecutive failures have occurred. Drives escalating UX hints.
  final int failureCount;
}
