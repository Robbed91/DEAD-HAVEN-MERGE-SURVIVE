# Batch 15 — Defence Presentation

## Scope

Completed the shared defence screen's visual and audio presentation without changing event IDs, residence gates, energy costs, skill bonuses, success chances, choice text, rewards, damage rules, progression, or save data.

## Approved artwork integrated

- Each of the five implemented defence events uses its matching defended residence painting.
- Leader selection uses the existing final determined portrait for every unlocked survivor.
- The selected survivor uses the shared final layered character rig.
- The implemented Drifter Hollow uses its final layered enemy rig and approved action states.
- Existing soft particle artwork supplies restrained impact and reward debris.

No new raster artwork was generated in this batch.

## Presentation and animation

- Preparation: illustrated leader cards, live energy cost, survivor idle, distant Drifter threat.
- Encounter: existing launch result reveals the unchanged choices, triggers leader defensive action, Drifter detection, restrained camera shake, and impact particles.
- Outcome: the existing resolved boolean alone selects survivor celebration/Drifter collapse or survivor injured idle/Drifter barricade attack.
- Buttons retain real dynamic text and the established destinations.
- Motion is skipped or reduced through the existing effects setting and stops when the screen leaves the tree.

## Audio retained and connected

- Defence preparation and defence music loops.
- Distant Hollow ambience.
- Defence warning, barricade impacts, Drifter detect/attack/collapse cues, defence success/failure, and victory/tension stings.
- Existing audio buses, concurrency, pitch variation and fades remain unchanged.

## Verification

- `SMOKE_DEFENCE_PRESENTATION_OK events=5 leaders=5 drifter=5 encounter_animation=1 gameplay_mutations=0`
- `SMOKE_DEFENCE_TEST_OK` verifies gating, energy, failure damage, retry, success progression, and save reload.
- Three running-game Android-reference captures cover preparation, encounter, and successful resolution.

## Remaining presentation work

- Remaining UI and effects audit/completion.
- Remaining music/audio audit/completion.
- Android optimisation, obsolete-placeholder removal, multi-branch consolidation, and final APK validation.
