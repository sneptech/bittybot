---
status: testing
phase: 03-app-foundation-and-design-system
source: 03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md
started: 2026-02-19T12:00:00Z
updated: 2026-02-19T12:00:00Z
---

## Current Test

number: 1
name: App launches on device
expected: |
  Run `flutter run` on Android device/emulator. The app builds, installs, and launches without crash.
  A loading screen appears briefly, then transitions to the main shell.
awaiting: user response

## Tests

### 1. App launches on device
expected: Run `flutter run` on Android device/emulator. The app builds, installs, and launches without crash. A loading screen appears briefly, then transitions to the main shell.
result: [pending]

### 2. Dark theme and Cohere green palette
expected: The app displays a near-black background (#0A1A0A), forest green primary elements (#1B5E20), and lime/yellow-green accent colors (#8BC34A). No white/light theme elements visible.
result: [pending]

### 3. Loading screen appearance
expected: During startup, a full-screen loading view appears with a lime-colored circular progress indicator, a title ("BittyBot" or localized equivalent), and a "Getting things ready" message. All text uses Lato font.
result: [pending]

### 4. Body text is Lato at 16sp
expected: Body text throughout the app renders in Lato font at a legible size (16sp minimum). Text is clearly readable — not too small for a travel scenario.
result: [pending]

### 5. Locale: Arabic (RTL layout)
expected: Set device locale to Arabic. Relaunch app. All UI strings appear in Arabic. Layout mirrors to RTL — text right-aligned, AppBar title right-aligned, padding directions reversed.
result: [pending]

### 6. Locale: Japanese
expected: Set device locale to Japanese. Relaunch app. All UI strings appear in Japanese characters.
result: [pending]

### 7. Locale: Unsupported locale fallback
expected: Set device locale to an unsupported language (e.g., Thai, Swahili). Relaunch app. All UI strings fall back to English.
result: [pending]

### 8. Error screen with retry
expected: If startup fails (e.g., simulate by temporarily breaking settings init), an error screen appears with a human-readable message (not a stack trace) and a "Retry" button. The retry button is at least 48dp tall.
result: [pending]

### 9. Unit tests pass
expected: `flutter test` runs all 20 tests (10 theme, 9 error resolver, 1 smoke) and all pass with zero failures.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0

## Gaps

[none yet]
