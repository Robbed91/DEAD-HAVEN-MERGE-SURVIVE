# Production Batch 03 — Redwater Service Station

Date: 31 July 2026

## Result

Approved and verified complete against the Hollow Creek vertical-slice standard.
The existing Redwater implementation was retained because it already uses a
locked painterly composition, visible repair progression, reusable motion,
residence-specific ambience and final UI framing.

## Assets recorded

- Six 720×1116 runtime compositions under `assets/art/redwater/runtime/`:
  destroyed, cleared, temporarily repaired, habitable, defended and fully
  upgraded.
- Twelve separated environment layers under `assets/art/redwater/layers/`.
- Eight aligned task-specific overlays under
  `assets/art/redwater/repair_overlays/`.
- Retained source compositions under `assets/art/redwater/source/`.

## Files modified in this batch

- `docs/production-batches/03_redwater_service_station.md`

No runtime file required modification; existing IDs, quests, requirements,
defence logic, navigation, economy and saves remain untouched.

## Animation recorded

Cloud/weather drift, vegetation movement, dust, lighting flicker, repair focus,
installation crossfade, task particles and reward return remain integrated in
`scenes/redwater/redwater_background.gd` and the shared animation layer.

## Audio recorded

Redwater station ambience, repair whoosh, task completion, generator, fence and
metal-fastening cues remain connected to existing accepted task events. Audio
buses and gameplay results are unchanged.

## Verification

- `tests/smoke_test_redwater.tscn` — passed, including Lena rescue, defence
  isolation and save/reload.
- `tests/smoke_test_redwater_visual_states.tscn` — passed for all six visual
  thresholds and defence milestone round trips.
- `tests/smoke_test_save.tscn`, `smoke_test_animation_layer.tscn` and
  `smoke_test_audio_presentation.tscn` — passed.
- Running screenshots for all six states:
  `docs/redwater-captures/01_destroyed.png` through
  `docs/redwater-captures/06_fully_upgraded.png`.
- Repair video: `docs/redwater-captures/redwater_repair_animation.avi`.

## Remaining placeholders

None in the Redwater master environment, state progression or repair overlays.
The shared hotspot script still contains procedural art for residences that have
not yet received final overlays; Redwater's implemented repair layers visually
replace those areas in its completed states and that shared fallback is not
deleted until the later residences have been verified.
