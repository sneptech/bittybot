import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_constants.dart';
import 'model_distribution_state.dart';
import 'sha256_verifier.dart';
import 'storage_preflight.dart';

/// Shared preferences key for persisting download progress between launches.
const _kProgressKey = 'model_download_progress';

/// Group name used for registering background_downloader callbacks.
const _kDownloadGroup = 'model_distribution';

/// Riverpod Notifier orchestrating the complete model download-verify-load
/// lifecycle for first-launch and every subsequent launch.
///
/// State machine overview:
/// ```
/// CheckingModelState → VerifyingState (model on disk)
///   ├─ valid: _proceedToLoad()
///   └─ invalid: delete + _runPreflight()
///
/// CheckingModelState → ResumePromptState (partial download saved)
///   └─ user confirms: _startDownload()
///
/// CheckingModelState → _runPreflight() (no model, no partial download)
///   ├─ InsufficientStorageState (not enough disk)
///   ├─ ErrorState (no network)
///   ├─ CellularWarningState (cellular detected)
///   └─ _startDownload() (wi-fi)
///
/// _startDownload() → DownloadingState → VerifyingState → _proceedToLoad()
///   └─ failed: ErrorState (with escalating troubleshooting hints)
///
/// _proceedToLoad() → LowMemoryWarningState (RAM < threshold)
///   └─ user acknowledges: LoadingModelState → ModelReadyState
///
/// _proceedToLoad() → LoadingModelState → ModelReadyState (normal RAM)
/// ```
class ModelDistributionNotifier extends Notifier<ModelDistributionState> {
  /// Absolute path to the GGUF model file resolved during [initialize].
  late String _modelFilePath;

  /// Absolute path to the models directory resolved during [initialize].
  late String _modelDirPath;

  /// How many consecutive download/verification failures have occurred.
  /// Drives progressive error escalation in [_onDownloadFailed].
  int _failureCount = 0;

  /// Last persisted progress fraction (0.0–1.0). Throttles shared_preferences
  /// writes to one per 5% of progress change.
  double _lastPersistedProgress = 0.0;

  /// Completer used to await the final [TaskStatusUpdate] when using
  /// [enqueue] + [registerCallbacks] instead of the [FileDownloader.download]
  /// convenience method. Using enqueue gives us [TaskProgressUpdate] with
  /// network speed and time-remaining data via [registerCallbacks].
  Completer<TaskStatusUpdate>? _downloadCompleter;

  /// Exposes the resolved model file path so Phase 4 can pass it to llama.cpp.
  String get modelFilePath => _modelFilePath;

  @override
  ModelDistributionState build() {
    return const CheckingModelState();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Must be called once during app startup (e.g. from main.dart or a top-level
  /// ProviderScope initialisation hook) to drive the first state transition.
  Future<void> initialize() async {
    state = const CheckingModelState();

    // Resolve paths
    final appSupportDir = await getApplicationSupportDirectory();
    _modelDirPath = ModelConstants.modelDirectory(appSupportDir.path);
    _modelFilePath = ModelConstants.modelFilePath(appSupportDir.path);

    // Ensure the models directory exists
    await Directory(_modelDirPath).create(recursive: true);

    final modelFile = File(_modelFilePath);
    if (await modelFile.exists()) {
      // Model file on disk — verify integrity before loading
      state = const VerifyingState();
      final valid = await verifyModelFile(_modelFilePath);
      if (valid) {
        await _proceedToLoad();
      } else {
        // Corrupt or truncated file — delete and re-download
        await modelFile.delete();
        await _runPreflight();
      }
      return;
    }

    // No model on disk — check for a saved partial download progress
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getDouble(_kProgressKey) ?? 0.0;
    if (savedProgress > 0.0) {
      state = ResumePromptState(progressFraction: savedProgress);
      return; // Wait for user to confirm or start over
    }

    // Fresh first launch — run preflight checks before starting download
    await _runPreflight();
  }

  /// Called when the user accepts the cellular data warning and wants to
  /// proceed with the ~2.14 GB download over mobile data.
  Future<void> confirmCellularDownload() async {
    await _startDownload();
  }

  /// Called when the user confirms they want to resume an interrupted download.
  Future<void> confirmResume() async {
    await _startDownload();
  }

  /// Called when the user chooses "Start over" from the resume dialog.
  ///
  /// This is a user choice, not a failure, so it does not increment
  /// [_failureCount].
  Future<void> startOverDownload() async {
    await _runPreflight();
  }

  /// Called from the error state "Try again" button and from the
  /// insufficient-storage "Free up space and try again" button.
  ///
  /// Increments the internal failure counter so the error UI can escalate
  /// after 3+ consecutive failures.
  Future<void> retryDownload() async {
    _failureCount++;
    await _runPreflight();
  }

  /// Called when the user dismisses the low-memory warning and wants to
  /// proceed anyway. Skips the RAM check and goes straight to loading.
  Future<void> acknowledgeMemoryWarning() async {
    state = const LoadingModelState();
    await _loadModel();
  }

  // ─── Private lifecycle methods ─────────────────────────────────────────────

  /// Runs storage and connectivity preflight checks.
  /// Sets the appropriate state and either continues to [_startDownload] or
  /// surfaces an error/warning state for the user to resolve.
  Future<void> _runPreflight() async {
    state = const PreflightState();

    // Check free disk space
    final storageResult = await checkStorageSpace(_modelDirPath);
    if (storageResult is StorageInsufficient) {
      state = InsufficientStorageState(
        neededBytes: storageResult.neededMB * 1024 * 1024,
        availableBytes: storageResult.availableMB * 1024 * 1024,
      );
      return;
    }

    // Check network connectivity
    final connection = await checkConnectionType();
    switch (connection) {
      case ConnectionType.none:
        state = ErrorState(
          message:
              'No internet connection. Connect to Wi-Fi or cellular data to download the language model.',
          failureCount: _failureCount,
        );
      case ConnectionType.cellular:
        state = const CellularWarningState();
      case ConnectionType.wifi:
        await _startDownload();
    }
  }

  /// Configures and starts the background_downloader download task.
  ///
  /// Uses [FileDownloader().enqueue] with [FileDownloader().registerCallbacks]
  /// (instead of the [FileDownloader().download] convenience method) so that
  /// [TaskProgressCallback] provides the full [TaskProgressUpdate] with
  /// network speed and estimated time-remaining data.
  Future<void> _startDownload() async {
    // Configure global foreground-service behaviour for large files
    await FileDownloader().configure(globalConfig: [
      (Config.runInForegroundIfFileLargerThan, 500),
    ]);

    // Configure OS-level download notification
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading language model',
        '{progress}% complete',
      ),
      paused: const TaskNotification('Download paused', 'Tap to resume'),
      complete: const TaskNotification(
        'Download complete',
        'Open BittyBot to continue',
      ),
      error: const TaskNotification('Download failed', 'Tap to retry'),
      progressBar: true,
    );

    final task = DownloadTask(
      url: ModelConstants.downloadUrl,
      filename: ModelConstants.filename,
      directory: ModelConstants.modelSubdirectory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: _kDownloadGroup,
      updates: Updates.statusAndProgress,
      allowPause: true,
      priority: 0, // UIDT on Android 14+ — highest priority foreground transfer
      retries: 3,
      displayName: 'Tiny Aya language model',
    );

    // Set initial downloading state
    state = DownloadingState(
      progressFraction: 0.0,
      downloadedBytes: 0,
      totalBytes: ModelConstants.fileSizeBytes,
      networkSpeedMBps: 0.0,
      timeRemaining: null,
    );

    // Register callbacks to receive full TaskProgressUpdate (speed, ETA)
    _downloadCompleter = Completer<TaskStatusUpdate>();
    FileDownloader().registerCallbacks(
      group: _kDownloadGroup,
      taskStatusCallback: _onStatusCallback,
      taskProgressCallback: _onProgressCallback,
    );

    // Enqueue — callbacks fire asynchronously; await via completer
    final enqueued = await FileDownloader().enqueue(task);
    if (!enqueued) {
      _downloadCompleter!.completeError(Exception('Failed to enqueue download'));
    }

    // Await completion via the completer — resolved in _onStatusCallback
    final result = await _downloadCompleter!.future;

    // Unregister callbacks for this group
    FileDownloader().unregisterCallbacks(group: _kDownloadGroup);
    _downloadCompleter = null;

    switch (result.status) {
      case TaskStatus.complete:
        await _onDownloadComplete();
      case TaskStatus.failed:
        await _onDownloadFailed(
          result.exception?.description ?? 'Download failed. Please try again.',
        );
      case TaskStatus.notFound:
        await _onDownloadFailed(
          'Model file not found on the server. Please check your internet connection and try again.',
        );
      default:
        // canceled, paused, etc. — no state transition needed here
        break;
    }
  }

  /// [TaskProgressCallback] receiving full progress data including network
  /// speed and time remaining. Used with [registerCallbacks] + [enqueue].
  void _onProgressCallback(TaskProgressUpdate update) {
    // progress < 0 are sentinel values (-1 unknown, -2 canceled, etc.)
    final fraction = update.progress.clamp(0.0, 1.0);
    final totalBytes = update.hasExpectedFileSize
        ? update.expectedFileSize
        : ModelConstants.fileSizeBytes;
    final downloadedBytes = (fraction * totalBytes).round();

    state = DownloadingState(
      progressFraction: update.progress, // keep raw value for indeterminate UI
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      networkSpeedMBps: update.hasNetworkSpeed ? update.networkSpeed : 0.0,
      timeRemaining: update.hasTimeRemaining ? update.timeRemaining : null,
    );

    // Persist progress — throttled to one write per 5% change to avoid
    // hammering shared_preferences on every callback
    if ((fraction - _lastPersistedProgress).abs() >= 0.05) {
      _lastPersistedProgress = fraction;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble(_kProgressKey, fraction);
      });
    }
  }

  /// [TaskStatusCallback] that resolves the download [Completer] when a
  /// terminal status is reached. Also handles [TaskStatus.paused].
  void _onStatusCallback(TaskStatusUpdate update) {
    switch (update.status) {
      case TaskStatus.paused:
        // background_downloader manages resume internally — no state change
        break;
      case TaskStatus.complete:
      case TaskStatus.failed:
      case TaskStatus.notFound:
      case TaskStatus.canceled:
        // Complete the awaiter with the final status
        if (_downloadCompleter != null &&
            !_downloadCompleter!.isCompleted) {
          _downloadCompleter!.complete(update);
        }
      default:
        // enqueued, running, waitingToRetry — no action needed
        break;
    }
  }

  /// Called when background_downloader reports a successful download.
  /// Transitions to [VerifyingState], runs SHA-256 check, then proceeds.
  Future<void> _onDownloadComplete() async {
    state = const VerifyingState();

    final valid = await verifyModelFile(_modelFilePath);
    if (valid) {
      // Clear persisted partial-progress — download is complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProgressKey);
      _lastPersistedProgress = 0.0;
      await _proceedToLoad();
    } else {
      // File is corrupt — delete and surface error
      final modelFile = File(_modelFilePath);
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProgressKey);
      _lastPersistedProgress = 0.0;
      _failureCount++;
      state = ErrorState(
        message: _buildErrorMessage(
          'Download verification failed. The file may be corrupted. Please try again.',
        ),
        failureCount: _failureCount,
      );
    }
  }

  /// Called when background_downloader reports a permanent download failure.
  Future<void> _onDownloadFailed(String message) async {
    _failureCount++;
    state = ErrorState(
      message: _buildErrorMessage(message),
      failureCount: _failureCount,
    );
  }

  /// Appends troubleshooting hints to [message] when [_failureCount] >= 3.
  String _buildErrorMessage(String message) {
    if (_failureCount >= 3) {
      return '$message\n\nTroubleshooting:\n'
          '- Make sure you have at least 2.5 GB of free storage\n'
          '- Try switching from cellular to Wi-Fi\n'
          '- Force-close the app and reopen\n'
          '- If the problem persists, the server may be temporarily busy';
    }
    return message;
  }

  /// Checks device RAM and transitions to [LoadingModelState] (or
  /// [LowMemoryWarningState] if the device is below the threshold).
  Future<void> _proceedToLoad() async {
    final lowMemory = await isLowMemoryDevice();
    if (lowMemory) {
      // system_info_plus doesn't expose a separate "how much RAM" query —
      // isLowMemoryDevice() uses physicalMemory. Since we know it's low,
      // report a value below threshold as the warning detail.
      const approximateLowRamMB = ModelConstants.lowMemoryThresholdMB - 1;
      state = const LowMemoryWarningState(availableMB: approximateLowRamMB);
      return; // Wait for user to acknowledge
    }

    state = const LoadingModelState();
    await _loadModel();
  }

  /// Performs the actual model load.
  ///
  /// TODO(phase-4): Wire actual llama_cpp inference load here.
  /// Phase 4 replaces the LoadingModel → ModelReady transition with real
  /// llama_cpp_dart initialisation using [modelFilePath].
  Future<void> _loadModel() async {
    // Phase 2 stub — Phase 4 will replace this with llama_cpp_dart.load()
    state = const ModelReadyState();
  }
}
