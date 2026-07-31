# Batch 11 — Vehicles

## Outcome

The only implemented vehicle, `delivery_van`, now has a final illustrated nine-stage progression in the running Godot screen. The vehicle ID, discovery event, stage names, stage requirements, item consumption, stage order, statistics, save data, and world-map destination are unchanged.

## Artwork

- Locked 3 × 3 production atlas: `assets/art/vehicles/delivery_van/source/delivery_van_progression_atlas.png`.
- Nine extracted 418 × 418 source panels in `assets/art/vehicles/delivery_van/source/`.
- Nine Android runtime textures at 512 × 512 in `assets/art/vehicles/delivery_van/runtime/`.
- Asset inventory: `docs/VEHICLE_ASSET_MANIFEST.csv`.

The atlas was created with the built-in OpenAI image-generation tool in original-generation mode. Final prompt direction: an original old rural delivery van presented in a strict 3 × 3 progression sheet, identical three-quarter front-left camera, vehicle proportions, wheelbase, olive-and-rust paint, scale, lighting, and framing across every cell; premium painterly 2.5D stylised realism; stages progressing through wreck, engine, tyres, fuel, interior racks, reinforced windows, front ram, roof cargo, and long-range radio configuration; no labels, logos, UI, characters, watermarks, changing camera, changing model, floating parts, collage, or flat vector treatment.

## Presentation integration

- `scripts/vehicle/vehicle_visual.gd` no longer draws the van from rectangles, circles, and lines.
- The existing stage value dynamically selects one illustrated texture.
- Previous and current stage art crossfade during upgrades.
- The existing requirement item remains a native `ItemView`; names, counts, and button availability remain dynamic.
- Stage title, progress, next upgrade, engine status, and completion state remain native UI text.
- The generic engine ambience is corrected to remain silent at the saved wreck stage and to fade in only after the engine-repair stage.

## Animation and effects

- Engine ignition compression and bounce.
- Low-amplitude idle suspension movement.
- Headlight glow.
- Bounded exhaust particles.
- Door-open interior-light reveal.
- Wheel-motion test with illustrated-art-aligned wheel overlays.
- Dust burst and short drive preview.
- Upgrade crossfade and amber install wash.
- Stage-eight radio pulse.

Animations are interruptible where appropriate, stop while off-screen, and collapse to the final visual state when `GameManager.effects_enabled()` is false. Route/map vehicle movement remains assigned to the next world-map batch because that animation belongs to the map route and must not be faked inside this screen.

## Audio

No new files were required. The screen uses the existing project-owned original cues and buses:

- `vehicle_start`
- `vehicle_exhaust`
- `vehicle_headlights`
- `vehicle_door`
- `vehicle_engine`
- existing UI, reward, error, and item-consumption cues

## Android optimisation

- Runtime art: nine 512 × 512 opaque PNGs, lossless, mipmaps disabled.
- Production masters excluded from Godot import with `.gdignore`.
- Runtime PNG disk footprint: approximately 4.53 MiB.
- Only the current and immediately previous stage textures are needed during a crossfade; normal steady-state environment texture memory is approximately 1 MiB RGBA.
- Verified at 720 × 1280 and 720 × 1414 logical Android portrait viewports.

## Verification

- `tests/smoke_test.tscn`
- `tests/smoke_test_vehicle_survivors.tscn`
- `tests/smoke_test_vehicle_presentation.tscn`
- `tests/smoke_test_animation_layer.tscn`
- `tests/smoke_test_ui_skin.tscn`
- `tests/smoke_test_save.tscn`

Running captures:

- All stages: `docs/vehicle-captures/01_stage_0.png` through `09_stage_8.png`.
- Active upgrade transition: `docs/vehicle-captures/10_upgrade_transition.png`.
- Tall Android equivalents: `docs/vehicle-captures/tall_android/`.

## Missing layers or technical problems

The approved state panels are flattened opaque illustrations, not a fully separated body/door/wheel/window rig. The runtime adds aligned effect layers and wheel-motion overlays without altering the paintings. True body-panel deformation, a separately articulated painted door, and continuous driving cycles would require separated source layers. No missing layer blocks the current upgrade screen or its saved states.

## Files modified

- `scripts/vehicle/vehicle_visual.gd`
- `scenes/vehicle/vehicle.gd`
- `scenes/vehicle/vehicle.tscn`
- `docs/FINAL_ASSET_MANIFEST.csv`
- `docs/ANIMATION_MANIFEST.csv`
- `docs/VEHICLE_ASSET_MANIFEST.csv`
- `docs/production-batches/11_vehicles.md`
- `tests/README.md`
- `tests/smoke_test_vehicle_presentation.gd`
- `tests/smoke_test_vehicle_presentation.tscn`
- `tests/capture_vehicle_stages.gd`
- `tests/capture_vehicle_stages.tscn`
