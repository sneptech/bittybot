---
phase: 04-core-inference-architecture
plan: "03"
subsystem: database, domain
tags: [drift, sqlite, repository-pattern, domain-model, clean-architecture, dart]

# Dependency graph
requires:
  - phase: 04-core-inference-architecture
    plan: "01"
    provides: Drift ChatSessions and ChatMessages tables (schemaVersion 2), sealed InferenceResponse types
  - phase: 03-app-foundation
    provides: AppDatabase stub with Drift setup

provides:
  - ChatSession domain value object (immutable, const constructor, id/title/mode/timestamps)
  - ChatMessage domain value object (immutable, const constructor, copyWith for streaming)
  - ChatRepository abstract interface (12 methods: session/message CRUD, reactive watch, bulk ops)
  - DriftChatRepository concrete implementation (Drift queries, reactive watch streams, session ordering)
  - InferenceRepository abstract interface (generate/stop/clearContext contract for notifiers)

affects:
  - 04-04 (ChatNotifier — depends on ChatRepository + InferenceRepository interfaces)
  - 04-05 (TranslationNotifier — depends on InferenceRepository interface)
  - 05-translation-ui
  - 06-chat-ui

# Tech tracking
tech-stack:
  added: []  # No new packages — all deps already in pubspec.yaml
  patterns:
    - Domain value objects decoupled from Drift-generated row types (clean architecture)
    - Import alias pattern: `import 'app_database.dart' as db` to disambiguate same-named Drift types from domain types
    - Abstract repository interface for dependency injection (notifiers depend on interface, not implementation)
    - Reactive Drift .watch() streams for auto-updating UI during token streaming
    - insertMessage touches parent session updatedAt for correct drawer ordering (most-recently-active first)
    - deleteSessionsOlderThan uses isIn() query for efficient bulk delete

key-files:
  created:
    - lib/features/chat/domain/chat_session.dart
    - lib/features/chat/domain/chat_message.dart
    - lib/features/chat/data/chat_repository.dart
    - lib/features/chat/data/chat_repository_impl.dart
    - lib/features/inference/domain/inference_repository.dart
  modified: []

key-decisions:
  - "Domain ChatSession and ChatMessage use same names as Drift-generated row types — resolved via import alias 'as db' in DriftChatRepository"
  - "DriftChatRepository passes AppDatabase via constructor (not DatabaseAccessor subclass) for simpler dependency injection via Riverpod"
  - "insertMessage touches parent session updatedAt — sessions float to drawer top on new activity without requiring explicit session update by callers"
  - "deleteSessionsOlderThan uses session createdAt (not updatedAt) as cutoff — ensures old inactive sessions are pruned even if they were re-titled"

patterns-established:
  - "Pattern: Domain value objects in lib/features/{feature}/domain/ — no Drift imports, pure Dart"
  - "Pattern: Repository interface in lib/features/{feature}/data/{feature}_repository.dart — abstract class only"
  - "Pattern: Drift implementation in lib/features/{feature}/data/{feature}_repository_impl.dart — imports app_database.dart as db prefix"
  - "Pattern: Private _mapSession() and _mapMessage() methods convert Drift row types to domain objects"
  - "Pattern: InferenceRepository interface in lib/features/inference/domain/ — bridges LlmService to notifiers"

requirements-completed: [CHAT-04]

# Metrics
duration: 3min
completed: 2026-02-25
---

# Phase 4 Plan 03: Chat Domain Layer Summary

**Immutable ChatSession and ChatMessage value objects, 12-method ChatRepository interface with Drift-backed reactive implementation, and InferenceRepository contract for notifier dependency injection**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-02-25T04:47:53Z
- **Completed:** 2026-02-25T04:50:11Z
- **Tasks:** 2
- **Files modified:** 5 (all created)

## Accomplishments

- Created ChatSession and ChatMessage immutable domain value objects with const constructors, decoupled from Drift's generated row types by same names
- Defined ChatRepository abstract interface with 12 methods covering session CRUD, message CRUD, reactive watch streams, and bulk delete operations
- Implemented DriftChatRepository with Drift queries, reactive `.watch()` streams for real-time UI, and session ordering by `updatedAt` desc for the drawer
- Defined InferenceRepository abstract interface that ChatNotifier and TranslationNotifier will depend on, imported from inference_message.dart for the response stream type

## Task Commits

Each task was committed atomically:

1. **Task 1: Chat domain models and repository interface** - `50a0e1b` (feat)
2. **Task 2: Drift-backed ChatRepository implementation** - `c29d718` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `lib/features/chat/domain/chat_session.dart` - ChatSession immutable value object with id, title (nullable), mode, createdAt, updatedAt; equality and hashCode
- `lib/features/chat/domain/chat_message.dart` - ChatMessage immutable value object with id, sessionId, role, content, isTruncated, createdAt; copyWith for token streaming
- `lib/features/chat/data/chat_repository.dart` - Abstract ChatRepository interface with 12 methods: 5 session operations, 5 message operations, 2 bulk operations
- `lib/features/chat/data/chat_repository_impl.dart` - DriftChatRepository concrete implementation; imports app_database.dart as `db` to resolve naming collision
- `lib/features/inference/domain/inference_repository.dart` - Abstract InferenceRepository interface: generate(), stop(), clearContext(), isGenerating, responseStream

## Decisions Made

- **Import alias for Drift types:** Drift generates row classes named exactly `ChatSession` and `ChatMessage` (same as our domain names). In `DriftChatRepository`, imported `app_database.dart as db` so `db.ChatSession`/`db.ChatMessage` refers to Drift types and unqualified `ChatSession`/`ChatMessage` refers to domain types. This avoids renaming either side.
- **Constructor injection over DatabaseAccessor:** `DriftChatRepository` receives `AppDatabase` via constructor rather than extending `DatabaseAccessor`. This keeps the class simple and works naturally with Riverpod provider injection.
- **insertMessage touches session updatedAt:** When a message is inserted, the parent session's `updatedAt` is updated to `now`. This ensures the session bubbles to the top of the drawer list without requiring callers to make a separate `updateSessionTitle` call.
- **deleteSessionsOlderThan uses createdAt cutoff:** Pruning is based on when the session was created, not when it was last used. Prevents old sessions with recent title edits from escaping pruning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Import alias required for Drift/domain naming collision**
- **Found during:** Task 2 (DriftChatRepository implementation)
- **Issue:** The plan's `_mapSession` and `_mapMessage` private mappers reference `ChatSessionData` and `ChatMessageData`, but Phase 4 Plan 01 already confirmed Drift generates `ChatSession` and `ChatMessage` (no "Data" suffix). The plan noted "verify the exact generated class name and adapt" — this is that adaptation. Without the `as db` import alias, the file would have an unresolvable name collision between the Drift-generated `ChatSession` and the domain `ChatSession`.
- **Fix:** Added `import '../../../core/db/app_database.dart' as db;` and used `db.ChatSession`, `db.ChatMessage`, `db.ChatSessionsCompanion`, `db.ChatMessagesCompanion` throughout the implementation
- **Files modified:** `lib/features/chat/data/chat_repository_impl.dart`
- **Verification:** `dart analyze lib/features/chat/data/chat_repository_impl.dart` returned "No issues found"
- **Committed in:** `c29d718` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — type naming adaptation already anticipated by plan spec)
**Impact on plan:** Required for zero-error compilation. No scope creep — the plan explicitly said to "check and adapt" the generated class names.

## Issues Encountered

None — both files compiled cleanly on first `dart analyze` run.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All five domain layer files are ready to import. Plan 04 (ChatNotifier) and Plan 05 (TranslationNotifier) can proceed immediately.
- `lib/features/chat/` directory is fully structured with `domain/` and `data/` subdirectories.
- `InferenceRepository` interface is defined; Plan 02 (LlmService) provides the concrete implementation.
- Reactive `watchMessagesForSession()` and `watchAllSessions()` streams are ready for UI consumption.
- `dart analyze` passes with zero issues across all 5 new files.

## Self-Check: PASSED

- FOUND: lib/features/chat/domain/chat_session.dart
- FOUND: lib/features/chat/domain/chat_message.dart
- FOUND: lib/features/chat/data/chat_repository.dart
- FOUND: lib/features/chat/data/chat_repository_impl.dart
- FOUND: lib/features/inference/domain/inference_repository.dart
- FOUND: .planning/phases/04-core-inference-architecture/04-03-SUMMARY.md
- FOUND commit: 50a0e1b (Task 1 — domain models + interfaces)
- FOUND commit: c29d718 (Task 2 — DriftChatRepository)

---
*Phase: 04-core-inference-architecture*
*Completed: 2026-02-25*
