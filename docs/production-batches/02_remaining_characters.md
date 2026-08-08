# Production Batch 02 — Remaining Characters

Date: 31 July 2026

## Result

All six implemented survivors and the implemented Drifter Hollow meet the
approved Hollow Creek character standard. This batch makes every survivor
portrait explicitly data-driven without changing survivor IDs, statistics,
skills, relationships, recruitment, dialogue or save data.

## Assets recorded

- Mara Vale, Noah Vance, Lena Ortiz, Dr Imogen Shaw, Riley Chen and Caleb Rusk:
  eight 512×512 expression portraits, six full-body pose/outfit composites and
  eight separated rig layers each under `assets/art/characters/<id>/`.
- Drifter Hollow: twelve state/pose images and eight rig layers under
  `assets/art/enemies/drifter_hollow/`.
- Source and authorship details: `docs/CHARACTER_VISUAL_PRODUCTION.md`.

## Files modified

- `data/characters/mara_vale.tres`
- `data/characters/noah_vance.tres`
- `data/characters/lena_ortiz.tres`
- `data/characters/imogen_shaw.tres`
- `data/characters/riley_chen.tres`
- `data/characters/caleb_rusk.tres`
- `tests/smoke_test_character_portraits.gd`
- `tests/README.md`
- `docs/production-batches/02_remaining_characters.md`

## Animation recorded

The shared layered rig retains idle breathing, blink, looking, speaking,
walking, running, carrying, hammering, sawing, searching, radio, injury
treatment, vehicle entry, celebration, fear, injured idle and defensive action.
The Drifter retains idle sway, slow walk, detection, barricade attack, hit/trap
reaction, collapse and distant wandering.

## Audio recorded

Existing character footsteps, tool handling, radio and Hollow cues remain
routed through Characters and Threats buses. No audio files changed.

## Verification

- `tests/smoke_test_character_portraits.tscn` validates 48 registered portrait
  paths and runtime texture selection, plus safe missing-asset behaviour.
- `tests/smoke_test_vehicle_survivors.tscn` validates survivor data/progression
  and save/reload compatibility.
- `tests/smoke_test_dialogue.tscn` validates dialogue logic remains unchanged.
- Running roster screenshot: `docs/character-captures/survivor_roster_final.png`.
- Running dialogue screenshot: `docs/character-captures/mara_dialogue_final.png`.

## Remaining placeholders

No implemented character uses geometric artwork in normal gameplay. The legacy
class name and its procedural emergency fallback remain temporarily until the
final obsolete-placeholder removal batch; the expanded test proves all current
survivors bypass it.
