# S12-T2 Instructions — Auto URL Detection + Web Mode Removal

**Worker:** Pane 4 (TopazPond)
**Branch:** master (already has T1 commit `3e38ce9`)

## Step 1: Pull latest master

```bash
cd /home/agent/git/bittybot && git checkout master && git pull origin master
```

## Step 2: Edit chat_input_bar.dart

File: `lib/features/chat/presentation/widgets/chat_input_bar.dart`

### EDIT 2a: Remove web_mode_indicator import (line 10)
DELETE this line entirely:
```dart
import 'web_mode_indicator.dart';
```

### EDIT 2b: Remove _isWebMode state variable (line 33)
DELETE this line entirely:
```dart
  bool _isWebMode = false;
```

### EDIT 2c: Replace _onSend method (lines 41-50)
Change:
```dart
  Future<void> _onSend(ChatState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    if (_isWebMode) {
      await _handleWebFetch(text);
      return;
    }
    await ref.read(chatProvider.notifier).sendMessage(text);
  }
```
To:
```dart
  Future<void> _onSend(ChatState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty || !state.isModelReady) return;
    _textController.clear();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      await _handleWebFetch(text);
      return;
    }
    await ref.read(chatProvider.notifier).sendMessage(text);
  }
```

### EDIT 2d: Replace _handleWebFetch success path (lines 80-86)
Change:
```dart
      final webFetchService = ref.read(webFetchServiceProvider);
      final content = await webFetchService.fetchAndExtract(url);
      final notifier = ref.read(chatProvider.notifier);
      await notifier.sendMessage(
        '[Web: $url]\n\n${l10n.webSearchPrompt}\n\n$content',
      );
```
To:
```dart
      final webFetchService = ref.read(webFetchServiceProvider);
      final content = await webFetchService.fetchAndExtract(url);
      final hiddenContext =
          'The user shared a web page. Here is the page content:\n\n$content\n\nExplain to the user what this page is about. Be concise.';
      await ref.read(chatProvider.notifier).sendMessage(url, hiddenContext: hiddenContext);
```

### EDIT 2e: Remove WebModeIndicator conditional (lines 119-122)
DELETE these 4 lines entirely:
```dart
            if (_isWebMode) ...[
              const WebModeIndicator(),
              const SizedBox(height: 8),
            ],
```

### EDIT 2f: Remove globe IconButton (lines 126-141)
DELETE these 16 lines entirely:
```dart
                IconButton(
                  onPressed: state.isGenerating
                      ? null
                      : () => setState(() => _isWebMode = !_isWebMode),
                  icon: Icon(
                    _isWebMode
                        ? Icons.language
                        : Icons.chat_bubble_outline,
                  ),
                  color: _isWebMode
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  tooltip: _isWebMode
                      ? l10n.switchToChat
                      : l10n.switchToWebSearch,
                ),
```

### EDIT 2g: Simplify hint text (around line 154)
Change:
```dart
                          hintText: _isWebMode
                              ? l10n.webSearchInputHint
                              : l10n.chatInputHint,
```
To:
```dart
                          hintText: l10n.chatInputHint,
```

## Step 3: Delete web_mode_indicator.dart

```bash
rm lib/features/chat/presentation/widgets/web_mode_indicator.dart
```

## Step 4: Remove obsolete ARB keys from ALL 10 files

For EACH of these 10 files in `lib/core/l10n/`:
- app_en.arb, app_ar.arb, app_de.arb, app_es.arb, app_fr.arb
- app_hi.arb, app_ja.arb, app_ko.arb, app_pt.arb, app_zh.arb

Remove these key PAIRS (both the key and its @-description). The exact key names are:
1. `"webSearchMode"` and `"@webSearchMode"`
2. `"switchToWebSearch"` and `"@switchToWebSearch"`
3. `"switchToChat"` and `"@switchToChat"`
4. `"webSearchInputHint"` and `"@webSearchInputHint"`
5. `"webSearchPrompt"` and `"@webSearchPrompt"`

KEEP these keys (still used): `noInternetConnection`, `fetchingPage`, all `webError*` keys.

Make sure to remove trailing commas properly so JSON remains valid.

## Step 5: Validate

```bash
export PATH=/home/agent/flutter/bin:$PATH
dart analyze lib/
```

## Step 6: Commit

```bash
git add -A
git commit -m 'feat(chat): [S12-T2] auto URL detection, remove manual web mode toggle'
```

Report back when done.
