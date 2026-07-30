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
