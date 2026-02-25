import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model_distribution/providers.dart';
import 'llm_service.dart';

part 'llm_service_provider.g.dart';

/// Manages the [LlmService] lifecycle as a keepAlive Riverpod provider.
///
/// Responsibilities:
/// - Obtains the model file path from [modelDistributionProvider].
/// - Spawns the inference isolate and loads the model in the background.
/// - Registers an [AppLifecycleState] observer to recover from OS-kill
///   while backgrounded (the "Reloading model..." banner pattern).
/// - Exposes [AsyncValue<LlmService>] so consumers can:
///     - Disable input while loading ([AsyncLoading]).
///     - Surface errors in the UI ([AsyncError]).
///     - Get the service for inference ([AsyncData]).
///
/// **Design:** [appStartupProvider] does NOT await this provider.
/// On subsequent launches, the app shell is fully usable while the model
/// loads — only the input field is disabled until [modelReadyProvider]
/// resolves. This satisfies the "partial access on subsequent launches"
/// locked decision.
@Riverpod(keepAlive: true)
class ModelReady extends _$ModelReady with WidgetsBindingObserver {
  LlmService? _llmService;

  @override
  Future<LlmService> build() async {
    // Obtain the model file path from Phase 2's ModelDistributionNotifier.
    // The model is guaranteed to exist on disk at this point — the
    // DownloadScreen gates first-launch; subsequent launches run SHA-256
    // verification in ModelDistributionNotifier.initialize() before
    // setting ModelReadyState (which triggers navigation to the main shell
    // and thus the first watch of this provider).
    final notifier = ref.read(modelDistributionProvider.notifier);
    final modelPath = notifier.modelFilePath;

    // Spawn the worker isolate and load the model.
    _llmService = LlmService(modelPath: modelPath);
    await _llmService!.start();

    // Register for app lifecycle events so we can detect and recover from
    // OS-kill while the app was backgrounded.
    WidgetsBinding.instance.addObserver(this);

    // Clean up on provider teardown (test overrides, hot-restart, etc.).
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _llmService?.dispose();
      _llmService = null;
    });

    return _llmService!;
  }

  /// Triggered when the app is foregrounded.
  ///
  /// If the OS killed the inference isolate while the app was backgrounded,
  /// [_llmService.isAlive] returns false. We transition to [AsyncLoading]
  /// (shows "Reloading model..." banner), dispose the stale service, and
  /// spawn a fresh one.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _checkAndRecoverIsolate();
    }
  }

  /// Best-effort check: if the worker isolate is gone, reload the model.
  ///
  /// [LlmService.isAlive] is a heuristic — it checks that [_isolate] and
  /// [_commandPort] are both non-null. An OS kill nulls the isolate reference
  /// via the error listener set up in [LlmService.start]. A subsequent
  /// [_commandPort.send()] would also throw, but we catch that here too.
  Future<void> _checkAndRecoverIsolate() async {
    if (_llmService == null || _llmService!.isAlive) return;

    // Isolate is dead — show loading banner and reload.
    state = const AsyncLoading();

    try {
      await _llmService!.dispose();
    } catch (_) {
      // Ignore errors from a dead isolate during cleanup.
    }

    final notifier = ref.read(modelDistributionProvider.notifier);
    final modelPath = notifier.modelFilePath;

    _llmService = LlmService(modelPath: modelPath);
    await _llmService!.start();
    state = AsyncData(_llmService!);
  }
}
