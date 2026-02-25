import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/llm_service.dart';
import '../application/llm_service_provider.dart';
import '../domain/inference_message.dart';
import '../domain/inference_repository.dart';

part 'inference_repository_impl.g.dart';

/// Concrete [InferenceRepository] that delegates to [LlmService].
///
/// ChatNotifier and TranslationNotifier (Plan 05) import the abstract
/// [InferenceRepository] interface and receive this implementation via
/// Riverpod — they never reference [LlmService] directly. This keeps
/// notifiers testable with fakes.
class LlmServiceInferenceRepository implements InferenceRepository {
  final LlmService _llmService;

  const LlmServiceInferenceRepository(this._llmService);

  @override
  int generate({required String prompt, required int nPredict}) =>
      _llmService.generate(prompt: prompt, nPredict: nPredict);

  @override
  void stop(int requestId) => _llmService.stop(requestId);

  @override
  void clearContext() => _llmService.clearContext();

  @override
  bool get isGenerating => _llmService.isGenerating;

  @override
  Stream<InferenceResponse> get responseStream => _llmService.responseStream;
}

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
@Riverpod(keepAlive: true)
InferenceRepository inferenceRepository(Ref ref) {
  final llmService = ref.watch(modelReadyProvider).value;
  if (llmService == null) {
    throw StateError(
      'inferenceRepositoryProvider accessed before modelReadyProvider resolved. '
      'Check modelReadyProvider state before calling inference methods.',
    );
  }
  return LlmServiceInferenceRepository(llmService);
}
