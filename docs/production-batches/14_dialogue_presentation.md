# Batch 14 — Dialogue Presentation

## Scope

Completed the presentation layer for every implemented dialogue sequence while preserving all dialogue IDs, text, branching options, rewards, relationship changes, next-ID links, triggers, and navigation.

## Approved artwork integrated

- Mara Vale, Noah Vance, Lena Ortiz, Riley Chen, Dr Imogen Shaw, and Caleb Rusk use their existing final expression portraits.
- The Signal Keeper uses the illustrated emergency radio relay as an in-world speaker representation; no geometric person placeholder is shown.
- Hollow Creek, Redwater, Greybridge, Saint Mercy, Northgate, and the radio relay use their matching approved environment paintings.
- Narration removes the portrait column entirely rather than reserving an empty placeholder.

No artwork was regenerated or altered in this batch.

## Presentation and animation

- Added real dynamic location captions above the scene artwork.
- Added sequence-specific environment staging.
- Dialogue resources' existing `expression_key` is now the presentation source of truth. Historical `suspicious` and `defensive` labels map to the nearest approved concerned and angry portraits without editing the data.
- Added interruptible scene crossfade/push, portrait entrance, text reveal, and staggered choice reveal.
- Existing idle/speaking/fear/injured portrait animation remains connected.
- All added motion is bypassed by the existing reduced-motion/low-quality setting.
- Existing dialogue music, ambience crossfade, ducking, advance sounds, choice sounds, radio cue, and emotional music hook remain active.

## Files modified

- `scenes/dialogue/dialogue.gd`
- `scenes/dialogue/dialogue.tscn`
- `scripts/ui/survivor_silhouette.gd`
- `tests/README.md`

## Verification

- `SMOKE_DIALOGUE_PRESENTATION_OK speakers=7 backgrounds=7 geometric_fallback=0 reduced_motion=1 reveal_animation=1`
- `SMOKE_MAIN_STORY_TEST_OK` confirms the complete Signal Keeper sequence, branch and persistence remain unchanged.
- `SMOKE_TEST_OK` across all major scenes.
- Three representative 1080×2400 Android-reference captures cover narration, survivor speech, and the non-character radio speaker.

## Remaining presentation work

- Defence presentation is next.
- Remaining UI/effects and audio completion follow.
- Android optimisation and final multi-branch consolidation remain reserved for the APK stage.
