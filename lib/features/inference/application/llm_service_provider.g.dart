// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ModelReady)
final modelReadyProvider = ModelReadyProvider._();

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
final class ModelReadyProvider
    extends $AsyncNotifierProvider<ModelReady, LlmService> {
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
  ModelReadyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelReadyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelReadyHash();

  @$internal
  @override
  ModelReady create() => ModelReady();
}

String _$modelReadyHash() => r'a9b87a7ff4cc0313031804a0a1a57eb62a013710';

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

abstract class _$ModelReady extends $AsyncNotifier<LlmService> {
  FutureOr<LlmService> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LlmService>, LlmService>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LlmService>, LlmService>,
              AsyncValue<LlmService>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
