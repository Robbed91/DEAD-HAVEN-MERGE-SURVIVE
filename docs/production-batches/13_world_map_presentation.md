# Batch 13 — World Map Presentation

## Scope

Completed the presentation layer of the existing world map without changing its destinations, scavenging availability, story flags, save fields, economy, or navigation. The approved painterly regional-map composition remains untouched.

## Assets created

Ten distinct scavenging markers replace the repeated generic crate: abandoned grocery storefront, damaged petrol pump, patched farm shed, roadside wreck, reinforced clinic entrance, police checkpoint, electronics workbench, survivor clothing outlet, warehouse loading bay, and emergency radio relay station.

Each marker has a 1024×1024 transparent source and a 256×256 transparent runtime PNG under `assets/ui/world_map/markers/`. Runtime textures use lossless UI import, alpha-border correction, and no mipmaps.

## Generation origin and prompt set

The ten markers are original project artwork generated with OpenAI's built-in image-generation tool on 1 August 2026. No stock art, existing-game assets, logos, copyrighted characters, photographic collage, or generated labels were used.

Shared prompt:

> Original premium 2.5D mobile-game navigation emblem for Dead Haven: Merge & Survive, stylised realism, painterly digital rendering, clean strong mobile-readable silhouette, simplified three-quarter elevated perspective, visible material depth, weathered post-apocalyptic construction, controlled detail, soft upper-left light, warm amber accents, cool storm-grey shadows, restrained charcoal edge definition, commercial Android game quality. Isolated physical location miniature or defining object, no baked frame, no text, no letters, no numerals, no logo, no watermark. Square composition, subject occupies 72–78 percent with generous consistent padding. Perfectly flat solid green chroma-key background. No green in the object. No cast shadow outside the object. No flat line icon, monochrome pictogram, emoji, utility-app symbol, cropped object, duplicate parts, or floating clutter.

Each generation appended the physical location description recorded in `docs/NAVIGATION_ICON_MANIFEST.csv`. Outputs were visually inspected, converted from green chroma to alpha locally, and downscaled to the runtime tier.

## Integration and animation

- Every available scavenging mission now resolves to its own illustrated location marker.
- Locked residences retain their illustrated building, desaturate, and receive a separate lock badge.
- Existing sequential story flags reveal four curved route segments. No new progression state was introduced.
- Route reveal and frontier pulse respect reduced-motion and low-quality settings.
- Existing unlocked residence markers receive a restrained reveal response.
- The delivery van still appears only after discovery and now travels presentation-only along the highest unlocked route segment before retaining its existing destination.

## Verification

- `SMOKE_WORLD_MAP_PRESENTATION_OK unique_scavenge=10 locked_identity=1 routes=4 vehicle=1`
- `SMOKE_UI_SKIN_OK states=8 navigation=5 emoji_markers=0`
- `SMOKE_TEST_OK` across all major scenes.
- Two running-game map states captured through a 720×1600 expanded canvas and scaled to the 1080×2400 Android reference.
- Ten source/runtime pairs verified for dimensions and transparent corners.
- The preceding hotspot Android captures were corrected to use the same logical-canvas simulation and refreshed.

## Remaining presentation work

- Dialogue staging, defence presentation, remaining UI/effects and audio completion.
- Android package optimisation and physical-device performance pass.
- Release-facing launcher icon replacement in the final Android batch.
- Before building the APK, all remote production branches must be inventoried and deliberately consolidated; this batch does not pre-emptively merge them.
