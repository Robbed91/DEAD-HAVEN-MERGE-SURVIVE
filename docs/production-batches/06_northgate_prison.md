# Production Batch 06 — Northgate Prison

Date: 31 July 2026

## Result

Northgate Prison now uses a locked painterly pre-dawn fortress environment in
place of the geometric prison placeholder. The eight existing hotspot IDs and
coordinates remain authoritative and reveal aligned repair artwork only after
their existing tasks complete. Caleb, defence, quests, progression, economy,
navigation and save data remain unchanged.

## Assets created

- Destroyed/upgraded masters under `assets/art/northgate/source/`.
- Six 720×1080 runtime states under `assets/art/northgate/runtime/`.
- Twelve separated layers under `assets/art/northgate/layers/`.
- Eight aligned repair overlays under `assets/art/northgate/repair_overlays/`
  for sally port, guard tower, armory, mess hall, Cell Block A, control room,
  transport bay and warden office.

The built-in image-generation tool created the masters. Prompt set: original
decommissioned British county-prison safe haven, locked elevated three-quarter
camera, cold pre-dawn storm palette, painterly mobile-readable stylised realism,
with an identity-preserving repaired-state edit. Camera, crop, cell blocks,
yard, walls, tower, transport bay, sally port, tree line and scale were locked;
UI, text, logos, watermark, emoji, gore, primitive geometry and copied content
were prohibited. Deterministic local processing created aligned states/layers.

## Files modified

- `scenes/northgate/northgate_background.gd`
- `scenes/northgate/northgate.gd`
- `tools/build_redwater_assets.ps1`
- `tests/capture_northgate_states.gd` / `.tscn`
- `tests/smoke_test_northgate_visual_states.gd` / `.tscn`
- `tests/README.md`
- Asset and capture paths listed above.

## Animation added

Cloud drift, perimeter vegetation wind, rain, yard dust, lamp flicker, distant
Drifter wandering, Caleb defensive idle, repair-position particles and aligned
installation transitions. Existing reduced-motion and quality gates apply.

## Audio added

Existing Northgate safe-residence/road ambience remains active. Sally-port work
uses fence repair, guard tower/armory use trap deployment, other repairs use
metal/repair/reward cues, all on existing buses.

## Verification

- Godot import and scanned all-screen instantiation passed.
- Northgate progression, Caleb, defence and save/reload smoke test passed.
- Six-threshold visual save/reload test passed.
- Global save, animation and complete-audio tests passed.
- Actual OpenGL Compatibility gameplay captures:
  `docs/northgate-captures/01_destroyed.png` through
  `docs/northgate-captures/06_fully_upgraded.png`.

## Remaining placeholders

None in Northgate's environment or repair-state art. The shared interactive
hotspot control skin remains scheduled for the later UI/obsolete-placeholder
cleanup after all screens using it are verified.
