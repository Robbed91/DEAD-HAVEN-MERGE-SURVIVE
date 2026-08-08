# Progression gating fixes

Date: 2026-08-01

Starting commit: `72fae9b`

Branch: `visual-production`

## Objective

Fix the two confirmed independent gating defects before restructuring the residence and merge screens: locked residence hotspots must not open, and the nine chain producers must activate progressively without breaking existing board saves.

## Hotspot tap and padlock findings

- `HotspotVisual._gui_input()` had emitted `tapped` for every left press since `e90730b`, without consulting `_is_locked()`.
- The small padlock is not present in the final Hollow Creek PNGs. It is drawn by `HotspotVisual._draw_illustrated_marker()` when `_is_locked()` is true; that procedural badge path entered in `ef661a1`.
- The uploaded v2 APK was assembled from a working tree based on `781c27c`; its runtime files were later committed in `72fae9b`, but it was not built from a clean checkout of that commit.
- All five residence definitions currently contain 41 hotspot-to-quest links. Runtime validation now rejects empty links, missing quests, and mismatched quest hotspot IDs, and prints the packed-build link total so a future Android capture can distinguish missing packed data from a rendering defect.

Locked presses now consume the input, play error feedback, and emit no hotspot tap. Available presses retain their existing signal and task-panel behavior.

## Producer progression

All nine established producer instances remain at their saved positions. Their existing `BoardItem.is_locked` field is reconciled from current quest, vehicle, and story progress after new-game reset and after every save load; no save key, item ID, charge, cooldown, or board position was added or replaced.

Activation order:

1. Construction — available from the start.
2. Tools — Secure the Front Door.
3. Food — Clear the Living Room.
4. Medical — Repair the Food Pantry.
5. Traps — Rescue Noah.
6. Vehicle Parts — discover the delivery van.
7. Fuel and Electronics — unlock Redwater.
8. Clothing — unlock Greybridge.

`BoardState.tap_producer()` enforces the derived rule independently and returns `producer_locked` without spending energy. Task panels identify the milestone for a requirement whose producer is still locked.

## Compatibility

- Merge rules, producer outputs, charges, cooldowns, energy cost, quest requirements, hotspot gating data, story flags, IDs, and save schema are unchanged.
- Legacy saves retain every producer object and are reconciled only to active/locked presentation and interaction state.
- Existing hotspot completion and reversal behavior is unchanged.

## Verification

- Headless import: pass.
- Focused hotspot test: all nine final Hollow Creek icons pass; locked press emits zero taps and available press emits exactly one.
- Focused merge test: 11 starting items retained, producer activation advances from 1 to 9, locked activation spends no energy, and save/reload retains board contents.
- Android export resource test: 41 hotspot links, zero link errors, both Android presets and all catalog counts pass.
- Full smoke suite: 33/33 pass.

## Remaining verification

The previous installed APK will continue to show its previously packaged behavior. The next Android build must confirm `hotspot_links=41 link_errors=0` in device logs and visually recheck Hollow Creek marker locks.

## Next batch

Extract the merge board into a reusable panel, place it in all five residence scenes, remove Merge navigation, and keep task-to-board highlighting local to the unified Home screen.
