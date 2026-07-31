# Batch 07 — Northgate Hotspot Approval Gate

## Scope

Northgate Prison only. Replaced its eight procedural task pictograms with unique illustrated physical repair objects. No quest, requirement, residence, economy, defence, dialogue, navigation, or save-data identifiers changed.

## Assets created

- Eight 1024 × 1024 transparent source illustrations under `assets/ui/repair_hotspots/northgate/source/`.
- Eight 256 × 256 transparent runtime illustrations under `assets/ui/repair_hotspots/northgate/runtime/`.
- Objects: sally-port gate, guard-platform/ladder, armory locker, mess table/supply station, cell-block bunk kit, security control console, fuel-transfer kit, and office barricade.
- Origin: original renders generated for this project with the documented Dead Haven object-art prompt; no external stock, game, television, or photographic assets were used.

## Integration and animation

- `HotspotVisual` selects the illustrated path only for Northgate; verified missing paths still retain the old fallback for later residences until their own replacements are approved.
- Available, selected, locked, completed, and insufficient-material states retain the physical object.
- Added dynamic owned/required count, restrained radial backing, independent lock/tick status badge, selected rim/scale, 1–2 px idle float, slow availability pulse, unlock light sweep, smooth tint transitions, and existing completion reward burst.
- Processing remains visibility-gated and respects the existing reduced-motion setting.

## Files modified

- `scripts/residence/hotspot_visual.gd`
- `scenes/northgate/northgate.gd`
- `tests/capture_northgate_states.gd`
- Northgate capture PNGs and the two new manifest CSVs.

## Verification

- `SMOKE_NORTHGATE_HOTSPOT_ICONS_OK icons=8 source=1024 runtime=256 fallback=0`
- `SMOKE_NORTHGATE_TEST_OK`
- `SMOKE_NORTHGATE_VISUAL_STATES_OK states=6`
- Save/reload retains each tested repair threshold and defence state.
- Real OpenGL captures: `docs/northgate-captures/01_destroyed.png` through `06_fully_upgraded.png`, plus `07_selected_control_room.png`.

## Remaining placeholders

Procedural fallback branches for other residences remain intentionally present and untouched. They must not be deleted until each later residence has a verified illustrated set.
