# Icon And Splash Migration Plan

Date: 2026-06-18

## Current State

- The active in-app bootstrap logo uses `assets/branding/icon-192.png`, copied from the local Intellia237 web reference.
- Existing launcher and splash generated assets remain from the pre-rebrand mobile project.
- `flutter_launcher_icons` and `flutter_native_splash` still point to historical `assets/icons/*` files.
- No icon generation or splash generation was executed in this phase.

## Required Future Steps

1. Confirm final INTELLIA237 brand master assets with product/design.
2. Replace `flutter_launcher_icons.image_path`, adaptive icon foreground, and platform-specific image paths with approved INTELLIA237 source assets.
3. Replace `flutter_native_splash.image` and `android_12.image` with approved INTELLIA237 source assets.
4. Run launcher and splash generation in a dedicated branch.
5. Verify Android launcher icon, Android 12 splash, iOS launch screen, web manifest icons, Windows/macOS/Linux metadata.
6. Remove legacy visual files only after generated platform assets are verified.

## Staging And Production Notes

- Production Android app ID must remain `com.edunova.app`.
- Production iOS bundle ID must remain `com.edunova.app`.
- Staging Android app ID is `com.intellia237.app.staging`.
- Staging iOS bundle ID is planned as `com.intellia237.app.staging`, but Xcode schemes/configurations were not generated from Windows in this phase.

## Blockers

- No final native icon/splash asset package was provided beyond the local web reference icons.
- Native iOS scheme work should be completed on macOS/Xcode to avoid signing and project-file drift.
- Staging Firebase client files must be created from the real `intellia237-staging` project before staging can launch.
