# Unified residence and merge home

Date: 2026-08-03

Starting commit: `c15b375`

Branch: `visual-production`

## Objective

Make each residence the persistent merge home: its illustrated environment, repair hotspots, and isolated 7x9 board coexist in one screen. Remove Merge as a player-facing navigation destination without changing board rules, quests, hotspot gating, content IDs, or the version-2 save format.

## Implementation

- Added `scenes/merge_board/board_panel.tscn`, a reusable embedded presentation of the existing `MergeBoard` controller.
- Embedded the panel in Hollow Creek, Redwater, Greybridge, Saint Mercy, and Northgate. Each scene activates its matching `BoardState` residence during `_enter_tree()` so the board is correct before its child UI initializes.
- Kept residence art visible above and through translucent board cells while preserving opaque item readability. Hotspot controls remain above the grid, and unused hotspot-layer space passes pointer input to board cells.
- Task requirements open as an in-place modal. **Find on Board** highlights the requested chain in the embedded board without a scene transition.
- Removed Merge from the four-button bottom navigation and from `SceneRouter`'s public route table. Haven now returns to the profile's current residence.
- Retained the old standalone merge scene only as an internal compatibility/test harness; it has no player-facing route or bottom-navigation entry.
- Corrected the task modal's viewport-bound calculation so it remains centered and fully actionable at 720x1600 after residence layout settles.

## Compatibility

No merge rule, producer behavior, board payload, save key/schema, quest/hotspot gate, item/chain/residence ID, economy value, story result, character/vehicle data, or navigation destination outside the removed redundant Merge tab changed. Each residence continues to use its isolated board from the preceding migration batch.

## Assets and evidence

No generated artwork, rejected artwork, animation, or audio asset was added. Existing approved residence, hotspot, item, and board presentation is recomposed in the unified view.

Real OpenGL 720x1600 captures:

- `docs/ui-skin-captures/unified_home_720x1600.png`
- `docs/ui-skin-captures/unified_home_redwater_720x1600.png`
- `docs/ui-skin-captures/unified_home_greybridge_720x1600.png`
- `docs/ui-skin-captures/unified_home_saint_mercy_720x1600.png`
- `docs/ui-skin-captures/unified_home_northgate_720x1600.png`
- `docs/ui-skin-captures/unified_home_task_720x1600.png`

The captures verify residence-specific backdrops, the complete 7x9 grid, overlaid hotspots, four-tab navigation, and an accessible task modal with Find/Complete/Close controls.

## Verification

- True empty-cache Godot 4.3 import rebuilt 1,722 imported artifacts. The long rebuild exceeded the command wrapper's two-minute capture window but completed normally; an immediate verbose reconciliation import exited 0.
- Full discovered smoke suite: 33/33 pass.
- Android exported-runtime resource contract: pass; both presets retain package/version/ABI and runtime-catalog guarantees.
- Critical log scan: zero parser, missing-resource, invalid-call, audio-catalog, save, import, shader, or texture failure signatures.
- Focused layout checks passed at 720x1600, 1080x2400/default, and 1440x3200.
- Focused navigation assertions verify four tabs, no Merge route, five residence routes, 63 embedded cells per residence, active-board identity, click-through hotspot layering, and in-place task-to-chain highlighting.

## Known issues and next batch

- This batch unifies existing systems; it does not yet add tap-to-cash-out rewards to the nine gameplay chains.
- Android device install/layout capture remains part of the later packaged verification batch. The current captures are desktop OpenGL windows at the target portrait resolution.
- Next: add data-driven, multi-level cash-out rewards to the nine gameplay chains while preventing covered/cobwebbed items from collecting and preserving all task/merge behavior.
