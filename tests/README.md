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
godot4 --headless --path . tests/smoke_test_dialogue.tscn
godot4 --headless --path . tests/smoke_test_scavenging.tscn
godot4 --headless --path . tests/smoke_test_vehicle_survivors.tscn
```

All of the above are cheap to run with a `timeout` wrapper (e.g.
`timeout 30 godot4 ...`) and it's worth always doing so - see Phase 5's
entry in `DEVELOPMENT_LOG.md` for a real case where a headless
`SceneTree` script hung indefinitely instead of exiting non-zero after a
script error, and would have looked like a stuck terminal rather than a
failure without a timeout.

None of these are wired up as the project's `run/main_scene` - they're
opt-in, point Godot at them directly as shown above.

## What each one covers

- **smoke_test** - instantiates every screen (Haven, Merge Board, World Map, Survivors, Settings, Dev Diagnostics) in turn and fails loudly if any of them throws a script error on `_ready()`.
- **smoke_test_save** - new game -> mutate resources -> save -> reload -> asserts the values round-tripped (as deltas from a post-`new_game()` baseline, not hardcoded absolutes, since Phase 2's starting board grants its own discovery-reward coins); then corrupts the primary save file on disk and asserts `SaveManager` recovers from the `.bak` copy instead of crashing.
- **smoke_test_settings** - changes audio/accessibility settings through `GameManager.update_setting()` and asserts the audio bus volume and rebuilt `Theme`'s font size actually reflect them.
- **smoke_test_merge** (Phase 2) - starting board layout; a valid merge and its discovery reward; invalid merges (producers, mismatched chains) and max-level merges are correctly rejected; producer tap spends energy and enforces cooldown, and the debug reset-cooldowns tool clears it; debug infinite-energy mode spends without deducting; storage transfer both directions; soft-delete + undo; reward-chain item collection grants the right amount; a full save/reload round trip preserves item count, storage contents and discovery state.
- **smoke_test_residence** (Phase 3) - residence/hotspot/quest data loads correctly; a task refuses to complete before its required item exists; completing it consumes the item, grants coins/XP, and flips the hotspot to COMPLETED; re-completing the same quest is rejected; completing the Noah-rescue quest unlocks him via the generic `unlock_survivor` reward; `get_active_quest_for_hotspot()` returns null once a hotspot's task is done; a full save/reload round trip preserves completed quests, hotspot state and the Noah unlock.
- **smoke_test_dialogue** (Phase 4) - the intro dialogue chain's `next_id` links resolve correctly end to end; `q_rescue_noah`'s `dialogue_trigger_id` and its branching options are wired as expected; applying a branching choice's effects grants the right reward and sets the right story flag; completing the front-door quest advances the chapter exactly once (re-advancing to the same chapter is a verified no-op); a full save/reload round trip preserves the chapter and story flags. This test also caught a real regression during development - see DEVELOPMENT_LOG.md Phase 4 "Tests performed" for the `smoke_test.tscn` hang it led to finding and fixing.
- **smoke_test_scavenging** (Phase 5) - mission content loads (5 locations, each with 2 encounter choices); launching a mission spends its energy cost and is refused with `no_energy` when there isn't enough; a forced-success resolve (temporarily overriding a loaded mission's `success_chance` in memory) grants both the base loot table and the choice's bonus loot; a forced-failure resolve applies exactly the configured penalty and never sets `GameManager.is_game_active` to false; completion counts and a save/reload round trip both check out.
- **smoke_test_vehicle_survivors** (Phase 6) - 6 survivors load with the expected shape; the delivery van is genuinely undiscovered at game start and refuses to upgrade; completing all 9 Hollow Creek Farmhouse hotspots discovers it; upgrading without the stage-1 item is refused, spawning it and retrying consumes it and advances the stage; Noah's personal quest completes through the generic quest path with no hotspot involved; the actual skill-matching function (not a reimplementation) is confirmed true for Noah on a matching mission and false for Mara/no-survivor; a save/reload round trip preserves vehicle discovery, stage, and quest completion.

## What these do NOT cover

They run with Godot's headless server backend - no window, no real touch
input, no on-screen rendering. They catch script/logic errors, not visual
bugs, gesture timing, or layout issues on an actual device. Use
`PHASE1_MANUAL_CHECKLIST.md` for Phase 1 screens on a real Android device
or in the editor's running game view; an equivalent Phase 2 checklist for
drag/merge/producer gestures hasn't been written yet (see DEVELOPMENT_LOG.md
Known issues).

Results as of Phase 6 (Godot 4.3.stable, downloaded fresh into this
development container - see DEVELOPMENT_LOG.md Known issues about it not
persisting between sessions): all eight pass. Run each with a `timeout`
wrapper if you're scripting this - both `smoke_test.tscn` (Phase 4) and
the one-off `generate_scavenging.gd` content script (Phase 5) genuinely
hung from real bugs during development (see DEVELOPMENT_LOG.md for both),
and while those specific bugs are fixed, a `timeout` around any headless
run here is cheap insurance against a future regression doing the same
thing.
