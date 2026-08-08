# Batch 10 — Scavenging Locations

## Outcome

All ten implemented scavenging missions now use original illustrated location artwork in the running Godot screen. The existing mission IDs, availability gates, energy costs, choice data, loot, success calculation, completion tracking, and save schema are unchanged.

The screen remains interactive UI. Location names, threat values, energy costs, survivor names, choices, outcome copy, resource values, and rewards are native dynamic controls and are not baked into the artwork.

## Assets created

- Ten 1536 × 1024 production masters under `assets/art/scavenging/source/`.
- Ten 1024 × 683 Android runtime PNGs under `assets/art/scavenging/runtime/`.
- Complete inventory: `docs/SCAVENGING_LOCATION_ASSET_MANIFEST.csv`.

The artwork was created with OpenAI image generation in original-generation mode. A shared prompt established premium painterly 2.5D stylised realism, three-quarter elevated composition, storm blue-grey shadows, warm amber practical lights, weathered materials, restrained debris, mobile-readable silhouettes, and no text, logo, watermark, UI, gore, collage, or flat vector treatment. Each mission prompt then described only the physical location and encounter-relevant props from its existing `.tres` definition. Recovered completed renders from the interrupted run were reused unchanged for `abandoned_grocery_store` and `farm_shed`; eight missing locations were generated in this resumed batch.

## Files modified

- `scenes/scavenging/scavenging.tscn`
- `scenes/scavenging/scavenging.gd`
- `tests/smoke_test_scavenging_presentation.gd`
- `tests/smoke_test_scavenging_presentation.tscn`
- `tests/capture_scavenging_locations.gd`
- `tests/capture_scavenging_locations.tscn`
- `tests/README.md`
- `docs/SCAVENGING_LOCATION_ASSET_MANIFEST.csv`
- `docs/production-batches/10_scavenging_locations.md`

## Presentation integration

- The mission ID selects exactly one location texture at runtime; the ten textures are not preloaded together.
- The selected survivor uses the existing final scavenging-pose artwork.
- Assessment, encounter, successful return, and forced-retreat states use distinct captions, tint treatment, and phase labels.
- Survivor selection, mission choices, rewards, and return navigation continue to call the pre-existing flow.
- Per-location ambience is selected from the already integrated original audio catalog. A primary bed crossfades through `AudioManager`; one restrained secondary layer is added per location.

## Animation added

- Slow 1.2% cinematic environment drift.
- Survivor portrait crossfade and settle when selection changes.
- Interruptible encounter/outcome panel reveal.
- State tint fade and phase-label change.
- Insufficient-energy error shake.

All motion checks `GameManager.effects_enabled()`, is skipped under reduced motion, and is stopped while the scene is off-screen.

## Audio integrated

No new audio file was required. The batch connects the existing original catalog to mission context:

- Interior retail/industrial locations: abandoned-building bed.
- Farm and road locations: forest, wind, or road bed.
- Clinic and high-threat warehouse: distant-Hollow secondary layer.
- Electronics and radio locations: restrained electrical-hum secondary layer.
- Petrol station: Redwater station bed plus road layer.

Existing `scavenge_launch`, `scavenge_search`, `scavenge_success`, `scavenge_failure`, reward, resource, and UI cues remain authoritative.

## Android optimisation

- Runtime textures are 1024 × 683, lossless, opaque, and imported without mipmaps.
- Production masters are excluded from Godot import with `.gdignore`.
- Runtime PNG disk footprint: approximately 16.1 MiB total.
- Only the current mission texture is dynamically loaded: approximately 2.67 MiB uncompressed RGBA working memory for the environment layer.
- Verified at the 720 × 1280 project reference viewport and a 720 × 1414 tall Android logical viewport without clipping or control overflow.

## Verification

- `tests/smoke_test.tscn`
- `tests/smoke_test_scavenging.tscn`
- `tests/smoke_test_scavenging_presentation.tscn`
- `tests/smoke_test_animation_layer.tscn`
- `tests/smoke_test_save.tscn`

Running-game captures:

- Ten assessment screens: `docs/scavenging-captures/01_abandoned_grocery_store.png` through `10_warehouse_depot.png`.
- Encounter state: `docs/scavenging-captures/11_grocery_encounter.png`.
- Successful outcome: `docs/scavenging-captures/12_grocery_success.png`.
- Tall Android equivalents: `docs/scavenging-captures/tall_android/`.

## Remaining placeholders

None remain in the scavenging location environment panel or survivor presentation. The dynamic outcome currently uses the existing generic item-discovery banner and reward systems by design; those systems are outside this location-art batch and remain functional.

## Missing layers or technical problems

The approved environment paintings are flattened opaque compositions rather than separated weather, foliage, prop, and light layers. Ambient motion therefore uses a restrained camera drift and native tint overlays. There are no missing layers that block the integrated scavenging flow. A future request for parallax or individually animated rain/foliage would require separated source layers; it is not simulated by redrawing these approved compositions.
