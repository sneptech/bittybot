---
created: 2026-02-25T02:01:38.491Z
title: Add live test output overlay to integration test runner
area: testing
files:
  - integration_test/spike_binding_load_test.dart
  - integration_test/spike_streaming_test.dart
  - integration_test/spike_multilingual_test.dart
---

## Problem

When running integration tests on-device, the phone shows a blank "Test starting..." screen with no indication of what's actually happening. For long-running tests (e.g., multilingual test at ~30-60 min), this makes it impossible to tell progress from the phone itself — you have to watch the terminal.

## Solution

Add a monospace text overlay below the "Test starting..." banner that streams live output of which test is running and its status.

Feasibility considerations:
- Flutter integration tests run via `flutter test integration_test/` which controls the app process
- Displaying output on the app's UI during testing may require a custom test harness or an overlay widget that only loads in test mode
- Could use a `StreamBuilder` connected to a test progress stream, rendered as a scrolling `Text` widget with monospace font
- Alternative: a transparent overlay that hooks into the test framework's reporter
- Scope: nice-to-have UX improvement, not blocking any phase work
