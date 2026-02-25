// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inference_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides [InferenceRepository] backed by the active [LlmService].
///
/// Reads [modelReadyProvider] to obtain the loaded [LlmService] instance.
/// Throws [StateError] if accessed before [modelReadyProvider] resolves —
/// callers (ChatNotifier, TranslationNotifier) must only read this provider
/// when `modelReadyProvider` is in [AsyncData] state.
///
/// [keepAlive: true] keeps the repository alive for the full app session.
/// The repository is a thin delegation wrapper; there is no per-request
/// state to manage.

@ProviderFor(inferenceRepository)
final inferenceRepositoryProvider = InferenceRepositoryProvider._();

/// Provides [InferenceRepository] backed by the active [LlmService].
///
/// Reads [modelReadyProvider] to obtain the loaded [LlmService] instance.
/// Throws [StateError] if accessed before [modelReadyProvider] resolves —
/// callers (ChatNotifier, TranslationNotifier) must only read this provider
/// when `modelReadyProvider` is in [AsyncData] state.
///
/// [keepAlive: true] keeps the repository alive for the full app session.
/// The repository is a thin delegation wrapper; there is no per-request
/// state to manage.

final class InferenceRepositoryProvider
    extends
        $FunctionalProvider<
          InferenceRepository,
          InferenceRepository,
          InferenceRepository
        >
    with $Provider<InferenceRepository> {
  /// Provides [InferenceRepository] backed by the active [LlmService].
  ///
  /// Reads [modelReadyProvider] to obtain the loaded [LlmService] instance.
  /// Throws [StateError] if accessed before [modelReadyProvider] resolves —
  /// callers (ChatNotifier, TranslationNotifier) must only read this provider
  /// when `modelReadyProvider` is in [AsyncData] state.
  ///
  /// [keepAlive: true] keeps the repository alive for the full app session.
  /// The repository is a thin delegation wrapper; there is no per-request
  /// state to manage.
  InferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inferenceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<InferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InferenceRepository create(Ref ref) {
    return inferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InferenceRepository>(value),
    );
  }
}

String _$inferenceRepositoryHash() =>
    r'07a98e1db0d57f3eddffd87bc03c0c83e8e253ae';
