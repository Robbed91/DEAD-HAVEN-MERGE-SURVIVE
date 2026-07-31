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

### Commands required to run or export the project

```bash
# Open and run in the editor
# (Godot 4.3+, standard build, GDScript-only project)
godot4 --path /path/to/dead-haven-merge-survive

# Headless import check (populates .godot/ cache, surfaces parse errors)
godot4 --headless --path /path/to/dead-haven-merge-survive --import

# Run the full smoke test suite (always with a timeout wrapper)
for f in smoke_test smoke_test_save smoke_test_settings smoke_test_merge smoke_test_residence smoke_test_dialogue smoke_test_scavenging smoke_test_vehicle_survivors smoke_test_defence smoke_test_redwater smoke_test_greybridge smoke_test_saint_mercy smoke_test_northgate; do
  timeout 30 godot4 --headless --path /path/to/dead-haven-merge-survive "tests/$f.tscn"
done

# Android export (after templates/SDK/keystore are configured in the editor)
godot4 --headless --path /path/to/dead-haven-merge-survive \
  --export-debug "Android" build/android/dead_haven.apk
```
