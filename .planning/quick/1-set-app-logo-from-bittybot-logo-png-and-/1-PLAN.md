---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  - android/app/src/main/res/mipmap-mdpi/ic_launcher.png
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
autonomous: true
requirements: []
must_haves:
  truths:
    - "Android launcher shows the bittybot green/gold robot dog icon, not the default Flutter icon"
    - "iOS home screen shows the bittybot green/gold robot dog icon, not the default Flutter icon"
    - "Android installed app name displays as 'Bittybot' (capital B)"
    - "iOS installed app name displays as 'Bittybot' (capital B)"
  artifacts:
    - path: "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
      provides: "Highest-res Android launcher icon (192x192)"
    - path: "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
      provides: "iOS App Store marketing icon (1024x1024)"
    - path: "android/app/src/main/AndroidManifest.xml"
      provides: "Android app label set to Bittybot"
  key_links: []
---

<objective>
Replace default Flutter app icons with the bittybot logo on both Android and iOS, and ensure the installed app name displays as "Bittybot" on both platforms.

Purpose: The app currently shows the default Flutter icon and lowercase name. This replaces them with the actual brand identity.
Output: All platform launcher icons replaced, app name corrected.
</objective>

<execution_context>
@/home/max/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
Source logo: /home/max/Pictures/logos and icons/bittybot/bittybot-logo.png (512x512 RGBA PNG)
ImageMagick available at: /usr/bin/magick
</context>

<tasks>

<task type="auto">
  <name>Task 1: Generate and place Android launcher icons</name>
  <files>
    android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  </files>
  <action>
Using ImageMagick (`magick`), resize the source logo `/home/max/Pictures/logos and icons/bittybot/bittybot-logo.png` to all required Android mipmap sizes and overwrite the existing `ic_launcher.png` in each density bucket:

- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

Use high-quality Lanczos resampling: `magick input.png -resize NxN -filter Lanczos output.png`

The source is 512x512 so all sizes are downscales (no upscaling artifacts).
  </action>
  <verify>
For each mipmap directory, run `file android/app/src/main/res/mipmap-*/ic_launcher.png` and confirm each reports the correct dimensions (48, 72, 96, 144, 192). Visually confirm one of them with the Read tool to ensure it shows the green/gold robot dog, not the Flutter logo.
  </verify>
  <done>All 5 Android mipmap directories contain ic_launcher.png resized from bittybot-logo.png at correct dimensions.</done>
</task>

<task type="auto">
  <name>Task 2: Generate and place iOS app icon assets</name>
  <files>
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
  </files>
  <action>
Using ImageMagick (`magick`), resize the source logo to all required iOS icon sizes and overwrite existing files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`. The source is 512x512, so the 1024x1024 marketing icon requires UPSCALING -- use `-filter Lanczos` for best quality.

Required sizes (filename -> pixel dimensions):
- Icon-App-20x20@1x.png -> 20x20
- Icon-App-20x20@2x.png -> 40x40
- Icon-App-20x20@3x.png -> 60x60
- Icon-App-29x29@1x.png -> 29x29
- Icon-App-29x29@2x.png -> 58x58
- Icon-App-29x29@3x.png -> 87x87
- Icon-App-40x40@1x.png -> 40x40
- Icon-App-40x40@2x.png -> 80x80
- Icon-App-40x40@3x.png -> 120x120
- Icon-App-60x60@2x.png -> 120x120
- Icon-App-60x60@3x.png -> 180x180
- Icon-App-76x76@1x.png -> 76x76
- Icon-App-76x76@2x.png -> 152x152
- Icon-App-83.5x83.5@2x.png -> 167x167
- Icon-App-1024x1024@1x.png -> 1024x1024

Do NOT modify Contents.json -- it already references the correct filenames.

Use Lanczos resampling for all: `magick input.png -resize NxN -filter Lanczos output.png`
  </action>
  <verify>
Run `file ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` to confirm 1024x1024 dimensions. Run `file ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` to confirm 180x180 dimensions. Visually confirm one with the Read tool to ensure it shows the bittybot logo, not the Flutter logo.
  </verify>
  <done>All 15 iOS icon asset files replaced with bittybot-logo.png at correct dimensions per Contents.json spec.</done>
</task>

<task type="auto">
  <name>Task 3: Set Android app display name to "Bittybot"</name>
  <files>android/app/src/main/AndroidManifest.xml</files>
  <action>
In `android/app/src/main/AndroidManifest.xml`, change `android:label="bittybot"` to `android:label="Bittybot"` (capitalize the B).

This is line 17 in the current file. Only change the label value; do not modify anything else.

Note: iOS already has `CFBundleDisplayName` set to "Bittybot" in Info.plist, so no iOS change is needed for the app name.
  </action>
  <verify>
Read AndroidManifest.xml and confirm `android:label="Bittybot"` appears (capital B). Grep for any remaining `android:label="bittybot"` (lowercase) to confirm none remain.
  </verify>
  <done>Android app will display as "Bittybot" in the launcher and app drawer.</done>
</task>

</tasks>

<verification>
- All Android mipmap ic_launcher.png files are bittybot-logo.png at correct density sizes
- All iOS AppIcon.appiconset PNGs are bittybot-logo.png at correct sizes per Contents.json
- Contents.json is unchanged (already correct)
- AndroidManifest.xml label is "Bittybot"
- iOS Info.plist CFBundleDisplayName is "Bittybot" (already was correct, unchanged)
</verification>

<success_criteria>
1. `file android/app/src/main/res/mipmap-*/ic_launcher.png` reports correct dimensions for each density bucket
2. `file ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` reports correct dimensions for each icon variant
3. Visual check of at least one icon per platform confirms bittybot green/gold robot dog logo
4. `android:label="Bittybot"` in AndroidManifest.xml
5. No default Flutter icons remain in any icon asset directory
</success_criteria>

<output>
Commit all changed icon files and AndroidManifest.xml with message describing the app icon and name update.
</output>
