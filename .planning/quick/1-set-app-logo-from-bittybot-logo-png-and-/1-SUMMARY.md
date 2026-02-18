---
phase: quick
plan: 1
subsystem: assets
tags: [app-icon, branding, android, ios, imagemagick]
dependency_graph:
  requires: []
  provides: [android-launcher-icon, ios-app-icon, bittybot-app-name]
  affects: [android-manifest, ios-asset-catalog]
tech_stack:
  added: []
  patterns: [ImageMagick Lanczos resampling for icon generation]
key_files:
  created: []
  modified:
    - android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    - android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    - android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    - android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    - android/app/src/main/AndroidManifest.xml
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
decisions:
  - Used Lanczos resampling for all sizes including the 1024x1024 upscale; iOS Contents.json left unchanged as filenames were already correct
metrics:
  duration: ~2 minutes
  completed: 2026-02-19
  tasks_completed: 3
  files_modified: 21
---

# Quick Task 1: Set App Logo from Bittybot Logo PNG Summary

**One-liner:** Replaced all Android and iOS default Flutter launcher icons with the bittybot green/gold robot dog logo (512x512 source PNG, Lanczos-resampled to all required densities) and capitalized the Android app label to "Bittybot".

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Generate and place Android launcher icons | 96c7381 | 5 mipmap ic_launcher.png files |
| 2 | Generate and place iOS app icon assets | 9887c53 | 15 AppIcon.appiconset PNG files |
| 3 | Set Android app display name to "Bittybot" | 1d2a86b | android/app/src/main/AndroidManifest.xml |

## What Was Done

### Task 1: Android Launcher Icons
Generated 5 sizes from the 512x512 RGBA source logo at `/home/max/Pictures/logos and icons/bittybot/bittybot-logo.png` using `magick -filter Lanczos`:
- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

### Task 2: iOS App Icons
Generated 15 sizes for `ios/Runner/Assets.xcassets/AppIcon.appiconset/` using Lanczos resampling. The 1024x1024 App Store marketing icon required upscaling from the 512x512 source. Contents.json was left unchanged as it already referenced the correct filenames.

### Task 3: Android App Label
Changed `android:label="bittybot"` to `android:label="Bittybot"` in `android/app/src/main/AndroidManifest.xml`. iOS `CFBundleDisplayName` was already "Bittybot" in Info.plist — no change needed.

## Success Criteria Verification

1. Android mipmap ic_launcher.png files — correct dimensions confirmed via `file` command
2. iOS AppIcon.appiconset PNGs — correct dimensions confirmed via `file` command
3. Visual check — both platforms show green/gold robot dog logo (confirmed via Read tool image preview)
4. `android:label="Bittybot"` in AndroidManifest.xml — confirmed
5. No default Flutter icons remain — all replaced by bittybot-logo.png source

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png: FOUND (192x192 RGBA PNG)
- ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png: FOUND (1024x1024 RGBA PNG)
- android/app/src/main/AndroidManifest.xml: android:label="Bittybot" confirmed
- Commits 96c7381, 9887c53, 1d2a86b: all exist in git log
