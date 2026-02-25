# Phase 5: Translation UI - Research

**Researched:** 2026-02-25
**Domain:** Flutter chat-style UI, language picker, streaming text display, navigation shell
**Confidence:** HIGH (core Flutter patterns verified; language data list verified from HuggingFace model card)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Screen Layout
- Chat-style interface, not traditional two-panel Google Translate layout
- Input bar at the bottom of the screen (accounting for system controls/safe area)
- User taps input bar → keyboard appears
- User message appears as a right-aligned chat bubble
- Model translation appears as a left-aligned chat bubble below user's message
- Follow-up messages continue the thread downward (like ChatGPT)
- Separate screen from Chat UI (Phase 6) — not a mode toggle
- Send button (visible icon to right of input field) — enter/return inserts newlines
- Multi-line expandable input field — grows as user types paragraphs
- Soft character limit with warning when approaching model context limit
- User bubbles show text only (no language tag)
- Model response bubbles show translated text + small target language tag (useful when target changes mid-history)
- New session button in top bar, right side (+ or new-page icon) — starts fresh translation session, saves old to history
- Centered prompt text for empty state ("Type something to translate") — disappears on first message

#### Language Selector
- Target language only — no source language selector (model auto-detects input language)
- Target language button in the top bar
- Tapping opens a scrollable bottom sheet with:
  - Search bar at top with text filtering
  - 3-column grid layout — each entry is a button with flag icon + language name
  - All 70+ supported languages shown
  - Popular languages (top ~10 most spoken) pinned at top
  - Last-used language is default on app reopen
  - Rolling history of last 3 used languages (for quick access)
- Flag icons: most prominent country per language, but detect device locale for variant (e.g., device set to `es_CO` → Colombia flag for Spanish; fallback to Spain)
- Language names displayed in user's OS language (fallback to English)
- Search matches both localized name AND English name (e.g., typing "esp" or "span" both find Spanish/Español)

#### Translation Trigger
- Send button only — no auto-translate while typing
- New messages queue behind active translation (FIFO) — no cancel-and-replace
- Changing target language starts a fresh session (old session saved to history) — aligns with Phase 4 TranslationNotifier's clearContext behavior

#### Streaming & Feedback
- Animated pulsing dots (iMessage-style typing indicator) until first word arrives
- Word-level batching for space-delimited scripts (Latin, Cyrillic, Arabic, etc.) — buffer until space/word boundary, then display complete word
- Token-by-token for non-space-delimited scripts (CJK, Thai) — display each token immediately
- Stop button: send button transforms into stop icon during streaming — tapping halts generation, keeps partial output
- Errors displayed in the response bubble using Phase 3's error resolver (not toast/snackbar)

#### Copy & Actions
- Long-press menu on translation bubbles for copy (and future share options) — no persistent copy icon on bubbles

#### Persistence
- Translation bubbles persist in DB and reload on app launch (like chat sessions)
- Language pair (target language) persists across app restarts

### Claude's Discretion
- Navigation pattern between Translation and Chat screens (bottom nav, top tabs, etc.) — based on existing Phase 3 app shell
- Exact input bar styling and spacing
- Loading skeleton or transition animations
- Exact grid item sizing in language picker
- Error bubble styling details

### Deferred Ideas (OUT OF SCOPE)
- Translation sessions in history drawer should have a distinct icon/theme to differentiate from chat sessions — Phase 7 (Chat History and Sessions)
- Auto-retranslate on language swap as a toggle in app settings — Phase 8 (Chat Settings and Maintenance)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TRNS-01 | User can type or paste text and get a translation to their selected target language | TranslationNotifier (Phase 4) already handles inference pipeline; UI needs input bar + bubble list wired to provider |
| TRNS-02 | User can select source and target languages from all 70+ supported languages | Language picker bottom sheet with GridView + search; language list hardcoded from Tiny Aya model card |
| TRNS-03 | User can swap source/target languages [SUPERSEDED by CONTEXT.md] | Auto-detect is locked — no source selector. TRNS-03 is effectively satisfied by auto-detect; no swap UI needed |
| TRNS-04 | User can copy translated text to clipboard with a single tap | Long-press context menu on translation bubbles using Clipboard.setData; no persistent copy icon |
| TRNS-05 | App remembers last-used language pair across sessions | Target language persisted via SharedPreferences key (settingsProvider already uses SharedPreferencesWithCache) |

**Important note on TRNS-03:** The roadmap requirement mentions "swap button" and "source and target independently" but CONTEXT.md (locked) removes the source language selector and swap button. TRNS-03 is satisfied by the auto-detect architecture; the planner should implement TRNS-03 as "target language only, source is auto-detected."
</phase_requirements>

---

## Summary

Phase 5 builds the Translation UI as a chat-style screen wired to the already-complete `TranslationNotifier` (Phase 4). The primary work is pure Flutter UI: a message bubble list, a multi-line expandable input bar, an iMessage-style typing indicator, word-level token batching, and a language picker bottom sheet with a 3-column grid, search, and flag icons.

The Phase 4 `TranslationNotifier` handles all inference logic (FIFO queue, streaming, stop, DB persistence, context-full detection, language pair reset). The UI layer consumes `TranslationState` and calls `translationNotifierProvider.notifier` methods. No new backend logic is required; Phase 5 is entirely UI.

The main complexity areas are: (1) the language picker — 70+ languages with localized names, flag icons, search that matches both localized and English names, pinned popular languages, and rolling history; (2) word-level token batching to buffer partial tokens before displaying; (3) the iMessage-style typing indicator animation; and (4) replacing the `MainShell` placeholder with a real navigation shell that includes both Translation (this phase) and Chat (Phase 6 placeholder) destinations.

**Primary recommendation:** Build all UI as plain Flutter widgets consuming `TranslationNotifier`. Add `country_flags ^4.1.2` for flag SVGs and `flutter_localized_locales ^2.0.5` for language names in device locale. Navigation shell: use `NavigationBar` (Material 3 bottom nav) to toggle between Translation and Chat tabs.

---

## Standard Stack

### Core (already in pubspec.yaml — no new additions needed for inference)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | 3.1.0 (pinned) | State management — consume TranslationNotifier | Established; pinned per Phase 3 learnings |
| drift | ^2.31.0 | DB persistence (sessions/messages) | Established in Phase 4 |
| shared_preferences | ^2.5.4 | Persist target language across restarts | Already used in settingsProvider |

### New Dependencies Required
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| country_flags | ^4.1.2 | SVG flag icons from ISO 3166 country codes | Active pub.dev package (published 29 days ago as of research date); uses `flag-icons` project; supports `CountryFlag.fromCountryCode()` and `CountryFlag.fromLanguageCode()` |
| flutter_localized_locales | ^2.0.5 | Language names localized to device locale | Provides `LocaleNames.of(context).nameOf('es')` → "Spanish" or "Español" depending on device locale; 563 locales; standard package for this use case |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| country_flags | emoji flags (Unicode) | Emoji flags are simpler (no dependency) but render inconsistently across Android versions and are not scalable; country_flags SVGs render identically on all devices |
| flutter_localized_locales | Hardcoded English names | Simpler, but user decision says "language names displayed in user's OS language"; must use localization package |
| NavigationBar | TabBar / BottomNavigationBar | NavigationBar is Material 3 standard; BottomNavigationBar is deprecated M2; TabBar is more for content tabs not app sections |

**Installation:**
```yaml
# Add to pubspec.yaml dependencies:
country_flags: ^4.1.2
flutter_localized_locales: ^2.0.5
```

```bash
/home/max/Android/flutter/bin/flutter pub get
```

---

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── features/
│   └── translation/
│       ├── application/
│       │   ├── translation_notifier.dart         # EXISTS (Phase 4)
│       │   ├── translation_notifier.g.dart       # EXISTS
│       │   └── language_history_provider.dart    # NEW: rolling 3-language history
│       ├── data/
│       │   └── language_preferences_repository.dart  # NEW: SharedPrefs for target lang
│       ├── domain/
│       │   └── supported_language.dart           # NEW: value object (code, name, countryCode)
│       └── presentation/
│           ├── translation_screen.dart           # NEW: main screen scaffold
│           ├── widgets/
│           │   ├── translation_bubble_list.dart  # NEW: ListView of bubbles
│           │   ├── translation_input_bar.dart    # NEW: TextField + send/stop button
│           │   ├── typing_indicator.dart         # NEW: iMessage pulsing dots
│           │   ├── language_picker_sheet.dart    # NEW: DraggableScrollableSheet with GridView+search
│           │   └── language_grid_item.dart       # NEW: flag + language name button
├── widgets/
│   └── main_shell.dart                           # REPLACE: add NavigationBar for Translation+Chat tabs
└── core/
    └── l10n/
        └── app_en.arb                            # EXTEND: add translation UI strings
```

### Pattern 1: Consuming TranslationNotifier in the UI

`TranslationNotifier` is `keepAlive: true`. Watch it from any widget using `ref.watch(translationNotifierProvider)`. The state object `TranslationState` has all fields needed:

```dart
// Source: translation_notifier.dart (Phase 4)
final state = ref.watch(translationNotifierProvider);

// state.isTranslating    — true during streaming
// state.isModelReady     — false = disable input
// state.translatedText   — current streamed/completed translation
// state.sourceText       — last submitted source text
// state.targetLanguage   — currently selected language name
// state.isContextFull    — show "start new session" banner
// state.activeSession    — current DB session (null before first translate)
```

Triggering actions:
```dart
// Send: calls translate() which queues if busy
ref.read(translationNotifierProvider.notifier).translate(text);

// Stop: cooperative stop — keeps partial output
ref.read(translationNotifierProvider.notifier).stopTranslation();

// New session: saves old session, starts fresh
// (TranslationNotifier._resetSession() is called internally on language change;
// the UI's "new session" button should clear in-memory state and call _resetSession)
// NOTE: TranslationNotifier needs a public newSession() method — check Phase 4 code.

// Change target language: automatically resets session
ref.read(translationNotifierProvider.notifier).setTargetLanguage('French');
```

**IMPORTANT**: Phase 4's `TranslationNotifier` does NOT expose a public `newSession()` / `startNewSession()` method (unlike `ChatNotifier`). The UI's "new session" button needs this. Either:
- (a) Add `newSession()` to `TranslationNotifier` (modifying Phase 4 code), or
- (b) Call `setTargetLanguage(state.targetLanguage)` to trigger `_resetSession()` via language "change" — but this won't work if the language is the same.

**Recommendation:** Add a `startNewSession()` public method to `TranslationNotifier` as part of Phase 5 work.

### Pattern 2: Loading Session History from DB

`TranslationNotifier` does not maintain `messages: List<ChatMessage>` in state (unlike `ChatNotifier`). The UI must load the active session's messages from `ChatRepository` to display history.

The `AppDatabase.watchMessagesForSession(sessionId)` stream auto-updates when new messages arrive. The TranslationScreen should watch this stream when `state.activeSession != null`.

```dart
// Watch messages reactively when a session exists
final sessionId = ref.watch(
  translationNotifierProvider.select((s) => s.activeSession?.id),
);
if (sessionId != null) {
  final messages = ref.watch(
    // Need a provider that wraps watchMessagesForSession(sessionId)
    messagesStreamProvider(sessionId),
  );
}
```

A `StreamProvider.family` is needed:
```dart
@riverpod
Stream<List<ChatMessage>> sessionMessages(Ref ref, int sessionId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchMessagesForSession(sessionId);
}
```

### Pattern 3: Word-Level Token Batching

The context decision requires word-level display for space-delimited scripts but token-by-token for CJK/Thai.

The `TranslationNotifier` currently accumulates all tokens into `state.translatedText` (raw concatenation). The word-batching logic should live in the widget layer, not the notifier:

```dart
// In TranslationBubbleList or a dedicated streaming bubble widget:
// Buffer tokens until a space/word boundary appears, then display.

String _buffer = '';
String _displayedText = '';

void _onNewText(String fullText) {
  // fullText is state.translatedText (grows with each token)
  final newTokens = fullText.substring(_displayedText.length + _buffer.length);

  // Detect if this is a space-delimited script
  if (_isSpaceDelimited(fullText)) {
    _buffer += newTokens;
    if (_buffer.contains(' ') || _buffer.contains('\n')) {
      // Flush up to last word boundary
      final lastSpace = _buffer.lastIndexOf(RegExp(r'[\s\n]'));
      _displayedText += _buffer.substring(0, lastSpace + 1);
      _buffer = _buffer.substring(lastSpace + 1);
    }
  } else {
    // CJK/Thai: display each token immediately
    _displayedText = fullText;
    _buffer = '';
  }
}

bool _isSpaceDelimited(String text) {
  // Unicode ranges: CJK (U+4E00-U+9FFF), Thai (U+0E00-U+0E7F),
  // Lao (U+0E80-U+0EFF), Khmer (U+1780-U+17FF), Burmese (U+1000-U+109F),
  // Japanese hiragana/katakana (U+3040-U+30FF), Japanese kanji shares CJK
  final cjkThaiPattern = RegExp(
    r'[\u4E00-\u9FFF\u3040-\u30FF\u0E00-\u0EFF\u0E80-\u0EFF\u1780-\u17FF\u1000-\u109F]',
  );
  return !cjkThaiPattern.hasMatch(text);
}
```

**Anti-Pattern:** Putting word-batching inside `TranslationNotifier` — it would make the notifier stateful about display state, mixing UI and business logic.

### Pattern 4: iMessage Typing Indicator

The Flutter cookbook provides a complete implementation using `AnimationController` with `Interval` curves for staggered pulsing dots.

Key elements:
- Two controllers: `_appearanceController` (show/hide), `_repeatingController` (loop)
- Three dot animations staggered with `Interval(start, end, curve: Curves.elasticOut)`
- Color pulsing: `Color.lerp(darkColor, brightColor, sin(pi * circleFlashPercent))`
- Show: `_appearanceController.forward()` + `_repeatingController.repeat()`
- Hide: `_appearanceController.reverse()` + `_repeatingController.stop()`

Trigger condition: show when `state.isTranslating && state.translatedText.isEmpty` (waiting for first token). Once the first token arrives (`translatedText.isNotEmpty`), switch to the streaming bubble.

### Pattern 5: Language Picker Bottom Sheet

```dart
// Source: Flutter docs — showModalBottomSheet + DraggableScrollableSheet
void _showLanguagePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // Required for DraggableScrollableSheet
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => LanguagePickerSheet(
        scrollController: scrollController,
        onLanguageSelected: (lang) {
          Navigator.pop(context);
          ref.read(translationNotifierProvider.notifier)
             .setTargetLanguage(lang.displayName);
        },
      ),
    ),
  );
}
```

Inside `LanguagePickerSheet`:
- `TextField` for search (filters language list in `StatefulWidget` local state)
- Pinned popular languages section (Row of chips or mini-grid)
- `GridView.count(crossAxisCount: 3, scrollController: scrollController)` for main list
- Each item: `CountryFlag.fromCountryCode(lang.primaryCountryCode, width: 32, height: 24)` + language name

### Pattern 6: Navigation Shell (Claude's Discretion)

Replace `MainShell` placeholder with a `NavigationBar` (Material 3) shell. Phase 6 will add the Chat tab; Phase 5 adds the Translation tab.

```dart
// In main_shell.dart (replace existing placeholder):
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;  // 0 = Translation, 1 = Chat (placeholder)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const TranslationScreen(),
          // Phase 6 Chat screen goes here — use placeholder for now
          const Center(child: Text('Chat — coming soon')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
      ),
    );
  }
}
```

`IndexedStack` keeps both screens alive (avoids rebuilding when switching tabs). `NavigationBar` is the Material 3 replacement for deprecated `BottomNavigationBar`.

### Pattern 7: Target Language Persistence (TRNS-05)

The target language should be persisted in `SharedPreferences`. The existing `settingsProvider` uses `SharedPreferencesWithCache`; the same pattern applies.

**Option A:** Extend `AppSettings` and `settingsProvider` with a `targetLanguage` field.
**Option B:** Create a separate `languagePreferencesProvider` in the translation feature.

**Recommendation:** Option A — extend `settingsProvider`. Adding a field to `AppSettings` keeps all user preferences in one place and avoids a second `SharedPreferences` initialization.

Add to `settings_provider.dart`:
```dart
class AppSettings {
  final Locale? localeOverride;
  final ErrorTone errorTone;
  final String targetLanguage;  // NEW

  const AppSettings({
    this.localeOverride,
    this.errorTone = ErrorTone.friendly,
    this.targetLanguage = 'Spanish',  // Default
  });
}
```

### Pattern 8: Clipboard Copy (TRNS-04)

```dart
// Source: Flutter services library (no extra package needed)
import 'package:flutter/services.dart';

// In long-press handler on translation bubble:
await Clipboard.setData(ClipboardData(text: message.content));
// Brief confirmation: AnimatedIcon or SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
);
```

Long-press menu pattern:
```dart
GestureDetector(
  onLongPress: () => _showBubbleMenu(context, message),
  child: TranslationBubble(message: message),
)

void _showBubbleMenu(BuildContext context, ChatMessage message) {
  if (message.role != 'assistant') return;
  showModalBottomSheet(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text('Copy translation'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: message.content));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
```

### Anti-Patterns to Avoid

- **`reverse: true` on ListView:** Tempting for chat UIs (new items at bottom), but it inverts the scroll physics and makes content jump when the keyboard appears. Instead, use `ScrollController` + `animateTo(maxScrollExtent)` after new items arrive.
- **Putting word-batching in the Notifier:** Mixes display state with business logic. Keep it in the widget.
- **`Clipboard.getData` without null check:** `getData` can return null if the clipboard is empty or restricted. Guard with null check if reading clipboard.
- **`ColorFiltered` with `BlendMode.saturation`:** NEVER use this for greyscale effects — known Flutter bug #179606 (Phase 2 learned pattern). Irrelevant here but noted.
- **DraggableScrollableSheet without `isScrollControlled: true`:** `showModalBottomSheet` must set `isScrollControlled: true` for `DraggableScrollableSheet` to work correctly.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Country flag SVGs | PNG sprite sheet or emoji | `country_flags ^4.1.2` | Edge cases: flag variants, rendering across Android versions; package uses `flag-icons` project (widely maintained) |
| Language names in device locale | Static English strings | `flutter_localized_locales ^2.0.5` | The user decision requires OS-language names; this package handles 563 locales with fallback to English |
| Clipboard copy | Custom platform channel | `Clipboard.setData` from `flutter/services.dart` | Built into Flutter; no external package needed |
| Typing indicator animation | Timer-based opacity toggle | `AnimationController` with `Interval` staggering | Timer approach causes janky animation; Flutter's animation system provides butter-smooth 60fps |

**Key insight:** The inference pipeline is entirely in Phase 4's `TranslationNotifier`. Phase 5 is a pure UI phase — the main complexity is the language picker and streaming display, not the backend.

---

## Common Pitfalls

### Pitfall 1: Session Messages Not Loading on App Relaunch

**What goes wrong:** `TranslationNotifier` (keepAlive) tracks `activeSession` and `translatedText` in memory. On a fresh app launch, `activeSession` is null and `translatedText` is empty even though the DB has persisted messages from the previous session.

**Why it happens:** `TranslationNotifier.build()` initializes from scratch. It does not query the DB for the last translation session on startup (unlike the Phase 4 pattern where ChatNotifier.loadSession() is called explicitly).

**How to avoid:** The TranslationScreen should, on first mount when `state.activeSession == null`, query `ChatRepository` for the most recent `mode: 'translation'` session and load its messages into a local provider (not into the notifier — the notifier's KV cache is separate). Display historical messages from DB; show model-ready state correctly.

**Warning signs:** "Type something to translate" empty state shown on relaunch even when previous messages exist.

### Pitfall 2: Keyboard Pushing Input Bar Up Incorrectly

**What goes wrong:** When the keyboard appears, the input bar gets pushed up but the message list doesn't resize properly, causing bubbles to be obscured.

**Why it happens:** `SafeArea` uses `viewPadding` (system chrome), but the keyboard contributes to `viewInsets.bottom`. The scaffold must handle `resizeToAvoidBottomInset: true` (default).

**How to avoid:** Use `Scaffold(resizeToAvoidBottomInset: true)` (default, don't set to false). Wrap the input bar in a `SafeArea(bottom: true)` — this adds system padding. For the message list, use `Expanded` widget to take remaining space. The `Scaffold` handles keyboard avoidance automatically when `resizeToAvoidBottomInset` is true.

**Warning signs:** Input bar hidden behind keyboard; messages obscured.

### Pitfall 3: Auto-Scroll Race Condition

**What goes wrong:** `ScrollController.animateTo(maxScrollExtent)` is called before the new widget is laid out, resulting in the scroll going to the previous `maxScrollExtent`, not accounting for the newly added bubble.

**Why it happens:** The call happens in the same frame as state update, before Flutter has laid out the new widget.

**How to avoid:** Use `WidgetsBinding.instance.addPostFrameCallback(() => _scrollToBottom())` after state changes that add a new message. This ensures the scroll happens after the new bubble is laid out.

**Warning signs:** Scroll lands one message short of the bottom.

### Pitfall 4: GridView Inside DraggableScrollableSheet — Scroll Conflict

**What goes wrong:** `GridView` inside `DraggableScrollableSheet` can have conflicting scroll physics — dragging the grid also drags the sheet.

**Why it happens:** Both the sheet and the grid handle vertical drag gestures.

**How to avoid:** Pass the `ScrollController` from `DraggableScrollableSheet.builder` directly to the `GridView`. Set `physics: ClampingScrollPhysics()` on the grid. The sheet's controller takes over drag coordination.

**Warning signs:** Sheet doesn't close when swiping down on the grid; grid doesn't scroll when sheet is at max extent.

### Pitfall 5: Language Search Matching Both Localized and English Names

**What goes wrong:** Search only matches localized names (e.g., typing "Espanol" doesn't find "Español"; typing "span" doesn't find "Spanish" on non-English devices).

**Why it happens:** Search is implemented against only one name string.

**How to avoid:** Each `SupportedLanguage` model must carry both `localizedName` (from `flutter_localized_locales`) and `englishName` (from a static list). The search query is tested against both using `toLowerCase().contains(query.toLowerCase())`.

**Warning signs:** Users on non-English devices can't find languages by typing the English name.

### Pitfall 6: TranslationNotifier Missing `startNewSession()`

**What goes wrong:** The "new session" (+) button in the top bar has nothing to call — `TranslationNotifier` exposes no public method for user-initiated session reset.

**Why it happens:** Phase 4 implemented `_resetSession()` as private (called internally on language change). Phase 4 notes say the UI for this is "Phase 5 / 6".

**How to avoid:** Phase 5 must add a `startNewSession()` public method to `TranslationNotifier` that calls `_resetSession()`. This is a Phase 4 code modification required by Phase 5.

---

## Code Examples

### CountryFlag Widget Usage
```dart
// Source: pub.dev/packages/country_flags (version 4.1.2)
import 'package:country_flags/country_flags.dart';

// By country code (ISO 3166-1 alpha-2):
CountryFlag.fromCountryCode(
  'ES',  // Spain for Spanish
  height: 24,
  width: 32,
  shape: const RoundedRectangle(4),
);

// By language code:
CountryFlag.fromLanguageCode(
  'es',
  height: 24,
  width: 32,
);
```

### LocaleNames Usage
```dart
// Source: pub.dev/packages/flutter_localized_locales (version 2.0.5)
// In app.dart — add to localizationsDelegates:
localizationsDelegates: [
  ...AppLocalizations.localizationsDelegates,
  LocaleNamesLocalizationsDelegate(),  // ADD THIS
],

// In widget:
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

final String localizedName = LocaleNames.of(context)!.nameOf('es') ?? 'Spanish';
// Returns 'Spanish' on English device, 'Español' on Spanish device
```

### Multi-line Expandable Input Field
```dart
// Source: Flutter official TextField documentation
TextField(
  controller: _textController,
  minLines: 1,
  maxLines: 6,  // Grows up to 6 lines before scrolling
  keyboardType: TextInputType.multiline,
  textInputAction: TextInputAction.newline,  // Enter inserts newline
  decoration: InputDecoration(
    hintText: l10n.translationInputHint,  // 'Type something to translate'
    // Uses app theme's inputDecorationTheme (Phase 3)
  ),
)
```

### Auto-Scroll to Bottom
```dart
// Source: Flutter ScrollController docs
final _scrollController = ScrollController();

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

// Call _scrollToBottom() when state.messages.length changes or
// state.translatedText changes (new tokens).
```

### Send/Stop Button Toggle
```dart
// Animated icon swap based on isTranslating state
IconButton(
  onPressed: state.isTranslating
      ? () => ref.read(translationNotifierProvider.notifier).stopTranslation()
      : _handleSend,
  icon: AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: state.isTranslating
        ? const Icon(Icons.stop_circle, key: ValueKey('stop'))
        : const Icon(Icons.send, key: ValueKey('send')),
  ),
  // Disable if model not ready or input is empty
  // color: state.isModelReady ? AppColors.secondary : AppColors.onSurfaceVariant,
)
```

---

## Complete Language List (70+ Tiny Aya Supported Languages)

The following languages are confirmed from the Tiny Aya Global model card on Hugging Face. This is the canonical list for the language picker.

**European (31):**
English, Dutch, French, Italian, Portuguese, Romanian, Spanish, Czech, Polish, Ukrainian, Russian, Greek, German, Danish, Swedish, Norwegian, Catalan, Galician, Welsh, Irish, Basque, Croatian, Latvian, Lithuanian, Slovak, Slovenian, Estonian, Finnish, Hungarian, Serbian, Bulgarian

**Middle Eastern & Central Asian (6):**
Arabic, Persian, Urdu, Turkish, Maltese, Hebrew

**South Asian (8):**
Hindi, Marathi, Bengali, Gujarati, Punjabi, Tamil, Telugu, Nepali

**Southeast Asian (7):**
Tagalog, Malay, Indonesian, Javanese, Khmer, Thai, Lao

**East Asian (4):**
Chinese, Burmese, Japanese, Korean

**African (10):**
Amharic, Hausa, Igbo, Malagasy, Shona, Swahili, Wolof, Xhosa, Yoruba, Zulu

**Total: 66 named languages** (model card says 70+; some additional regional variants may exist in regional model variants — Earth/Fire/Water)

### Language-to-Country Code Mapping (for flag icons)

Each language maps to a primary country code for the flag. The `country_flags` package uses ISO 3166-1 alpha-2 codes.

```dart
// Core mapping — primary country per language
// Device locale variant: if device is 'es_CO', use 'CO' for Spanish
const Map<String, String> kLanguagePrimaryCountry = {
  'English': 'GB',    // or 'US' — use 'US' as it's more globally recognized
  'Spanish': 'ES',    // override to 'MX', 'CO', etc. based on device locale
  'French': 'FR',
  'German': 'DE',
  'Portuguese': 'PT', // or 'BR'
  'Italian': 'IT',
  'Dutch': 'NL',
  'Russian': 'RU',
  'Chinese': 'CN',
  'Japanese': 'JP',
  'Korean': 'KR',
  'Arabic': 'SA',
  'Hindi': 'IN',
  'Bengali': 'BD',    // or 'IN'
  'Urdu': 'PK',
  'Turkish': 'TR',
  'Polish': 'PL',
  'Ukrainian': 'UA',
  'Swedish': 'SE',
  'Norwegian': 'NO',
  'Danish': 'DK',
  'Finnish': 'FI',
  'Greek': 'GR',
  'Czech': 'CZ',
  'Romanian': 'RO',
  'Hungarian': 'HU',
  'Bulgarian': 'BG',
  'Croatian': 'HR',
  'Slovak': 'SK',
  'Slovenian': 'SI',
  'Serbian': 'RS',
  'Estonian': 'EE',
  'Latvian': 'LV',
  'Lithuanian': 'LT',
  'Catalan': 'ES',    // No country flag for Catalan; use Spain
  'Galician': 'ES',   // No country flag for Galician; use Spain
  'Welsh': 'GB',
  'Irish': 'IE',
  'Basque': 'ES',     // No country flag for Basque; use Spain
  'Maltese': 'MT',
  'Hebrew': 'IL',
  'Persian': 'IR',
  'Tagalog': 'PH',
  'Malay': 'MY',
  'Indonesian': 'ID',
  'Vietnamese': 'VN',
  'Thai': 'TH',
  'Khmer': 'KH',
  'Lao': 'LA',
  'Burmese': 'MM',
  'Javanese': 'ID',   // No separate flag; use Indonesia
  'Tamil': 'LK',      // or 'IN' — use 'IN' since India has more speakers
  'Telugu': 'IN',
  'Marathi': 'IN',
  'Gujarati': 'IN',
  'Punjabi': 'IN',    // or 'PK'
  'Nepali': 'NP',
  'Swahili': 'TZ',    // or 'KE'
  'Amharic': 'ET',
  'Hausa': 'NG',
  'Yoruba': 'NG',
  'Igbo': 'NG',
  'Zulu': 'ZA',
  'Xhosa': 'ZA',
  'Shona': 'ZW',
  'Wolof': 'SN',
  'Malagasy': 'MG',
};
```

### Popular Languages (Pinned at Top of Picker — ~10)

Based on most-spoken globally, these should appear at the top of the picker:
1. Spanish
2. French
3. Arabic
4. Chinese
5. Hindi
6. Portuguese
7. Russian
8. Japanese
9. German
10. Korean

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BottomNavigationBar` | `NavigationBar` (Material 3) | Flutter 3.7 / Material 3 stable | Old widget deprecated; new is themed automatically by app ColorScheme |
| Emoji flags | `country_flags` SVG package | Ongoing — emoji flags broken on older Android | SVGs render identically cross-platform |
| Static English language names | `flutter_localized_locales` | Available for years; now version 2.0.5 | Names appear in device locale (French users see "Español" not "Spanish") |
| Manual clipboard platform channel | `Clipboard.setData` (services) | Flutter 1.x | Built in; no external package needed |

**Deprecated/outdated:**
- `BottomNavigationBar`: Deprecated in favor of `NavigationBar` for Material 3 apps. BittyBot already uses Material 3 (useMaterial3 defaults to true in Flutter 3.16+).
- `Scaffold.floatingActionButton` for send button: The send button belongs in the input bar area, not as a FAB.

---

## Open Questions

1. **How to load previous translation session on app relaunch**
   - What we know: `TranslationNotifier` initializes with no `activeSession`. The DB has messages from the prior session. `ChatRepository.watchAllSessions()` can filter by `mode: 'translation'`.
   - What's unclear: Should `TranslationScreen` query the DB on first mount and show historical messages? Or does the notifier load them? The phase 4 `TranslationNotifier` has no `loadSession()` analog to ChatNotifier.
   - Recommendation: Add a `loadLatestSession()` method to `TranslationNotifier` (alongside `startNewSession()`) that queries DB for the latest `mode: 'translation'` session and populates `activeSession`. The bubble list then watches `sessionMessages(state.activeSession.id)` via `StreamProvider.family`.

2. **Spanish flag variant by device locale**
   - What we know: User decision says "detect device locale for variant (e.g., device set to `es_CO` → Colombia flag for Spanish; fallback to Spain)".
   - What's unclear: `country_flags ^4.1.2` supports `CountryFlag.fromCountryCode('CO')` — the variant mapping logic must be in the app code, not the package.
   - Recommendation: Create a `_resolveCountryCode(String languageName, Locale deviceLocale)` helper. For Spanish: if `deviceLocale.countryCode` is `'MX', 'CO', 'AR', 'CL'...` etc., use that country code instead of 'ES'. For other languages where variant is not relevant, use the primary mapping.

3. **Language history rolling 3 (quick access)**
   - What we know: User wants "rolling history of last 3 used languages (for quick access)" in the language picker.
   - What's unclear: Where this is stored (SharedPreferences as a JSON list?) and where in the picker UI it appears (chips? mini-row above the grid?).
   - Recommendation: Persist as a `List<String>` (language names) in SharedPreferences. Show as a row of 3 compact buttons above the popular languages section in the picker.

4. **Soft character limit — what threshold?**
   - What we know: User decision mentions "soft character limit with warning when approaching model context limit". Phase 4 TranslationNotifier has `isContextFull` based on 90% of nCtx=2048 at the prompt level.
   - What's unclear: What character count to show as warning in the input field (before sending).
   - Recommendation: Use a conservative 500 characters as the soft limit for input (corresponding to roughly 125 tokens for Latin scripts). Show a character counter below the input field when > 400 chars. This is separate from `isContextFull` (which is accumulated context, not single-message length).

---

## Sources

### Primary (HIGH confidence)
- Phase 4 `translation_notifier.dart` — complete `TranslationNotifier` API, `TranslationState` fields
- Phase 4 `chat_notifier.dart` — `ChatNotifier.loadSession()` / `startNewSession()` pattern for TranslationNotifier extension
- Phase 3 `app_colors.dart`, `app_theme.dart` — existing design system for bubble styling
- Phase 4 `chat_repository.dart` — `watchMessagesForSession(sessionId)` streaming pattern
- HuggingFace `CohereLabs/tiny-aya-global` model card — confirmed 66-70 language list
- `pub.dev/packages/country_flags` — version 4.1.2, `CountryFlag.fromCountryCode()` API
- `pub.dev/packages/flutter_localized_locales` — version 2.0.5, `LocaleNames.of(context).nameOf()` API
- `docs.flutter.dev/cookbook/effects/typing-indicator` — iMessage typing indicator with `AnimationController + Interval + sin()`

### Secondary (MEDIUM confidence)
- Flutter `NavigationBar` API docs — M3 bottom navigation standard
- Flutter `showModalBottomSheet` + `DraggableScrollableSheet` docs — language picker sheet implementation
- Flutter `TextField` docs — `minLines: 1, maxLines: 6` expandable input pattern
- Flutter `Clipboard.setData` docs — clipboard copy without external package
- Flutter `ScrollController.animateTo` + `addPostFrameCallback` — auto-scroll to bottom pattern

### Tertiary (LOW confidence)
- Word-level token batching pattern — derived from first principles and Unicode ranges; no direct official source. Unicode range list should be validated against actual Tiny Aya output tokens.
- Language-to-country code mapping — hand-curated for this research; some mappings (e.g., Tamil → 'LK' vs 'IN') are judgment calls.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — packages verified on pub.dev with versions confirmed
- Architecture: HIGH — patterns derived from existing Phase 4 code and verified Flutter docs
- Language list: HIGH — verified from HuggingFace model card for tiny-aya-global
- Language-to-country mapping: MEDIUM — hand-curated; validate edge cases
- Word-batching Unicode ranges: MEDIUM — derived from Unicode standard; verify with test tokens from actual model
- Pitfalls: HIGH — based on existing Phase 2-4 code patterns and Flutter documented issues

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (Flutter stable; packages unlikely to change significantly within 30 days)
