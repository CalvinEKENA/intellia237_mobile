# Brand Asset Inventory

Date: 2026-06-18

## Source Reference

Assets copied from the local web reference at `intellia237/public`.

| Source | Destination | Size | Use |
| --- | --- | ---: | --- |
| `intellia237/public/favicon.svg` | `assets/branding/favicon.svg` | 466 B | Future web/favicon reference. |
| `intellia237/public/icon-192.png` | `assets/branding/icon-192.png` | 3.4 KB | Active Flutter bootstrap logo. |
| `intellia237/public/icon-512.png` | `assets/branding/icon-512.png` | 10.8 KB | Candidate launcher/splash source after native regeneration. |
| `intellia237/public/apple-touch-icon.png` | `assets/branding/apple-touch-icon.png` | 3.1 KB | Candidate iOS/web touch icon reference. |
| `intellia237/public/companions/kira.png` | `assets/companions/kira.png` | 285.7 KB | Kira companion asset candidate. |
| `intellia237/public/companions/leo.png` | `assets/companions/leo.png` | 248.8 KB | Leo companion asset candidate. |
| `intellia237/public/companions/kira.svg` | `assets/companions/kira.svg` | 1.6 KB | Kira vector placeholder/reference. |
| `intellia237/public/companions/leo.svg` | `assets/companions/leo.svg` | 1.7 KB | Leo vector placeholder/reference. |

## Active Usage

| Asset | Active use |
| --- | --- |
| `assets/branding/icon-192.png` | `BootstrapScreen` logo. |
| `assets/branding/` | Declared in `pubspec.yaml`. |
| `assets/companions/` | Declared in `pubspec.yaml` for the future Kira/Leo migration. |

## Legacy Assets

| Asset | Current state | Decision |
| --- | --- | --- |
| `assets/icons/edunova.png` | Not referenced by active Flutter code after this phase. | Keep as legacy source until a dedicated visual cleanup removes or archives it. |
| `assets/icons/icone.png` | Still referenced by `flutter_launcher_icons` config. | Do not regenerate launcher icons in this phase; replace through the icon migration plan. |
| `assets/icons/logo_splash.png` | Still referenced by `flutter_native_splash` config. | Do not regenerate splash screens in this phase; replace through the icon migration plan. |
| `assets/icons/logo_android12.png` | Still referenced by Android 12 splash config. | Do not regenerate splash screens in this phase; replace through the icon migration plan. |
| `assets/lottie/onboarding_welcome.json` | Not referenced by active Flutter code. Contains embedded legacy text. | Keep as documented legacy generated animation pending visual cleanup. |
| `assets/lottie/education-excellence-v2.json` | Not referenced by active Flutter code. Contains embedded legacy text. | Keep as documented legacy generated animation pending visual cleanup. |

## Constraints

- No new logo or generated image was created.
- No launcher icon or splash generation was run.
- Copied assets are source-backed by the local web reference.
- Legacy visual files are not presented as final INTELLIA237 assets.
