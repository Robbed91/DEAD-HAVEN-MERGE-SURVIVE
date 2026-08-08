# Batch 17 — Splash Presentation

## Scope

Replaced the plain charcoal splash and broken stacked SVG with the approved painterly safe-haven composition and live title typography. The existing boot destination, timed advance, fade duration and tap-to-skip behaviour are preserved.

## Presentation

- Reuses the verified 720 × 1280 main-menu runtime environment instead of loading a second full-screen texture at boot.
- Uses real theme text for `DEAD HAVEN`, `MERGE & SURVIVE`, and the static tagline; no generated lettering is baked into imagery.
- Adds a restrained title plate, vignette, rain, road mist and warm light flicker.
- Adds a 3.5% title settle during fade-in when effects are enabled.
- Reduced motion removes the title settle and suspends all ambient processors and particles.

No new raster artwork was created in this batch.

## Verification

- `SMOKE_SPLASH_PRESENTATION_OK final_art=1 live_title=1 legacy_svg=0 reduced_motion=pass`
- Running-game capture: `docs/splash-captures/splash_final_1080x2400.png`.
- The capture was rendered from the real splash scene at 720 × 1600 logical resolution and exported at 1080 × 2400.

## Remaining release-facing work

- Replace the current flat geometric launcher/adaptive icon with final illustrated Android icon artwork during the dedicated Android export batch.
- Reconcile remaining UI/effects/audio manifest rows against current runtime evidence.
- Consolidate the explicitly selected GitHub branches before the final APK build, then run device/performance and install/upgrade validation.
