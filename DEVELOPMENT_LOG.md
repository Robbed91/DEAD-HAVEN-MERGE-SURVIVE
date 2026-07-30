# Development log

This is the authoritative phase-by-phase record for Dead Haven: Merge &
Survive, per the project's working rules: work incrementally, keep the
project runnable after every phase, and report honestly at the end of
each one.

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
