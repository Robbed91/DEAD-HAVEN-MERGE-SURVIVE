# Hollow Creek Farmhouse — Final Visual Vertical Slice

## Scope lock

This slice changes presentation only. It does not alter quest IDs, residence or hotspot IDs, requirements, merge outcomes, board dimensions, save payloads, navigation destinations, progression, balancing, or economy.

## Residence presentation states

| Visual state | Existing completed-hotspot count | Runtime illustration |
|---|---:|---|
| Destroyed | 0 | `hollow_creek_state_01_destroyed.png` |
| Temporarily secured | 1–2 | `hollow_creek_state_02_secured.png` |
| Habitable | 3–4 | `hollow_creek_state_03_habitable.png` |
| Defended | 5–7 | `hollow_creek_state_04_defended.png` |
| Fully upgraded | 8–9 | `hollow_creek_state_05_upgraded.png` |

The presentation derives its state from the existing `ResidenceManager` hotspot states. No new progression state is stored.

Every completed repair also replaces its live hotspot pulse with a painted, chain-specific repair marker. Major completion thresholds crossfade the whole illustrated environment, while fireplace, Noah, lighting, smoke, and defence visuals respond to their existing events.

## Layer package

The runtime and source package under `assets/art/hollow_creek/environments/` contains separate deliverables for:

- Sky and clouds.
- Distant landscape.
- Trees.
- Barn.
- Main farmhouse.
- Roof.
- Windows.
- Doors.
- Porch.
- Fence.
- Garden.
- Ground.
- Debris.
- Repair overlays.
- Character and Hollow planes.
- Foreground vegetation.
- Lighting.
- Weather.
- Particles.

Five 720 × 1116 runtime composites provide deterministic low-draw-call Android state switching. Separate layers drive ambient animation and remain available for later device-tier tuning.

## Final characters and enemy

- Mara Vale full-body and portrait artwork.
- Noah Vance full-body and portrait artwork.
- One Drifter Hollow full-body sprite.

The Haven uses small full-body scene sprites with independent idle cycles. Dialogue uses final portrait textures; the remaining cast continues to use the existing fallback until its own approved slice.

## Merge-board slice

- All eight existing `construction_1`–`construction_8` item paths now resolve to painted transparent artwork.
- The existing `construction_producer` path resolves to the Salvaged Tool Crate.
- Selected, active, cooldown, exhausted, and reward crate treatments are included.
- Existing BoardState merge, producer, energy, cooldown, drag, storage, and discovery logic is unchanged.
- Other merge chains retain their fallbacks until a later approved slice.

## Animation and VFX

- Moving cloud overlay.
- Wind movement on foreground grass and foliage.
- Hanging lantern sway and flicker.
- Interior-light flicker.
- Dust motes and storm weather particles.
- Chimney smoke after the existing fireplace repair.
- Mara and Noah idle movement.
- Distant Drifter walk loop.
- Unrepaired hotspot pulse.
- Five-state environment crossfade.
- Ten-frame window-boarding sequence with hammer impacts.

Reduced-motion and low-effects settings continue to use the existing `GameManager.effects_enabled()` gate where the prior presentation already used it.

## Audio treatment

| Cue | File/use |
|---|---|
| Hollow Creek residence music | `assets/audio/music/hollow_creek_residence_loop.wav` |
| Hollow Creek storm ambience | `assets/audio/ambience/hollow_creek_storm_loop.wav` |
| UI tap | All live buttons via AudioManager presentation hook |
| Merge / invalid merge | Existing merge events |
| Tool Crate | Existing producer event |
| Discovery | Existing discovery event |
| Repair completion | Existing task completion plus repair accent |
| Window hammer | Boarding animation frames 3, 5, and 7 |
| Dialogue radio | Hollow Creek intro dialogue presentation |
| Lantern / wood | Environmental cue library |

All cues use the existing Music and SFX buses and honour current volume settings.

## Original environment prompt set

The three missing progression states were produced with the built-in image-generation workflow as controlled edits of the approved Stage 2 Hollow Creek source. Each prompt locked the camera, farmhouse, barn, path, wheelbarrow, storm framing, and major silhouettes, then changed only the visible repair progression:

1. **Habitable:** safe porch, functional door, roof patches, firewood, supply crates, first amber interior light, first chimney smoke.
2. **Defended:** cross-braced windows, repaired perimeter, gate, warning stakes, lookout, strengthened barn, increased occupied light.
3. **Fully upgraded:** completed reclaimed roof and porch repairs, iron door reinforcement, organised supplies, rain barrels, finished perimeter, strongest controlled haven light.

Every prompt required original painterly 2.5D stylised realism and prohibited people, text, logos, watermarks, copied elements, excessive gore, geometry changes, camera movement, pristine renovation, or sunny lighting.

## Running captures

- `docs/vertical-slice-captures/hollow_creek_final_running.png`
- `docs/vertical-slice-captures/merge_board_final_running.png`
- `docs/vertical-slice-captures/task_panel_final_running.png`
- `docs/vertical-slice-captures/dialogue_final_running.png`
- `docs/vertical-slice-captures/hollow_creek_ambient_and_repair.avi`

The capture scenes under `tests/` mutate only in-memory preview state and never invoke quest completion, progression rewards, economy changes, or save methods.
