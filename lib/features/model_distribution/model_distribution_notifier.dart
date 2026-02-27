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

/// SharedPreferences key: whether the model has been verified after download.
const _kModelVerifiedKey = 'model_verified';

/// SharedPreferences key: file size at the time of successful verification.
const _kModelVerifiedSizeKey = 'model_verified_size';

/// Group name used for registering background_downloader callbacks.
const _kDownloadGroup = 'model_distribution';

typedef _AppSupportDirectoryProvider = Future<Directory> Function();
typedef _VerifyModelFileFn = Future<bool> Function(String);
typedef _SharedPreferencesProvider = Future<SharedPreferences> Function();
typedef _StorageChecker = Future<StorageCheckResult> Function(String);
typedef _ConnectionChecker = Future<ConnectionType> Function();
typedef _LowMemoryChecker = Future<bool> Function();

double _clampProgress(double progress) {
  return progress.clamp(0.0, 1.0).toDouble();
}

/// Returns a progress value that never moves backward.
double resolveMonotonicProgress({
  required double previousProgress,
  required double incomingProgress,
}) {
  final clampedPrevious = _clampProgress(previousProgress);
  final clampedIncoming = _clampProgress(incomingProgress);
  if (clampedIncoming < clampedPrevious) {
    return clampedPrevious;
  }
  return clampedIncoming;
}

/// Resolves initial display progress for resume flows.
///
/// Uses whichever value is further ahead so persisted progress cannot
/// overwrite newer live progress.
double resolveResumeProgress({
  required double persistedProgress,
  required double liveProgress,
}) {
  return resolveMonotonicProgress(
    previousProgress: persistedProgress,
    incomingProgress: liveProgress,
  );
}

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
  ModelDistributionNotifier({
    Future<Directory> Function()? appSupportDirectoryProvider,
    Future<bool> Function(String)? verifyModelFileFn,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    Future<StorageCheckResult> Function(String)? storageChecker,
    Future<ConnectionType> Function()? connectionChecker,
    Future<bool> Function()? lowMemoryChecker,
  }) : _appSupportDirectoryProvider =
           appSupportDirectoryProvider ?? getApplicationSupportDirectory,
       _verifyModelFileFn = verifyModelFileFn ?? verifyModelFile,
       _sharedPreferencesProvider =
           sharedPreferencesProvider ?? SharedPreferences.getInstance,
       _storageChecker = storageChecker ?? checkStorageSpace,
       _connectionChecker = connectionChecker ?? checkConnectionType,
       _lowMemoryChecker = lowMemoryChecker ?? isLowMemoryDevice;

  final _AppSupportDirectoryProvider _appSupportDirectoryProvider;
  final _VerifyModelFileFn _verifyModelFileFn;
  final _SharedPreferencesProvider _sharedPreferencesProvider;
  final _StorageChecker _storageChecker;
  final _ConnectionChecker _connectionChecker;
  final _LowMemoryChecker _lowMemoryChecker;
  Future<SharedPreferences>? _sharedPreferencesFuture;

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

    // Yield two frames so the loading UI is visible before startup I/O begins.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 16));

    // Start SharedPreferences initialization early so it can overlap with
    // directory and file checks.
    final prefsFuture = _getSharedPreferences();

    // Resolve paths
    final appSupportDir = await _appSupportDirectoryProvider();
    _modelDirPath = ModelConstants.modelDirectory(appSupportDir.path);
    _modelFilePath = ModelConstants.modelFilePath(appSupportDir.path);

    final modelFile = File(_modelFilePath);
    if (await modelFile.exists()) {
      // Check if model was already verified in a previous session
      final prefs = await prefsFuture;
      final alreadyVerified = prefs.getBool(_kModelVerifiedKey) ?? false;
      final verifiedSize = prefs.getInt(_kModelVerifiedSizeKey) ?? -1;
      final actualSize = await modelFile.length();

      if (alreadyVerified && verifiedSize == actualSize) {
        // Previously verified and file size unchanged — skip SHA-256
        // Yield one frame before starting heavyweight model loading work.
        await Future<void>.delayed(const Duration(milliseconds: 16));
        await _proceedToLoad();
      } else {
        // First launch with this file or size mismatch — full verification
        state = const VerifyingState();
        final valid = await _verifyModelFileFn(_modelFilePath);
        if (valid) {
          await prefs.setBool(_kModelVerifiedKey, true);
          await prefs.setInt(_kModelVerifiedSizeKey, actualSize);
          await _proceedToLoad();
        } else {
          // Corrupt or truncated file — clear flag, delete, re-download
          await prefs.remove(_kModelVerifiedKey);
          await prefs.remove(_kModelVerifiedSizeKey);
          await modelFile.delete();
          await _runPreflight();
        }
      }
      return;
    }

    // Ensure the models directory exists only when a download may be needed.
    await Directory(_modelDirPath).create(recursive: true);

    // No model on disk — check for a saved partial download progress
    final prefs = await prefsFuture;
    final savedProgress = _clampProgress(prefs.getDouble(_kProgressKey) ?? 0.0);
    if (savedProgress > 0.0) {
      _lastPersistedProgress = savedProgress;
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

  Future<SharedPreferences> _getSharedPreferences() {
    final existing = _sharedPreferencesFuture;
    if (existing != null) return existing;

    final future = _sharedPreferencesProvider();
    _sharedPreferencesFuture = future;
    unawaited(
      future.then<void>((_) {}).catchError((_) {
        if (identical(_sharedPreferencesFuture, future)) {
          _sharedPreferencesFuture = null;
        }
      }),
    );
    return future;
  }

  /// Runs storage and connectivity preflight checks.
  /// Sets the appropriate state and either continues to [_startDownload] or
  /// surfaces an error/warning state for the user to resolve.
  Future<void> _runPreflight() async {
    state = const PreflightState();

    // Check free disk space
    final storageResult = await _storageChecker(_modelDirPath);
    if (storageResult is StorageInsufficient) {
      state = InsufficientStorageState(
        neededBytes: storageResult.neededMB * 1024 * 1024,
        availableBytes: storageResult.availableMB * 1024 * 1024,
      );
      return;
    }

    // Check network connectivity
    final connection = await _connectionChecker();
    switch (connection) {
      case ConnectionType.none:
        state = ErrorState(
          kind: DownloadErrorKind.noInternet,
          message: '',
          failureCount: _failureCount,
        );
        return;
      case ConnectionType.cellular:
        state = const CellularWarningState();
        return;
      case ConnectionType.wifi:
        await _startDownload();
        return;
    }
  }

  /// Configures and starts the background_downloader download task.
  ///
  /// Uses [FileDownloader().enqueue] with [FileDownloader().registerCallbacks]
  /// (instead of the [FileDownloader().download] convenience method) so that
  /// [TaskProgressCallback] provides the full [TaskProgressUpdate] with
  /// network speed and estimated time-remaining data.
  Future<void> _startDownload() async {
    final prefs = await _getSharedPreferences();
    final persistedProgress = _clampProgress(
      prefs.getDouble(_kProgressKey) ?? 0.0,
    );
    final stateProgress = switch (state) {
      ResumePromptState(:final progressFraction) => progressFraction,
      DownloadingState(:final progressFraction) => progressFraction,
      _ => 0.0,
    };
    final seededProgress = resolveResumeProgress(
      persistedProgress: persistedProgress,
      liveProgress: _lastPersistedProgress,
    );
    final initialProgress = resolveResumeProgress(
      persistedProgress: seededProgress,
      liveProgress: stateProgress,
    );

    // Configure global foreground-service behaviour for large files
    await FileDownloader().configure(
      globalConfig: [(Config.runInForegroundIfFileLargerThan, 500)],
    );

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
      progressFraction: initialProgress,
      downloadedBytes: (initialProgress * ModelConstants.fileSizeBytes).round(),
      totalBytes: ModelConstants.fileSizeBytes,
      networkSpeedMBps: 0.0,
      timeRemaining: null,
    );
    _lastPersistedProgress = initialProgress;

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
      _downloadCompleter!.completeError(
        Exception('Failed to enqueue download'),
      );
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
          kind: DownloadErrorKind.downloadFailed,
          message: result.exception?.description ?? '',
        );
      case TaskStatus.notFound:
        await _onDownloadFailed(kind: DownloadErrorKind.notFound, message: '');
      default:
        // canceled, paused, etc. — no state transition needed here
        break;
    }
  }

  /// [TaskProgressCallback] receiving full progress data including network
  /// speed and time remaining. Used with [registerCallbacks] + [enqueue].
  void _onProgressCallback(TaskProgressUpdate update) {
    // progress < 0 are sentinel values (-1 unknown, -2 canceled, etc.)
    final previousProgress = switch (state) {
      DownloadingState(:final progressFraction) => progressFraction,
      _ => _lastPersistedProgress,
    };
    final fraction = resolveMonotonicProgress(
      previousProgress: previousProgress,
      incomingProgress: update.progress,
    );
    final totalBytes = update.hasExpectedFileSize
        ? update.expectedFileSize
        : ModelConstants.fileSizeBytes;
    final downloadedBytes = (fraction * totalBytes).round();

    state = DownloadingState(
      progressFraction: fraction,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      networkSpeedMBps: update.hasNetworkSpeed ? update.networkSpeed : 0.0,
      timeRemaining: update.hasTimeRemaining ? update.timeRemaining : null,
    );

    // Persist progress — throttled to one write per 5% change to avoid
    // hammering shared_preferences on every callback
    if (fraction - _lastPersistedProgress >= 0.05) {
      _lastPersistedProgress = fraction;
      unawaited(
        _getSharedPreferences().then((prefs) {
          prefs.setDouble(_kProgressKey, fraction);
        }),
      );
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
        if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
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

    final valid = await _verifyModelFileFn(_modelFilePath);
    if (valid) {
      // Clear persisted partial-progress and mark model as verified
      final prefs = await _getSharedPreferences();
      await prefs.remove(_kProgressKey);
      _lastPersistedProgress = 0.0;
      final fileSize = await File(_modelFilePath).length();
      await prefs.setBool(_kModelVerifiedKey, true);
      await prefs.setInt(_kModelVerifiedSizeKey, fileSize);
      await _proceedToLoad();
    } else {
      // File is corrupt — clear verification flag, delete, surface error
      final modelFile = File(_modelFilePath);
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      final prefs = await _getSharedPreferences();
      await prefs.remove(_kProgressKey);
      await prefs.remove(_kModelVerifiedKey);
      await prefs.remove(_kModelVerifiedSizeKey);
      _lastPersistedProgress = 0.0;
      _failureCount++;
      state = ErrorState(
        kind: DownloadErrorKind.verificationFailed,
        message: '',
        failureCount: _failureCount,
      );
    }
  }

  /// Called when background_downloader reports a permanent download failure.
  Future<void> _onDownloadFailed({
    required DownloadErrorKind kind,
    required String message,
  }) async {
    _failureCount++;
    state = ErrorState(
      kind: kind,
      message: _buildErrorMessage(message),
      failureCount: _failureCount,
    );
  }

  /// Appends troubleshooting hints to [message] when [_failureCount] >= 3.
  String _buildErrorMessage(String message) {
    if (message.trim().isEmpty) return '';
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
    final lowMemory = await _lowMemoryChecker();
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

  /// Signals that model distribution is complete and the model is ready.
  ///
  /// Actual model loading is handled by [LlmService] via
  /// [llmServiceProvider] — this method only transitions the distribution
  /// state machine to its terminal state.
  Future<void> _loadModel() async {
    state = const ModelReadyState();
  }
}
