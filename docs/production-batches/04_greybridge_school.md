# Production Batch 04 — Greybridge School

Date: 31 July 2026

## Result

Greybridge School now uses an original locked painterly 2.5D environment in
place of the flat procedural brick building. All eight existing repair areas
remain at their original coordinates and every accepted task reveals an aligned
painted repair layer. No residence, task, quest, survivor, defence, navigation,
economy or save identifier changed.

## Assets created

- `assets/art/greybridge/source/greybridge_master_destroyed.png`
- `assets/art/greybridge/source/greybridge_master_upgraded.png`
- Six aligned 720×1080 runtime states under `assets/art/greybridge/runtime/`.
- Twelve separated environment layers under `assets/art/greybridge/layers/`.
- Eight aligned repair overlays under `assets/art/greybridge/repair_overlays/`:
  main hall, gymnasium, library, cafeteria, boiler room, admin office,
  playground fence and radio tower.

The two masters were created with the built-in image-generation tool. Prompt
set: original abandoned British secondary-school safe haven, elevated locked
three-quarter camera, storm blue-grey/amber Dead Haven palette, mobile-readable
painterly stylised realism, with an identity-preserving repair edit for the
fully upgraded master. The edit explicitly locked camera, crop, architecture,
playground geometry, tree line and object scale; it prohibited UI, text, logos,
watermarks, primitive geometry and copied media content. Deterministic local
processing in `tools/build_redwater_assets.ps1 -Residence greybridge` produced
the aligned intermediate states, layers and hotspot differences.

## Files modified

- `scenes/greybridge/greybridge_background.gd`
- `scenes/greybridge/greybridge.gd`
- `tools/build_redwater_assets.ps1`
- `tests/capture_greybridge_states.gd` / `.tscn`
- `tests/smoke_test_greybridge_visual_states.gd` / `.tscn`
- `tests/README.md`
- Asset and capture paths listed above.

## Animation added

Moving cloud layer, vegetation/foreground wind, rain, dust, warm-light flicker,
distant Drifter wandering, Riley radio idle, per-hotspot repair reveal,
installation flash and task-position repair particles. Effects respect the
existing reduced-motion/graphics-quality gate.

## Audio added

Existing wind/safe-residence routing remains active. Repairs now trigger
material fastening and repair cues; boiler completion uses the generator cue;
radio-tower completion uses the radio pulse. Character/Hollow cues remain on
their existing buses. No gameplay result depends on audio.

## Verification

- Godot 4.3 import completed and the all-screen smoke test was scanned for
  script, parse and resource-loader errors.
- `tests/smoke_test_greybridge.tscn` — passed progression, Riley, defence and
  save/reload assertions.
- `tests/smoke_test_greybridge_visual_states.tscn` — passed all six state/save
  thresholds.
- Animation, audio and global save smoke tests passed.
- Actual OpenGL Compatibility gameplay captures for all states:
  `docs/greybridge-captures/01_destroyed.png` through
  `docs/greybridge-captures/06_fully_upgraded.png`.

## Remaining placeholders

None in Greybridge's environment composition or repair-state artwork. The
shared hotspot controls remain interactive UI overlays and will receive their
final global cleanup in the remaining-UI/obsolete-placeholder batches after all
residences are visually verified.
