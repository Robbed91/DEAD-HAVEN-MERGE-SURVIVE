# Production Batch 19 — Android Launcher Identity

## Objective

Replace the flat launcher SVG with an original painterly Dead Haven identity that works as a legacy icon, Android adaptive icon, and Android 13 themed icon without falling back to Godot artwork.

## Art direction and generation record

The accepted composition is a fortified timber safe-haven gate seen head-on, reinforced with weathered metal, with warm amber safety light against a cool storm-blue exterior. It deliberately avoids title text and small decoration so the central doorway remains legible at launcher size.

The source master, foreground chroma master, and background master were generated with OpenAI image generation using the approved Hollow Creek painterly 2.5D style as the direction. The foreground prompt required a complete isolated gate, centered inside the adaptive safe zone, on a uniform green removal field. The background prompt required only atmospheric storm woodland and amber ground glow, with no doorway or focal object. Generated results were reviewed at full resolution before integration.

The first keyed foreground conversion was rejected because green/teal spill remained around the silhouette. No rejected conversion is retained in a runtime path. `tools/build_android_launcher_assets.ps1` now performs deterministic green-dominance removal and edge despill, then derives all runtime and review assets from the approved masters.

## Runtime assets

- `assets/branding/android/launcher_main.png` — opaque 512×512 legacy/main icon.
- `assets/branding/android/adaptive_foreground.png` — transparent 432×432 foreground; critical gate content stays inside the central 264×264 safe square.
- `assets/branding/android/adaptive_background.png` — opaque 432×432 atmospheric background.
- `assets/branding/android/adaptive_monochrome.png` — white-alpha 432×432 themed silhouette.
- `android/build/res/mipmap-anydpi-v26/icon.xml` and density-specific `icon_monochrome.png` files — explicit Android 13 themed-icon resource overlay.

Godot 4.3.stable supports main/adaptive foreground/background export but does not emit the later monochrome option itself. The checked-in Gradle resource overlay adds the monochrome element to the generated adaptive icon XML, preventing a default themed layer while retaining the required matching 4.3.stable editor and export templates.

## Evidence

- `docs/android-launcher-captures/launcher_mask_contact_sheet.png` — circle, squircle, rounded-square, legacy square, and themed light/dark review.
- `docs/android-launcher-captures/launcher_48_*.png` — 48-pixel legibility reviews.
- `docs/android-launcher-captures/pixel9_app_drawer_installed.png` — installed Pixel 9 app-drawer presentation.
- `docs/android-launcher-captures/pixel9_launcher_installed.png` — installed launcher presentation.
- `docs/android-launcher-captures/pixel9_launcher_themed.png` — installed Android themed-icon presentation.
- `docs/android-launcher-captures/pixel9_recent_apps.png` — installed Recents presentation.

## Verification

- Focused launcher test validates dimensions, opacity/alpha roles, adaptive safe-zone bounds, project/export references, and the explicit Android monochrome overlay.
- Debug-signed version-code-1 APK installed under `com.deadhaven.mergeandsurvive` and retained the same debug signing certificate as the baseline.
- APK inspection confirms the adaptive XML contains `<monochrome>` and all six monochrome density resources.
- The installed themed-icon review rejected the first detail-derived silhouette because it read like a letter at dock size; the final authored peaked doorway silhouette is installed and readable.
- Clean Godot import and all 33 smoke-test scenes pass.
