# Batch 12 — Remaining Residence Hotspot Illustrations

## Scope

Replaced the release-facing procedural hotspot pictograms for Redwater Service Station, Greybridge School, and Saint Mercy Hospital. Existing residence IDs, hotspot IDs, quest requirements, state transitions, save data, progression, and economy remain unchanged.

## Assets created

- Redwater: `fuel_pumps`, `service_bay`, `convenience_store`, `cashier_office`, `generator_room`, `perimeter_fence`, `drainage_tunnel`, `garage_workshop`.
- Greybridge: `main_hall`, `gymnasium`, `library`, `cafeteria`, `boiler_room`, `admin_office`, `playground_fence`, `radio_tower`.
- Saint Mercy: `reception_er`, `pharmacy`, `patient_ward`, `surgical_suite`, `power_room`, `ambulance_bay`, `records_office`, `isolation_ward`.
- Each object has a 1024×1024 alpha source and 256×256 alpha runtime PNG under `assets/ui/repair_hotspots/<residence>/`.

## Generation origin and prompt set

The artwork is original project artwork generated with OpenAI's built-in image-generation tool on 1 August 2026. No external game assets, stock objects, logos, copyrighted characters, or photographic collages were used.

Shared prompt:

> Original premium 2.5D mobile-game object illustration for Dead Haven: Merge & Survive, stylised realism, painterly digital rendering, strong mobile-readable silhouette, three-quarter top-down perspective, weathered post-apocalyptic materials, controlled detail, soft directional lighting from upper-left, subtle charcoal edge definition, warm amber highlights, cool storm-grey shadows, commercial Android merge-game quality, isolated physical object, no text, no watermark. Square 1024 composition, subject occupying 76–80 percent with generous padding. No flat line icon, pictogram, square frame, letters, numerals, logos, floating or duplicated pieces, or cropped object.

Each call appended the physical-object description recorded in `docs/REPAIR_HOTSPOT_ASSET_MANIFEST.csv`. Sources were rendered against uniform green chroma, converted to alpha locally, and visually checked before integration. The first fuel-pump render was rejected because it contained meter lettering; the accepted replacement uses a completely blank meter.

## Files modified

- `scripts/residence/hotspot_visual.gd`
- `tools/process_icon_chroma.gd`
- `docs/REPAIR_HOTSPOT_ASSET_MANIFEST.csv`
- Residence capture images under `docs/redwater-captures/`, `docs/greybridge-captures/`, and `docs/saint_mercy-captures/`
- New source/runtime artwork under `assets/ui/repair_hotspots/redwater/`, `greybridge/`, and `saint_mercy/`
- New verification scripts `tests/smoke_test_remaining_hotspot_icons.*` and `tests/capture_remaining_hotspots_android.*`

## Integration and states

All 24 IDs now use the shared illustrated hotspot presentation with:

- Full-colour available state and restrained availability pulse.
- Selected scale/rim response.
- Desaturated locked state while retaining the physical object.
- Completed object with separate completion indicator and reduced movement.
- Insufficient-material count without replacing the object.
- Idle float, unlock sweep, state crossfade, and completion burst.

The procedural renderer remains only as a defensive fallback for unknown future residence data. It is no longer reached by any hotspot in the five implemented residences.

## Verification

- `SMOKE_REMAINING_HOTSPOT_ICONS_OK icons=24 source=1024 runtime=256 fallback=0`
- Redwater gameplay, six visual-state save round trips, and Lena rescue pass.
- Greybridge gameplay, six visual-state save round trips, and Riley rescue pass.
- Saint Mercy gameplay, six visual-state save round trips, and Imogen rescue pass.
- General save, reload, and backup recovery pass.
- Eighteen desktop running-game state captures refreshed.
- Three true 1080×2400 SubViewport captures saved under `docs/hotspot-captures/`.

Godot 4.3 was used for import and verification. Runtime icons use lossless UI texture import, alpha-border correction, and no mipmaps.

## Remaining placeholders

- No procedural hotspot icon remains in the five implemented residence screens.
- Main menu procedural environment, defence presentation, world-map interaction layer, dialogue staging, and remaining animation/effects work remain scheduled for later batches.
