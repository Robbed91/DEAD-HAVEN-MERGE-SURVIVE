# Production Batch 05 — Saint Mercy Hospital

Date: 31 July 2026

## Result

Saint Mercy Hospital now uses an original locked painterly night environment in
place of its flat procedural building. All eight existing repair areas retain
their IDs and coordinates; accepted tasks reveal aligned painted repairs.
Progression, quests, Imogen's rescue, defence results, economy, navigation and
save schema are unchanged.

## Assets created

- Destroyed and upgraded masters under `assets/art/saint_mercy/source/`.
- Six 720×1080 runtime states under `assets/art/saint_mercy/runtime/`.
- Twelve environment layers under `assets/art/saint_mercy/layers/`.
- Eight repair overlays under `assets/art/saint_mercy/repair_overlays/` for ER
  reception, pharmacy, patient ward, surgical suite, power room, ambulance bay,
  records office and isolation ward.

The built-in image-generation tool produced the two masters. Prompt set:
original abandoned British community hospital at storm-blue night, locked
elevated three-quarter camera, painterly mobile-readable stylised realism and
the approved charcoal/teal/amber hierarchy. The identity-preserving upgrade
edit locked architecture, crop, car park, ambulance canopy, generator compound,
rooftop isolation ward and scale while restricting changes to repairs and
lighting. It prohibited UI, text, logos, watermark, emoji, gore, primitive
geometry and copied media content. Deterministic local processing generated the
aligned states/layers/overlays.

## Files modified

- `scenes/saint_mercy/saint_mercy_background.gd`
- `scenes/saint_mercy/saint_mercy.gd`
- `tools/build_redwater_assets.ps1`
- `tests/capture_saint_mercy_states.gd` / `.tscn`
- `tests/smoke_test_saint_mercy_visual_states.gd` / `.tscn`
- `tests/README.md`
- Asset and capture paths listed above.

## Animation added

Cloud drift, vegetation/foreground wind, rain, dust, restored-light flicker,
distant Drifter wandering, Imogen injury-treatment idle, task-position repair
particles and aligned overlay installation transitions. Existing reduced-motion
and graphics-quality gates remain authoritative.

## Audio added

Existing Saint Mercy safe-residence/electrical ambience remains routed by the
audio manager. Power completion uses the generator cue; pharmacy/surgery use
the medical-material cue; other repairs use fastening/repair/reward cues.

## Verification

- Godot import and all-screen instantiation passed without parse or missing-
  resource errors.
- Saint Mercy progression/rescue/defence smoke test passed.
- New six-threshold visual save/reload smoke test passed.
- Global save, animation and 250-asset audio tests passed.
- Actual OpenGL Compatibility captures:
  `docs/saint_mercy-captures/01_destroyed.png` through
  `docs/saint_mercy-captures/06_fully_upgraded.png`.

## Remaining placeholders

None in Saint Mercy's environment or repair-state artwork. Shared interactive
hotspot controls remain scheduled for the later global UI/placeholder cleanup
after every residence is verified.
