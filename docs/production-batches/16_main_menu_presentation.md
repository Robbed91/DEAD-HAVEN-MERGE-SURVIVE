# Batch 16 — Main Menu Presentation

## Scope

Replaced the release-facing procedural farmhouse, polygon treeline, gradient bands and circle glow with an original painterly safe-haven title environment. Existing new-game, continue, settings, quit, overwrite-confirmation and hidden debug-title behaviour remain unchanged.

## Artwork created and integrated

- Source master: `assets/art/main_menu/source/main_menu_safe_haven_master.png` (941 × 1672).
- Android runtime texture: `assets/art/main_menu/runtime/main_menu_safe_haven.png` (720 × 1280).
- Live title and subtitle text remain UI controls rather than baked raster text.
- Existing textured button states and real dynamic control labels remain interactive.

The source artwork is an original OpenAI image-generation output created for this project on 2026-08-01. It contains no external stock assets, copied characters, generated text or watermark. The exact production prompt is recorded below.

## Generation prompt

> Use case: stylized-concept. Asset type: portrait main-menu environment for an Android game, designed for a 720x1280 runtime crop. Create an original final-quality cinematic title-screen environment for Dead Haven: Merge & Survive. A fortified rural safe haven at blue-hour night: weathered two-storey farmhouse beyond a reinforced timber-and-chain-link gate, watchtower and patched fence, muddy approach road, overgrown vegetation, rain-heavy storm clouds, a few distant Hollow figures outside the perimeter, and warm amber window and lantern light communicating fragile safety. Premium 2.5D mobile-game illustration, stylised realism, painterly digital rendering, polished commercial survival merge-game artwork. Portrait 9:16; upper 22 percent atmospheric and relatively uncluttered for a real dynamic game title; farmhouse focal point around the middle third; gate and road creating depth in the lower half; essential art away from the outer 5 percent. Cool storm blue-grey exterior, warm safe-haven amber, dangerous but hopeful, cinematic volumetric mist and restrained rain. Charcoal, storm blue-grey, weathered timber brown, rust orange, olive and warm amber highlights. Wet timber, rusted metal, cracked plaster, muddy gravel, canvas and chain link. No text, letters, numbers, title, logo, watermark, UI, buttons, frames, photographic collage, copied characters, excessive gore, flat polygons, primitive geometry or pixel art.

## Presentation and optimisation

- One compressed 720 × 1280 runtime texture is used by the interactive scene.
- The full source master remains outside runtime scene references.
- Bounded rain (58 particles), road mist (8 particles), and two soft-light sprites add atmosphere without shaders or pre-rendered video.
- Motion and particle emission stop when off-screen and disable through the existing reduced-motion/low-quality effects gate.
- A broken legacy SVG wordmark found in the first running capture was rejected and replaced with licence-safe live theme typography.

## Verification

- `SMOKE_MAIN_MENU_PRESENTATION_OK final_art=1 runtime=720x1280 controls=4 ambient_layers=4 reduced_motion=pass primitives=0`
- Running-game capture: `docs/main-menu-captures/main_menu_final_1080x2400.png`.
- The capture was rendered from the real interactive scene at 720 × 1600 logical resolution and exported at the requested 1080 × 2400 Android reference size.

## Remaining presentation work

- Remaining UI/effects manifest reconciliation and any verified release-facing gaps.
- Remaining music/audio audit reconciliation.
- Android texture/performance pass, obsolete-placeholder verification, multi-branch consolidation and final APK validation.
