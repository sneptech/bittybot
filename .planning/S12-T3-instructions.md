# S12-T3: URL Detection + Web Fetch for Translation

## Setup
```bash
cd /home/agent/git/bittybot && git pull origin mowismtest
export PATH="/home/agent/flutter/bin:$PATH"
```

---

## FILE 1: lib/features/translation/application/translation_notifier.dart

### EDIT 1 — Line 137: Change queue type

FIND:
```dart
  final Queue<String> _pendingQueue = Queue<String>();
```
REPLACE WITH:
```dart
  final Queue<({String text, String? hiddenContext})> _pendingQueue = Queue<({String text, String? hiddenContext})>();
```

### EDIT 2 — Line 227: Add hiddenContext parameter to translate()

FIND:
```dart
  Future<void> translate(String text) async {
```
REPLACE WITH:
```dart
  Future<void> translate(String text, {String? hiddenContext}) async {
```

### EDIT 3 — Line 231: Queue entry carries hiddenContext

FIND:
```dart
      _pendingQueue.add(text);
```
REPLACE WITH:
```dart
      _pendingQueue.add((text: text, hiddenContext: hiddenContext));
```

### EDIT 4 — Line 235: Pass hiddenContext to _processTranslation

FIND:
```dart
    await _processTranslation(text);
```
REPLACE WITH:
```dart
    await _processTranslation(text, hiddenContext: hiddenContext);
```

### EDIT 5 — Line 283: Add hiddenContext parameter to _processTranslation()

FIND:
```dart
  Future<void> _processTranslation(String text) async {
```
REPLACE WITH:
```dart
  Future<void> _processTranslation(String text, {String? hiddenContext}) async {
```

### EDIT 6 — Lines 297-309: Use hiddenContext for prompt building

FIND (the block after `await chatRepo.insertMessage(...)` and before context-full detection):
```dart
    // Build prompt — initial for first translation in pair, follow-up thereafter.
    final String prompt;
    if (state.turnCount == 0) {
      prompt = PromptBuilder.buildTranslationPrompt(
        text: text,
        targetLanguage: state.targetLanguage,
      );
    } else {
      prompt = PromptBuilder.buildFollowUpTranslationPrompt(
        text: text,
        targetLanguage: state.targetLanguage,
      );
    }
```
REPLACE WITH:
```dart
    // Use hidden context (e.g. scraped web page) for prompt if provided,
    // otherwise use the user's text directly.
    final promptText = hiddenContext ?? text;

    // Build prompt — initial for first translation in pair, follow-up thereafter.
    final String prompt;
    if (state.turnCount == 0) {
      prompt = PromptBuilder.buildTranslationPrompt(
        text: promptText,
        targetLanguage: state.targetLanguage,
      );
    } else {
      prompt = PromptBuilder.buildFollowUpTranslationPrompt(
        text: promptText,
        targetLanguage: state.targetLanguage,
      );
    }
```

### EDIT 7 — Lines 449-451: _dequeueNextIfAny passes hiddenContext

FIND:
```dart
    if (_pendingQueue.isNotEmpty) {
      final next = _pendingQueue.removeFirst();
      await _processTranslation(next);
    }
```
REPLACE WITH:
```dart
    if (_pendingQueue.isNotEmpty) {
      final next = _pendingQueue.removeFirst();
      await _processTranslation(next.text, hiddenContext: next.hiddenContext);
    }
```

---

## FILE 2: lib/features/translation/presentation/widgets/translation_input_bar.dart

### EDIT 8 — Line 10: Add imports after the camera_button import

FIND:
```dart
import '../../../ocr/presentation/widgets/camera_button.dart';
```
REPLACE WITH:
```dart
import '../../../ocr/presentation/widgets/camera_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../chat/data/web_fetch_service.dart';
import '../../../chat/application/web_fetch_provider.dart';
```

### EDIT 9 — Lines 41-46: Make _onSend async and add URL detection

FIND:
```dart
  void _onSend(TranslationState state) {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    ref.read(translationProvider.notifier).translate(text);
  }
```
REPLACE WITH:
```dart
  Future<void> _onSend(TranslationState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      await _handleWebFetch(text);
      return;
    }
    ref.read(translationProvider.notifier).translate(text);
  }
```

### EDIT 10 — After _onCamera() method (after line 81): Add _handleWebFetch

FIND:
```dart
    if (result != null && result.trim().isNotEmpty) {
      _textController.text = result.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
```
REPLACE WITH:
```dart
    if (result != null && result.trim().isNotEmpty) {
      _textController.text = result.trim();
    }
  }

  Future<void> _handleWebFetch(String url) async {
    final l10n = AppLocalizations.of(context);
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnectivity = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasConnectivity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noInternetConnection)),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fetchingPage),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      final webFetchService = ref.read(webFetchServiceProvider);
      final content = await webFetchService.fetchAndExtract(url);
      final targetLang = ref.read(translationProvider).targetLanguage;
      final hiddenContext =
          'The user shared a web page. Here is the page content:\n\n$content\n\nTranslate the main content of this page to $targetLang. Output ONLY the translation.';
      ref
          .read(translationProvider.notifier)
          .translate(url, hiddenContext: hiddenContext);
    } on WebFetchException catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = switch (error.kind) {
        WebFetchErrorKind.invalidUrl => l10n.webErrorInvalidUrl,
        WebFetchErrorKind.httpError => l10n.webErrorHttpStatus(
          error.statusCode ?? 0,
        ),
        WebFetchErrorKind.emptyContent => l10n.webErrorEmptyContent,
        WebFetchErrorKind.networkError => l10n.webErrorNetwork,
        WebFetchErrorKind.timeout => l10n.webErrorTimeout,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
```

---

## Validation

Run these commands after ALL edits:
```bash
cd /home/agent/git/bittybot
export PATH="/home/agent/flutter/bin:$PATH"
dart analyze lib/
```

If `dart analyze` is clean, commit:
```bash
git add lib/features/translation/application/translation_notifier.dart lib/features/translation/presentation/widgets/translation_input_bar.dart
git commit -m 'feat(translation): [S12-T3] add URL detection and web fetch to translation'
```

Report back with the dart analyze output and the git diff.
