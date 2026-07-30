# Tests

Godot has no built-in unit-test runner comparable to a typical xUnit
framework; these are small headless-runnable scenes instead. Each one
loads real game systems (autoloads, real `.tscn` screens) and prints a
`..._OK` / `..._FAIL` line, so they work in CI or a plain terminal with no
display server.

Run any of them with a Godot 4.3+ binary:

```bash
godot4 --headless --path . tests/smoke_test.tscn
godot4 --headless --path . tests/smoke_test_save.tscn
godot4 --headless --path . tests/smoke_test_settings.tscn
godot4 --headless --path . tests/smoke_test_merge.tscn
godot4 --headless --path . tests/smoke_test_residence.tscn
```

None of these are wired up as the project's `run/main_scene` - they're
opt-in, point Godot at them directly as shown above.

## What each one covers

- **smoke_test** - instantiates every screen (Haven, Merge Board, World Map, Survivors, Settings, Dev Diagnostics) in turn and fails loudly if any of them throws a script error on `_ready()`.
- **smoke_test_save** - new game -> mutate resources -> save -> reload -> asserts the values round-tripped (as deltas from a post-`new_game()` baseline, not hardcoded absolutes, since Phase 2's starting board grants its own discovery-reward coins); then corrupts the primary save file on disk and asserts `SaveManager` recovers from the `.bak` copy instead of crashing.
- **smoke_test_settings** - changes audio/accessibility settings through `GameManager.update_setting()` and asserts the audio bus volume and rebuilt `Theme`'s font size actually reflect them.
- **smoke_test_merge** (Phase 2) - starting board layout; a valid merge and its discovery reward; invalid merges (producers, mismatched chains) and max-level merges are correctly rejected; producer tap spends energy and enforces cooldown, and the debug reset-cooldowns tool clears it; debug infinite-energy mode spends without deducting; storage transfer both directions; soft-delete + undo; reward-chain item collection grants the right amount; a full save/reload round trip preserves item count, storage contents and discovery state.
- **smoke_test_residence** (Phase 3) - residence/hotspot/quest data loads correctly; a task refuses to complete before its required item exists; completing it consumes the item, grants coins/XP, and flips the hotspot to COMPLETED; re-completing the same quest is rejected; completing the Noah-rescue quest unlocks him via the generic `unlock_survivor` reward; `get_active_quest_for_hotspot()` returns null once a hotspot's task is done; a full save/reload round trip preserves completed quests, hotspot state and the Noah unlock.

## What these do NOT cover

They run with Godot's headless server backend - no window, no real touch
input, no on-screen rendering. They catch script/logic errors, not visual
bugs, gesture timing, or layout issues on an actual device. Use
`PHASE1_MANUAL_CHECKLIST.md` for Phase 1 screens on a real Android device
or in the editor's running game view; an equivalent Phase 2 checklist for
drag/merge/producer gestures hasn't been written yet (see DEVELOPMENT_LOG.md
Known issues).

Results as of Phase 3 (Godot 4.3.stable, downloaded fresh into this
development container - see DEVELOPMENT_LOG.md Known issues about it not
persisting between sessions): all five pass.
