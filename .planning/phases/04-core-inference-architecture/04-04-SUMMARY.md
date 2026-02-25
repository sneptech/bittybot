---
phase: 04-core-inference-architecture
plan: "04"
subsystem: inference, database
tags: [riverpod, llm-service, inference-repository, chat-repository, drift, provider-graph, lifecycle]

# Dependency graph
requires:
  - phase: 04-core-inference-architecture
    plan: "02"
    provides: LlmService (inference isolate lifecycle, generate/stop/clearContext, isAlive)
  - phase: 04-core-inference-architecture
    plan: "03"
    provides: ChatRepository interface, DriftChatRepository, InferenceRepository interface, AppDatabase
  - phase: 02-model-distribution
    provides: modelDistributionProvider with modelFilePath accessor

provides:
  - modelReadyProvider (keepAlive AsyncNotifier<LlmService>): loads model in background, OS-kill recovery
  - appDatabaseProvider (keepAlive provider<AppDatabase>): single DB instance for app lifetime
  - chatRepositoryProvider (keepAlive provider<ChatRepository>): DriftChatRepository via Riverpod DI
  - inferenceRepositoryProvider (keepAlive provider<InferenceRepository>): wraps LlmService in interface

affects:
  - 04-05 (ChatNotifier — consumes chatRepositoryProvider + inferenceRepositoryProvider)
  - 05-translation-ui (TranslationNotifier — consumes inferenceRepositoryProvider)
  - 06-chat-ui (chat session drawer — consumes chatRepositoryProvider)

# Tech tracking
tech-stack:
  added: []  # No new packages — all deps already in pubspec.yaml
  patterns:
    - Partial-access launch pattern: appStartupProvider awaits settings only; modelReadyProvider runs independently
    - WidgetsBindingObserver mixin on AsyncNotifier for app lifecycle monitoring inside Riverpod provider
    - InferenceRepository abstraction layer: notifiers never import LlmService directly
    - keepAlive on all providers in inference/chat stack — long-lived resources shared across the app
    - StateError thrown when inferenceRepositoryProvider accessed before model loaded (fast-fail for ordering bugs)

key-files:
  created:
    - lib/features/inference/application/llm_service_provider.dart
    - lib/features/inference/application/llm_service_provider.g.dart
    - lib/features/chat/application/chat_repository_provider.dart
    - lib/features/chat/application/chat_repository_provider.g.dart
    - lib/features/inference/data/inference_repository_impl.dart
    - lib/features/inference/data/inference_repository_impl.g.dart
  modified:
    - lib/widgets/app_startup_widget.dart

key-decisions:
  - "appStartupProvider remains settings-only: model loads independently via modelReadyProvider (partial-access pattern)"
  - "ModelReady uses WidgetsBindingObserver mixin on AsyncNotifier for OS-kill recovery"
  - "inferenceRepositoryProvider throws StateError if accessed before modelReadyProvider resolves"
  - "LlmServiceInferenceRepository uses const constructor — stateless delegation to LlmService"

patterns-established:
  - "Pattern: Provider graph chain — modelDistributionProvider -> modelReadyProvider -> inferenceRepositoryProvider"
  - "Pattern: appDatabaseProvider -> chatRepositoryProvider (single DB, single repo, full app lifetime)"
  - "Pattern: notifiers consume interface providers (inferenceRepositoryProvider, chatRepositoryProvider) not concrete classes"
  - "Pattern: WidgetsBindingObserver lifecycle monitoring inside AsyncNotifier subclass"

requirements-completed: [MODL-05]

# Metrics
duration: 3min
completed: 2026-02-25
---

# Phase 4 Plan 04: Provider Graph Wiring Summary

**keepAlive Riverpod provider graph wiring model distribution -> LlmService -> InferenceRepository interface, plus chatRepositoryProvider and OS-kill recovery in ModelReady AsyncNotifier**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-02-25T04:53:16Z
- **Completed:** 2026-02-25T04:56:01Z
- **Tasks:** 2
- **Files modified:** 7 (6 created, 1 modified)

## Accomplishments

- Created ModelReady keepAlive AsyncNotifier that spawns LlmService, loads the model in background, and recovers from OS-kill via WidgetsBindingObserver lifecycle monitoring (shows AsyncLoading "Reloading model..." banner)
- Created appDatabaseProvider and chatRepositoryProvider wiring AppDatabase -> DriftChatRepository into the Riverpod DI graph
- Created LlmServiceInferenceRepository (all 5 InferenceRepository members) and inferenceRepositoryProvider, completing the inference abstraction layer that Plan 05 notifiers will consume
- Updated app_startup_widget.dart to remove the Phase 4 placeholder comment and document the partial-access design decision

## Task Commits

Each task was committed atomically:

1. **Task 1: modelReadyProvider, chatRepositoryProvider, appDatabase + app_startup_widget** - `9188702` (feat)
2. **Task 2: InferenceRepository implementation and inferenceRepositoryProvider** - `2aefef0` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `lib/features/inference/application/llm_service_provider.dart` - ModelReady AsyncNotifier with WidgetsBindingObserver for OS-kill recovery; modelReadyProvider keepAlive
- `lib/features/inference/application/llm_service_provider.g.dart` - Riverpod codegen output for ModelReady
- `lib/features/chat/application/chat_repository_provider.dart` - appDatabaseProvider + chatRepositoryProvider (both keepAlive)
- `lib/features/chat/application/chat_repository_provider.g.dart` - Riverpod codegen output
- `lib/features/inference/data/inference_repository_impl.dart` - LlmServiceInferenceRepository (5 delegating methods) + inferenceRepositoryProvider keepAlive
- `lib/features/inference/data/inference_repository_impl.g.dart` - Riverpod codegen output
- `lib/widgets/app_startup_widget.dart` - Removed Phase 4 placeholder comment; added design explanation for partial-access pattern

## Decisions Made

- **appStartupProvider remains settings-only:** The Phase 3 comment "Phase 4 will add: await ref.watch(modelReadyProvider.future)" was removed because the locked CONTEXT.md decision takes priority: subsequent launches allow partial access (chat history + settings accessible while model loads). modelReadyProvider runs independently in the background.
- **WidgetsBindingObserver on AsyncNotifier:** Using the mixin on the `ModelReady` class (rather than a separate StatefulWidget) keeps the lifecycle monitoring co-located with the provider that owns the LlmService. The `addObserver`/`removeObserver` calls are in `build()` and `onDispose()` respectively.
- **StateError in inferenceRepositoryProvider:** Fast-fail pattern when the provider is accessed before model loads — better than silently returning null and crashing later inside a notifier method.
- **const constructor on LlmServiceInferenceRepository:** The class holds no state of its own (all state is in LlmService), so a const constructor is correct and enables compile-time constants.

## Deviations from Plan

None — plan executed exactly as written. The codegen for `inference_repository_impl.g.dart` was correctly anticipated and ran cleanly on first attempt.

## Issues Encountered

None — all three files compiled cleanly on first `dart analyze` run. Codegen produced expected outputs without conflicts.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Provider graph is complete. Plan 05 (ChatNotifier and TranslationNotifier) can consume:
  - `chatRepositoryProvider` for session and message persistence
  - `inferenceRepositoryProvider` for generation requests
  - `modelReadyProvider` to gate input enable/disable
- `lib/features/chat/application/` and `lib/features/inference/data/` directories are created and ready for Plan 05 additions
- `dart analyze` passes with zero issues across all new and modified files

## Self-Check: PASSED

- FOUND: lib/features/inference/application/llm_service_provider.dart
- FOUND: lib/features/inference/application/llm_service_provider.g.dart
- FOUND: lib/features/chat/application/chat_repository_provider.dart
- FOUND: lib/features/chat/application/chat_repository_provider.g.dart
- FOUND: lib/features/inference/data/inference_repository_impl.dart
- FOUND: lib/features/inference/data/inference_repository_impl.g.dart
- FOUND: .planning/phases/04-core-inference-architecture/04-04-SUMMARY.md
- FOUND commit: 9188702 (Task 1)
- FOUND commit: 2aefef0 (Task 2)

---
*Phase: 04-core-inference-architecture*
*Completed: 2026-02-25*
