# Development log

This is the authoritative phase-by-phase record for Dead Haven: Merge &
Survive, per the project's working rules: work incrementally, keep the
project runnable after every phase, and report honestly at the end of
each one.

---

## 2026-08-05 — Scavenging becomes a merge challenge

### Starting commit and objective

- Starting commit: `47e0024` on `visual-production`.
- Objective: the user's follow-up to the hotspot-strip fix was specific and structural, not another bug report: scavenging currently has "no relation to the game" - launching a mission just rolls a dice-based encounter choice, with no merge gameplay involved at all - and per the user's own words, the correct design is "when you go scavenge a location you should need to complete a merge game to successfully progress." This is a real feature, not a fix, so it's documented with its own design rationale rather than folded into the bug-fix entries above.

### Design: reuse every existing authored balance value, change only how the outcome is determined

- Scavenging missions already have rich per-location content (`loot_table`, `encounter_choices` each with `success_chance`/`success_loot`/`failure_penalty`/`success_text`/`failure_text`) across all ten locations. Rewriting that content was explicitly out of scope - the goal was to change *how success is decided* (a merge puzzle instead of `randf() < chance`) while keeping every location's authored numbers and text meaningful.
- New `scripts/scavenge_merge/`: `ScavengeMergeState` (a `RefCounted` grid, `Vector2i -> item_id`), `ScavengeTileView` (a stripped-down sibling of `scripts/merge/item_view.gd` - drag-and-drop only, no producer/cooldown/lock/cobweb presentation it has no use for), `ScavengeCell` (a stripped-down sibling of `scenes/merge_board/board_cell.gd`). Deliberately **not** built on `BoardState`/`BoardItem` - that singleton owns the player's real, saved residence boards, and a scavenging attempt needs a throwaway grid that's generated fresh and discarded on win/lose/retreat with zero save-schema footprint.
- `ScavengeMergeState.try_merge()` uses the identical chain+level rule as `BoardState.try_merge()` (verified against it directly in the new test, not just self-consistently), just without any of the producer/lock/cobweb/storage checks that rule also has to make, since none of those concepts exist on this board.
- Board seeding guarantees solvability: `_seed_board()` always places at least `2^(target_level-1)` level-1 tiles of the mission's primary chain (enough to reach target_level through repeated pairwise merges alone), plus secondary-chain tiles as real, mergeable alternative material - not decoration.
- The chosen encounter approach's own `success_chance` (plus the existing survivor skill-match bonus from `_survivor_has_matching_skill()`) now sets the merge challenge's **difficulty** - `ScavengingManager.compute_challenge_params()` maps a higher chance to more moves (a generous approach was already meant to be the safer one; now that safety is expressed as "more room to work the puzzle" instead of "better dice odds"). `chain_ids_for_mission()` is deterministic per `mission_id` (hashed, not random) so the same location always salvages the same two material types on repeat visits - a small thing, but it's part of what "the map has no relation to the game" was pointing at: the loot at a location should feel like it comes from that location.
- `ScavengingManager.resolve_choice()` (the old dice-roll path) was refactored to share its reward/penalty/text logic with a new `resolve_choice_with_outcome(mission_id, choice_index, succeeded)` via a common `_apply_choice_outcome()`. `resolve_choice()` itself is unchanged in behavior and signature - existing tests that force outcomes by mutating `success_chance` to 0.0/1.0 and calling it still work exactly as before, untouched. `resolve_choice_with_outcome()` is what the real UI calls now, fed a `succeeded` boolean earned by actually winning or losing the merge puzzle instead of computing one internally.
- `scenes/scavenging/scavenging.gd`/`.tscn`: new `MergeChallengePanel` (label showing target level/moves remaining, a 5x5 `GridContainer` of `ScavengeCell`s, a Retreat button to concede early) slotted between the existing `EncounterPanel` and `OutcomePanel`. Picking an encounter choice now opens this panel instead of resolving instantly; winning or losing it (or hitting Retreat, which counts as a loss) calls `resolve_choice_with_outcome()` and proceeds into the same outcome presentation as before.

### Tests performed

- New `tests/smoke_test_scavenge_merge.gd`/`.tscn`: seeded-board solvability, `try_merge()` parity with `BoardState`'s rule (including that it refuses to merge against an empty cell and spends exactly one move per successful merge), win-on-target-level and lose-on-moves-exhausted, difficulty scaling with `success_chance`, and that `resolve_choice_with_outcome()` grants byte-for-byte the same rewards/penalty/text as `resolve_choice()` for a known outcome (checked against real mission data, not a mock).
- New `tests/capture_scavenge_merge.gd`/`.tscn`: drives the real `scavenging.tscn` scene (not just the isolated state class) through send -> pick a choice, and captures the actual merge grid it opens into - confirms the wiring works end to end, not only in isolated logic tests.
- Full regression pass: `smoke_test` (all residences/scenes including scavenging still instantiate cleanly), `smoke_test_scavenging` (all pre-existing dice-based assertions pass unchanged - `resolve_choice()`'s public behavior is untouched), `smoke_test_scavenging_presentation`, `smoke_test_vehicle_survivors` (its own skill-matching-bonus assertion against `resolve_choice()` also unaffected), `smoke_test_main_story`, `smoke_test_save` - all pass.

### Known issues and exact next phase

- Desktop-verified only; needs a fresh APK to confirm the drag-and-drop feel of the new compact grid on a real touchscreen.
- The merge-challenge grid currently has no hover/drop visual feedback (`board_cell.gd`'s pulse-on-valid-drop presentation wasn't ported) and no merge burst VFX - functionally complete, visually plainer than the main board. Worth a follow-up pass once the core mechanic itself is confirmed to be what the user wanted.
- `target_level` (3) and the moves-per-`success_chance` curve (4-8 moves) are first-pass numbers, not playtested for real difficulty feel - likely to need tuning once played on a real device rather than verified only for internal consistency.
- This is a new gameplay system, not a bug fix - it should be treated as a first draft to react to, not a finished feature, given how much of this whole thread has been about matching a specific vision the user has and I don't have full visibility into.

---

## 2026-08-05 — Follow-up: repair tasks off the board grid entirely

### Starting commit and objective

- Starting commit: `8e33e64` on `visual-production` (the merge of this same day's real-device bug-fix batch below and Codex's Android import-optimisation batch).
- Objective: the user's reply to the previous entry's fixes was that the game "still" isn't close to what they asked for in a merge game, referencing Merge Mansion again. An `AskUserQuestion` asking whether to make the board fully clean/opaque (moving repair tasks into their own panel, closer to the reference games) versus keeping the current translucent room-behind-the-grid look was interrupted/declined by the user rather than answered. Rather than re-ask (already declined once) or leave it unresolved, proceeded on the better-evidenced option: real merge games never place task/request icons on top of the merge grid itself, and the corner-badge fix from the previous entry - while it stopped hotspots from fully blocking items - still had them sitting on the grid, which was never how the reference games do it.

### Change: hotspot markers move into a dedicated task strip above the board

- Previously `HotspotVisual` markers (even after the previous entry's 40x40 corner-badge shrink) were still absolutely positioned on top of specific board cells via `hotspot.area_position`, still visually and functionally part of the grid. Moved them into a new horizontal `ScrollContainer` strip (`HotspotStrip`, styled like the existing `HeaderPlate`/`CharcoalPanel` chrome) sitting between the residence name/chapter/progress header and the embedded board panel, mirroring the merge board's own `ChainLegend` scroll-strip pattern already used one screen below it. Applied identically across all five residence scenes/controllers (`scenes/haven`, `scenes/northgate`, `scenes/redwater`, `scenes/greybridge`, `scenes/saint_mercy`).
- `_build_hotspot()` in each residence controller no longer does any anchor/offset math against `hotspot.area_position` - it just adds the `HotspotVisual` as a normal child of the strip's `HBoxContainer`, which lays them out automatically. `HOTSPOT_SIZE` changed from a 40x40 corner badge to a 48x48 strip icon (matching `ChainLegendIcon`'s own 48x48). `HOTSPOT_CORNER_BIAS` is gone entirely - there's no longer a "corner" to bias toward.
- `hotspot.area_position` itself is untouched in the data and is still used for the repair camera-focus zoom effect (`_play_repair_camera_sequence()`), which pans/zooms the residence art behind the header on task completion - that effect is about the residence artwork, not the board, so it's unaffected by where the task badge itself now lives.
- Net effect: the embedded board is now completely clean - every cell shows only its own merge item, nothing else drawn or positioned on top of it - while repair/decoration requests read as a proper task list, tap-to-open exactly as before.

### Tests performed

- `tests/smoke_test.gd`'s per-residence embedded-board check previously asserted `Layout/Scene/Hotspots` existed directly under the scene root with `mouse_filter == MOUSE_FILTER_IGNORE` (a pass-through check that only made sense for the old full-screen overlay architecture). Updated to resolve `%Hotspots` (now nested inside the strip) and assert the strip's own rect ends above the board panel's top edge instead - the actual invariant this change is meant to guarantee. Caught and fixed before considering this done, not after a false pass.
- Full suite re-run: `smoke_test` (all 5 residences instantiate and pass the updated embedded-board check), `smoke_test_residence`, `smoke_test_redwater(_visual_states)`, `smoke_test_greybridge(_visual_states)`, `smoke_test_saint_mercy(_visual_states)`, `smoke_test_northgate(_visual_states)`, `smoke_test_hollow_creek_hotspot_icons`, `smoke_test_remaining_hotspot_icons`, `smoke_test_northgate_hotspot_icons`, `smoke_test_merge`, `smoke_test_merge_icons`, `smoke_test_save`, `smoke_test_settings`, `smoke_test_ui_skin`, `smoke_test_main_menu_presentation` - all pass.
- Visual verification: `tests/capture_layout_haven.gd` re-run at 1080x2340 and a one-off equivalent capture of Redwater (built, checked, then deleted - not kept as a permanent test since `capture_layout_haven.gd` already covers the pattern) both show a fully clean 7x9 board with the repair strip as a separate row above it, at the user's own screenshot resolution.

### Known issues and exact next phase

- Still desktop-verified only; needs a fresh APK on the user's device to confirm.
- Next: get the user's reaction to this build before considering the "merge is nothing like Merge Mansion" thread resolved - if the remaining gap isn't the board clutter, it needs a more specific description (e.g. producer/chain pacing, chest mechanics, animation feel) since the two concrete, evidenced issues found so far (hotspot/board overlap, dialog overflow) are now both addressed.

---

## 2026-08-05 — Real-device bug fixes: hotspot/board overlap, dialog overflow

### Starting commit and objective

- Starting commit: `b138e83` on `visual-production` (`67868a6`, the Android import optimisation batch immediately below, landed independently from the same base and is merged alongside this entry).
- Objective: the user installed a build on their own Android phone and reported it as broadly broken - drag-and-drop merging unreliable, most board icons "blacked out" and unclickable, a light touch popping an info panel instead of dragging, and the New Game confirmation dialog's text and OK button running off the right edge of the screen. All of this was reported with real device screenshots, not a description. Prior sessions' desktop `xvfb-run` captures use synthetic mouse input and can't reproduce touch-specific or real-screen-bounds issues, so this required re-reading the actual runtime scene composition against the screenshots rather than re-trusting earlier desktop-only verification.

### Root cause 1: repair hotspot markers sized and layered to fully cover board cells

- `HotspotVisual` markers were sized 76x76 (Hollow Creek Farmhouse, Northgate) or 64x64 (Redwater, Greybridge, Saint Mercy) - matching or nearly matching `BoardCell`'s 78x78 - and centered exactly on their `hotspot.area_position` point, with `mouse_filter = MOUSE_FILTER_STOP`. This was deliberate when hotspots were the only thing on the residence screen (Phase 3), and the 2026-08-03 unified-screen batch's own log correctly predicted "hotspots coexist above the cells" - but never revisited the marker's actual footprint once a full 7x9 board sat directly underneath it. Every hotspot whose `area_position` landed on a board cell fully painted over that cell (`_draw_illustrated_marker`'s dark radial backing) and fully absorbed its input: taps opened the hotspot's own task panel or a "not available yet" toast instead of the item beneath, and merge drops targeting that cell landed on the hotspot control (which implements no `_can_drop_data`/`_drop_data`) and silently did nothing. This alone explains all three of the user's non-dialog complaints: icons "blacked out", "touch even lightly" opens a popup, and drags that don't merge.
- Fixed by shrinking `HOTSPOT_SIZE` to a uniform 40x40 corner badge (down from 76x76/64x64) and biasing its position with a new `HOTSPOT_CORNER_BIAS` constant so it sits toward a cell's corner instead of dead-center, across all five residence controllers (`scenes/haven/haven.gd`, `scenes/northgate/northgate.gd`, `scenes/redwater/redwater.gd`, `scenes/greybridge/greybridge.gd`, `scenes/saint_mercy/saint_mercy.gd`). `HotspotVisual`'s own drawing code needed no changes - its progress badge and lock/complete indicators are already sized relative to its own `size`. No `ResidenceHotspot`/quest data changed; this is presentation-only.
- Verified visually, not just by absence of test failures: `tests/capture_layout_haven.gd` re-run at 1080x2340 (the user's own screenshot resolution) shows every board item that previously sat under a hotspot marker (wardrobe, chest, bed, dresser, medicine cabinet, storage bag, workbench, fireplace) now fully visible and reachable, with the repair badge as a small corner accent instead of a covering disc.

### Root cause 2: native ConfirmationDialog doesn't respect canvas_items stretch

- `project.godot` sets `window/stretch/mode="canvas_items"` so the whole UI scales correctly from its 720-wide logical base to any real screen size - but Godot's `ConfirmationDialog`/`AcceptDialog` are `Window` subclasses, and a `Window`'s own size/centering is not run through that same stretch transform. On the user's actual phone this rendered the New Game overwrite dialog at (approximately) its 720-logical-width layout without the compensating scale-down, pushing the dialog text and its "Start New Game" button off the right edge of the screen - exactly matching the submitted screenshot.
- The same native `ConfirmationDialog` pattern was used in three places: `scenes/main_menu/main_menu.tscn` (overwrite prompt), `scenes/ui/item_info_panel.tscn` (rare-item delete confirm), `scenes/settings/settings.tscn` (reset-progress confirm) - all three would have the same overflow on a real device even though only the first was screenshotted.
- Fixed by adding `scenes/ui/app_confirm_dialog.gd`/`.tscn` (`class_name AppConfirmDialog`), a plain-`Control`-based modal (`CanvasLayer` > `Scrim` > `CenterContainer` > `PanelContainer`) that mirrors the exact structure `ItemInfoPanel` already uses successfully - since ordinary Controls fully participate in canvas_items stretch, this cannot exhibit the same class of bug. Exposes the same `dialog_title`/`dialog_text`/`ok_button_text`/`cancel_button_text` properties, `confirmed`/`canceled` signals, and a no-argument `popup_centered()` method as the native dialog, so all three call sites needed only a node-type swap in their `.tscn` and an `@onready` type-annotation change in their `.gd` - no behavioral logic changed. Matches the native dialog's sound cues exactly (`modal_open` on open, `confirmation` on confirm, `modal_close` on cancel) since `AudioManager._on_node_added()`'s automatic `ConfirmationDialog` wiring no longer applies to a `CanvasLayer`.
- Verified visually: new `tests/capture_overwrite_dialog.gd`/`.tscn` drives the real main menu to a save-exists state and pops the dialog at 1080x2340; the result shows the full title, both wrapped body lines, and both buttons entirely on-screen and centered.

### On the "merge is still on its own page, not part of progressing the story" and "nothing like Merge Mansion" complaints

- Not changed this session. The fused Haven+Merge screen (one persistent Home screen per residence, no separate Merge destination) was the user's own explicit prior choice, confirmed via `AskUserQuestion` earlier in this project. Given that both concrete architectural bugs above (hotspot/board layering, dialog overflow) were severe enough to make any design read as broken, and that the residence's own `Repairs: N / 9` counter already ties board-merge progress directly to story/chapter advancement (`ResidenceManager`/`QuestDefinition`, unchanged), this is deliberately left as-is pending the user's reaction to a build with the concrete bugs fixed, rather than reversing a explicitly-chosen architecture on an unconfirmed read of a frustrated bug report.

### Tests performed

- Full relevant subset re-run headless: `smoke_test`, `smoke_test_save`, `smoke_test_settings`, `smoke_test_ui_skin`, `smoke_test_main_menu_presentation`, `smoke_test_merge`, `smoke_test_merge_icons`, `smoke_test_residence`, `smoke_test_redwater(_visual_states)`, `smoke_test_greybridge(_visual_states)`, `smoke_test_saint_mercy(_visual_states)`, `smoke_test_northgate(_visual_states)`, `smoke_test_hollow_creek_hotspot_icons`, `smoke_test_remaining_hotspot_icons`, `smoke_test_northgate_hotspot_icons` - all pass.
- A newly-added `class_name` (`AppConfirmDialog`) isn't visible to other scripts until Godot rebuilds `.godot/global_script_class_cache.cfg`; the first re-run after adding it failed with `Could not find type "AppConfirmDialog" in the current scope"` until `godot4 --headless --editor --quit-after 3` forced the rescan. Not a code bug, but worth remembering next time a new `class_name` is added in a single headless session.
- Two new one-off visual verifications (not part of the regular smoke suite, matching the audit-script precedent from the export-size batch): `tests/capture_layout_haven.gd` re-run at 1080x2340 and new `tests/capture_overwrite_dialog.gd`/`.tscn`, both under `docs/layout-captures/`.

### Known issues and exact next phase

- These fixes are desktop-verified only (xvfb-run + software rasterizer); real on-device confirmation still depends on a fresh APK, which this environment cannot build (no Android SDK/export templates, network policy blocks the Google/Godot template mirrors - unchanged from the Batch 4 audit).
- The "some icons drag but don't merge" complaint should now be substantially resolved as a side effect of the hotspot-overlap fix (drop targets under a hotspot badge are now mostly clear board cells again), but this was not independently reproducible in this environment even before the fix (headless/xvfb testing uses synthetic mouse events, not touch), so it should be re-checked on the next real-device build rather than assumed fixed.
- Next: install a fresh build and re-triage against this exact list of complaints; if hotspot/dialog fixes don't fully resolve "can't drag and drop," revisit touch-vs-ScrollContainer interaction in the Storage drawer (`scenes/ui/storage_panel.tscn`), which research this session flagged as a separate, real, but still real-device-unverified risk.

---

## 2026-08-04 — Android import optimisation and debug device verification

### Starting commit and objective

- Starting commit: `b138e83` on `visual-production`.
- Objective: apply the two exact fixes from `docs/EXPORT_SIZE_AUDIT.md`,
  remeasure actual APK size, then run the signed-debug Pixel 9 upgrade,
  lifecycle, save, memory, and frame-time checks.

### Changes

- Changed exactly 46 large background import sidecars to ETC2/VRAM
  (`compress/mode=2`): world map, residence runtime backgrounds, five requested
  weather layers, scavenging runtime backgrounds, and the dialogue approach
  background. Items, producers, portraits, hotspots, navigation, and UI remain
  lossless.
- Changed all 26 music/ambience WAV import sidecars to IMA-ADPCM
  (`compress/mode=1`). Short SFX remain PCM/lossless.
- Added `editor/export/convert_text_resources_to_binary=false` to
  `project.godot`. During real APK verification, Godot 4.3's default converter
  reproducibly erased all 41 exported residence-hotspot task arrays, yielding
  `hotspot_links=0 link_errors=41` and a blank boot frame. A clean exported
  pack after the setting reports `hotspot_links=41 link_errors=0`; the rebuilt
  APK renders and loads the upgraded game normally.

### Measurements and artifacts

- Selected ETC2 Android payload: 22.74 MiB. Imported ADPCM loops: 3.48 MiB
  (previous imported PCM set: 13.89 MiB).
- Universal debug APK: 315,345,644 → 283,128,596 bytes, a 32,217,048-byte
  reduction (10.22%).
- arm64 debug APK: 205,710,503 bytes (196.18 MiB), below 200 MiB but 5.71 MB
  above a strict decimal 200 MB limit.
- Artifact hashes, certificate, paths, and ABI reports are recorded in
  `docs/production-batches/27_android_import_optimisation_and_device_verification.md`.
- Pixel 9 emulator: 201,211 KB steady PSS, 319,864 KB RSS; 62-frame
  SurfaceFlinger sample median 16.63 ms, p95 18.50 ms, max 20.61 ms; cold start
  1.14–1.28 seconds.

### Tests performed

- Clean Godot 4.3 `--headless --import`: exit 0.
- All 39 current smoke scenes executed and printed `_OK`; 37 were completely
  clean. The save test's deliberate corrupt-primary step prints an expected
  JSON parse diagnostic. The danger test still prints the already-documented
  deferred freed-Button binding error seven times, so the strict no-error gate
  is not claimed.
- Android launcher focused test: pass.
- Android export-resource focused test: pass.
- Version-code-1 → version-code-2 debug-signed install: package upgrade pass;
  certificate identity pass; pause/resume and force-stop/relaunch pass.
- Save fixture retained chapter/residence/board/survivor/token/settings state.
  Offline energy regen behaved as designed. Migration exposed a pre-existing
  +200 coin discovery-reward side effect while materialising four new boards.

### Known issues and exact next phase

- Strict release acceptance remains blocked by the migration coin mutation,
  deferred UI binding errors, decimal size interpretation, Godot 4.3's lack of
  16 KB native-library alignment, and manual ETC2/audio review on the user's
  physical device.
- Exact coding fixes and evidence are in production batch 27. No gameplay IDs,
  rules, outcomes, quest data, producer economy, or save keys were changed by
  this optimisation batch.

---

## Phase 1: Foundation - complete

### Files created

Project config: `project.godot`, `.gitignore`, `icon.svg`, `export_presets.cfg`

Autoloads: `autoload/event_bus.gd`, `autoload/game_manager.gd`,
`autoload/save_manager.gd`, `autoload/audio_manager.gd`,
`autoload/scene_router.gd`

Data models: `scripts/data_models/item_definition.gd`, `board_item.gd`,
`residence_definition.gd`, `residence_hotspot.gd`, `survivor_definition.gd`,
`scavenging_mission.gd`, `quest_definition.gd`, `vehicle_definition.gd`,
`dialogue_entry.gd`

UI foundation: `scripts/ui/theme_factory.gd`, `scripts/ui/survivor_silhouette.gd`,
`scenes/ui/toast.gd`/`.tscn`, `scenes/ui/top_resource_bar.gd`/`.tscn`,
`scenes/ui/bottom_nav.gd`/`.tscn`

Screens: `scenes/boot/`, `scenes/main_menu/` (+ background),
`scenes/haven/` (+ background), `scenes/merge_board/`, `scenes/world_map/`
(+ background), `scenes/survivors/`, `scenes/settings/`,
`scenes/dev_diagnostics/`

Docs/content scaffolding: `README.md`, `ART_ASSET_GUIDE.md`,
`AUDIO_ASSET_GUIDE.md`, `data/README.md`, `assets/manifests/asset_manifest.json`,
`tests/PHASE1_MANUAL_CHECKLIST.md`, `.gitkeep` in every empty `data/` and
`assets/` subfolder and in `shaders/`

### Files modified

None - first commit.

### Features completed

- Portrait Android export configuration (`export_presets.cfg`, `gl_compatibility` renderer, min SDK 28 / target SDK 34, no network permission)
- Main menu: New Game (with overwrite confirmation when a save exists), Continue (disabled with no save), Settings, Quit
- Scene navigation with fade transition and back-history stack (`SceneRouter`)
- Local JSON save/load: temp-file-then-rename writes, automatic `.bak` backup, corrupted-primary falls back to backup, debounced autosave on resource/setting changes plus save-on-pause/close
- Global `EventBus` signal hub for player resources, XP/level, scene changes, settings, toasts and save events
- `AudioManager` with Music/SFX buses wired to the volume settings; cues are named/keyed now but no audio files exist yet (tracked in `AUDIO_ASSET_GUIDE.md`) - missing cues warn once and no-op rather than crashing
- Responsive UI theme (`ThemeFactory`) implementing the palette, large touch targets, and a high-contrast variant; text-scale slider rebuilds it live
- Fully wired Settings screen: master/music/sfx volume, vibration, reduced motion, high contrast, colour-blind flag (stored, not yet consumed by any visual - see Known issues), subtitles flag (stored, not yet consumed - no dialogue system exists yet), text scale, reset progress (with confirmation), replay tutorial (honest "later phase" toast, no tutorial exists yet)
- Hidden developer diagnostics menu, debug-builds-only, reached by 5 taps on the main menu title; live FPS/scene/state display, working +energy/+coins/+level/reset-save actions, and honestly-disabled buttons (with phase-naming tooltips) for every system not yet built
- Placeholder screens for Haven (Hollow Creek Farmhouse exterior with 3 named but inert hotspots: front door, kitchen window, barn), the 7x9 Merge Board grid frame, the World Map (5 residence markers, 1 active/pulsing + 4 locked), and the Survivors roster (6 named cast members, Mara unlocked, 5 shown locked with a silhouette placeholder)
- All placeholder art is original and procedurally drawn in-engine (`Control._draw()`), not blank rectangles or generic circles, per the placeholder art policy - see `ART_ASSET_GUIDE.md`

### Tests performed

A Godot 4.3.stable Linux binary was downloaded and run headlessly against
the real project (no display server or Android SDK is available in this
container, so this is not the graphical editor and not an APK export):

- `godot4 --headless --path . --import` - clean project import, zero script/parse errors (one was found and fixed: `toast.gd` had a `:=` inference-from-Variant warning treated as an error under Godot 4.3's default strictness; changed to an explicit `bool` annotation)
- `tests/smoke_test.tscn` - instantiates Haven, Merge Board, World Map, Survivors, Settings and Dev Diagnostics in turn; all load and run `_ready()` with no errors
- `tests/smoke_test_save.tscn` - new game -> mutate resources -> save -> reload -> values round-trip correctly; primary save file corrupted on disk -> `SaveManager` recovers from `.bak` instead of crashing
- `tests/smoke_test_settings.tscn` - `GameManager.update_setting()` for volume/reduced-motion/high-contrast/text-scale is reflected in the real `AudioServer` bus volume and a rebuilt `Theme`'s font size

See `tests/README.md` for exact commands. This is real verification of
script correctness and core logic, but headless mode has no window - it
does **not** confirm visual layout, touch gestures, or animation feel on
an actual screen. `tests/PHASE1_MANUAL_CHECKLIST.md` covers what still
needs a real device or the editor's running game view.

### Known issues

- **Not visually confirmed.** Headless runs confirm the logic; nobody has looked at this on a real screen yet - see README "Honest limitation".
- `export_presets.cfg` was hand-written to Godot 4's known format rather than generated by the editor (no editor available here); if the Export dialog rejects it, delete it and let Godot regenerate the Android preset with the same package name/settings.
- Colour-blind mode and subtitles are stored settings with no visual/UI effect to attach to yet, because no colour-coded gameplay indicators or dialogue exist in Phase 1. They'll do something real starting Phase 2 (merge item rarity indicators) and Phase 4 (dialogue subtitles) respectively.
- The merge board screen currently shows the correct 7x9 empty grid and nothing else; this is the intended Phase 1 scope, not a bug.
- Single save slot only (matches the design spec's save-system requirements as written; multi-slot was not requested and was intentionally not added speculatively).

### Exact next phase

**Phase 2: Merge board** - grid drag-and-drop, merge rules (identical
item + identical item -> next level), producers with charges/cooldowns,
energy consumption tied to `GameManager.spend_energy()`, storage/inventory
transfer, tap-for-info and long-press-for-detail panels, task highlighting,
and the full merge/discovery animation set. Starts against the existing
`scenes/merge_board/` grid built this phase; will introduce the first
merge chain(s) with real `ItemDefinition` data under `data/items/`.

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## 2026-08-03 — Strict-quality Batch 3, part 2: status doc reconciliation

### Starting commit and objective

- Starting commit: `64f94c2` on `visual-production` (the chain-legend final-art batch).
- Objective: the doc-reconciliation piece of Batch 3 from `docs/CLAUDE_HANDOVER_2026-08-03.md` - update `docs/RELEASE_PRESENTATION_GAP_REPORT.md`, `docs/FINAL_ASSET_MANIFEST.csv`, and `ART_ILLUSTRATION_CHECKLIST.md` against runtime truth, without touching any code.

### Changes

- `docs/RELEASE_PRESENTATION_GAP_REPORT.md`: rewrote against the current branch tip. Added rows for producer state art, gameplay-chain cash-out, chain-legend art, and the unified Home screen, all with real test-name evidence. Removed the Android launcher/icon blocker (done, per `docs/production-batches/19_android_launcher_identity.md`). Reframed the remaining blockers as exactly two: Android device optimisation/APK verification (Batch 4, not started) and chain-VFX/environment/danger presentation (the rest of Batch 3, not started). Updated the branch-consolidation counts (`visual-production` is 47 commits ahead of `main`, 32 ahead of `claude/dead-haven-repo-setup-gvbesn`, both re-measured directly rather than copied from the stale report).
- `docs/FINAL_ASSET_MANIFEST.csv`: the 8 non-Construction producer rows still read "awaiting generalized resolver" / "Approved awaiting integration" from before Batch 1 of this handover; updated to "integrated via generalized resolver" / "Integrated - already acceptable". Fixed `UI_CHAIN_LEGEND`'s row the same way for this batch's own chain-legend-art change. Caught and fixed a CSV-breaking mistake during editing: my first replacement text for the producer rows contained an unescaped comma, which would have silently shifted every later column on those two lines - verified with `awk -F',' '{print NF}'` that all 92 rows have exactly 14 columns both before treating it as done and after the real fix.
- `ART_ILLUSTRATION_CHECKLIST.md`: updated the producer section's trailing note, which still said the 8 sets were "artwork-complete but await generalized runtime texture resolution" - no longer true since Batch 1 integrated them.
- `assets/manifests/asset_manifest.json` checked for the same stale phrasing; none found, so left alone rather than making unevidenced changes.

### Tests performed

- Clean headless import: zero parse/script errors (no `.gd`/`.tscn` files changed in this batch).
- Full suite: 36/36 pass, confirming the doc-only changes didn't affect anything runtime.

### Exact next phase

- Continue Batch 3: the two remaining, larger pieces - a pooled chain-ID-driven merge VFX system for all 9 gameplay chains, and per-residence environment presets (rain/fog/dust/leaves/smoke/embers/sparks/flicker/radio pulses/cloud shadows/foliage) plus gameplay-neutral danger presentation on existing triggers.

## 2026-08-03 — Export-size audit and desktop layout verification

### Starting commit and objective

- Starting commit: `b9a3a42` on `visual-production` (Batch 3 complete).
- Objective: do as much of Batch 4 as is genuinely possible without an Android SDK, export templates, or a device/emulator - none of which exist in this environment - rather than skip it entirely. The user's Codex budget is nearly exhausted, so anything provable from here should be done here.

### Export filter correctness: verified empirically, not assumed

A first attempt at simulating `export_presets.cfg`'s exclude filter in Python assumed `*` in a glob pattern doesn't cross `/` (standard shell/fnmatch behaviour) and got a badly wrong answer - it implied `docs/*` only excludes direct children of `docs/`, leaving tens of MB of `.avi` captures and screenshot PNGs looking like they'd ship. Rather than report that, it was checked against Godot's actual matcher directly: `tests/verify_export_filter_semantics.gd`, a one-off headless script calling `String.matchn()` (the same function the exporter uses) on real repo paths. Confirmed: Godot's `*` matches any run of characters *including* `/`, so the existing exclude filter is correct as written - `docs/*`, `tests/*`, `assets/concepts/*`, `assets/**/source/*` etc. all correctly catch everything nested under them, and real runtime assets under `assets/items/<chain>/*.png` are correctly not caught. No fix needed here; the filter config itself was never the problem.

### Export size measurement: a real, actionable finding

With the verified-correct semantics, re-measured what would actually ship: **212.4 MB source weight** (2009 files: 183.6 MB PNG, 20.1 MB WAV, 6.2 MB JPG) against the release plan's own 200 MB target - and every PNG/WAV import currently uses the least space-efficient setting available (`compress/mode=0` on every `.import` sidecar checked - fully lossless PNG, uncompressed PCM WAV). Full findings and a priority-ordered fix list in new `docs/EXPORT_SIZE_AUDIT.md`. Headline: the "texture/audio compression" step in the release plan isn't optional polish, it's required to hit budget at all, based on this measurement.

### Desktop layout verification

Godot's dummy `--headless` renderer can't produce screenshots (established in the producer-artwork batch), but `xvfb-run --rendering-driver opengl3` can, and doesn't need Android anything - just a real GPU-less software rasterizer, which this container has. New `tests/capture_layout_haven.gd`/`.tscn` and `tests/capture_layout_scavenging.gd`/`.tscn` render those two screens at 720×1600 (narrow), 1080×2400 (Pixel reference), and 1440×3200 (large) to `docs/layout-captures/`. All clean - no clipping or overlap on the top bar, merge board, chain legend, nav bar, hero panel, threat badge, or action buttons at any of the three widths. One minor observation, not a functional bug: the danger overlay's screen-corner threat indicator (added this session, see the danger-presentation batch) sits at the same on-screen position as the global top status bar and may render underneath it depending on CanvasLayer ordering - worth a real-device check, but the underlying data (which mission/event raises it, at what intensity) is already proven correct by `smoke_test_danger_presentation`.

### Tests performed

- Clean headless import: zero parse/script errors.
- Full suite: 39/39 pass (no `.gd` outside `tests/` changed in this session's audit work).
- `tests/verify_export_filter_semantics.gd` is a one-off verification script (run via `godot4 --headless --script`, not part of the smoke suite), kept for anyone who wants to re-verify filter semantics after future `export_presets.cfg` changes.

### Known issues

- Actual packed/compressed APK size, on-device frame time/memory, and whether ETC2 visibly degrades any specific texture all still require the real toolchain and are explicitly out of `docs/EXPORT_SIZE_AUDIT.md`'s scope.
- The danger-overlay corner-indicator layering question above needs a real-device or at least a full-app (not isolated-scene) capture to resolve conclusively.

### Exact next phase

Whoever has the Android SDK/export templates/device (Codex, on the user's own machine): read `docs/EXPORT_SIZE_AUDIT.md` first - it names the exact two changes (ETC2 on large opaque backgrounds, WAV compress/mode 0→1) most likely to close the size gap, so the remaining Batch 4 work is applying and verifying those rather than rediscovering the problem from scratch.

## 2026-08-03 — Strict-quality Batch 3, part 5: danger presentation (Batch 3 complete)

### Starting commit and objective

- Starting commit: `2cd9a79` on `visual-production` (the environment-layers batch).
- Objective: the last piece of Batch 3 from `docs/CLAUDE_HANDOVER_2026-08-03.md` - gameplay-neutral danger presentation (warning pulse, screen-edge threat indicator, gas cloud) wired only to existing defence/scavenging/fuel triggers, with the safety restrictions (no flashing, no full-screen filter, no photosensitivity risk, reduced motion keeps static information) treated as hard requirements, not suggestions.

### Implementation

- New `scripts/vfx/danger_overlay.gd` (`DangerOverlay`, extends Control): three effects, `set_danger(intensity, gas_cloud)` / `clear_danger()` as its only API.
  - Warning pulse: a slow single-colour glow confined to the four screen edges. Its angular speed is a named constant (`PULSE_ANGULAR_SPEED := 1.6`, ≈0.25 Hz - one cycle every ~3.9 seconds) specifically so the "not a strobe" property is a directly testable fact, not something eyeballed from a screenshot.
  - Screen-edge threat indicator: a small static (non-pulsing) corner glyph, present identically whether or not reduced motion is on - the actual "there is danger here" information survives even when the pulse's motion is suppressed.
  - Gas cloud: soft drifting vapour, only ever drawn when a caller explicitly passes `gas_cloud=true` - restricted by the calling scenes (see below) to the one real fuel/petrol context in the current roster, not offered as a free-standing option.
  - Edge width is bounded by named constants (`EDGE_BASE`/`EDGE_PER_INTENSITY`) that keep it under 5% of a narrow screen's width even at maximum intensity - a border accent, never a full-screen filter, structurally rather than by convention.
  - Reduced motion: `set_process()` turns off (no animation) but `intensity` stays wherever it was set - the warning tint remains visible, static, at the pulse's resting value.
- `scenes/scavenging/scavenging.gd`: reads each mission's own already-existing `danger_rating`/`human_threat` in `_apply_danger_presentation()`, called from `_configure_location()` - no new data, no new signal. `danger_rating >= 3` or `human_threat > 0` raises the overlay; `mission_id == "petrol_station"` is the only case that also requests the gas cloud, since it's the only real fuel/petrol location in the current 10-location roster.
- `scenes/defence/defence.gd`: `_on_send_pressed()` raises the overlay right where the existing `"defence_warning"` SFX already plays (the actual defence warning/start moment); `_play_outcome()` keeps it raised on a failed/dangerous choice and clears it on success. Neither `DefenceManager.launch()`/`resolve_choice()` nor their odds/results changed.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_danger_presentation.gd`/`.tscn`: asserts the pulse's Hz is below the photosensitivity threshold and the max edge width is below 5% of a narrow screen, both directly from the named constants rather than rendering and measuring pixels; reduced motion leaves `intensity > 0` while `is_processing()` becomes false; a real Petrol Station mission produces a non-zero intensity and the gas cloud, a real low-threat mission produces neither; a real defence event's launch/failure/success sequence raises, holds, and clears the overlay correctly; and none of it touches `GameManager.resources`. Caught a real ordering bug while writing this test, not caught by hand-reading the diff: `_danger_overlay` was constructed at the very end of `scavenging.gd`'s `_ready()`, but `_configure_location()` (which uses it) is called much earlier in the same function - every mission threw "Invalid call: Nonexistent function 'set_danger' in base 'Nil'" until the overlay's construction was moved before that call.
- Full suite: 39/39 pass. `smoke_test_audio_presentation` reconfirmed as the same pre-existing flake (2/3 in isolated reruns, no code changed in between) tracked since the producer-state-artwork batch - still not this batch's doing.
- New `tests/capture_danger_presentation.gd`/`.tscn`: captures a real Police Checkpoint (danger_rating=3, human_threat=3) and Petrol Station encounter to `docs/producer-state-captures/live_danger_*.png`. The overlay is intentionally subtle against dark scavenging-location art at normal viewing scale - consistent with "restrained, not full-screen" being the actual requirement - so as with the environment-layers batch, the automated constant/data checks above are the rigorous verification; the captures are supplementary proof nothing crashes or renders incorrectly, not a demonstration of dramatic visual impact.

### Known issues

- `smoke_test_audio_presentation`'s pre-existing timing flake continues to appear intermittently, unrelated to any batch since it was first noted. Still not fixed.
- The `_bind_button` deferred-call error from `ui_animation_director.gd` (first seen and diagnosed as harmless in the merge-VFX batch) appeared again in this batch's test output when freeing scavenging/defence scene instances - same known, non-fatal, self-inflicted-by-rapid-instantiation pattern, not a new issue.

### Batch 3 complete

All five pieces of Batch 3 from `docs/CLAUDE_HANDOVER_2026-08-03.md` are done: chain-legend final art, status-doc reconciliation, chain-specific merge VFX, per-residence environment layers, and this danger presentation. Batch 4 (Android device optimisation, export-size audit, and signed-build verification) is the only remaining item from that handover, and it requires an Android SDK, Godot export templates, and a real or emulated device - none of which are available in this remote environment (no network path to `dl.google.com` or `github.com/godotengine` releases, confirmed by the proxy's own status endpoint returning a policy denial, and no export templates or SDK present locally). That work needs to happen on a machine with those installed.

## 2026-08-03 — Strict-quality Batch 3, part 4: per-residence environment layers

### Starting commit and objective

- Starting commit: `692850d` on `visual-production` (the chain-specific merge VFX batch).
- Objective: the environment-presets half of Batch 3's last remaining piece from `docs/CLAUDE_HANDOVER_2026-08-03.md` - rain/fog/dust/leaves/smoke/embers/sparks/flicker/radio pulses/cloud shadows/foliage, mapped per residence, without a generic one-look-fits-all overlay.

### A correction before starting

`scripts/vfx/ambient_vfx.gd` already existed, already auto-attaches to every residence's "Background" node via `scripts/ui/ui_animation_director.gd`'s `_scan_scene()` (a global `CanvasLayer` autoload that scans the current scene on every scene change) - this was not starting from nothing, it was completing an existing system. It had 4 *exclusive* presets (`storm`/`dust`/`fog`/`industrial`), one per residence, chosen by matching substrings in the scene's file path. `industrial` already covered sparks, radio-pulse rings and a generator-vibration motif combined; cloud shadows and lantern/interior flicker were already drawn unconditionally regardless of preset.

### Implementation

- `scripts/vfx/ambient_vfx.gd`: replaced the exclusive `@export_enum preset` with `@export var layers: Array[String]`, so a residence can combine several named effects at once instead of picking one. Added `leaves` (tumbling triangles, faster fall + more horizontal drift than dust), `smoke` (rising, expanding, fading puffs from a low source), `embers` (smaller, brighter, flickering motes rising faster than smoke), and `foliage` (swaying grass blades near the bottom edge - a sway, not a fall/rise, so it reads distinct from leaves). Kept `rain` (renamed from `storm`), `fog`, `dust`, `sparks`, and `radio_pulse` (now its own independently placeable layer instead of bundled only into `industrial`). Cloud shadows and lantern flicker stay unconditional. Unknown layer names are silently ignored rather than erroring. Particle budget/quality-tier/visibility gating logic is unchanged in behaviour, just restructured to build a `Dictionary` of per-layer particle arrays instead of one flat array.
- `scripts/ui/ui_animation_director.gd`: replaced `_preset_for_scene()` (one string) with `_layers_for_scene()` (an array), matching the handover's own scene-mapping list per residence: Hollow Creek (`scenes/haven/haven.tscn` - the farmhouse's actual folder name is `haven`, not `hollow_creek`, caught by a test before it ever ran for real) gets rain/foliage/dust/smoke/embers for its storm-clouds-and-chimney-fire setting; Redwater gets rain/dust/sparks/smoke for road mist, wind debris, fuel-station flicker and generator exhaust; Greybridge gets rain/leaves/radio_pulse/smoke/foliage for its radio tower and schoolyard; Saint Mercy gets fog/rain/sparks/smoke for its emergency lighting and generator; Northgate gets rain/dust/sparks for yard dust and restrained sparks. The vehicle screen keeps a generic dust/sparks combination; anything unmatched falls back to plain dust, same as before.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_environment_layers.gd`/`.tscn`: asserts `_layers_for_scene()` returns the exact expected array for all 5 residence scene paths; low graphics quality produces zero particles for every particle-based layer without erroring; an unknown layer name doesn't crash the node; visibility-based processing gating (`is_processing()` on show/hide) is unchanged from before the rewrite. Caught two real bugs while writing this test, both worth knowing about: the Hollow Creek path match against `"hollow_creek"` never matched anything real, since the actual scene lives at `scenes/haven/haven.tscn` (fixed before ever running against real data, not after a failure); and two coroutine helper functions needed explicit `await` at their call sites, a GDScript static-typing requirement this project's earlier tests hadn't hit yet.
- Full suite: 38/38 pass, including a clean run of `smoke_test_audio_presentation` this time - see Known issues below for that test's ongoing pre-existing flake, unrelated to this batch.
- New `tests/capture_environment_layers.gd`/`.tscn`: attaches Hollow Creek's real assigned layer combination to its actual background and captures it via `xvfb-run --rendering-driver opengl3` to `docs/producer-state-captures/live_environment_layers_hollow_creek.png`. Hides the embedded `%BoardPanel` first since it otherwise covers almost the entire background these effects render onto - a real constraint of the unified-screen layout from the earlier batch, not a bug. Motion-based effects (rain fall, smoke rise, foliage sway) don't read dramatically in a single static frame by design - deliberately faint accents over final art, matching the existing cloud-shadow/flicker effects' own established restraint - so the automated per-residence assignment test above is the rigorous verification here, this capture is supplementary proof nothing crashes/renders wrong.

### Known issues

- `smoke_test_audio_presentation`'s pre-existing timing flake (tracked since the producer-state-artwork batch) didn't reproduce in this batch's runs. Still not chased down or fixed - noted every batch since it first appeared, still unrelated to any of these changes.
- Effect combinations per residence are a reasonable interpretation of the handover's scene-mapping list using this project's actual available layer types, not a pixel-exact reproduction of every named detail in that list (e.g. Northgate's "fence movement", "warning lamps", "tower light" aren't generic atmosphere - they'd need bespoke object animation in that residence's own background script, which is a different, larger piece of work than this generic layer system).

### Exact next phase

- The last piece of Batch 3: gameplay-neutral danger presentation (warning pulse, screen-edge threat indicator, gas cloud) wired only to existing defence/scavenging/fuel/danger triggers, respecting reduced motion.

## 2026-08-03 — Strict-quality Batch 3, part 3: chain-specific merge VFX

### Starting commit and objective

- Starting commit: `798bfdf` on `visual-production` (the doc-reconciliation batch).
- Objective: the first of Batch 3's two remaining larger pieces from `docs/CLAUDE_HANDOVER_2026-08-03.md` - replace the single hardcoded wood-chip/dust burst every chain's merge shared with one pooled, chain-ID-driven system, without changing merge timing or results.

### Implementation

- New `scripts/vfx/merge_particle.gd` (`MergeParticle`, extends Control): one reusable, poolable particle that draws a small procedural shape (shard/fragment/crumb/cross/glint/cord/droplet/chunk/ring/zigzag/fiber/puff) via `_draw()`, colored and sized per use through `prime()`. Procedural shapes, not raster sprites, because this environment still has no image-generation tool - the same constraint that's shaped every other visual choice in this project; this is the established fallback technique (see `ItemIconRenderer`), applied here deliberately rather than as a placeholder.
- New `scripts/vfx/merge_vfx.gd` (`MergeVFX`, pure data/static functions, no node state - same shape as the existing `MotionFXScript` helper): a `STYLES` table maps each of the 9 gameplay chains to a primary/secondary shape+color pair matching the brief's material descriptions (Construction keeps its original wood/dust look exactly, since that was already chain-correct; Tool gets grey fragments + sparks; Food gets crumbs + leaf flecks; Medical gets a soft cross + glints; Trap gets fragments + cord strands; Fuel gets droplets + amber glints; Vehicle Parts gets heavier chunks + sparks; Electronics gets cool-blue rings + zigzag arcs; Clothing gets soft fibres). `burst_plan(chain_id, level, quality)` returns the exact particle count/shape/color list for a burst - reduced under `"low"` graphics quality, unchanged at `"standard"`/`"high"`, unknown chain ids fall back to Construction's style rather than producing nothing.
- `scenes/merge_board/merge_board.gd`: `_play_merge_reward()` rewritten to use a pre-built pool (`_particle_pool`: 16 `MergeParticle`s, `_glow_pool`: 2 glows, built once in `_build_vfx_pools()` from `_ready()`) instead of instantiating and `queue_free()`-ing new `TextureRect`s every merge. `reduced_motion` now gets a real short fade/glow (glow only, shorter duration) instead of the old blanket `_effects_disabled()` gate skipping the whole function - previously reduced motion showed literally nothing for a successful merge. Low graphics quality keeps the full glow-plus-particle sequence but with `MergeVFX.burst_plan()`'s reduced count. The pull/compression/expansion/bounce steps around it (`_play_merge_pull`, `_play_result_expansion`) are unchanged and stay chain-agnostic, matching the brief's own sequence description - only the "material-specific particles" step needed chain variety. `_on_drop_attempted()` now passes the resulting item's `chain_id` through to the reward call.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_merge_vfx.gd`/`.tscn`: `MergeVFX.burst_plan()` is correct for all 9 chains as pure data (7 particles at level 1, 12 with `emphasize=true` at level 5+, no empty shapes); low quality reduces count without zeroing it; an unknown chain id falls back instead of failing; three real merges against a live embedded Haven board leave `_particle_pool`/`_glow_pool` at their exact pre-built sizes (proving reuse, not per-merge node churn); `reduced_motion` shows the glow with zero particles made visible. Caught two real issues while writing this test, both in the test itself, not the feature: instantiating and freeing two separate `Haven` scenes in the same run produced a noisy (but harmless) deferred-call error in the unrelated nav-bar animation code, fixed by reusing one instance across checks; and the reduced-motion check initially raced the previous check's still-in-flight particle tweens in real time, fixed by explicitly resetting pool state instead of relying on timing.
- Full suite: 37/37 pass. `smoke_test_audio_presentation` failed once even in isolation during this batch (previously only ever failed in rapid sequential runs, not alone) but passed 5/5 further isolated reruns immediately after with no code changed in between - still the same pre-existing flake, just a visibly wider one than previously observed; not touched by this batch.
- New `tests/capture_merge_vfx.gd`/`.tscn`: triggers a real Electronics-chain merge on the embedded Haven board and captures it mid-burst via `xvfb-run --rendering-driver opengl3` to `docs/producer-state-captures/live_merge_vfx_electronics.png` - visibly shows cool-blue ring/arc particles, not the old wood-chip/dust look.

### Known issues

- All 9 particle "materials" are procedural shape+color combinations, not illustrated sprites, for the reason stated above. If a future session gets an image-generation tool, these are natural candidates to replace with authored art without changing `MergeVFX`'s interface.
- `smoke_test_audio_presentation`'s flake widened slightly (now occasionally fails alone, not just in rapid sequences) - still not chased down, same as every batch since it was first noted.

### Exact next phase

- The last piece of Batch 3: per-residence environment presets (rain/fog/dust/leaves/smoke/embers/sparks/flicker/radio pulses/cloud shadows/foliage) and gameplay-neutral danger presentation on existing triggers. Note `scripts/vfx/ambient_vfx.gd` already exists with 4 presets (storm/dust/fog/industrial) covering some of this list (rain-like streaks, dust motes, fog, sparks, radio pulse rings, a generator-vibration motif, lantern flicker) - that work is extending/completing it, not starting from nothing.

## 2026-08-03 — Strict-quality Batch 3, part 1: chain-legend final art

### Starting commit and objective

- Starting commit: `d084c08` on `visual-production` (the gameplay-chain cash-out batch).
- Objective: the first piece of Batch 3 from `docs/CLAUDE_HANDOVER_2026-08-03.md` - replace the merge board's procedural chain-legend swatches with existing final illustrated art, keeping the defensive procedural renderer as a fallback only.

### Implementation

- `scripts/merge/chain_legend_icon.gd`: each swatch now looks up its own chain's `producer_item_id` through `ItemDatabase.get_chain()`/`get_item()` and shows that producer's real `icon_path` texture (added as a child `TextureRect`, `MOUSE_FILTER_IGNORE` so the swatch's own tap handling is unaffected) instead of calling `ItemIconRenderer.draw_chain_swatch()` unconditionally. `_draw()` only falls back to the procedural swatch when no final art resolves, and the selection highlight border is unchanged. `ItemIconRenderer.draw_chain_swatch()` itself is untouched and remains available for that fallback case.
- No merge rule, chain data, highlight/selection behaviour, or save data changed - this is presentation-only, reusing each chain's producer art exactly as already used elsewhere on the board.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_chain_legend_art.gd`/`.tscn`: confirms all 9 gameplay chains (the reward chains correctly have no legend entry at all) resolve `has_final_illustration() == true`.
- Full suite: 36/36 pass (35 existing + this one), except `smoke_test_audio_presentation`'s pre-existing timing flake in the rapid sequential run - reconfirmed unrelated by rerunning it alone.
- New `tests/capture_chain_legend.gd`/`.tscn`: renders the real embedded Haven board to `docs/producer-state-captures/live_chain_legend.png` via the same `xvfb-run --rendering-driver opengl3` path established in the producer-artwork batch - the legend row visibly shows 9 distinct illustrated icons instead of flat colour swatches.

### Exact next phase

- Continue Batch 3: reconcile the stale `docs/RELEASE_PRESENTATION_GAP_REPORT.md`/`assets/manifests/asset_manifest.json`/`docs/FINAL_ASSET_MANIFEST.csv` against runtime truth, then the larger remaining pieces - pooled chain-VFX, environment presets, and gameplay-neutral danger presentation.

## 2026-08-03 — Gameplay-chain cash-out

### Starting commit and objective

- Starting commit: `4fb95bd` on `visual-production` (the producer-state-artwork integration batch).
- Objective: Batch 2 from `docs/CLAUDE_HANDOVER_2026-08-03.md` - add tap-to-collect on the nine gameplay chains, not only the four reward chains, without changing chain order, merge results, item IDs, or save keys.

### Implementation

- `autoload/board_state.gd`: generalized `collect_reward()` behind a new `can_collect_reward(instance_id) -> Dictionary` that returns `{allowed, reason}` (plus `resource`/`amount` when allowed). Reward chains keep their exact original `level * per_level_value` formula. Gameplay-chain items become collectible wherever `ItemDefinition.sell_value > 0` - every real level in every chain already has one, authored and balanced when the items were created (5/20/45/80/125/180/245 coins for Tool's 7 levels, for example); this reuses that existing additive field instead of inventing a second, parallel reward table or touching any item ID or save key. `_resolve_cash_out_reward()` holds the resource/amount formula for both cases.
- Added explicit refusal reasons ahead of the reward lookup: `producer` (never collectible, matching the handover's restriction even though producers also have `sell_value = 0` and would be refused by the formula anyway), `blocked` (covers box-covered/`is_locked` and cobwebbed/`has_cobweb` via the existing `is_item_blocked()`), and `bubbled` (`BoardItem.is_in_bubble` - not previously checked by anything, since nothing needed to block on it before this).
- `autoload/residence_manager.gd`: added `is_item_reserved_for_active_task(item_id, residence_id, count)`, the new `task_reserved` guard - refuses collecting the last copy(ies) of an item an active, not-yet-complete hotspot task on that residence still needs, so the new cash-out button can't let a player accidentally give away task progress. Does not affect normal merging, task completion's own requirement check, or anything outside the collect path.
- `scenes/ui/item_info_panel.gd`: the Collect button's visibility and label now come from `can_collect_reward()` instead of an `is_reward_chain` check, so it appears for both categories under the same real gating; added a failure toast ("Can't collect that right now.") where there previously was silent no-op on refusal.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_gameplay_cash_out.gd`/`.tscn`: a freely-collectible gameplay item (dynamically chosen - not currently reserved by an active Hollow Creek task, since which items are mid-task at a fresh `new_game()` is itself data, not something safe to hardcode) collects for exactly its `sell_value` in coins and leaves the board; a producer, a box-covered item, a cobwebbed item, and a bubbled item are each refused with the correct distinct reason; an item topped up to exactly an active task's requirement is refused as `task_reserved`, and a surplus copy above that requirement is collectible; the existing reward-chain formula is confirmed unchanged; a collected item's removal and its granted coins both survive a `to_save_data()`/`apply_save_data()` round trip. Discovered and fixed a real test bug during development, not a product bug: an initial version hardcoded `tool_3` as "obviously safe to collect" and failed immediately because Hollow Creek's starting quests really do reserve it at a fresh game - the task-reserved guard was correctly refusing it. Fixed by picking a target dynamically instead of assuming.
- Full suite: 35/35 pass (33 existing + `smoke_test_producer_states` + this one), except `smoke_test_audio_presentation`'s pre-existing timing flake in the rapid sequential run - confirmed unrelated by rerunning it alone 3/3 times successfully; not touched by this batch.
- New `tests/capture_gameplay_cash_out.gd`/`.tscn`: instantiates the real embedded Haven screen, spawns a freely-collectible item, opens the real `ItemInfoPanel` through the embedded board's own `_info_panel`, and captures it to `docs/producer-state-captures/live_gameplay_chain_collect_button.png` via the same `xvfb-run --rendering-driver opengl3` path the producer-artwork batch established. Shows a real "Bent Nail" (Tool level 1) with a live "Collect (+5 coins)" button, matching `tool_1.tres`'s authored `sell_value` exactly.

### Known issues

- `sell_value` values were authored earlier in the project as descriptive/informational text only ("Sell N coins" in the info panel) and were never balance-tested against an actual working cash-out action before now. They read as reasonable relative to the ~250-600 coin range a fresh game starts with, but haven't been played through a full economy pass.
- `tests/README.md`'s bullet list and run-command block are updated only for the two tests this and the prior batch added, same tracked staleness as before - full reconciliation is still Batch 3's job.

### Exact next phase

- Batch 3 from `docs/CLAUDE_HANDOVER_2026-08-03.md`: remaining strict-quality presentation - pooled chain-ID-driven merge VFX, environment presets, gameplay-neutral danger presentation, replacing the procedural chain-legend swatches with final art, and reconciling the stale gap report/manifests against runtime truth.

## 2026-08-03 — Producer state artwork integration

### Starting commit and objective

- Starting commit: `65ddd9b` on `visual-production`, picked up directly from `docs/CLAUDE_HANDOVER_2026-08-03.md` (Batch 1 of the required coding batches).
- Objective: generalize producer state texture resolution beyond Construction's old special case, so all nine producer chains resolve their authored `producer_<state>.png` art, then add focused tests and push.

### Implementation

- `scripts/merge/item_view.gd`: replaced the `def.chain_id == "construction"` special case in `_refresh_final_texture()` with a chain-agnostic `_resolve_producer_state_path()` that checks `res://assets/items/<chain_id>/producer_<state>.png` for every producer, in the same priority order the Construction-only code already used (transient visual-state override, then empty, then recharge/cooldown, then low-charge, then selected). A chain with no authored file for the state that would apply falls back to the existing tint-only presentation instead of a broken texture load, so an incomplete future chain stays readable.
- Did not touch producer IDs, charges, cooldowns, energy costs, outputs, unlock rules, spawn probabilities, or any save data - this is presentation-only, matching the handover's compatibility requirement.

### Tests performed

- Clean headless import: zero parse/script errors.
- New `tests/smoke_test_producer_states.gd`/`.tscn`: for all 9 producers in `BoardState.PRODUCER_UNLOCK_RULES`, asserts `_resolve_producer_state_path()` returns the correct authored file for selected/active/low-charge/empty/recharge and returns no override for the idle state; asserts a locked producer's `BoardState.is_item_blocked()` stays true and `_get_drag_data()` stays null regardless of which visual state is showing; asserts `set_selected_visual()`/`play_producer_visual_state()` never mutate the underlying `BoardItem`'s charge/cooldown/lock fields. All 9 chains' low-charge/empty/recharge paths are exercised directly against manually-constructed `BoardItem`s rather than through real gameplay, since every current producer has unlimited charges (`producer_charges = -1`) and wouldn't naturally reach those states yet - the resolver logic itself is proven correct independent of that.
- Full suite: 34/34 (33 existing + the new one).
- New `tests/capture_producer_states.gd`/`.tscn`: instantiates the real embedded Haven screen (not a standalone board), finds the live `tool_producer` `ItemView`, and captures its active/empty/recharge states to `docs/producer-state-captures/live_embedded_tool_*.png`. This container's plain `--headless` run uses Godot's dummy renderer, which returns a null viewport texture and can't actually save a screenshot (confirmed by trying it first, not assumed) - `xvfb-run -a godot4 --path . --rendering-driver opengl3` works in this container via its installed `Xvfb`/Mesa llvmpipe software rasterizer and produces real captures. This is the first real in-engine screenshot taken from inside this remote environment across the whole project; every prior phase's "not visually confirmed" caveat assumed it wasn't possible here at all.

### Known issues

- `tests/README.md`'s test-by-test bullet list and run-command block were only updated for the one new test added here, not fully reconciled against every test file that already exists - same tracked staleness `docs/RELEASE_PRESENTATION_GAP_REPORT.md` already calls out project-wide. Not fixed here; still Batch 3's job per the handover.
- The `xvfb-run` capture path discovered here is new and only used for this batch's evidence; it hasn't been applied retroactively to any earlier phase's unverified visual claims.

### Exact next phase

- Batch 2 from `docs/CLAUDE_HANDOVER_2026-08-03.md`: gameplay-chain cash-out - add tap-to-collect at several data-driven levels on the nine gameplay chains (not just the four reward chains), excluding box-covered/cobwebbed/task-reserved items, with reward metadata stored additively so no item ID or save key changes.

## 2026-08-01 — Progression gating fixes

### Starting commit and objective

- Starting commit: `72fae9b` on `visual-production`.
- Objective: block interaction with locked residence hotspots and activate the nine existing chain producers progressively, without changing gameplay data or the save schema.

### Implementation and source tracing

- `HotspotVisual._gui_input()` now consumes locked presses, plays the existing error feedback, and emits no `tapped` signal. Available hotspots retain their existing behavior.
- The padlock seen on Hollow Creek markers is drawn procedurally by `HotspotVisual._draw_illustrated_marker()`; it entered in commit `ef661a1` and is not baked into the final residence artwork.
- The uploaded v2 APK was assembled from a working tree based on `781c27c`. Its runtime files were later committed in `72fae9b`, but the artifact was not produced from a clean checkout of that commit.
- The nine established board producer objects and positions remain intact. Their existing `BoardItem.is_locked` state is reconciled from current progress after new-game reset, save load, quest completion, vehicle discovery, and relevant story-flag changes.
- Unlock order is Construction at start; Tools after Secure the Front Door; Food after Clear the Living Room; Medical after Repair the Food Pantry; Traps after Rescue Noah; Vehicle Parts after delivery-van discovery; Fuel and Electronics after Redwater unlock; and Clothing after Greybridge unlock.
- Locked producer taps return `producer_locked`, identify the required milestone, and spend no energy. Task panels now expose that milestone when their required chain source is still locked.
- Residence catalog validation now checks all 41 hotspot-to-quest links for missing IDs, missing quests, and mismatched hotspot IDs.

### Assets, animation, audio, and optimisation

- Assets created or rejected: none.
- Visual states and animations added: none; this batch corrects interaction and progression gating only.
- Audio changes: none; existing locked/error cues are reused.
- Optimisation changes: none.

### Files modified

- `autoload/board_state.gd`, `autoload/event_bus.gd`, `autoload/game_manager.gd`, and `autoload/residence_manager.gd`.
- `scripts/residence/hotspot_visual.gd`, `scenes/merge_board/merge_board.gd`, and `scenes/ui/task_panel.gd`.
- Focused assertions in `tests/smoke_test_merge.gd`, `tests/smoke_test_hollow_creek_hotspot_icons.gd`, and `tests/android_export_resource_test.gd`.
- Detailed evidence: `docs/production-batches/22_progression_gating_fixes.md`.

### Verification

- Clean Godot 4.3 headless import: pass.
- Hotspot focused test: all nine Hollow Creek icons resolve; locked tap emits zero signals; available tap emits one.
- Merge focused test: 11 starting objects retained; active producers advance from 1 to 9; locked taps consume no energy; board save/reload remains intact.
- Android export resource test: 41 hotspot links and zero validation errors; both Android presets and all runtime catalog totals pass.
- Full smoke suite: 33/33 pass.

### Compatibility, known issues, and exact next phase

- No item, producer, quest, residence, hotspot, story, vehicle, resource, economy, merge-rule, board-position, save-key, or save-schema changes.
- The previously uploaded APK still contains its previously packaged behavior. A later Android package must verify the new `hotspot_links=41 link_errors=0` runtime line and recheck marker interaction on-device.
- Next: extract the merge board into a reusable panel, embed it in all five residence screens, remove Merge as a navigation destination, and keep hotspot requirements and task-to-board highlighting inside the unified Home screen.

## 2026-08-01 — Per-residence board save migration

### Starting commit and objective

- Starting commit: `644e396` on `visual-production`.
- Objective: replace the singular saved board with five isolated residence boards and a deterministic version-1 migration before changing board layouts or presentation.

### Implementation

- `BoardState` remains the public gameplay API while snapshotting inactive boards by stable residence ID. Its existing item/grid/storage calls operate on the active residence.
- Save version 2 stores all five residence payloads, the active residence, and account-wide discovery history. The existing profile residence stays synchronized.
- Version-1 saves move their complete legacy board into the saved residence exactly once, preserving instance/item IDs, coordinates, storage, producer charges/cooldowns, lock/cobweb/bubble flags, and discovery history. Four clean boards are then materialized; legacy items are never duplicated.
- Assets created/rejected, visual states, animations, audio, Android export, gameplay values, merge rules, quest data, and economy: unchanged.
- Files: `autoload/board_state.gd`, `autoload/save_manager.gd`, `tests/smoke_test_merge.gd`, `tests/smoke_test_save.gd`, and `docs/production-batches/23_per_residence_board_save_migration.md`.

### Verification

- Godot 4.3 zero-cache import: exit 0. One allocator cleanup diagnostic appeared once at shutdown; an immediate rerun completed cleanly with no parser/import/resource error.
- Focused merge/save tests: board isolation, five residence keys, exact legacy sentinel position, version-2 round trip, and backup recovery pass.
- Full discovered smoke suite: 33/33 pass.

### Known issues and exact next phase

- All five boards intentionally retain the old sparse starting layout in this schema-only batch.
- Next: authored per-residence box/cobweb layouts plus covered/cobweb interaction and task-count restrictions.

## 2026-08-03 — Residence junk and cobweb layouts

### Starting commit and objective

- Starting commit: `14a07ec0a8eb5c88b92a304931759b17bb479a4a` on `visual-production`.
- Objective: turn all five isolated residence boards into dense rooms to excavate by activating the saved box/cobweb state, without changing normal merge outcomes, gameplay data, or the version-2 save envelope.

### Implementation

- Added five deterministic runtime manifests under `data/boards/`. Every new 7x9 residence board has 59 occupied cells: nine established producers, two free Construction level-1 starters, six authored cobwebbed items, 42 box-covered items, and four usable work cells.
- Successful merges reveal orthogonally adjacent boxes into cobwebbed underlying items. A cobwebbed target is freed only by merging a matching non-cobwebbed item of the same existing chain/level; the result remains the chain's normal next-level item.
- Covered/cobwebbed items cannot move, enter storage, delete, collect, count toward tasks, be consumed by tasks, or act as dragged merge sources. Producer locks retain their independent progressive story/repair behavior.
- Existing version-2 boards preserve every item and coordinate, then fill eligible empty cells once using `layout_version = 1`. Version-1 migration remains single-assignment and receives the same one-time backfill. Authored junk grants no account discovery rewards.
- Both Android presets explicitly include dynamically loaded `data/boards/*.json`; the focused export contract parses and structurally validates every manifest.
- Assets created/rejected: none. Existing final item art and existing lock/cobweb overlays are now used by live gameplay. No new animation or audio assets; no economy, quest, story, producer-output, content-ID, or merge-result changes.
- Files and detailed evidence: `autoload/board_state.gd`, the merge/item UI scripts, `export_presets.cfg`, five `data/boards/*.json` manifests, focused tests, and `docs/production-batches/24_residence_junk_cobweb_layouts.md`.

### Verification

- Focused merge and save tests pass: dense counts, blocked interactions, adjacency reveal, matching cobweb clear, 1-to-9 producer progression, five-board isolation, exact-position legacy migration, save/reload, and backup recovery.
- Android export-resource contract passes for both presets and all five manifests.
- Empty-cache Godot 4.3 import rebuilt 1,722 artifacts but returned exit 1 without diagnostics at cleanup; the immediate verbose reconciliation import exited 0 with no parser/import/resource/shader/texture failure.
- Full smoke suite: 33/33 pass. Only established ObjectDB shutdown warnings and intentional save-corruption recovery warnings were emitted.

### Known issues and exact next phase

- Box and cobweb states use the existing shipped overlays; this batch does not author new overlay artwork or perform Android visual capture.
- Next: embed a reusable board panel in every residence, activate the correct per-residence board before child setup, keep hotspot requirements in the same view, remove Merge as a bottom-nav destination, and update navigation tests without deleting behavioral coverage.

## 2026-08-03 — Remaining producer state artwork

### Starting commit and objective

- Starting commit: `a96f0b5` on `visual-production`.
- Objective: complete the illustration-only portion of the eight remaining producer state sets, then stop coding and provide a full Claude handover.

### Artwork

- Preserved all eight approved normal producer images unchanged.
- Added 40 transparent 256x256 runtime illustrations: selected, active, low-charge, empty, and recharge for Tool, Food, Medical, Trap, Fuel, Vehicle Parts, Electronics, and Clothing.
- Added eight high-resolution five-state source masters under `assets/concepts/producer_states/`.
- Selected images are pixel-faithful normal-state derivatives with restrained amber/olive rim emphasis. Other states use visible physical operation, depletion, empty storage, and restocking/repair rather than tint-only feedback.
- One standalone Workshop Bench selected attempt was rejected for changing tool placement and was not retained.
- Alpha and full-resolution review: `docs/producer-state-captures/producer_states_contact_sheet.png`; actual 68px board-scale review: `producer_states_board_scale_68px.png`.

### Validation and compatibility

- All 40 files validate as RGBA 256x256 with transparent corners and controlled subject coverage. Chroma-edge fragments were removed before approval.
- Empty-cache Godot 4.3 rebuilt 1,818 artifacts, then exited with Windows access-violation code `-1073741819` during shutdown; immediate verbose reconciliation exited 0 with zero critical import/resource signatures. All 33 smoke scenes pass and the aggregate critical-log scan is clean.
- No gameplay or integration code, item/producer data, balance, IDs, saves, navigation, animation timing, or audio changed.
- Artwork remains deliberately unintegrated: `scripts/merge/item_view.gd` still special-cases Construction states. Integration and all remaining coding are specified in `docs/CLAUDE_HANDOVER_2026-08-03.md`.
- Detailed batch evidence: `docs/production-batches/26_remaining_producer_state_artwork.md`.

### Exact next phase

- Claude should generalize producer state texture resolution, add focused all-producer state tests, run clean import and all 33 smoke scenes, capture live states, document, commit separately, and push to `origin/visual-production`.

## 2026-08-03 — Unified residence and merge home

### Starting commit and objective

- Starting commit: `c15b375` on `visual-production`.
- Objective: make all five illustrated residences, their repair hotspots, and their isolated 7x9 boards one persistent Home screen, eliminating Merge as a separate player-facing destination without changing gameplay or saves.

### Implementation

- Added reusable `scenes/merge_board/board_panel.tscn` and embedded it in Hollow Creek, Redwater, Greybridge, Saint Mercy, and Northgate. Each residence activates its own `BoardState` payload before the embedded controller initializes.
- Board cells use an embedded translucent presentation so the residence remains the room underneath the grid; items remain opaque and readable. Hotspots coexist above the cells while empty overlay space passes pointer input through to board gameplay.
- Repair requirements now open in place. **Find on Board** highlights the requested chain in the local embedded board instead of navigating away.
- Removed Merge from bottom navigation, the public scene route table, and scene-specific audio routing. Haven returns to the profile's current residence. The old standalone scene remains unreachable as an internal compatibility/test harness only.
- Corrected the task modal's deferred viewport bounds after a real 720x1600 capture exposed an oversized CanvasLayer center container; the complete Find/Complete/Close card is now centered and accessible.
- Assets created/rejected, animations, and audio assets: none. Six real OpenGL 720x1600 captures document all five residences and the in-place task flow under `docs/ui-skin-captures/`.
- Files and detailed evidence: the five residence scenes/controllers, merge board/panel and cell presentation, bottom navigation/router/audio presentation, task panel, survivor task routing, updated smoke/capture tests, and `docs/production-batches/25_unified_residence_merge_home.md`.

### Verification

- Empty-cache Godot 4.3 rebuild completed with 1,722 imported artifacts; its long-running process exceeded the two-minute output wrapper, then an immediate verbose reconciliation import exited 0.
- Full smoke suite: 33/33 pass.
- Android exported-runtime resource contract: pass for both presets and all catalog totals.
- Critical log scan found zero parser, missing-resource, invalid-call, audio-catalog, save, import, shader, or texture failure signatures.
- Focused structural checks pass at 720x1600, reference/default portrait, and 1440x3200. Runtime captures confirm all five backgrounds, 63-cell boards, hotspots, four-tab navigation, and the in-place task modal.

### Compatibility, known issues, and exact next phase

- No merge rule, producer behavior, board/save payload, save key/schema, content ID, quest/hotspot gate, economy value, story outcome, character, or vehicle data changed.
- Android device install/layout evidence remains for the packaged verification batch; these captures use the real OpenGL renderer in desktop windows at Android portrait dimensions.
- Next: add data-driven cash-out rewards at multiple levels of the nine gameplay chains, with covered/cobwebbed items excluded and all existing task/story uses preserved.

## 2026-08-01 — Android export dependency audit checkpoint

### Starting commit and objective

- Starting commit: `781c27c` on `visual-production`.
- Objective: replace the broad Android export with audited shipping and verification presets, prove dynamically loaded content survives packing, preserve version-code-1 save data, and prepare a debug-signed version-code-2 playtest package.

### Assets and files

- Promoted the live farmhouse-approach dialogue painting from the excluded concepts tree to `assets/art/dialogue/runtime/intro_farmhouse_approach.png`; no new or rejected artwork.
- Added `scripts/data/packed_directory.gd` and updated the six catalog autoloads so Godot PCK `.tres.remap` directory entries resolve to their canonical `.tres` paths.
- Added `Android` (arm64) and `Android Verification` (arm64 plus x86_64) version-code-2 presets with explicit runtime includes and audited development/source exclusions.
- Corrected `project.godot` from the string `"portrait"` to Godot 4.3's integer orientation enum `1`. The generated Android manifest now says `screenOrientation="portrait"`.
- Added `tests/android_export_resource_test.gd/.tscn`, updated the dialogue presentation assertion for the promoted runtime filename, and captured prior upgrade evidence under `docs/android-export-captures/`.
- Detailed evidence: `docs/production-batches/21_android_export_audit.md`.
- Visual states, animations, audio assets, gameplay values, identifiers, and save schema: unchanged.

### Export, install, and optimisation evidence

- Filtered export tree: 2,179 files, 163,664,357 bytes; all expected catalog remaps and 13 chain JSON files present.
- Earlier v2 verification install loaded complete runtime catalogs and upgraded the v1 representative save without clearing data. Canonical `files/saves/slot1.json` retained SHA-256 `dccf7b2030d7b4113b2c0c108d60d6d79877d5f45f74506d868d2fffd5c33abf`.
- Regenerated portrait verification APK is stored outside Git at `S:\Rob B\Codex\B\Codex\godot-4.3\artifacts\batch3-export-audit\dead-haven-v2-debug-verification-portrait.apk`.
- APK size: 315,345,644 bytes; SHA-256 `ED06DF7387B7DC091D16CED5E60E2A980A0F517852674DF37E7EDBA212891CA1`.
- Debug certificate SHA-256 `1fba3d732cbc32351fb7e67e69044aeed0d27d1a84fc680fec79ffc7eb2b9f94`, matching the v1 baseline. No credential is tracked.
- Packaging excludes non-runtime material but the APK remains above the final 200 MB target; texture/audio optimisation remains Batch 4 work.

### Tests run

- Clean Godot 4.3 headless import from a new cache: pass.
- Focused Android export resource test: pass with both presets and catalog totals 101 items, 13 chains, 6 characters, 5 residences, 42 quests, 23 dialogue entries, 10 scavenging locations, and 1 vehicle.
- Dialogue presentation focused rerun: pass.
- All non-audio smoke scenes: 32/32 pass.
- Audio presentation: pass on its first isolated rerun; the same pre-existing headless playback-start timing check failed in the rapid final 33-scene loop, leaving that loop at 32/33. This checkpoint is deliberately not described as a final 33/33 acceptance build.

### Known issues and exact next phase

- Godot's Gradle wrapper did not return promptly after generating the complete export tree. Direct Gradle assembly succeeded and the resulting APK verifies, but the newly rebuilt portrait artifact has not yet been installed on the emulator.
- Next: install the portrait v2 APK over the retained v1/v2 data, verify portrait presentation and canonical save persistence, make the headless audio test deterministic enough for a clean 33/33 loop, then produce the arm64-only playtest APK and begin texture/audio/memory optimisation.

---

## 2026-08-01 — Strict-quality Batch 1: final Android launcher identity

### Starting commit

`b79ae07a6d0d7847fdfc10a9c4cb5bf251bc2ed3` on `visual-production`.

### Batch objective

Replace every Android launcher fallback with one original painterly safe-haven identity, including legacy, adaptive foreground/background, and Android 13 monochrome presentation, while preserving gameplay and save compatibility.

### Assets created

- Three reviewed 1024×1024 source masters under `assets/branding/android/source/`.
- Opaque 512×512 main launcher, transparent 432×432 adaptive foreground, opaque 432×432 adaptive background, and 432×432 monochrome layer.
- Deterministic launcher build/review script and mask/48-pixel evidence captures.
- Density-specific Android monochrome resources and adaptive XML overlay.

### Assets rejected

- The first automated chroma-key conversion was rejected for visible green/teal edge spill. It was replaced by the deterministic dominance/despill conversion and was not retained in a runtime path.
- The first detail-derived monochrome mask was rejected after the installed themed-icon review because its timber gaps read like a letter at dock size. It was replaced with the authored fortified-doorway silhouette.

### Files modified

- `.gitignore`, `project.godot`, and `export_presets.cfg`.
- `assets/branding/android/`, `android/build/res/`, `tools/build_android_launcher_assets.ps1`.
- `tests/android_launcher_asset_test.gd` and `.tscn`.
- `docs/android-launcher-captures/` and `docs/production-batches/19_android_launcher_identity.md`.

### Visual states added

- Legacy full-square, adaptive color, themed monochrome light, and themed monochrome dark launcher presentations.

### Animations and audio

- None. This batch changes branding presentation only.

### Optimisation changes

- Runtime launcher files are right-sized; editable 1024×1024 masters remain separate from the runtime paths.

### Tests and evidence

- Full-resolution, transparency, adjacent-layer, actual 48-pixel, adaptive-mask, and installed Pixel 9 reviews completed.
- Focused launcher asset/configuration test passes.
- Matching Godot 4.3.stable clean headless import passes.
- All 33 `tests/smoke_test*.tscn` scenes pass; output scan finds no parser, missing-resource, invalid-call, orphan-node, audio-catalog, save, import, shader, or texture failures.
- Debug-signed version-code-1 artifact installs as `com.deadhaven.mergeandsurvive`; signing certificate matches the baseline debug certificate.
- Evidence paths are recorded in `docs/production-batches/19_android_launcher_identity.md`.

### Known issues

- Godot 4.3.stable does not itself emit Android's monochrome adaptive-icon element. The tracked Gradle resource overlay supplies the authored layer and APK inspection proves it is packaged.
- The exact-final zero-cache importer suffered one native Godot 4.3 access violation after 5m51s on the network workspace. Resuming that same empty-origin import completed with exit 0, the focused test passed, and the subsequent full suite passed 33/33. An earlier independent zero-cache import also completed with exit 0.
- The first exact-final suite run saw one transient headless audio timing failure. The unchanged audio test then passed three consecutive isolated reruns and the complete 33-scene rerun passed cleanly.
- The baseline broad-resource export and packed-build dynamic catalog enumeration defect are unchanged and remain the next audited build task.

### Remaining placeholders

- Producer state sets, chain-specific merge effects, environment/danger effects, and verified procedural fallbacks remain for their approved later batches. No launcher fallback remains.

### Exact next phase

Batch 2/3: formalise the debug-signed Android verification presets and audit every dynamic runtime dependency so version-code-2 exports include required catalogs while excluding source/development content.

## 2026-08-01 — Strict-quality Batch 2: Android debug toolchain and baseline

### Starting commit

`9d3c7b5` on `visual-production`.

### Batch objective

Lock the approved debug-signing policy, verify the matching Godot 4.3/JDK 17/Android toolchain, and preserve an exact version-code-1 upgrade source without committing an APK, keystore, or secret.

### Assets created or rejected

- No presentation assets were created or rejected. This is a build-verification batch.

### Files modified

- Added `tools/verify_android_debug_toolchain.ps1`.
- Added `docs/production-batches/20_android_debug_baseline.md`.
- Updated `DEVELOPMENT_LOG.md`.

### Visual states, animation, audio, and optimisation

- No runtime changes. Gameplay, saves, presentation, animation, audio, and resource imports are unchanged.

### Tests and evidence

- Verified Godot `4.3.stable.official.77dcf97d8`, matching templates, OpenJDK 17, Android SDK/build tools, Pixel 9 AVD, and Godot debug keystore.
- Verified the external v1 APK package/version/ABIs, APK SHA-256, and debug-certificate SHA-256.
- Verified the representative installed save SHA-256 matches its external fixture.
- Clean import, focused launcher test, and all 33 smoke-test scenes pass for the unchanged runtime tree.

### Known issues and remaining placeholders

- The 373 MB baseline is intentionally unaudited and dynamically discovered catalogs are empty in the packed baseline. Both are carried directly into Batch 3.
- All presentation placeholders listed after Batch 1 remain unchanged.

### Exact next phase

Batch 3: audit static and dynamic resource dependencies, repair packed catalog discovery without changing IDs or save schema, and create separate arm64 shipping and arm64+x86_64 verification presets at version code 2.

---

## Steering reconciliation — data-driven Mara portraits (31 July 2026)

### Files modified

- `data/characters/mara_vale.tres`
- `scripts/ui/survivor_silhouette.gd`
- `tests/smoke_test_character_portraits.gd` / `.tscn`
- `tests/README.md`
- `README.md`
- `ART_ILLUSTRATION_CHECKLIST.md`
- `assets/manifests/asset_manifest.json`

### Features completed

- Registered Mara Vale's neutral, concerned and injured 512×512 transparent
  production portraits in the existing `SurvivorDefinition` dictionaries.
- Changed the existing portrait presenter to prefer registered character data,
  while preserving convention-based paths for already-integrated survivors.
- Restored a clean procedural survivor drawing solely as a defensive fallback
  when neither registered nor convention-based final art exists.
- Added test-visible state queries without changing character data, dialogue,
  recruitment, progression, navigation or save behaviour.
- Confirmed the merge board remains generated from the existing source-of-truth
  dimensions: 7 columns × 9 rows, with 63 runtime cells.

### Tests performed

- `tests/smoke_test_character_portraits.tscn` verifies all three registered Mara
  paths, final-art selection, the missing-asset fallback and the instantiated
  7×9 merge grid.
- Godot 4.3 headless editor/import startup completed with no script or parse
  errors.
- Full headless regression passed: all 20 `tests/smoke_test*.tscn` scenes
  emitted their expected success markers, including animation, audio, UI,
  merge, all residence/progression, save/reload and main-story coverage.

### Known issues

- Other survivors still resolve their integrated portraits through the existing
  filename convention rather than explicit `.tres` dictionaries. This is safe
  and tested indirectly by existing screen smoke tests, but explicit registration
  would make all character data equally self-describing.
- A physical Android device pass remains required for final GPU, touch, safe-area
  and audio-balance verification.

### Exact next phase

Register the remaining survivor portrait dictionaries without changing their
IDs or runtime presentation, then perform the physical-device Android QA pass
documented in the visual and audio production guides.

## Art Phase 2 (part 1): Vertical-slice concept batch - complete

### Files created

- `assets/concepts/vertical_slice/characters/mara_vale_character_sheet_concept.png`
- `assets/concepts/vertical_slice/characters/noah_vance_character_sheet_concept.png`
- `assets/concepts/vertical_slice/enemies/drifter_concept_sheet.png`
- `assets/concepts/vertical_slice/environments/hollow_creek_stage_1_concept.png`
- `assets/concepts/vertical_slice/environments/hollow_creek_stage_2_concept.png`
- `assets/concepts/vertical_slice/items/construction_chain_concept.png`
- `assets/concepts/vertical_slice/items/salvaged_tool_crate_states_concept.png`
- `assets/concepts/vertical_slice/animation/window_boarding_storyboard_concept.png`
- `assets/concepts/vertical_slice/dialogue/intro_farmhouse_approach_concept.png`
- Godot-generated `.png.import` sidecars for each of the nine PNGs above

### Files modified

- `README.md`
- `ART_ASSET_GUIDE.md`
- `ART_GENERATION_PROMPTS.md`
- `ART_ILLUSTRATION_CHECKLIST.md`
- `assets/manifests/asset_manifest.json`
- `DEVELOPMENT_LOG.md`

`data/README.md` and `tests/README.md` are unchanged because this art-only
unit adds no game-data resources and no tests; their existing content
counts remain accurate.

### Features completed

- Produced and visually reviewed nine original flattened concepts from
  the vertical-slice prompt set: two survivor sheets, one Hollow sheet,
  two matched farmhouse states, one eight-level item-chain sheet, one
  six-state producer sheet, one ten-panel repair storyboard, and one
  intro dialogue composition.
- Used the accepted Mara and farmhouse concepts as explicit references
  for the storyboard and intro composition so character, building, and
  lighting identity remain coherent across assets.
- Recorded every accepted concept separately in manifest version 3 with
  its actual file dimensions, generation source, and `approved` status.
- Kept all runtime replacement checkboxes open. None of these images is
  layered, transparent, sliced, optimised, or wired into a Godot scene,
  so every existing procedural placeholder remains the live visual.
- Rejected both merge-board generation attempts instead of storing them:
  the first rendered a 7x10 grid and the correction rendered 6x9, while
  gameplay requires exactly 7x9.

### Tests performed

- Downloaded the official Godot 4.3 stable Windows build to the local
  Codex tools directory and verified
  `4.3.stable.official.77dcf97d8`.
- Confirmed the repository had no existing `.godot` directory, then ran
  a clean headless import. It completed with no parse or import errors.
- Parsed `assets/manifests/asset_manifest.json` successfully after the
  version-3 update: 25 total entries, including 9 approved concept
  entries.
- Read every stored PNG's actual metadata and corrected the manifest to
  match those dimensions.
- Ran the full 14-scene smoke suite with an independent 30-second timeout
  per test. All 14 printed their expected `SMOKE_*_OK` line and exited 0.
  The save test's deliberate corrupt-primary-file case printed its
  expected JSON parse and backup-fallback warnings, then passed.

### Known issues

- These are approved direction concepts, not production assets. The
  character sheets lack separated rig layers and transparent portrait
  crops; environment/dialogue images lack parallax and hotspot layers;
  item/producer sheets lack individually sliced transparent icons; and
  the storyboard is not an implemented animation.
- The generated environment work leans toward detailed stylised realism
  at the realistic end of the project's intended 2.5D range. It should be
  checked on a real phone before mass-producing further environments.
- The exact 7x9 merge-board concept remains unresolved. Image generation
  was unreliable for exact grid geometry, so its frame/grid should be
  built deterministically and any generated texture/state art composited
  around that structure.
- No concept in this phase has been visually tested inside the running
  game. Headless import confirms the PNGs are valid Godot resources, not
  that they work at phone scale or under live UI.
- Real audio, an Android export/device pass, the Ashborn/Eli continuation,
  and the remaining illustration checklist are still open.

### Exact next phase

Art Phase 2 part 2 should turn one accepted concept into a complete
runtime proof rather than generating more flattened sheets. The best
first target is Mara: produce transparent neutral/concerned/injured
portrait crops with consistent identity, register them in
`data/characters/mara_vale.tres`, teach the survivor roster/dialogue UI
to prefer real portrait textures with `SurvivorSilhouette` as fallback,
and add a headless resource/fallback smoke test. In parallel with that
asset path, build the merge board's 7x9 geometry deterministically rather
than asking image generation to count cells.

---

## Phase 2: Merge board - complete

### Files created

Item content: 101 `ItemDefinition` resources under `data/items/` (9 gameplay
chains from the design spec - Construction 8 levels + Tool/Food/Medical/Trap/
Fuel/Vehicle Parts/Electronics/Clothing at 7 levels each, one producer per
chain = 73 resources; plus 4 reward chains - Energy/Coins/XP/Haven Tokens at
7 levels each, no producer = 28 resources), and 13 chain-summary
`data/chains/*.json` files (grouping metadata: item id order, producer id,
task tags, and for reward chains the resource they grant and its
per-level value). Generated by a one-time script run through the Godot
binary and then deleted per `data/README.md`'s "content lives here as data"
rule - the `.tres`/`.json` files are the real, directly-editable content
going forward, nothing regenerates them.

New autoloads: `autoload/item_database.gd` (loads/indexes every item and
chain at startup), `autoload/board_state.gd` (owns every `BoardItem`, the
grid, storage, merge/producer/delete rules, and the board's save format).

Merge board runtime: `scripts/merge/item_icon_renderer.gd` (procedural
placeholder icon per item - category silhouette + rarity colour + level/
producer/cooldown/lock/cobweb/bubble overlays, one reusable renderer
instead of 101 bespoke drawings), `scripts/merge/item_view.gd` (interactive
per-item Control: draws itself, handles tap/double-tap/long-press/drag),
`scripts/merge/board_cell.gd` (one grid cell, Godot drag-and-drop target),
`scripts/merge/chain_legend_icon.gd` (tappable chain swatch for the
highlight legend).

Merge board UI: `scenes/ui/item_info_panel.tscn`/`.gd` (tap-for-info /
long-press-for-detail, same panel with extra actions in detail mode),
`scenes/ui/storage_panel.tscn`/`.gd` (bottom drawer, not a full-screen
modal, so the board stays reachable for drag-drop while it's open),
`scenes/ui/discovery_banner.tscn`/`.gd`.

Tests: `tests/smoke_test_merge.gd`/`.tscn`.

### Files modified

- `project.godot` - registered `ItemDatabase` and `BoardState` autoloads.
- `autoload/event_bus.gd` - added board_item_added/moved/removed,
  items_merged, item_discovered, producer_activated signals.
- `autoload/game_manager.gd` - energy regen (1 energy / 3 min, configurable
  `ENERGY_REGEN_INTERVAL_SECONDS`; also catches up while the app was
  closed, capped so a clock jump can't be exploited), `debug_infinite_energy`
  flag + `set_debug_infinite_energy()`/`debug_instant_recharge()`/
  `debug_reset_all_cooldowns()`, `to_save_data()`/`apply_save_data()` now
  include `BoardState`'s save block, `new_game()` calls
  `BoardState.reset_new_board()`.
- `scenes/merge_board/merge_board.gd`/`.tscn` - full rewrite: real 7x9 grid
  of `BoardCell`s, chain-highlight legend, storage button/drawer, item info
  panel, discovery banner, merge/pop/shake animation feedback.
- `scenes/dev_diagnostics/dev_diagnostics.gd`/`.tscn` - "Add Any Item" and
  the energy debug tools are now real (see Known issues in Phase 1 for what
  they replaced); added infinite-energy toggle and reset-cooldowns.
- `tests/smoke_test_save.gd` - the hardcoded expected coin total (373) broke
  because the Phase 2 starting board now grants first-discovery coin
  rewards for the 9 starter producers; fixed to assert against a baseline
  captured after `new_game()` instead of a hardcoded absolute number, which
  is the correct fix (the old assumption was fragile, not the new
  behaviour wrong).

### Features completed

- **Grid + drag-and-drop**: real 7x9 board using Godot's built-in Control
  drag-and-drop (`_get_drag_data`/`_can_drop_data`/`_drop_data`), works with
  the existing `emulate_mouse_from_touch` default so the same code path
  covers desktop mouse and Android touch.
- **Merge rules**: identical chain + identical level -> next level, enforced
  in `BoardState.try_merge()`. Producers never merge. Max-level items reject
  merging (`is_max_level` in the result) rather than crashing.
- **Producers**: all 9 chain producers placed on the board from the start
  (Phase 2 has no producer-unlock gating yet - see Known issues). Tap costs
  1 energy (spec-specified), enforces a 30s cooldown per producer
  (configurable per-item via `producer_cooldown_seconds`), spawns the
  chain's level-1 item into the first empty cell. Exhausted/on-cooldown/
  no-energy/board-full all fail with a distinct reason the UI turns into a
  toast rather than the tap silently doing nothing.
- **Energy**: 100 max, ticks up 1 per 3 minutes online, catches up offline
  time on load (capped), `spend_energy()`/`add_energy()` from Phase 1
  extended with a debug infinite-energy mode that never depletes.
- **Storage**: 30-slot capacity (configurable), a bottom drawer (not a
  modal) so items can be dragged directly from storage onto the board or
  vice versa; "Move to Storage"/"Move to Board" also available from the
  item detail panel.
- **Item information**: tap opens a compact info panel (name, description,
  rarity, level/max level, sell value); long-press opens the same panel
  with actions attached (Collect for reward-chain items, Move to Storage/
  Board, Delete).
- **Task highlighting (interim)**: no residence tasks exist yet (Phase 3),
  so this phase implements the mechanical half honestly - a chain-highlight
  legend row lets the player tap a chain swatch to dim every non-matching
  item on the board. Phase 3's real "tap a task marker" will call the same
  highlight function once task data exists.
- **Deletion with undo**: any non-producer item can be soft-deleted
  (removed immediately) and restored via `undo_delete()` within a 5-second
  window; rare-or-better items require confirmation first
  (`requires_delete_confirmation()`, backed by a real `ConfirmationDialog`).
- **Reward-chain collection**: the Energy/Coins/XP/Haven Tokens chains from
  spec section 7 ("Energy items may be merged into stronger energy items")
  merge exactly like any other chain, but instead of feeding a residence
  task, tapping Collect on one grants the scaled resource amount directly
  and consumes the item.
- **Animations**: scale-in "pop" on move/producer-spawn/merge-result,
  squash-ish overshoot via `TRANS_BACK` easing, a fading expanding-ring
  burst on successful merges, a left-right shake on rejected merge attempts,
  a slide-in/fade discovery banner. All skip/shorten under the existing
  `reduced_motion` setting.
- **Discovery rewards**: first-time pickup of any of the 101 items grants
  its `discovery_reward` (coins scaling with level; energy for level 3+
  chain items; every producer grants a flat coin bonus) exactly once,
  tracked in `BoardState.discovered_item_ids` and persisted.
- **Debug tools**: infinite-energy toggle, instant recharge, +20 energy,
  reset all producer cooldowns, add a random item to the board, +500 coins,
  +1 level, reset save - all real, all still gated behind
  `OS.is_debug_build()`.

### Tests performed

Re-ran the full existing headless suite plus a new one, via the same Godot
4.3.stable Linux binary approach as Phase 1 (downloaded fresh into this
container - it is not persisted between sessions, see Known issues):

- `godot4 --headless --path . --import` - clean, zero script/parse errors
  across the full project including all 101 new `.tres` resources.
- `tests/smoke_test.tscn` - still instantiates every screen (including the
  rewritten Merge Board) with no runtime error.
- `tests/smoke_test_save.tscn` - still passes after the delta-based fix
  described above.
- `tests/smoke_test_settings.tscn` - unaffected, still passes.
- `tests/smoke_test_merge.tscn` (new) - starting layout (11 items: 9
  producers + 2 starter items); a valid merge with correct discovery
  reward; merging two producers and merging mismatched chains both
  correctly rejected; merging two max-level items correctly rejected;
  producer tap spends energy and enforces cooldown, `debug_reset_all_
  cooldowns()` clears it; `debug_infinite_energy` spends without
  deducting; storage transfer round-trip; soft-delete + undo; reward-chain
  collection grants the right amount; full save -> reload round trip
  verifies item count, storage, and discovery state all persisted
  correctly.

This is real verification of merge/producer/energy/storage/delete/save
logic, not a claim about how it feels to actually play - see Known issues
and `tests/PHASE1_MANUAL_CHECKLIST.md`'s successor (not yet written for
Phase 2, tracked below) for what still needs a real screen.

### Known issues

- **Not visually confirmed**, same as Phase 1 - headless mode has no window.
  Drag gesture feel, icon readability at real board-cell size, and
  animation timing all need a real device or the editor's game view.
- **No manual test checklist yet for Phase 2** - `tests/PHASE1_MANUAL_CHECKLIST.md`
  covers Phase 1 screens only; a `PHASE2_MANUAL_CHECKLIST.md` covering
  drag/merge/producer/storage gestures on a real touchscreen should be
  written alongside the next phase that touches this screen.
- **All 9 producers start unlocked** - there is no producer-gating/unlock
  system yet because that's tied to residence milestones and quests, which
  don't exist until Phase 3+. Every producer sits on the board from turn
  one. This is scoped correctly for Phase 2 in isolation, not a bug, but
  it means the board will need a "some producers start locked/off-board"
  pass once quest gating exists.
- **Placeholder icons are procedural, not per-asset files** - `icon_path` on
  every `ItemDefinition` already points at the *intended final* PNG path
  (e.g. `res://assets/items/construction/level_3.png`), but no such files
  exist; `ItemIconRenderer` draws a category+rarity+level placeholder
  entirely in code instead. Swapping in real art means dropping PNGs at
  those paths and pointing `ItemView` at them instead of the renderer - no
  gameplay code changes required, but that swap-over code doesn't exist
  yet (`ItemView` always uses the renderer right now).
- **No true pre-merge slide animation.** Spec describes items moving toward
  each other before merging; this phase merges state instantly and animates
  the *result* item scaling in plus a burst effect at the target cell,
  which is simpler to get right within this phase's scope and still reads
  as "something happened" - a true two-item slide-together is left as
  polish, not core logic.
- **No item-picker UI for "Add Any Item"** - the dev-diagnostics button
  spawns a uniformly random item from all 101 rather than letting you pick
  one; picking a specific id is possible from the Godot remote debugger or
  a future picker UI, not from this button.
- **`export_presets.cfg` still hand-written** - unchanged from Phase 1,
  still flagged there as needing regeneration from a real Export dialog.
- **Godot binary is not persisted** - like Phase 1, this environment has no
  package manager entry for Godot; it was downloaded fresh from
  `github.com/godotengine/godot` releases into this container for testing
  and will need to be re-downloaded (or installed properly) in any future
  session that needs to run these tests again.

### Exact next phase

**Phase 3: Residence system** - build the real Hollow Creek Farmhouse
scene (currently `scenes/haven/` is Phase 1's placeholder exterior with
inert hotspots): repair hotspots that actually require specific merge-board
items (via `task_tags`) and consume them on completion, multi-state visual
transitions per hotspot (destroyed -> cleared -> under repair -> completed
-> upgraded), construction animations, and the first residence milestones
from the design spec (secure the front door, board the kitchen windows,
etc.). This is also where the chain-highlight legend from this phase
becomes real task highlighting - a task references a `chain_id`/`task_tags`
requirement, and "tap a task marker" calls the same
`_on_legend_tapped`-style highlight this phase already built.

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the Phase 2 merge board smoke test
godot4 --headless --path /path/to/dead-haven-merge-survive tests/smoke_test_merge.tscn

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## Phase 3: Residence system - complete

### Files created

Content: `data/residences/hollow_creek_farmhouse.tres` (`ResidenceDefinition`
with 9 `ResidenceHotspot` sub-resources), 9 `data/quests/q_*.tres`
(`QuestDefinition`) - one per Hollow Creek Farmhouse milestone from the
design spec section 9 (front door, kitchen windows, living room, fireplace,
pantry, rescue Noah, barn, rear escape, perimeter traps). Generated once by
a script run through the Godot binary and deleted, same pattern as Phase
2's item content.

New autoload: `autoload/residence_manager.gd` (loads residence/quest
content, owns hotspot-state and quest-completion runtime state, checks/
consumes merge-board item requirements, grants rewards including the
`unlock_survivor` special-case).

Residence UI: `scripts/residence/hotspot_visual.gd` (one procedurally-drawn
before/after patch per hotspot, distinct shape per area, a repair-burst
animation on completion), `scenes/ui/task_panel.gd`/`.tscn` (tap a hotspot
-> task name/description/required item with owned-vs-needed count/reward
-> Complete, or Find on Board to jump to the Merge Board with the right
chain highlighted).

Tests: `tests/smoke_test_residence.gd`/`.tscn`.

### Files modified

- `project.godot` - registered the `ResidenceManager` autoload.
- `autoload/event_bus.gd` - added hotspot_state_changed, quest_completed,
  survivor_unlocked signals.
- `autoload/game_manager.gd` - `profile.unlocked_survivor_ids`,
  `unlock_survivor()`/`is_survivor_unlocked()`; `new_game()` now also
  calls `ResidenceManager.reset_new_game()`; save data now includes
  `ResidenceManager`'s block.
- `autoload/board_state.gd` - `count_item()`/`consume_item()`, so
  ResidenceManager can check and spend merge-board items without reaching
  into BoardState's internals.
- `scenes/haven/haven.gd`/`.tscn` - full rewrite: hotspots are now built
  from `ResidenceManager.get_residence()` data instead of 3 hardcoded inert
  buttons; added a repair-progress label.
- `scenes/merge_board/merge_board.gd` - reads a `highlight_chain_id` param
  from `SceneRouter.take_pending_params()` on `_ready()`, so "Find on
  Board" from a task panel lands with the right chain already highlighted
  - this is Phase 2's chain-highlight legend becoming the real task
  highlighting the spec describes.
- `scenes/survivors/survivors.gd` - Noah's locked state now reads
  `GameManager.is_survivor_unlocked("noah_vance")` instead of a hardcoded
  `true`; every other roster entry is still hardcoded-locked pending Phase
  6's real recruitment system.

### Features completed

- **Real repair hotspots**: 9 hotspots on Hollow Creek Farmhouse, each
  backed by a `ResidenceHotspot` + one `QuestDefinition`, each requiring a
  specific merge-board item (spread across 5 of the 9 chains - Construction
  x4, Tool x2, Food x1, Medical x1, Trap x1 - so the milestone chain
  exercises most of Phase 2's content rather than just one chain).
- **Visual state change, not just a label**: every hotspot draws its own
  distinct damaged-vs-fixed patch (`HotspotVisual`) - a boarded/cracked
  door vs. a solid one, broken vs. intact window panes, debris vs. a couch,
  a cold vs. lit fireplace, and so on - plus a small dust-burst animation
  played on completion (spec: hammering/dust/sparks - simplified to a
  reusable particle burst rather than distinct SFX/VFX per hotspot type,
  see Known issues).
- **Task panel**: tap a hotspot -> see its title, description, required
  item (with a live owned/needed count via `BoardState.count_item()`), and
  reward preview. Complete is disabled until the requirement is met;
  "Find on Board" routes to the Merge Board with the exact chain
  highlighted instead of leaving the player to guess.
- **Item consumption**: completing a task actually removes the required
  item from storage/board (`BoardState.consume_item()`), not just a
  cosmetic check - the item is genuinely spent.
- **Rewards**: coins + XP per milestone, tuned roughly to milestone
  significance (30-60 range); the "Someone's Upstairs" milestone (spec
  milestone 6, "Save survivor Noah Vance") additionally unlocks Noah in
  the Survivors roster via a generic `unlock_survivor` reward key - reusing
  Phase 1's roster screen with a real state change instead of building a
  new one.
- **Duplicate-completion prevention**: `try_complete_quest()` on an
  already-completed quest fails with `already_complete` rather than
  double-granting rewards or re-consuming items.
- **Save/reload**: hotspot states, completed quest ids, and the Noah
  unlock all persist and reload correctly (see Tests performed).

### Tests performed

Same headless-binary approach as Phases 1-2 (binary downloaded fresh into
this container, not persisted - see Known issues):

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- `tests/smoke_test.tscn` - still instantiates every screen including the
  rewritten Haven with no runtime error.
- `tests/smoke_test_save.tscn`, `tests/smoke_test_settings.tscn`,
  `tests/smoke_test_merge.tscn` - all still pass, no regressions from the
  Phase 3 additions.
- `tests/smoke_test_residence.tscn` (new) - residence/hotspot/quest data
  loads with the expected shape; a task correctly refuses to complete
  before its required item exists; spawning the item and completing the
  task consumes it, grants coins/XP, and flips the hotspot to COMPLETED;
  completing the same quest again is correctly rejected; completing
  `q_rescue_noah` unlocks `noah_vance` via the generic reward path;
  `get_active_quest_for_hotspot()` correctly returns null once a hotspot's
  only task is done; a full save -> reload round trip preserves completed
  quests, hotspot state, and the Noah unlock.

### Known issues

- **Not visually confirmed**, same caveat as every phase so far - headless
  mode has no window. Hotspot tap-target size/spacing on the actual
  background art, and whether the 9 marker positions read clearly against
  the Phase 1 procedural background, need a real screen.
- **Two-state hotspots, not five.** `ResidenceHotspot.State` defines
  DESTROYED/PARTIALLY_CLEARED/UNDER_REPAIR/COMPLETED/UPGRADED; Phase 3
  only ever uses DESTROYED and COMPLETED (a hotspot flips straight from
  one to the other when its single linked quest finishes). The other three
  states exist in the schema for hotspots with more than one sequential
  task - none of Hollow Creek Farmhouse's hotspots need that yet, but a
  later residence (or an "upgrade" pass on this one) can use
  `required_task_ids` with more than one entry without any data-model
  changes.
- **One shared repair-burst effect for every hotspot type**, not distinct
  hammering/sawing/dust/spark animations per repair type as spec section
  21 lists - reusing Phase 2's merge-burst pattern was the pragmatic choice
  within this phase's scope; per-hotspot animation variety is a polish-pass
  candidate.
- **Milestone 10 ("Survive the first night attack") is not in this
  phase.** It's explicitly Phase 7's defence-event system per the
  design spec's own phase breakdown; Hollow Creek Farmhouse's 9 completable
  hotspots here cover milestones 1-9. The residence won't show as fully
  "complete" until Phase 7 adds the tenth.
- **Noah's rescue has no dialogue scene** - completing `q_rescue_noah`
  unlocks him via a toast ("Repaired!", same as any other task) rather
  than the story beat described in the design spec ("Noises are heard
  inside... Player chooses whether to trust him"). The real dialogue
  engine is Phase 4; wiring `dialogue_trigger_id` (already a field on
  `QuestDefinition`, currently unset) to a real scene happens then.
- **World Map / residence-to-residence progression untouched.** Completing
  all 9 hotspots doesn't yet unlock Redwater Service Station or update the
  World Map - `ResidenceDefinition.completion_rewards` already has the
  intended keys (`unlocks: world_map`, `unlocks_residence`) but nothing
  reads them yet; that's Phase 8 ("Additional content") territory per the
  spec's own phase order, or an earlier pass once Phase 7's defence event
  makes the residence genuinely "done".
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 4: Story** - the dialogue engine (speaker/portrait/expression/
text/background/animation/sound/branching/conditions/rewards/relationship
changes/quest triggers per spec section 16), character portraits/
expressions (currently `SurvivorSilhouette` placeholders), and chapter
progression. This is also where Noah's rescue gets a real scene instead of
a toast, and where `QuestDefinition.dialogue_trigger_id` (unused since
Phase 1) becomes real.

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the Phase 2-4 smoke tests
godot4 --headless --path /path/to/dead-haven-merge-survive tests/smoke_test_merge.tscn
godot4 --headless --path /path/to/dead-haven-merge-survive tests/smoke_test_residence.tscn
godot4 --headless --path /path/to/dead-haven-merge-survive tests/smoke_test_dialogue.tscn

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## Phase 4: Story - complete (scoped to what Phases 1-3's systems support)

### Files created

Content: `data/dialogue/intro_01.tres`/`intro_02.tres`/`intro_03.tres` (the
Chapter 1 arrival beat) and `data/dialogue/noah_01.tres`/`noah_02.tres`/
`noah_03.tres` (the Chapter 2 Noah-rescue scene, `noah_03` branches into a
trust-or-wary choice). Generated once by a script run through the Godot
binary and deleted, same pattern as every phase's content so far.

New autoload: `autoload/dialogue_manager.gd` (loads `DialogueEntry`
content, `start_dialogue(id, return_scene_key)` is the one entry point
every trigger calls through).

New screen: `scenes/dialogue/dialogue.gd`/`.tscn` - renders one
`DialogueEntry` at a time (speaker name, a colour-coded `SurvivorSilhouette`
portrait, text), advances via `next_id` on tap, or shows branching-option
buttons that apply `reward` (same coins/xp/energy keys quest rewards use)
and `relationship_changes` (written into the new story-flags system, see
below) before continuing.

Tests: `tests/smoke_test_dialogue.gd`/`.tscn`.

### Files modified

- `project.godot` - registered `DialogueManager`; added the `"dialogue"`
  scene path to `SceneRouter.SCENE_PATHS`.
- `autoload/event_bus.gd` - added `chapter_changed`, `dialogue_finished`.
- `autoload/game_manager.gd` - `profile.current_chapter_id` /
  `profile.story_flags`, `set_story_flag()`/`get_story_flag()`/
  `advance_chapter()`. **Also fixed a pre-existing bug**: Phase 3's
  `unlocked_survivor_ids` field was only ever added to `new_game()`'s reset
  dict, not the outer `var profile` declaration (an `Edit` whose
  replacement text matched one indentation level but not the other) -
  harmless in practice since every real codepath calls `new_game()` or
  `apply_save_data()` before reading `profile`, but a latent crash risk
  for any future codepath that doesn't. Fixed to keep both copies in sync,
  and double-checked the new `current_chapter_id`/`story_flags` fields
  landed in both places this time.
- `autoload/residence_manager.gd` - `try_complete_quest()` now calls
  `GameManager.advance_chapter()` when `q_secure_front_door` completes.
- `scenes/ui/task_panel.gd` - if the completed quest has a
  `dialogue_trigger_id`, routes to that dialogue instead of the generic
  "Repaired!" toast (and skips the on-Haven repair-burst animation for
  that one hotspot, since the scene changes immediately - see Known
  issues).
- `scenes/haven/haven.gd`/`.tscn` - added a chapter-title label; launches
  `intro_01` on first arrival, guarded by `get_tree().current_scene == self`
  (see Known issues / bugs fixed below) and a `story_flags` seen-flag.
- `scenes/survivors/survivors.gd` - no functional change this phase, just
  along for the ride via the `profile` shape fix above.
- `data/quests/q_rescue_noah.tres` - `dialogue_trigger_id` set to
  `"noah_01"` (hand-edited, one field, rather than regenerating all 9 quest
  files through a restored generator script).

### Features completed

- **Real dialogue engine**: `DialogueEntry`'s full schema (speaker,
  portrait/expression key, text, branching options with reward/
  relationship_changes, linear `next_id` chaining) is genuinely
  interpreted, not just defined - the `condition` and `quest_trigger`
  fields exist and are read but unused by any current content (no
  dialogue yet needs to gate a choice or fire a quest from within itself),
  which is honestly noted rather than faked with placeholder logic.
- **Chapter 1 intro**: plays automatically the first time the player
  reaches Haven after starting a new game, framing the radio message and
  the merge board.
- **Chapter 2 - Noah's rescue**: completing the "Someone's Upstairs" task
  (spec milestone 6) now plays a real 3-beat scene instead of a toast, and
  ends on a genuine choice - "offer him a place here" (+20 coins, sets
  story flag `noah_trusted = true`) vs. "keep him at a distance" (no bonus,
  `noah_trusted = false`). Both options still rescue him (unlocking him in
  the roster stays a guaranteed reward of completing the underlying quest,
  matching the design spec's milestone wording literally - the choice
  flavors the outcome, it doesn't gate it).
- **Chapter progression**: `GameManager.profile.current_chapter_id`
  advances from "The Open Door" to "Someone Upstairs" when the front door
  is secured (spec: that's exactly where the design doc's own chapter
  break falls), shown on Haven's header. It does not advance further -
  see Known issues.
- **Lightweight relationship placeholder**: `GameManager.story_flags` lets
  a dialogue choice have a real, persisted consequence (`noah_trusted`)
  without inventing a numeric trust/friendship/rivalry model that nothing
  else reads yet - Phase 6 is where a real relationship system with actual
  mechanical effects belongs.

### Tests performed

Same headless-binary approach as every phase so far:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- **A real regression was caught and fixed during this phase**:
  `tests/smoke_test.tscn` hung indefinitely after the Haven intro-dialogue
  change, because `Haven._ready()` called `SceneRouter.start_dialogue()`
  -> `get_tree().change_scene_to_file()` unconditionally, including when
  `smoke_test.gd` instantiates Haven as a plain child (deliberately not
  via `SceneRouter`) to inspect it - which ripped the active scene tree
  out from under the running test. Fixed by gating the auto-launch on
  `get_tree().current_scene == self`, i.e. only firing when Haven is
  genuinely the tree's active scene. Re-ran with a hard `timeout` wrapper
  afterward to confirm it no longer hangs before trusting a clean pass
  again.
- `tests/smoke_test.tscn`, `tests/smoke_test_save.tscn`,
  `tests/smoke_test_settings.tscn`, `tests/smoke_test_merge.tscn`,
  `tests/smoke_test_residence.tscn` - all still pass after the fix above,
  no other regressions.
- `tests/smoke_test_dialogue.tscn` (new) - the intro chain's `next_id`
  links resolve in order and end correctly; `q_rescue_noah`'s
  `dialogue_trigger_id` and `noah_03`'s two branching options are wired as
  expected; applying a branching choice's effects grants the right coin
  reward and sets the right story flag; completing the front-door quest
  advances the chapter exactly once (re-advancing to the same chapter is
  a verified no-op); a full save/reload round trip preserves the chapter
  and the story flag.

### Known issues

- **Not visually confirmed**, same caveat as every phase. Text pacing,
  portrait sizing, and whether tap-to-advance feels responsive all need a
  real screen.
- **Chapters 3-5 don't exist yet.** The design spec's own chapter
  breakdown needs a scavenging mission (Ch. 3, Phase 5), a defence event
  and a discovered radio message (Ch. 4, Phase 7), and a repaired vehicle
  plus World Map unlock (Ch. 5, Phase 6/8) - none of those systems are
  built yet, so `current_chapter_id` caps at "chapter_2_someone_upstairs"
  honestly rather than faking further chapter titles with nothing behind
  them.
- **No portrait art or real expressions** - the dialogue screen reuses
  Phase 1's `SurvivorSilhouette` placeholder, coloured per speaker; the
  `expression_key` field is set on content (e.g. Noah's `"injured"`) but
  nothing currently changes the portrait's rendering based on it.
  Wiring that up needs either more `SurvivorSilhouette` variants or real
  art - tracked as a placeholder-art gap, not a logic gap.
- **No background scene per dialogue beat** - `background_scene_path` is
  part of the schema and set to `""` on every current entry; the dialogue
  screen just shows a flat dark panel. Real per-scene backgrounds are an
  art/polish addition once there's art to show.
- **The Noah hotspot skips its repair-burst animation** - since
  completing that task immediately changes scenes to the dialogue screen,
  there's no time for the on-Haven burst to play; every other hotspot
  still gets it. Documented as an intentional trade-off in `task_panel.gd`,
  not an oversight.
- **`condition` and `quest_trigger` dialogue-option fields are unused.**
  They're read (no crash, no silent drop) but nothing in this phase's
  content needs a conditional choice or a dialogue-triggered quest, so
  there's no logic consuming them yet - real usage arrives whenever a
  future phase's content actually needs one.
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 5: Scavenging** - mission selection, survivor assignment (blocked
on Phase 6 existing, so this phase may need to introduce a minimal
placeholder assignment step or reorder against Phase 6 - to be decided
when that phase starts), choice-based encounters, loot rewards, mission
animations. This is also when Chapter 3 ("Before Nightfall") becomes real.

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the full smoke test suite
for f in smoke_test smoke_test_save smoke_test_settings smoke_test_merge smoke_test_residence smoke_test_dialogue; do
  godot4 --headless --path /path/to/dead-haven-merge-survive "tests/$f.tscn"
done

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## Phase 5: Scavenging - complete

### Files created

Content: 5 `data/scavenging/*.tres` (`ScavengingMission`) - Abandoned
Grocery Store, Petrol Station, Farm Shed, Roadside Wreck, Medical Clinic,
each with a danger rating, threat/noise flavour values, a base loot table
drawing from existing merge chains, and one 2-choice encounter. Generated
once by a script run through the Godot binary and deleted, same pattern
as every phase's content so far.

New autoload: `autoload/scavenging_manager.gd` - owns mission content and
the two-step flow (`launch_mission()` spends energy, `resolve_choice()`
rolls the chosen option and grants rewards).

New screen: `scenes/scavenging/scavenging.gd`/`.tscn` - survivor picker ->
Send -> encounter choice buttons -> outcome text, all in one screen with
three panels toggled by visibility rather than separate scenes.

Tests: `tests/smoke_test_scavenging.gd`/`.tscn`.

### Files modified

- `project.godot` - registered `ScavengingManager`.
- `autoload/event_bus.gd` - added `mission_completed`.
- `autoload/game_manager.gd` - `get_unlocked_survivor_ids()` (Mara always
  included, plus whatever's in `unlocked_survivor_ids`); `new_game()`,
  `to_save_data()` and `apply_save_data()` now also cover
  `ScavengingManager`.
- `scripts/data_models/scavenging_mission.gd` - added `energy_cost` and
  `encounter_choices` fields. **This is a deliberate extension beyond the
  design spec's literal section 31 field list** (ID, Location, Threat
  level, Duration, Requirements, Encounter table, Loot table, Story
  conditions) - that list doesn't actually specify what an encounter
  *contains*, and section 10's "choice-based encounter system" needs
  somewhere to hold each choice's text/odds/outcomes. Extending the
  existing Resource class was simpler and more consistent than inventing
  a whole separate `EncounterDefinition` type for one phase's needs.
- `scenes/world_map/world_map.gd`/`.tscn` - added 5 scavenging location
  markers (📦), built from `ScavengingManager` content, positioned via a
  display-only lookup table in the script (not a schema field - see the
  `encounter_choices` note above for the general principle: UI-only data
  doesn't need to live in a shared content schema).
- `scenes/dialogue/dialogue.gd` - proactively applied the same
  `get_tree().current_scene == self` guard from Phase 4's bug fix, since
  the same unconditional-navigation-in-`_ready()` pattern was present
  here too (never actually triggered a hang, since `dialogue.tscn` wasn't
  in `smoke_test.gd`'s coverage list yet - fixed before it could be).
- `tests/smoke_test.gd` - added `dialogue.tscn` and `scavenging.tscn` to
  the coverage list (both now guarded against the instantiate-as-child
  pattern; see above).

### Features completed

- **Real mission flow**: pick a survivor from whoever's unlocked (Mara is
  always available; Noah too once rescued), spend energy to send them,
  choose how to handle the encounter, see the outcome - all from one
  screen, all backed by real state changes.
- **Choice-based encounters, not passive timers**: each mission's
  encounter is 2 meaningfully different choices (e.g. "force the entrance"
  vs. "find a quieter way in") with different success odds and different
  rewards - a higher-risk choice can pay out more, matching spec section
  10's own supermarket example.
- **Non-blocking failure**: a failed encounter still costs something small
  (coins or energy) but never removes a board item, never blocks
  progression, and never ends the session - verified directly in the
  smoke test (`GameManager.is_game_active` stays true through a forced
  failure).
- **Real loot**: missions grant actual merge-board items (spawned via
  `BoardState.spawn_item()`, not a fake currency), plus coins/energy on
  top - a genuine second way to get board content beyond producers.
- **World Map integration**: 5 tappable scavenging markers alongside the
  existing residence markers, each routing straight into that location's
  mission flow.

### Tests performed

Same headless-binary approach as every phase so far, with `timeout`
wrappers on every run per Phase 4's lesson:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- **A real bug was caught and fixed during content generation this
  phase**: the one-off `tools/generate_scavenging.gd` script assigned an
  untyped `Array` (from a `Dictionary` literal) to `ScavengingMission`'s
  typed `encounter_choices: Array[Dictionary]` field, which Godot rejects
  with a script error - and because that error happened inside
  `_initialize()` before `quit()` was reached, the headless `SceneTree`
  process just sat idling forever with no window and no error surfaced
  until the `timeout`-wrapped run was inspected directly. **General
  lesson recorded for future phases**: any headless one-off `SceneTree`
  script needs a `timeout` wrapper the first time it's run, because a
  script error partway through `_initialize()` hangs the process rather
  than exiting non-zero. Fixed by building the typed array explicitly
  (`var choices: Array[Dictionary] = []; for c in ...: choices.append(c)`)
  instead of relying on implicit conversion.
- `tests/smoke_test.tscn` (now covering `dialogue.tscn` and
  `scavenging.tscn` too), `tests/smoke_test_save.tscn`,
  `tests/smoke_test_settings.tscn`, `tests/smoke_test_merge.tscn`,
  `tests/smoke_test_residence.tscn`, `tests/smoke_test_dialogue.tscn` -
  all still pass, no regressions.
- `tests/smoke_test_scavenging.tscn` (new) - mission content loads (5
  missions, each with 2 encounter choices); launching spends the
  mission's energy cost and refuses with `no_energy` when there isn't
  enough; a forced-success resolve (by temporarily overriding a loaded
  mission's `success_chance` to 1.0 in memory, not touching the `.tres`
  file) grants both the base loot table and the choice's `success_loot`;
  a forced-failure resolve (`success_chance` 0.0) applies exactly the
  configured `failure_penalty` and leaves `GameManager.is_game_active`
  true; completion counts and a full save/reload round trip both check
  out.

### Known issues

- **Not visually confirmed**, same caveat as every phase. Marker
  placement on the map, panel transitions on the scavenging screen, and
  whether the encounter choices read clearly all need a real screen.
- **Missions resolve synchronously, not as timed/background operations.**
  `duration_seconds` is shown as flavour text (via the danger/threat
  summary line) but nothing actually makes the player wait or lets them
  leave and come back later - spec's "Duration" field implies a real time
  cost that this phase doesn't implement. A true async mission (send,
  leave the screen, come back after `duration_seconds` to collect results)
  is a reasonable next enhancement but adds real complexity (surviving app
  close mid-mission, a mission-in-progress indicator elsewhere in the UI)
  that this phase's scope didn't need to prove the core loop works.
- **No survivor skill effects on odds.** Picking Noah over Mara (or vice
  versa) currently only changes flavour text ("Noah Vance heads out to...")
  - `success_chance` is fixed per choice regardless of who's sent, because
  neither survivor has real `SurvivorDefinition`-backed skills data yet
  (that's Phase 6). Once it exists, `resolve_choice()` is the one place
  a skill-based modifier needs to plug in.
- **No vehicle, food/medical, or equipment preparation step.** Spec
  section 10 describes choosing a vehicle, supplies, weapons and
  inventory capacity before a mission; none of that exists yet (vehicles
  are Phase 6, and there's no pre-mission "loadout" system at all) - this
  phase's "preparation" is just picking who goes.
- **5 of the design spec's 10 initial scavenging locations exist**
  (grocery store, petrol station, farm shed, roadside wreck, medical
  clinic). The other 5 (construction yard, police checkpoint, forest
  campsite, suburban house, warehouse) follow the same pattern and can be
  added the same way - not added this phase to keep scope focused on
  proving the mechanic works end to end first.
- **`ScavengingMission.encounter_choices` is a schema extension** beyond
  the design spec's literal field list, as noted under Files modified -
  documented there rather than repeated here.
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 6: Vehicles and survivors** - vehicle repair/upgrades (the
delivery van, 9 stages per spec section 13), a real `SurvivorDefinition`-
backed roster (skills, health, morale, personal quests) replacing the
Phase 1 placeholder roster and Phase 3/5's name-only survivor references,
and the skill-based mission-odds modifier flagged above. This is also
when Chapter 5 ("Follow the Signal") becomes reachable.

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the full smoke test suite (always with a timeout wrapper - see
# "Tests performed" above for why)
for f in smoke_test smoke_test_save smoke_test_settings smoke_test_merge smoke_test_residence smoke_test_dialogue smoke_test_scavenging; do
  timeout 30 godot4 --headless --path /path/to/dead-haven-merge-survive "tests/$f.tscn"
done

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## Phase 6: Vehicles and survivors - complete

### Files created

Content: 6 `data/characters/*.tres` (`SurvivorDefinition` - Mara Vale,
Noah Vance, Lena Ortiz, Dr Imogen Shaw, Riley Chen, Caleb Rusk, all fully
populated per design spec section 11 even though only Mara/Noah have an
unlock path yet - same "content ready ahead of its consuming system"
approach as Phase 2's 101 items), `data/quests/pq_noah_workbench.tres`
(Noah's personal quest - the first `SURVIVOR_PERSONAL`-type quest that
isn't tied to a residence hotspot), `data/vehicles/delivery_van.tres`
(`VehicleDefinition`, 9 upgrade stages per spec section 13). Generated
once by a script run through the Godot binary and deleted, same pattern
as every phase's content so far.

New autoloads: `autoload/character_database.gd` (indexes survivor
content, same shape as `ItemDatabase`), `autoload/vehicle_manager.gd`
(owns discovery + current-stage runtime state - not mutated on the loaded
`VehicleDefinition`, same pattern `ResidenceManager` uses for hotspot
state - plus the upgrade flow: check requirements, consume items, advance
stage).

New screen: `scenes/vehicle/vehicle.gd`/`.tscn` with
`scripts/vehicle/vehicle_visual.gd` - a single procedural van silhouette
that visibly evolves across all 9 stages (body colour shifts rust-to-olive
with progress, and each stage lights up one more concrete drawn detail -
wheels, fuel cap, storage rack, window tint, front ram, roof box, antenna)
rather than needing 9 separate illustrations.

Tests: `tests/smoke_test_vehicle_survivors.gd`/`.tscn`.

### Files modified

- `project.godot` - registered `CharacterDatabase` and `VehicleManager`;
  added `"vehicle"` to `SceneRouter.SCENE_PATHS`.
- `autoload/event_bus.gd` - added `vehicle_discovered`, `vehicle_stage_changed`.
- `autoload/game_manager.gd` - `new_game()`/`to_save_data()`/
  `apply_save_data()` now also cover `VehicleManager`.
- `autoload/residence_manager.gd` - `try_complete_quest()` now also calls
  a new `_maybe_discover_vehicle()` check after advancing a hotspot.
- `autoload/scavenging_manager.gd` - `resolve_choice()` gained an optional
  `survivor_id` parameter; when the sent survivor has a skill matching the
  mission's `recommended_equipment` tags, success chance gets a +0.15
  bonus (capped at 0.95) - this closes Phase 5's "no skill effects on
  odds" known issue.
- `scenes/scavenging/scavenging.gd` - passes `_selected_survivor_id`
  through to `resolve_choice()`.
- `scenes/survivors/survivors.gd`/`.tscn` - full rewrite: real
  `SurvivorDefinition` data instead of Phase 1's hardcoded `ROSTER`
  constant; unlocked cards show real role/biography/skills; a card with
  an incomplete personal quest is tappable and opens a `TaskPanel`.
- `scenes/ui/task_panel.gd` - generalized: the hotspot-specific lookup
  moved into `show_for_hotspot()`, with a new `show_for_quest(quest_id)`
  entry point (used by Survivors) sharing the same underlying
  `_show_quest()` renderer - both are just a `QuestDefinition` underneath.
- `scenes/world_map/world_map.gd`/`.tscn` - added a vehicle marker (🚐),
  shown once the van is discovered.
- `tests/smoke_test.gd` - added `vehicle.tscn` to the coverage list.

### Features completed

- **Real survivor roster**: unlocked cards (Mara always, Noah once
  rescued) show actual biography, role and skills from data instead of a
  hardcoded name/role pair; locked cards stay "???" per the Phase 1
  placeholder pattern (real portraits are still an art-asset gap, not a
  logic gap - see `ART_ASSET_GUIDE.md`).
- **Personal quests, proven end to end**: Noah's "Noah's Workbench" quest
  is the first `SURVIVOR_PERSONAL`-type quest that isn't tied to a
  residence hotspot - `try_complete_quest()` already handled this
  correctly (it only advances a hotspot `if residence_hotspot_id` is set),
  so no special-casing was needed, just a quest with that field left empty
  and a new UI entry point (`TaskPanel.show_for_quest()`) to reach it.
- **Vehicle discovery tied to a real milestone**: completing all 9 Hollow
  Creek Farmhouse hotspots discovers the delivery van - a concrete, earned
  trigger rather than an arbitrary unlock (see Known issues for why this
  isn't the design spec's literal Chapter 5 radio-signal beat).
- **9-stage vehicle upgrade**: each stage requires and consumes a specific
  merge-board item (drawing from Vehicle Parts, Fuel, Construction and
  Electronics chains), gated exactly like a residence task - shows the
  requirement, disables Upgrade until met, consumes on success.
- **Skill-based scavenging bonus**: sending a survivor whose skill tags
  match a mission's `recommended_equipment` (e.g. Noah's `"tool"` skill on
  the Farm Shed mission, which recommends `"tool"`) now measurably
  improves the odds, closing the gap Phase 5 flagged.

### Tests performed

Same headless-binary approach as every phase, with `timeout` wrappers on
every run:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- `tests/smoke_test.tscn` (now also covering `vehicle.tscn`),
  `tests/smoke_test_save.tscn`, `tests/smoke_test_settings.tscn`,
  `tests/smoke_test_merge.tscn`, `tests/smoke_test_residence.tscn`,
  `tests/smoke_test_dialogue.tscn`, `tests/smoke_test_scavenging.tscn` -
  all still pass, no regressions.
- `tests/smoke_test_vehicle_survivors.tscn` (new) - 6 survivors load with
  the expected shape; the van is genuinely undiscovered at game start and
  refuses to upgrade (`not_discovered`); completing all 9 Hollow Creek
  Farmhouse hotspots (looping through every hotspot's active quest,
  spawning what it needs, completing it) discovers the van; upgrading
  without the stage-1 item is refused (`requirements_not_met`), spawning
  it and retrying consumes it and advances to stage 1; Noah's personal
  quest completes through the generic quest path with an empty
  `hotspot_id` (verifying no hotspot coupling leaked in); the skill-match
  function is called directly (not reimplemented in the test) and confirmed
  true for Noah on the Farm Shed mission, false for Mara, false for no
  survivor selected, plus a deterministic zero-chance-stays-zero check
  when there's no matching skill; a full save/reload round trip preserves
  vehicle discovery, stage, and the personal quest completion. **One test
  bug was caught and fixed while writing this**: an early draft asserted
  Noah should still be locked at a point in the test where all 9 hotspots
  (including his own rescue quest) had already been completed as part of
  triggering vehicle discovery - the assertion was simply wrong about the
  test's own setup, not a game bug; removed rather than working around.

### Known issues

- **Not visually confirmed**, same caveat as every phase. Card layout with
  the new skills line and personal-quest button, and whether the evolving
  van silhouette actually reads as "changing" at real screen size, both
  need a real screen.
- **Vehicle discovery is simplified from the design spec's Chapter 5 beat.**
  Spec ties finding the van to following the radio signal in Chapter 5,
  which needs Chapter 3/4 content (scavenging framed narratively, a
  defence event, the radio message itself) that doesn't exist yet. "All 9
  hotspots repaired" is a real, earned substitute milestone - not a random
  unlock - but it isn't the literal story beat.
- **Only Mara and Noah are actually reachable.** Lena, Imogen, Riley and
  Caleb have full `SurvivorDefinition` content (bio, skills, personality)
  but no rescue quest/trigger yet - they need Redwater Service Station and
  beyond (Phase 8) or dedicated scavenging encounters to actually recruit.
  Their entries exist and are correct, just permanently locked in this
  build.
- **Survivor trust/health/morale are inert.** `SurvivorDefinition.trust`/
  `.health`/`.morale` are set (Noah defaults to 100/70) but nothing reads
  or changes them yet - Phase 4's `noah_trusted` story flag is a separate,
  simpler mechanism that doesn't feed into this schema's `trust` field.
  Wiring real stat changes (e.g. injuries from a failed scavenging
  encounter, morale from story choices) is follow-up work once something
  actually needs to consume them.
- **No vehicle stats (fuel_use/reliability/storage_capacity/noise/
  protection/range_km) affect anything yet.** They're set on
  `VehicleDefinition` per spec section 13 but nothing reads them - they
  matter once scavenging mission range/capacity or a defence event reads
  vehicle state, neither of which exists yet.
- **Only one vehicle exists.** Spec section 13 lists future vehicles
  (trail motorcycle, farm pickup, armoured bus, utility truck, riverboat)
  as later content - not attempted this phase.
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 7: Defence** - preparation tasks, trap placement, an animated
attack sequence, and success/failure consequences that damage rather than
end the game (matching this phase's and Phase 5's non-blocking-failure
principle). This is also milestone 10 for Hollow Creek Farmhouse
("Survive the first night attack") - the one milestone every prior phase
has deliberately left out - and unlocks Chapter 4 ("The First Wave").

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the full smoke test suite (always with a timeout wrapper)
for f in smoke_test smoke_test_save smoke_test_settings smoke_test_merge smoke_test_residence smoke_test_dialogue smoke_test_scavenging smoke_test_vehicle_survivors; do
  timeout 30 godot4 --headless --path /path/to/dead-haven-merge-survive "tests/$f.tscn"
done

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```

---

## Phase 7: Defence - complete

### Files created

New autoload: `autoload/defence_manager.gd` - Hollow Creek Farmhouse's
milestone 10, "Survive the first night attack". Unlike every prior
phase's content, its choice data is deliberately kept as inline `var`
constants in the autoload rather than a `data/` file - it's a single,
story-critical event, not a repeatable content category like items/
quests/missions, so a whole data-file-plus-generator-script pipeline for
one event would be needless indirection. (It's `var`, not `const`,
specifically so tests can force deterministic outcomes the same way
`smoke_test_scavenging.gd` already does on `ScavengingMission.encounter_choices`
- GDScript rejects mutating elements of a true `const` container.)

New screen: `scenes/defence/defence.gd`/`.tscn` - survivor picker ->
Prepare -> 3-choice encounter -> outcome, reusing
`scenes/scavenging/scavenging.gd`'s exact three-panel pattern rather than
inventing a new one.

Tests: `tests/smoke_test_defence.gd`/`.tscn`.

### Files modified

- `project.godot` - registered `DefenceManager`; added `"defence"` to
  `SceneRouter.SCENE_PATHS`.
- `autoload/event_bus.gd` - added `defence_resolved`.
- `autoload/game_manager.gd` - `new_game()`/`to_save_data()`/
  `apply_save_data()` now also cover `DefenceManager`.
- `autoload/residence_manager.gd` - new `revert_hotspot()`, used only by
  `DefenceManager` on a failed defence to send one hotspot back to
  DESTROYED and un-mark its quest as complete (spec: "damaged defences").
- `scenes/haven/haven.gd`/`.tscn` - a "Prepare for the Night" button
  appears once `DefenceManager.can_attempt()` is true (all 9 hotspots
  COMPLETED and the first wave not yet survived); added
  `"chapter_4_the_first_wave"` to the chapter title lookup.
- `scenes/world_map/world_map.gd` - the Redwater Service Station marker's
  message changes once `GameManager.story_flags["redwater_unlocked"]` is
  set (see Features completed).
- `tests/smoke_test.gd` - added `defence.tscn` to the coverage list.

### Features completed

- **Gated on real completion**: the defence event only becomes reachable
  once every one of Hollow Creek Farmhouse's 9 hotspots is COMPLETED -
  `DefenceManager.can_attempt()` is the single source of truth the Haven
  button, the Defence screen's own guard, and the smoke test all check.
- **Choice-based, with a skill bonus**: 3 approaches (hold the barricades,
  retreat to the cellar, use the traps) with different odds; sending a
  survivor with the `"trap"` or `"defence"` skill tag improves the chance,
  same `+0.15`-capped-at-`0.95` mechanism Phase 6 introduced for
  scavenging (currently only meaningful once Caleb Rusk - who has the
  `"trap"`/`"defence"` skills - is eventually recruited; Mara and Noah
  don't have a matching skill, so the bonus is real but currently inert in
  practice, same honest situation Phase 6 documented for its own bonus).
- **Failure is real but never blocking**: a failed attempt reverts one
  random already-COMPLETED hotspot back to DESTROYED and costs a little
  coin - spec's own listed failure consequences ("damaged defences...
  additional repair tasks... rebuild and try again"), not a game-over.
  The event can be attempted again the moment that hotspot is repaired.
- **Success has real, felt consequences**: a big coin/XP reward, the
  chapter advances directly from "Someone Upstairs" to "The First Wave"
  (spec's own Chapter 4 content *is* this event - see Known issues for why
  there's no separate Chapter 3 transition), and the World Map's Redwater
  Service Station marker changes from a flat "locked" message to
  something that acknowledges the story has actually moved - honest about
  Redwater not being built yet rather than pretending it's reachable.

### Tests performed

Same headless-binary approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors
  after fixing the `const` mutation issue below.
- **A real bug was caught immediately by trying to write the test**: the
  first draft of `smoke_test_defence.gd` tried to force deterministic
  outcomes with `DefenceManager.choices[0].success_chance = 0.0/1.0`, the
  same technique `smoke_test_scavenging.gd` uses - except `choices` had
  been declared `const`, and GDScript's parser rejects assigning into any
  element of a `const` container outright (`Cannot assign a new value to
  a constant`), unlike a `const`-bound `Resource` reference (Phase 5's
  case) whose *fields* remain mutable. Fixed by changing the declaration
  to `var` (renamed from `CHOICES` to `choices` to match ordinary-variable
  naming convention at the same time) - functionally identical at
  runtime, just testable.
- `tests/smoke_test.tscn` (now also covering `defence.tscn`),
  `tests/smoke_test_save.tscn`, `tests/smoke_test_settings.tscn`,
  `tests/smoke_test_merge.tscn`, `tests/smoke_test_residence.tscn`,
  `tests/smoke_test_dialogue.tscn`, `tests/smoke_test_scavenging.tscn`,
  `tests/smoke_test_vehicle_survivors.tscn` - all still pass, no
  regressions.
- `tests/smoke_test_defence.tscn` (new) - `can_attempt()`/`launch()` both
  correctly refuse before all 9 hotspots are done; launching spends the
  energy cost; a forced failure (`success_chance` 0.0) never sets
  `has_survived_first_wave`, never touches `GameManager.is_game_active`,
  and reverts exactly one hotspot to DESTROYED whose quest becomes
  completable again; re-repairing that hotspot makes the event attemptable
  again and a forced success (`success_chance` 1.0) sets
  `has_survived_first_wave`, advances the chapter, and sets
  `redwater_unlocked`; `can_attempt()` correctly goes false again once
  already survived; a full save/reload round trip preserves all of it.

### Known issues

- **Not visually confirmed**, same caveat as every phase. Whether the
  "Prepare for the Night" button reads clearly against the hotspot layer,
  and the defence screen's pacing, both need a real screen.
- **Chapter jumps from 2 straight to 4 - there's no distinct Chapter 3
  beat.** Spec's Chapter 3 ("Before Nightfall") is "food/water secured,
  traps built, rear exit restored, first scavenging mission introduced" -
  all of that is mechanically true by the time a player reaches this
  event (the relevant hotspots are done, scavenging has existed since
  Phase 5), but nothing marks a Chapter 3 *transition* specifically. This
  was a deliberate choice over inventing an empty chapter-only milestone
  with no new content behind it.
- **The skill bonus has no one to apply to yet.** Same situation Phase 6
  flagged for scavenging: the mechanism is real and tested, but Caleb Rusk
  (the survivor whose skills would trigger it) has no rescue path built.
- **Defence choice data lives in code, not `data/`** - a deliberate,
  documented exception (see Files created) for this one story-critical
  event, not an inconsistency with the rest of the project's content
  philosophy.
- **No animated attack sequence, trap-triggering visuals, or barricade-
  durability display** per spec section 15's fuller description - this
  phase is the real mechanical loop (gate, choice, odds, consequence,
  retry) without the presentation layer on top. Same "logic first,
  animation later" trade-off every prior phase has made under this
  container's headless-only testing constraint.
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 8: Additional content** - Redwater Service Station (spec section
9's second residence: forecourt/shop/garage/roof/fuel store/staff room/
road barrier/drainage tunnel, 10 milestones, Lena Ortiz's rescue),
additional merge chains/survivors/scavenging locations, and World Map
expansion (the remaining locked residence markers, routes, weather). This
is also where the `redwater_unlocked` flag this phase introduced finally
does something - flip Redwater from "coming soon" to actually reachable.

## Phase 8: Additional content - complete

### Files created

New residence: `data/residences/redwater_service_station.tres` - Redwater
Service Station, the second residence, reachable once
`GameManager.story_flags["redwater_unlocked"]` is set (Phase 7). 8
hotspots (fuel pumps, service bay, convenience store, cashier's office,
generator room, perimeter fence, drainage tunnel, garage workshop) rather
than spec's fuller 10 - the same "concrete and earned over exhaustive"
trade-off every phase's content generation has made, covering every item
chain the residence's flavour touches (fuel, tool, food, construction,
electronics, trap) plus the rescue.

New quests: `data/quests/q_clear_fuel_pumps.tres`,
`q_repair_service_bay.tres`, `q_restock_convenience_store.tres`,
`q_board_office_windows.tres`, `q_restart_generator.tres`,
`q_reinforce_perimeter_fence.tres`, `q_clear_drainage_tunnel.tres`, and
`q_rescue_lena.tres` (the rescue quest - `medical_3`, `unlock_survivor:
lena_ortiz`, `dialogue_trigger_id: lena_01`, same shape as Phase 3's
`q_rescue_noah`).

New dialogue: `data/dialogue/lena_01.tres`/`lena_02.tres`/`lena_03.tres` -
Lena Ortiz found barricaded in the garage workshop, defensive at first
(she assumes anyone knocking is there to siphon the pumps dry), then a
branching trust choice mirroring Noah's rescue beat.

New screen: `scenes/redwater/redwater.gd`/`.tscn` and
`scenes/redwater/redwater_background.gd` - the same data-driven
hotspot/task-panel screen shape as `scenes/haven/haven.gd`, reused
deliberately rather than re-architected (a residence screen is a
residence screen regardless of which `ResidenceDefinition` backs it). The
background is a dusk forecourt/canopy/store/garage illustration in the
same layered `_draw()` placeholder technique as Hollow Creek's, given a
distinct palette and time of day on purpose so the two residences read as
different places rather than a reskin.

Tests: `tests/smoke_test_redwater.gd`/`.tscn`.

### Files modified

- `project.godot` - added `"redwater"` to `SceneRouter.SCENE_PATHS`.
- `autoload/defence_manager.gd` - **generalized from one hardcoded
  residence/event to a dictionary of events keyed by `event_id`**
  (`events`, `event_choices`), so Redwater's own "Defend the Station"
  attack (`redwater_defence`) is a second entry rather than a duplicated
  manager. Every function (`can_attempt`, `launch`, `resolve_choice`,
  `all_hotspots_complete`, `has_survived`, ...) now takes `event_id`
  instead of assuming Hollow Creek.
- `scenes/defence/defence.gd`/`.tscn` - now reads `event_id` and
  `return_scene_key` from `SceneRouter.take_pending_params()` instead of
  being hardcoded to Hollow Creek's event, so the same screen serves both
  residences' defence encounters.
- `autoload/residence_manager.gd` - `try_complete_quest()` now also
  handles a `set_story_flag` reward key (alongside `coins`/`xp`/`energy`/
  `unlock_survivor`), and advances the chapter to
  `chapter_5_the_station` specifically on `q_rescue_lena`'s completion.
- `scenes/ui/task_panel.gd` - **bug fix**: `show_for_hotspot()` took no
  `residence_id` and silently defaulted to `"hollow_creek_farmhouse"`,
  which would have made every Redwater hotspot's task panel report
  "Already repaired." (`ResidenceManager.get_active_quest_for_hotspot()`
  looks the hotspot up inside a specific residence's own hotspot list -
  Redwater's hotspot ids don't exist in Hollow Creek's). Now takes an
  explicit `residence_id`; both `haven.gd` and `redwater.gd` pass their
  own. `tests/smoke_test_redwater.gd` asserts the wrong-residence lookup
  fails and the right one succeeds, specifically to guard this.
- `scripts/residence/hotspot_visual.gd` - added a distinct hand-drawn
  placeholder shape per Redwater hotspot id (pumps, garage bay slats,
  store shelves, office window, generator vents, fence posts, drainage
  arc, workbench), matching the "distinct shape per hotspot, not a blank
  circle" policy the file's own docstring already commits to for Hollow
  Creek.
- `scenes/world_map/world_map.gd`/`.tscn` - the Redwater marker now
  actually routes to `SceneRouter.go_to("redwater")` once
  `redwater_unlocked` is set, replacing Phase 7's "found, not yet
  reachable" placeholder toast. **Bug fix while re-running the full smoke
  suite**: `MapArea` (the scavenging/vehicle marker container) was
  missing `unique_name_in_owner = true`, so every `%MapArea` lookup in
  `_build_scavenging_markers()`/`_build_vehicle_marker()` was silently
  failing with a script error on every World Map load - present since
  Phase 5, never caught because a script error doesn't fail
  `smoke_test.gd`'s pass/fail check (no `quit(1)`) the way a `_fail()`
  call does. Fixed by adding the flag; confirmed clean in
  `smoke_test.tscn`'s output afterward.
- `scenes/haven/haven.gd` - added `"chapter_5_the_station"` to the
  chapter title lookup (both residence screens show whichever chapter is
  current, not just their own).
- `tests/smoke_test.gd` - added `redwater.tscn` to the coverage list.
- `tests/smoke_test_defence.gd` - narrowed its own docstring/scope note
  now that a second event exists; unchanged otherwise (it still only
  exercises `hollow_creek_first_wave` - `smoke_test_redwater.gd` covers
  `redwater_defence`).

### Features completed

- **A second full residence**, symmetric with Hollow Creek: 8 data-driven
  hotspots, each gated behind a merge-chain item requirement, one of them
  a rescue (Lena Ortiz) that unlocks a survivor and advances the story.
- **DefenceManager generalized to N events instead of 1** - proven by
  `redwater_defence` resolving completely independently of
  `hollow_creek_first_wave` (surviving one doesn't mark the other
  survived; each has its own energy cost, choices, and skill tags).
  Lena's own skills (`vehicle_parts`, `fuel`, `vehicle_repair`) don't
  match Redwater's `trap`/`defence` tags, so - same honest situation
  Phases 6 and 7 both documented - the skill bonus mechanism is exercised
  but currently inert for her specifically.
- **`set_story_flag` as a generic quest reward key**, not just the
  `unlock_survivor`/`coins`/`xp`/`energy` set Phase 3 originally shipped -
  used by Lena's rescue but available to any future quest.
  **Chapter 5 opens on her rescue** specifically, the same
  "one hardcoded `quest_id` check advances the story" pattern
  `q_secure_front_door` established in Phase 3.
- **Two residence-shaped bugs caught and fixed by building a second
  residence**: the `task_panel.gd` residence_id default (would have
  silently broken every Redwater task) and the World Map's missing
  `unique_name_in_owner` on `MapArea` (silently broke every map marker
  since Phase 5). Both are exactly the kind of assumption that only
  surfaces once "the thing" stops being singular - the same value Phase 6
  got from generalizing scavenging skill bonuses, applied here to
  residences and defence events.

### Tests performed

Same headless-binary approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- `tests/smoke_test.tscn`, `tests/smoke_test_save.tscn`,
  `tests/smoke_test_settings.tscn`, `tests/smoke_test_merge.tscn`,
  `tests/smoke_test_residence.tscn`, `tests/smoke_test_dialogue.tscn`,
  `tests/smoke_test_scavenging.tscn`,
  `tests/smoke_test_vehicle_survivors.tscn`,
  `tests/smoke_test_defence.tscn` - all still pass, no regressions (this
  run is also what caught the `MapArea` bug above, in
  `smoke_test.tscn`'s `world_map.tscn` instantiation step).
- `tests/smoke_test_redwater.tscn` (new) - residence data loads with 8
  hotspots; `get_active_quest_for_hotspot("fuel_pumps",
  "hollow_creek_farmhouse")` correctly resolves to nothing while the same
  call with `"redwater_service_station"` resolves to
  `q_clear_fuel_pumps`, guarding the `task_panel.gd` fix; completing every
  hotspot except the rescue leaves `redwater_defence` un-attemptable;
  completing `q_rescue_lena` unlocks `lena_ortiz`, advances the chapter to
  `chapter_5_the_station`, and its `dialogue_trigger_id` is `lena_01`;
  once all 8 are done, `redwater_defence` becomes attemptable, spends its
  own `energy_cost`, and a forced success marks it (and only it) survived,
  independent of Hollow Creek's own event; a full save/reload round trip
  preserves all of it.

### Known issues

- **Not visually confirmed**, same caveat as every phase. The dusk
  forecourt background's readability against the hotspot layer, and
  whether the palette shift from Hollow Creek reads as intentional rather
  than inconsistent, both need a real screen.
- **8 hotspots, not spec's 10** - see Files created; every merge chain the
  location's flavour would plausibly touch is covered, but "roof" and
  "staff room" specifically weren't given their own milestone.
- **No route/travel scene between residences** - `SceneRouter.go_to`
  jumps straight from World Map to Redwater the same way it does for
  Hollow Creek, with no travel-time or vehicle-use step, even though the
  delivery van (Phase 6) narratively exists for exactly this.
- **3 residences remain locked placeholders on the World Map** (Greybridge
  School, Saint Mercy Hospital, Northgate Prison) - map markers only, no
  content behind them yet.
- **Lena's skills have no defence event to bonus at Redwater specifically**
  - same "mechanism real, no matching recruit yet for this exact case"
  situation Phases 6 and 7 both flagged, just inverted (a survivor exists,
  the tags on Redwater's own event don't happen to match her).
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 9: Polish** - per the original spec's phase list: animation/
juice pass on existing systems, audio, accessibility, performance
profiling on Android, and a first real look at the illustrated-art
question (see `ART_ASSET_GUIDE.md` - every visual in the project through
Phase 8 is procedural placeholder art via `_draw()`, by necessity of this
environment having no image-generation tool).

## Art Phase 1: Visual foundation - complete

Prompted by the full art/graphics/animation brief (48 sections) attached
mid-Phase-8. This environment has no image-generation tool - unchanged
from every prior phase's honest disclosure - so this phase is scoped to
the brief's own Section 45 fallback: produce everything achievable
without raster generation, and track everything else as a concrete,
ready-to-generate production prompt rather than skip it or fake it.

### Files created

- `assets/branding/logo/` (5 SVGs: horizontal dark/light, stacked, icon-
  only, monochrome) and `assets/branding/app_icon/notification_icon.svg`
  - original hand-authored vector art on the boarded-doorway motif
  already established in `icon.svg`, not a placeholder.
- `scenes/splash/splash.gd`/`.tscn` - a real splash screen (previously
  just a comment in `boot.gd` saying one belonged there), showing the
  stacked logo with a fade in/hold/fade out before routing to the main
  menu; tap-to-skip; respects the same active-scene guard every other
  auto-navigating screen uses so `tests/smoke_test.gd` can still
  instantiate it safely as a plain child.
- `ART_STYLE_GUIDE.md` - the formal palette (named semantic roles,
  cross-referenced 1:1 with `ThemeFactory` constants) and typography
  direction (Oswald + Inter, both SIL OFL 1.1 - licence-clear, not yet
  bundled as font files).
- `ART_GENERATION_PROMPTS.md` - the brief's shared style header +
  negative prompt, plus 10 fully detailed generation prompts covering
  its Section 48 vertical slice (Mara Vale and Noah Vance character
  sheets, the Drifter concept sheet, Hollow Creek's two earliest exterior
  states, the merge-board design, the construction item chain as a
  template, the Tool Crate producer, a window-boarding task/animation
  storyboard, and the intro dialogue scene) - each grounded in this
  project's actual data files, not generic filler.
- `ART_ILLUSTRATION_CHECKLIST.md` - a flat, hand-off-ready list of every
  illustration the game currently needs (14 categories), with a
  suggested batching/priority order, for whichever future session
  actually has an image-generation tool.
- `assets/manifests/animation_manifest.json` - every animation in the
  project, implemented and planned, per the brief's Section 37 schema.

### Files modified

- `scripts/ui/theme_factory.gd` - added `SAFE_AMBER`/`STORM_BLUEGREY` as
  named palette constants (the brief's "safe-haven amber"/"storm
  blue-grey" semantic roles existed as one-off hex values in a couple of
  background scripts already; now centralised).
- `assets/manifests/asset_manifest.json` - expanded from a short informal
  list to the brief's full Section 36 schema (asset id, category,
  transparency, animation type, scenes using it, licence/generation
  source, optimisation status) for every existing entry, plus new
  entries for the logo set/splash/notification icon.
- `autoload/scene_router.gd` - added `"splash"` to `SCENE_PATHS`.
- `scenes/boot/boot.gd` - now routes to `"splash"` first instead of
  straight to `"main_menu"`.
- `tests/smoke_test.gd` - added `splash.tscn` to the coverage list.
- `ART_ASSET_GUIDE.md` / `README.md` - cross-reference the new documents;
  a new "Finished (non-placeholder) assets" section in `ART_ASSET_GUIDE.md`
  so the logo/splash aren't mistaken for placeholders alongside everything
  else in that document.

### Tests performed

`godot4 --headless --path . --import` (confirms the new SVGs import
cleanly - Godot's built-in SVG rasterizer, same path `icon.svg` already
used successfully) and the full smoke test suite including the new
`splash.tscn` step - all pass, no regressions.

### Known issues

- **This is vector/spec work, not the illustrated art the brief
  actually asks for.** No painted character, environment, or item art
  exists. That gap is unchanged and can't be closed without an
  image-generation tool - see `ART_GENERATION_PROMPTS.md`'s intro.
- **No font files bundled yet** - Oswald/Inter are documented
  recommendations, not yet added to the project.
- **The wordmark's "distressed" treatment is a stand-in** (a subtle SVG
  `feTurbulence` displacement filter), not a hand-painted texture pass.

### Exact next phase

Resume **Phase 9: Polish** (animation/juice pass, accessibility,
performance) - see below.

## Phase 9: Polish (part 1 - accessibility + performance settings) - complete

### Files modified

- `autoload/game_manager.gd` - **bug fix**: `EventBus.settings_changed`
  had zero listeners anywhere in the codebase. `text_scale`,
  `high_contrast` and (newly) `colorblind_mode` were baked into
  `get_window().theme` exactly once, at `Boot._ready()`, and never
  rebuilt - toggling any of them on the Settings screen changed the
  stored value and did nothing visible until the app restarted. Fixed by
  rebuilding the theme inline in `update_setting()` for those three keys,
  the same way audio volume keys already trigger `AudioManager.apply_volume_settings()`.
  Also added a new `graphics_quality` setting (`"low"`/`"standard"`/
  `"high"`, default `"standard"` - brief section 38's performance tiers)
  and a single `effects_enabled()` helper folding it together with
  `reduced_motion`, replacing three near-duplicate ad hoc checks.
- `scripts/ui/theme_factory.gd` - `build_theme()` now takes a
  `colorblind_mode` parameter. Deliberately does **not** touch palette
  hues (unverifiable without a real screen in this environment - see
  `ART_STYLE_GUIDE.md`); instead adds a visible outline to every button
  state so "which button is this / can I tap it" doesn't depend on
  perceiving a colour difference at all.
- `scenes/boot/boot.gd` - passes `colorblind_mode` through on the initial
  theme build too.
- `scenes/merge_board/merge_board.gd`, `scripts/residence/hotspot_visual.gd`,
  `scenes/world_map/world_map.gd` - the three existing particle/motion
  effects (merge burst, hotspot repair dust, map marker pulse) now check
  `GameManager.effects_enabled()` instead of reading `reduced_motion`
  directly, so `graphics_quality: "low"` also suppresses them - real
  Android performance headroom, not just an accessibility toggle.
- `scenes/settings/settings.gd`/`.tscn` - new "Graphics quality" row
  (Low/Standard/High `OptionButton`) under a new "Graphics" section.
- `tests/smoke_test_settings.gd` - rewritten to actually catch the bug
  above: asserts `get_window().theme` (the live one, not a freshly-built
  throwaway `Theme`) reflects each setting change, and that
  `effects_enabled()` correctly folds `reduced_motion` +
  `graphics_quality`.

### Features completed

- **Accessibility settings now take effect immediately**, no restart
  required: text scale, high contrast, and colour-blind mode (new) all
  rebuild the live theme the moment they're toggled.
- **A real graphics-quality tier setting** exists and is wired through
  to every current particle/motion effect - `"low"` measurably reduces
  what's drawn per frame, which is the actual point of a performance
  tier on Android, not just a UI toggle that does nothing.

### Tests performed

`godot4 --headless --path . --import` clean; full 10-test smoke suite
passes, including the rewritten `smoke_test_settings.tscn` which now
genuinely exercises the live-theme-rebuild bug fix rather than just
building a disposable `Theme` and checking its font size in isolation.

### Known issues

- **Colour-blind mode is shape/outline-based, not palette-based** - a
  hue-shifted, deuteranopia/protanopia-tuned palette pass is still open
  work; doing it correctly needs actual visual verification this
  headless environment can't provide.
- **No audio exists to apply the new graphics tiers' spirit to** - the
  brief's Low/Standard/High modes also cover weather/particle density
  and target frame rate, which don't have enough real content
  (weather, more than one particle effect) yet to meaningfully tier.
- **No new juice/animation content this pass** - Phase 9's "animation
  pass on existing systems" is scoped down to this settings/performance
  work; the fuller repair-sequence/vehicle/character animation work in
  `ART_GENERATION_PROMPTS.md` and `animation_manifest.json` is still
  gated on real art existing to animate.
- **Godot binary still not persisted** in this environment - same caveat
  as every phase so far.

### Exact next phase

**Phase 10 (or continued Phase 9)**: build the 3 remaining residences
(Greybridge School, Saint Mercy Hospital, Northgate Prison) and their
survivor rescues (Dr Imogen Shaw, Riley Chen, Caleb Rusk), the 5
remaining scavenging locations, and a main-story chapter arc connecting
them - the biggest remaining gap is content breadth (half the survivor
roster and most residences are still narratively absent), not any single
system. Illustrated art remains gated on an image-generation tool
becoming available - `ART_ILLUSTRATION_CHECKLIST.md` is ready whenever
that happens.

## Phase 10: Greybridge School - complete

Third residence, following Phase 8's Redwater pattern exactly: a new
`ResidenceDefinition`, 8 quests, a rescue (Riley Chen, a radio technician,
found guarding the roof's radio tower), her own 3-part dialogue scene, a
third `DefenceManager` event, and a new screen/background. The one
deliberate design choice beyond "repeat the pattern": `greybridge_defence`'s
`skill_tags` are `["electronics", "communications"]` - Riley's own skills
- specifically so her skill bonus is live immediately on her own rescue,
closing the "skill bonus mechanism real but nobody currently unlocked
matches it" known issue every phase since 6 has carried forward.

### Files created

- `data/residences/greybridge_school.tres` - 8 hotspots (main hall,
  gymnasium, library, cafeteria, boiler room, admin office, playground
  fence, radio tower), covering construction/clothing/electronics/food/
  tool/trap chains.
- `data/quests/q_clear_main_hall.tres`, `q_salvage_gymnasium.tres`,
  `q_restore_library.tres`, `q_restock_cafeteria.tres`,
  `q_restart_boiler.tres`, `q_secure_admin_office.tres`,
  `q_reinforce_playground_fence.tres`, and the rescue quest
  `q_rescue_riley.tres` (`electronics_3`, `unlock_survivor: riley_chen`,
  `dialogue_trigger_id: riley_01`).
- `data/dialogue/riley_01.tres`/`riley_02.tres`/`riley_03.tres` - Riley
  found behind a wedged-shut stairwell, defensive about the radio signal
  she's kept running, then a branching trust choice.
- `scenes/greybridge/greybridge.gd`/`.tscn` and
  `scenes/greybridge/greybridge_background.gd` - a third distinct
  palette/time-of-day (flat cold overcast daylight) so all three
  residences read as different places even as procedural placeholders;
  the radio tower is drawn as its own foreground silhouette above the
  main building, the actual `radio_tower` hotspot's location.
- Tests: `tests/smoke_test_greybridge.gd`/`.tscn`.

### Files modified

- `autoload/defence_manager.gd` - new `greybridge_defence` event
  (`residence_id: greybridge_school`, `skill_tags: ["electronics",
  "communications"]`, `success_flag: saint_mercy_unlocked`); also filled
  in `redwater_defence`'s previously-empty `success_flag` with
  `greybridge_unlocked` - Phase 8 left it blank because Greybridge didn't
  exist yet to unlock.
- `autoload/residence_manager.gd` - `q_rescue_riley` advances the chapter
  to `chapter_6_the_signal`.
- `scripts/residence/hotspot_visual.gd` - a distinct placeholder shape
  per Greybridge hotspot id (double doors, a basketball hoop, book
  spines, a cafeteria table, a boiler tank, a desk, chain-link diamond
  fencing, and a radio mast).
- `scenes/world_map/world_map.gd`/`.tscn` - `_setup_greybridge_marker()`
  (identical shape to `_setup_redwater_marker()`), routing to the new
  screen once `greybridge_unlocked` is set; refactored the locked-marker
  loop since Greybridge moved out of it.
- `scenes/haven/haven.gd`, `scenes/redwater/redwater.gd`,
  `scenes/defence/defence.gd` - added Chapter 6's title and
  `greybridge_defence`'s/`riley_chen`'s labels so both other residence
  screens and the shared Defence screen display them correctly.
- `autoload/scene_router.gd` - added `"greybridge"`.
- `tests/smoke_test.gd` - added `greybridge.tscn` to the coverage list.

### Features completed

- **A third full residence**, same shape as Hollow Creek and Redwater:
  8 data-driven hotspots, one of them a rescue that unlocks a survivor
  and advances the story.
- **The skill-bonus mechanism is no longer inert for its own rescue** -
  Riley's `electronics`/`communications` skills match
  `greybridge_defence`'s own `skill_tags`, verified directly in
  `smoke_test_greybridge.gd` rather than just asserted in a comment.
- **`redwater_defence` now actually unlocks something** - Phase 8 shipped
  it with an empty `success_flag` because there was nothing yet to
  unlock; that gap is closed.

### Tests performed

Same headless approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- Full existing suite (`smoke_test`, `smoke_test_save`,
  `smoke_test_settings`, `smoke_test_merge`, `smoke_test_residence`,
  `smoke_test_dialogue`, `smoke_test_scavenging`,
  `smoke_test_vehicle_survivors`, `smoke_test_defence`,
  `smoke_test_redwater`) - all still pass, no regressions.
- `tests/smoke_test_greybridge.tscn` (new) - residence data loads with 8
  hotspots; completing every hotspot except the rescue leaves
  `greybridge_defence` un-attemptable; completing `q_rescue_riley` unlocks
  `riley_chen`, advances the chapter to `chapter_6_the_signal`, and its
  `dialogue_trigger_id` is `riley_01`; `greybridge_defence`'s
  `skill_tags` are directly asserted to overlap `riley_chen`'s real
  skills (not a re-implementation - the actual `CharacterDatabase`
  record); a forced success spends the event's own energy cost, marks
  only itself survived, and sets `saint_mercy_unlocked`; a full
  save/reload round trip preserves all of it.

### Known issues

- **Not visually confirmed**, same caveat as every phase.
- **8 hotspots, not spec's fuller count** - same "concrete and earned"
  trade-off every residence's content generation has made.
- **Saint Mercy Hospital and Northgate Prison remain locked
  placeholders** - Dr Imogen Shaw and Caleb Rusk still have no rescue
  path. Caleb in particular has `trap`/`defence` skills that would make
  *every* existing defence event's bonus live at once, once he exists.
- **No route/travel scene between residences**, same gap Phase 8 flagged.
- **Godot binary still not persisted** in this environment.

### Exact next phase

Saint Mercy Hospital (Dr Imogen Shaw) and/or Northgate Prison (Caleb
Rusk) - the same pattern a third time - then the remaining 5 scavenging
locations, then a real look at whether the story-flag/chapter chain needs
a proper main-story arc connecting all five residences rather than each
one only advancing its own next-door neighbour.

## Phase 11: Saint Mercy Hospital - complete

Fourth residence, same Phase 8/10 pattern a third time: a new
`ResidenceDefinition`, 8 quests, a rescue (Dr Imogen Shaw, a former
emergency physician found behind the isolation ward's self-sealed
doors), her own 3-part dialogue scene, a fourth `DefenceManager` event,
and a new screen/background. Unlike Greybridge's deliberately-matched
skill_tags, `saint_mercy_defence` uses the standard `["trap", "defence"]`
tags on purpose - see Features completed.

### Files created

- `data/residences/saint_mercy_hospital.tres` - 8 hotspots (ER reception,
  pharmacy, patient ward, surgical suite, power room, ambulance bay,
  records office, isolation ward), covering construction/medical/
  clothing/tool/electronics/fuel/trap chains.
- `data/quests/q_clear_er_reception.tres`, `q_secure_pharmacy.tres`,
  `q_clear_patient_ward.tres`, `q_restore_surgical_suite.tres`,
  `q_restart_power_room.tres`, `q_clear_ambulance_bay.tres`,
  `q_secure_records_office.tres`, and the rescue quest
  `q_rescue_imogen.tres` (`medical_3`, `unlock_survivor: imogen_shaw`,
  `dialogue_trigger_id: imogen_01`).
- `data/dialogue/imogen_01.tres`/`imogen_02.tres`/`imogen_03.tres` -
  Imogen found behind the isolation ward's self-sealed doors, guarded and
  demanding proof of health before she'll open up (matching her
  `calm_under_pressure`/`guarded` traits), then a branching trust choice.
- `scenes/saint_mercy/saint_mercy.gd`/`.tscn` and
  `scenes/saint_mercy/saint_mercy_background.gd` - a fourth distinct
  palette/time-of-day: full night lit by a sickly green-white emergency
  glow from a handful of still-working windows, rather than any of the
  other three residences' light sources.
- Tests: `tests/smoke_test_saint_mercy.gd`/`.tscn`.

### Files modified

- `autoload/defence_manager.gd` - new `saint_mercy_defence` event
  (`residence_id: saint_mercy_hospital`, `skill_tags: ["trap",
  "defence"]` - deliberately the standard tags, not Imogen's own medical
  ones, since triage skill doesn't make someone better at holding a
  barricade; `success_flag: northgate_unlocked`).
- `autoload/residence_manager.gd` - `q_rescue_imogen` advances the
  chapter to `chapter_7_do_no_harm`.
- `scripts/residence/hotspot_visual.gd` - a distinct placeholder shape
  per Saint Mercy hotspot id (a cross-marked ER doors, pharmacy shelving,
  a hospital bed, an operating table with an overhead light, a power
  room with a lightning-bolt accent, an ambulance silhouette, stacked
  file drawers, and a sealed observation window).
- `scenes/world_map/world_map.gd`/`.tscn` - `_setup_saint_mercy_marker()`
  (identical shape to the Redwater/Greybridge setup functions).
- `scenes/haven/haven.gd`, `scenes/redwater/redwater.gd`,
  `scenes/greybridge/greybridge.gd`, `scenes/defence/defence.gd` - added
  Chapter 7's title and `saint_mercy_defence`'s/`imogen_shaw`'s labels.
- `autoload/scene_router.gd` - added `"saint_mercy"`.
- `tests/smoke_test.gd` - added `saint_mercy.tscn` to the coverage list.

### Features completed

- **A fourth full residence**, same shape as the other three.
- **A deliberate contrast with Phase 10's skill-tag choice, tested
  directly**: `smoke_test_saint_mercy.gd` asserts `saint_mercy_defence`
  uses the standard `["trap", "defence"]` tags *and* that Imogen's real
  skills do **not** match them - a doctor being good at triage doesn't
  make her better at holding a barricade, and the test makes that a
  checked design decision rather than something that could silently
  drift. Those standard tags are waiting for Caleb Rusk (Northgate
  Prison), whose actual skills are `trap`/`defence` - once he exists,
  his bonus goes live for *three* events at once (Hollow Creek, Redwater,
  Saint Mercy), not just one.

### Tests performed

Same headless approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- Full existing suite (all 11 prior smoke tests) - all still pass, no
  regressions.
- `tests/smoke_test_saint_mercy.tscn` (new) - residence data loads with 8
  hotspots; completing every hotspot except the rescue leaves
  `saint_mercy_defence` un-attemptable; completing `q_rescue_imogen`
  unlocks `imogen_shaw`, advances the chapter to `chapter_7_do_no_harm`,
  and its `dialogue_trigger_id` is `imogen_01`; `saint_mercy_defence`'s
  `skill_tags` are directly asserted to be the standard set and to NOT
  overlap Imogen's real skills; a forced success spends the event's own
  energy cost, marks only itself survived, and sets
  `northgate_unlocked`; a full save/reload round trip preserves all of
  it.

### Known issues

- **Not visually confirmed**, same caveat as every phase.
- **8 hotspots, not spec's fuller count** - same trade-off every
  residence's content generation has made.
- **Northgate Prison remains a locked placeholder** - Caleb Rusk still
  has no rescue path, and with him the last unmatched defence skill
  bonus.
- **No route/travel scene between residences**, same gap every phase
  since 8 has flagged.
- **Godot binary still not persisted** in this environment.

### Exact next phase

Northgate Prison (Caleb Rusk) - the fifth and final residence in the
current roster, closing out every existing defence event's skill bonus
at once. After that: the remaining 5 scavenging locations, and a real
look at whether the story-flag/chapter chain needs a proper main-story
arc connecting all five residences rather than each one only advancing
its own next-door neighbour (a Known Issue carried since Phase 8).

## Phase 12: Northgate Prison - complete

Fifth and final residence in the current roster, closing the loop the
previous three phases were building toward: Caleb Rusk's real skills
(`trap`/`defence`/`combat`) match the *standard* `["trap", "defence"]`
tags used by every defence event except Greybridge's - so recruiting him
doesn't just make `northgate_defence`'s bonus live, it retroactively
makes `hollow_creek_first_wave`'s, `redwater_defence`'s, and
`saint_mercy_defence`'s bonuses live too, all at once. Same
`ResidenceDefinition`/quests/dialogue/screen/DefenceManager-event pattern
as Phases 8/10/11.

### Files created

- `data/residences/northgate_prison.tres` - 8 hotspots (sally port,
  guard tower, armory, mess hall, cell block A, control room, transport
  bay, warden's office), covering construction/tool/trap/food/clothing/
  electronics/fuel chains (trap used twice, at different tiers, same as
  Saint Mercy reused medical).
- `data/quests/q_reinforce_sally_port.tres`, `q_repair_guard_tower.tres`,
  `q_secure_armory.tres`, `q_clear_mess_hall.tres`,
  `q_salvage_cell_block.tres`, `q_restore_control_room.tres`,
  `q_clear_transport_bay.tres`, and the rescue quest
  `q_rescue_caleb.tres` (`trap_4` - deliberately his own skill area,
  bringing him security/defence gear as proof rather than medical
  supplies; `unlock_survivor: caleb_rusk`, `dialogue_trigger_id:
  caleb_01`).
- `data/dialogue/caleb_01.tres`/`caleb_02.tres`/`caleb_03.tres` - Caleb
  found holed up in a bunkered warden's office, openly hostile at first
  (matching his `trap`/`defence`/`combat` skillset - he's the first
  rescue who is actually dangerous to approach), with a single seeded
  narrative detail (a scrap of unfamiliar stitched insignia under his
  jacket) per the spec's "hidden Ashborn visual clue" - not explained,
  not pressed by Mara, just noticed. The branching choice lets the player
  ask about it directly or let it go.
- `scenes/northgate/northgate.gd`/`.tscn` and
  `scenes/northgate/northgate_background.gd` - a fifth distinct
  palette/time-of-day: early dawn, cold grey-blue breaking to pale rose,
  completing the "every residence has its own time of day" set (Hollow
  Creek day, Redwater dusk, Greybridge flat overcast, Saint Mercy night,
  Northgate dawn).
- Tests: `tests/smoke_test_northgate.gd`/`.tscn`.

### Files modified

- `autoload/defence_manager.gd` - new `northgate_defence` event
  (`residence_id: northgate_prison`, `skill_tags: ["trap", "defence"]` -
  the standard set, same as Hollow Creek/Redwater/Saint Mercy;
  `success_flag: ""` since there's no sixth residence yet to unlock).
- `autoload/residence_manager.gd` - `q_rescue_caleb` advances the
  chapter to `chapter_8_old_debts`.
- `scripts/residence/hotspot_visual.gd` - a distinct placeholder shape
  per Northgate hotspot id (a barred gate, a stilted watchtower, a
  weapons rack, a mess table, cell bars, a control panel grid, a
  transport truck, and a barred office/desk).
- `scenes/world_map/world_map.gd`/`.tscn` - `_setup_northgate_marker()`
  (identical shape to the other three setup functions) replaces the
  flat "locked" toast Northgate had since Phase 1.
- `scenes/haven/haven.gd`, `scenes/redwater/redwater.gd`,
  `scenes/greybridge/greybridge.gd`, `scenes/saint_mercy/saint_mercy.gd`,
  `scenes/defence/defence.gd` - added Chapter 8's title and
  `northgate_defence`'s/`caleb_rusk`'s labels.
- `autoload/scene_router.gd` - added `"northgate"`.
- `tests/smoke_test.gd` - added `northgate.tscn` to the coverage list.
- `tests/smoke_test_greybridge.gd` - **bug fix, found while writing this
  phase's test**: the forced-success section launched/resolved with
  `"riley_chen"`, whose skills match `greybridge_defence`'s own tags.
  Forcing `success_chance = 1.0` while a matching-skill survivor is
  active triggers the real `minf(chance + 0.15, 0.95)` bonus math, which
  silently *reduces* an intentionally-forced 1.0 down to 0.95 - a 5%
  chance of spurious failure on every run, previously undetected because
  it happened not to trigger across this project's testing so far.
  Switched to `"mara_vale"` (no matching skill) for that section; the
  skill-match itself is proven separately via a direct, non-random
  `CharacterDatabase` assertion that doesn't go through `resolve_choice()`
  at all.

### Features completed

- **A fifth full residence**, same shape as the other four - the current
  roster's residence count is now complete (5/5).
- **The full skill-bonus payoff**: `smoke_test_northgate.gd` directly
  asserts Caleb's real skills overlap all four `["trap", "defence"]`-
  tagged events' tags at once, not just his own. Every defence event's
  skill bonus - documented as "real but currently inert" starting in
  Phase 6 - is now live for at least one recruitable survivor.
- **A real test-flakiness bug caught and fixed**, in an *existing* test
  from two phases ago, by writing this phase's test carefully enough to
  notice the same pattern about to repeat itself - see Files modified.

### Tests performed

Same headless approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- `tests/smoke_test_northgate.tscn` first failed intermittently
  (`SMOKE_NORTHGATE_FAIL: forced-success resolve_choice ... got
  outcome_success: false`) - exactly the skill-bonus-cap interaction
  described above. Re-ran 5 times after the fix with no failures, then
  applied the same fix to `smoke_test_greybridge.gd` and re-ran that 5
  times too.
- Full existing suite (all 12 prior smoke tests) - all still pass, no
  regressions.
- `tests/smoke_test_northgate.tscn` (new, now deterministic) - residence
  data loads with 8 hotspots; completing every hotspot except the rescue
  leaves `northgate_defence` un-attemptable; completing `q_rescue_caleb`
  unlocks `caleb_rusk`, advances the chapter to `chapter_8_old_debts`,
  and its `dialogue_trigger_id` is `caleb_01`; Caleb's real skills are
  directly asserted to overlap all four standard-tag events' `skill_tags`;
  a forced success (launched with a non-matching survivor to stay
  deterministic) spends the event's own energy cost and marks only
  itself survived; a full save/reload round trip preserves all of it.

### Known issues

- **Not visually confirmed**, same caveat as every phase.
- **8 hotspots, not spec's fuller count** - same trade-off every
  residence's content generation has made.
- **`northgate_defence` unlocks nothing** - there's no sixth residence in
  the current roster for its `success_flag` to point at. A genuine stub
  for whatever comes next (the spec's wider story - Eli, the Ashborn,
  the Signal Keeper - none of which exist in this build yet).
- **The Ashborn tease in Caleb's dialogue goes nowhere yet** - it's
  seeded, deliberately not explained, and there is currently no later
  content that pays it off. Honest placeholder for future story work,
  not a bug.
- **No route/travel scene between residences**, same gap every phase
  since 8 has flagged.
- **Godot binary still not persisted** in this environment.

### Exact next phase

With all 5 currently-planned residences built, the largest remaining
gaps are: the 5 unbuilt scavenging locations from the original 10-location
spec; a real main-story arc connecting all five residences (today each
one only advances the very next residence's own unlock flag, with no
overarching thread); and illustrated art, still gated on an
image-generation tool becoming available (`ART_ILLUSTRATION_CHECKLIST.md`
is ready whenever that happens).

## Phase 13: Remaining scavenging locations + main-story capstone - complete

Two threads requested together: finish the original 10-location
scavenging spec (5 more locations), and give the 5-residence roster a
connecting narrative thread instead of each residence only knowing about
unlocking its immediate neighbour.

### Files created

- `data/scavenging/police_checkpoint.tres`, `electronics_workshop.tres`,
  `clothing_outlet.tres`, `warehouse_depot.tres`, and
  `radio_relay_station.tres` - completing the original 10-location spec
  (Phase 5 built the first 5). Cover the trap, electronics, clothing,
  and vehicle_parts/construction chains, none of which had a primary
  scavenging source before. `police_checkpoint` is the first scavenging
  location with `human_threat` higher than `zombie_threat` (3 vs 2) and
  seeds an "arranged, not overrun" detail hinting at the Ashborn, echoing
  Caleb Rusk's own tease from Phase 12. `radio_relay_station` is the
  first mission ever to use `story_condition` for real (gated on
  `saint_mercy_unlocked`) and is the first scavenging loot table to
  include the `token_reward` (Haven Tokens) chain.
- `data/dialogue/signal_keeper_01.tres` through `signal_keeper_05.tres` -
  the main-story capstone: an unprompted, live transmission on Hollow
  Creek's own radio (payoff for the very first line of dialogue in the
  game, `intro_01`/`intro_02`) from whoever built the Haven Line network.
  Confirms the network's status, gives Mara's search for her missing
  brother Eli a genuine (unresolved) lead, and connects Caleb's seeded
  Ashborn tease to something larger - deliberately a hook forward, not a
  resolution. Ends on a branching choice (chase the lead east vs.
  consolidate what's built) that's flavour/relationship-only for now,
  same honest scope as every other branching choice in this build.
- Tests: `tests/smoke_test_main_story.gd`/`.tscn`.

### Files modified

- `autoload/scavenging_manager.gd` - **bug fix**: `ScavengingMission.
  story_condition` existed on the schema since Phase 5 but was never
  read anywhere - every mission was always available regardless of its
  value. Added `is_available()`, checked by `launch_mission()`
  (returns `"not_available"` instead of silently launching) and by the
  World Map's marker-building.
- `autoload/defence_manager.gd` - new `all_events_survived()`, the
  Signal Keeper capstone's trigger condition.
- `scenes/world_map/world_map.gd`/`.tscn` - 5 new
  `SCAVENGING_MARKER_POSITIONS` entries; `_build_scavenging_markers()`
  now skips a mission whose `story_condition` isn't met instead of
  always building every marker; refreshed the module docstring, which
  had gone stale describing Saint Mercy/Northgate as still-locked
  placeholders after Phases 11-12 actually built them.
- `scenes/scavenging/scavenging.gd` - **bug fix**: `SURVIVOR_NAMES` only
  ever had Mara and Noah, so sending any later-recruited survivor (Lena,
  Riley, Imogen, Caleb) on a scavenging mission showed their raw id
  instead of a display name - never caught earlier because no smoke
  test asserts a screen's button text. Also now guards against
  navigating to an unavailable (`story_condition` unmet) mission the
  same way it already guarded against an unknown one.
- `scenes/dialogue/dialogue.gd` - **the same bug, found while adding the
  Signal Keeper speaker**: `SPEAKER_NAMES`/`SPEAKER_COLORS` also only
  ever had Mara and Noah, so every later rescue scene's own speaker
  (Lena, Riley, Imogen, Caleb) displayed as a literal id string with a
  generic grey portrait instead of their name and an accent colour.
  Fixed for all four, plus a new `"signal_keeper"` entry.
- `scenes/haven/haven.gd` - the capstone trigger itself: once
  `DefenceManager.all_events_survived()` is true and
  `signal_keeper_triggered` isn't yet set, advances to
  `chapter_9_the_signal_keeper` and starts the dialogue chain - same
  active-scene-guard and one-time-flag pattern as the existing Chapter 1
  intro trigger just above it.
- `scenes/redwater/redwater.gd`, `scenes/greybridge/greybridge.gd`,
  `scenes/saint_mercy/saint_mercy.gd`, `scenes/northgate/northgate.gd` -
  added Chapter 9's title so every residence screen displays it
  correctly once reached, not just Haven.
- `tests/smoke_test_scavenging.gd` - now expects 10 missions, and adds a
  section proving `story_condition` actually gates `launch_mission()`
  and availability (the bug fix above).

### Features completed

- **All 10 of the original spec's scavenging locations exist.**
- **`story_condition` does something real for the first time** - a
  scavenging location can now be gated behind story progress, not just
  always available from the start.
- **Two more "only Mara and Noah" display bugs found and fixed** (Files
  modified) - the same shape of gap Phase 9 found in
  `EventBus.settings_changed`, now found twice more in screen-local
  speaker/survivor name dicts that nobody had extended past Phase 4/5.
- **The 5-residence roster has a connecting narrative thread.** Every
  defence event previously only unlocked its immediate neighbour with no
  awareness of the wider picture; the Signal Keeper capstone is the
  first content that reacts to "the whole roster," not just one
  residence, and it deliberately ties back to the game's very first
  line of dialogue and Caleb's still-unresolved Ashborn tease rather
  than introducing an unconnected new thread.

### Tests performed

Same headless approach as every phase, `timeout`-wrapped throughout:

- `godot4 --headless --path . --import` - clean, zero script/parse errors.
- Full existing suite (all 13 prior smoke tests) - all still pass, no
  regressions.
- `tests/smoke_test_scavenging.tscn` (updated) - 10 missions load;
  `radio_relay_station` is correctly unavailable before
  `saint_mercy_unlocked` is set (and `launch_mission()` refuses it with
  `"not_available"`) and correctly available after; every other existing
  assertion (energy cost, forced success/failure, completion tracking,
  save/reload) still passes unchanged.
- `tests/smoke_test_main_story.tscn` (new) - `all_events_survived()`
  is false with 0-4 of 5 events survived and only becomes true once all
  5 are (checked after each individual event, not just at the end,
  guarding against an off-by-one); the `signal_keeper_01`-`05` chain's
  `next_id` links are verified end to end and its final entry's
  branching choice is real; the capstone's chapter advance and one-time
  trigger flag both persist through a save/reload round trip.

### Known issues

- **The Signal Keeper's branching choice doesn't gate anything yet** -
  both options grant identical mechanical rewards; only the
  `relationship_changes` flag differs. Honest placeholder for whichever
  future phase builds on this thread, not a bug.
- **The Ashborn/Eli threads both remain open** - by design (see Features
  completed), but there is currently no further content for either to
  lead to. A future phase would need to build that before this capstone
  stops feeling like a hook with nothing behind it.
- **5 of the 10 scavenging locations remain danger_rating <= 2 with
  human_threat 0** - `police_checkpoint` is the only new location that
  meaningfully raises human threat; the original 5 are also still all
  zombie-only encounters. Matches Phase 5's own established tone, not a
  regression, but worth knowing if a future pass wants more human-threat
  variety.
- **Not visually confirmed**, same caveat as every phase.
- **Godot binary still not persisted** in this environment.

### Exact next phase

With scavenging locations complete and the roster's residences now
tied together by one real narrative thread, the largest remaining gaps
are: illustrated art (still gated on an image-generation tool -
`ART_ILLUSTRATION_CHECKLIST.md` is ready whenever that happens), real
audio (same fundamental gap, see `AUDIO_ASSET_GUIDE.md`), and deciding
whether the Ashborn/Eli threads get built out further or the project
moves to a pure polish pass (animation, performance profiling on an
actual device, accessibility beyond what Phase 9 covered).

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the full smoke test suite (always with a timeout wrapper)
for f in smoke_test smoke_test_save smoke_test_settings smoke_test_merge smoke_test_residence smoke_test_dialogue smoke_test_scavenging smoke_test_vehicle_survivors smoke_test_defence smoke_test_redwater smoke_test_greybridge smoke_test_saint_mercy smoke_test_northgate smoke_test_main_story; do
  timeout 30 godot4 --headless --path /path/to/dead-haven-merge-survive "tests/$f.tscn"
done

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```
