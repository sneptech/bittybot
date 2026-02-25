// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages translation request state.
///
/// Responsibilities:
/// - Accepts translation requests for a configured language pair.
/// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
/// - Sends generation requests to [InferenceRepository] with nPredict=128.
/// - Streams tokens to [TranslationState.translatedText] as they arrive.
/// - Queues new requests behind active generation; auto-dequeues on done.
/// - Persists all translations to Drift DB via [ChatRepository] for history.
/// - Accumulates context within the same language pair session for terminology
///   consistency. Language pair change or swap resets the session and KV cache.
/// - Detects context-full condition via [TranslationState.isContextFull].
/// - Supports cooperative stop via [InferenceRepository.stop].
///
/// [keepAlive: true] so the last-used language pair persists across navigation
/// (TRNS-05 requirement: language pair selection survives screen changes).

@ProviderFor(TranslationNotifier)
final translationProvider = TranslationNotifierProvider._();

/// Manages translation request state.
///
/// Responsibilities:
/// - Accepts translation requests for a configured language pair.
/// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
/// - Sends generation requests to [InferenceRepository] with nPredict=128.
/// - Streams tokens to [TranslationState.translatedText] as they arrive.
/// - Queues new requests behind active generation; auto-dequeues on done.
/// - Persists all translations to Drift DB via [ChatRepository] for history.
/// - Accumulates context within the same language pair session for terminology
///   consistency. Language pair change or swap resets the session and KV cache.
/// - Detects context-full condition via [TranslationState.isContextFull].
/// - Supports cooperative stop via [InferenceRepository.stop].
///
/// [keepAlive: true] so the last-used language pair persists across navigation
/// (TRNS-05 requirement: language pair selection survives screen changes).
final class TranslationNotifierProvider
    extends $NotifierProvider<TranslationNotifier, TranslationState> {
  /// Manages translation request state.
  ///
  /// Responsibilities:
  /// - Accepts translation requests for a configured language pair.
  /// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
  /// - Sends generation requests to [InferenceRepository] with nPredict=128.
  /// - Streams tokens to [TranslationState.translatedText] as they arrive.
  /// - Queues new requests behind active generation; auto-dequeues on done.
  /// - Persists all translations to Drift DB via [ChatRepository] for history.
  /// - Accumulates context within the same language pair session for terminology
  ///   consistency. Language pair change or swap resets the session and KV cache.
  /// - Detects context-full condition via [TranslationState.isContextFull].
  /// - Supports cooperative stop via [InferenceRepository.stop].
  ///
  /// [keepAlive: true] so the last-used language pair persists across navigation
  /// (TRNS-05 requirement: language pair selection survives screen changes).
  TranslationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translationNotifierHash();

  @$internal
  @override
  TranslationNotifier create() => TranslationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranslationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranslationState>(value),
    );
  }
}

String _$translationNotifierHash() =>
    r'b83677a28a773ff31cc03cca5f60516520544dcd';

/// Manages translation request state.
///
/// Responsibilities:
/// - Accepts translation requests for a configured language pair.
/// - Builds Aya-formatted prompts via [PromptBuilder] (initial vs. follow-up).
/// - Sends generation requests to [InferenceRepository] with nPredict=128.
/// - Streams tokens to [TranslationState.translatedText] as they arrive.
/// - Queues new requests behind active generation; auto-dequeues on done.
/// - Persists all translations to Drift DB via [ChatRepository] for history.
/// - Accumulates context within the same language pair session for terminology
///   consistency. Language pair change or swap resets the session and KV cache.
/// - Detects context-full condition via [TranslationState.isContextFull].
/// - Supports cooperative stop via [InferenceRepository.stop].
///
/// [keepAlive: true] so the last-used language pair persists across navigation
/// (TRNS-05 requirement: language pair selection survives screen changes).

abstract class _$TranslationNotifier extends $Notifier<TranslationState> {
  TranslationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TranslationState, TranslationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TranslationState, TranslationState>,
              TranslationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
