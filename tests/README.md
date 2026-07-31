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
godot4 --headless --path . tests/smoke_test_merge_icons.tscn
godot4 --headless --path . tests/smoke_test_ui_skin.tscn
godot4 --headless --path . tests/smoke_test_residence.tscn
godot4 --headless --path . tests/smoke_test_dialogue.tscn
godot4 --headless --path . tests/smoke_test_scavenging.tscn
godot4 --headless --path . tests/smoke_test_vehicle_survivors.tscn
godot4 --headless --path . tests/smoke_test_defence.tscn
godot4 --headless --path . tests/smoke_test_redwater.tscn
godot4 --headless --path . tests/smoke_test_greybridge.tscn
godot4 --headless --path . tests/smoke_test_saint_mercy.tscn
godot4 --headless --path . tests/smoke_test_northgate.tscn
godot4 --headless --path . tests/smoke_test_main_story.tscn
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

- **smoke_test** - instantiates every screen (Splash, Haven, Redwater, Greybridge, Saint Mercy, Northgate, Merge Board, World Map, Survivors, Settings, Dev Diagnostics, Dialogue, Scavenging, Vehicle, Defence) in turn and fails loudly if any of them throws a script error on `_ready()`. This is also what caught Phase 8's `world_map.gd` `%MapArea` bug (see DEVELOPMENT_LOG.md Phase 8) - a script error on instantiation doesn't fail this test's own pass/fail check by itself, but it's visible in the output, which is why every phase's regression run always reads the full output, not just the final `_OK` line.
- **smoke_test_save** - new game -> mutate resources -> save -> reload -> asserts the values round-tripped (as deltas from a post-`new_game()` baseline, not hardcoded absolutes, since Phase 2's starting board grants its own discovery-reward coins); then corrupts the primary save file on disk and asserts `SaveManager` recovers from the `.bak` copy instead of crashing.
- **smoke_test_settings** - changes audio/accessibility settings through `GameManager.update_setting()` and asserts the audio bus volume and the *live* `get_window().theme` (not a freshly-built one) actually reflect text_scale/high_contrast/colorblind_mode changes - this test caught a real Phase 9 bug where `EventBus.settings_changed` had zero listeners, so those three settings were stored and toggleable but had no visible effect until an app restart; also asserts `GameManager.effects_enabled()` correctly folds together `reduced_motion` and the `graphics_quality` tier (Phase 9's new Low/Standard/High setting).
- **smoke_test_merge** (Phase 2) - starting board layout; a valid merge and its discovery reward; invalid merges (producers, mismatched chains) and max-level merges are correctly rejected; producer tap spends energy and enforces cooldown, and the debug reset-cooldowns tool clears it; debug infinite-energy mode spends without deducting; storage transfer both directions; soft-delete + undo; reward-chain item collection grants the right amount; a full save/reload round trip preserves item count, storage contents and discovery state.
- **smoke_test_merge_icons** - inventories all 101 implemented item definitions, asserts every `icon_path` exists and imports as a 256 x 256 texture, and verifies every definition takes the final-art rendering path rather than the procedural fallback.
- **smoke_test_ui_skin** - verifies all eight component-state styles, final resource/navigation/toggle icons, selected navigation treatment, illustrated map-marker routing, and the absence of marker text placeholders.
- **smoke_test_animation_layer** - verifies shared UI motion, reduced-motion fallback, off-screen ambience suspension, vehicle presentation state neutrality, and that animation does not mutate resources or profile progression.
- **smoke_test_residence** (Phase 3) - residence/hotspot/quest data loads correctly; a task refuses to complete before its required item exists; completing it consumes the item, grants coins/XP, and flips the hotspot to COMPLETED; re-completing the same quest is rejected; completing the Noah-rescue quest unlocks him via the generic `unlock_survivor` reward; `get_active_quest_for_hotspot()` returns null once a hotspot's task is done; a full save/reload round trip preserves completed quests, hotspot state and the Noah unlock.
- **smoke_test_dialogue** (Phase 4) - the intro dialogue chain's `next_id` links resolve correctly end to end; `q_rescue_noah`'s `dialogue_trigger_id` and its branching options are wired as expected; applying a branching choice's effects grants the right reward and sets the right story flag; completing the front-door quest advances the chapter exactly once (re-advancing to the same chapter is a verified no-op); a full save/reload round trip preserves the chapter and story flags. This test also caught a real regression during development - see DEVELOPMENT_LOG.md Phase 4 "Tests performed" for the `smoke_test.tscn` hang it led to finding and fixing.
- **smoke_test_scavenging** (Phase 5, extended Phase 13) - mission content loads (10 locations, each with 2 encounter choices); launching a mission spends its energy cost and is refused with `no_energy` when there isn't enough; a forced-success resolve (temporarily overriding a loaded mission's `success_chance` in memory) grants both the base loot table and the choice's bonus loot; a forced-failure resolve applies exactly the configured penalty and never sets `GameManager.is_game_active` to false; completion counts and a save/reload round trip both check out. Phase 13 added a `story_condition` gating check - `radio_relay_station` is correctly unavailable (and `launch_mission()` refuses it with `not_available`) before `saint_mercy_unlocked` is set, and correctly available after, guarding a real bug where `story_condition` had existed on the schema since Phase 5 but was never actually read anywhere.
- **smoke_test_vehicle_survivors** (Phase 6) - 6 survivors load with the expected shape; the delivery van is genuinely undiscovered at game start and refuses to upgrade; completing all 9 Hollow Creek Farmhouse hotspots discovers it; upgrading without the stage-1 item is refused, spawning it and retrying consumes it and advances the stage; Noah's personal quest completes through the generic quest path with no hotspot involved; the actual skill-matching function (not a reimplementation) is confirmed true for Noah on a matching mission and false for Mara/no-survivor; a save/reload round trip preserves vehicle discovery, stage, and quest completion.
- **smoke_test_defence** (Phase 7) - the gate correctly refuses `can_attempt()`/`launch()` before all 9 hotspots are done; launching spends the energy cost; a forced failure never sets the survived flag or touches `GameManager.is_game_active`, and reverts exactly one hotspot to DESTROYED whose quest becomes completable again; re-repairing it makes the event attemptable again, and a forced success sets the survived flag, advances the chapter, and unlocks the Redwater story flag; a save/reload round trip preserves all of it. This test also caught a real GDScript limitation - see DEVELOPMENT_LOG.md Phase 7 for the `const` vs `var` fix it led to. Only exercises Hollow Creek's own `hollow_creek_first_wave` event - see smoke_test_redwater below for Phase 8's second event.
- **smoke_test_redwater** (Phase 8) - Redwater Service Station's residence data loads with 8 hotspots; `get_active_quest_for_hotspot("fuel_pumps", "hollow_creek_farmhouse")` correctly resolves to nothing while the same lookup against `"redwater_service_station"` resolves to the right quest, guarding a real bug `task_panel.gd` had (see DEVELOPMENT_LOG.md Phase 8); completing every hotspot except the rescue leaves `redwater_defence` un-attemptable; completing the Lena-rescue quest unlocks `lena_ortiz`, advances the chapter to `chapter_5_the_station`, and its `dialogue_trigger_id` is wired correctly; once every hotspot is done, `redwater_defence` becomes attemptable, spends its own energy cost, and a forced success marks it (and only it, not Hollow Creek's event) survived; a save/reload round trip preserves all of it.
- **smoke_test_greybridge** (Phase 10) - same shape as smoke_test_redwater for Greybridge School's 8 hotspots and the Riley-rescue quest (unlocks `riley_chen`, advances to `chapter_6_the_signal`, `dialogue_trigger_id` is `riley_01`); additionally asserts `greybridge_defence`'s `skill_tags` actually overlap `riley_chen`'s real `CharacterDatabase` skills (not a re-implementation or a comment claiming it) - the first defence event whose skill bonus is verified live for its own rescue rather than documented as inert; a forced success spends the event's own energy cost, marks only itself survived, and sets `saint_mercy_unlocked`; a save/reload round trip preserves all of it.
- **smoke_test_saint_mercy** (Phase 11) - same shape again for Saint Mercy Hospital's 8 hotspots and the Imogen-rescue quest (unlocks `imogen_shaw`, advances to `chapter_7_do_no_harm`, `dialogue_trigger_id` is `imogen_01`); the deliberate mirror-image assertion to smoke_test_greybridge's - checks `saint_mercy_defence`'s `skill_tags` are the standard `["trap", "defence"]` set AND that they do NOT overlap Imogen's real medical skills, making that design choice (a doctor's skills don't help hold a barricade) a checked fact instead of an assumption; a forced success spends the event's own energy cost, marks only itself survived, and sets `northgate_unlocked`; a save/reload round trip preserves all of it.
- **smoke_test_northgate** (Phase 12) - same shape again for Northgate Prison's 8 hotspots and the Caleb-rescue quest (unlocks `caleb_rusk`, advances to `chapter_8_old_debts`, `dialogue_trigger_id` is `caleb_01`); the payoff test - directly asserts Caleb's real skills (`trap`/`defence`/`combat`) overlap the `skill_tags` of all four standard-tag defence events (`hollow_creek_first_wave`, `redwater_defence`, `saint_mercy_defence`, `northgate_defence`) at once, not just his own, closing the "skill bonus mechanism real but nobody currently unlocked matches it" situation every phase since 6 has carried. Writing this test caught a real flakiness bug (see DEVELOPMENT_LOG.md Phase 12): forcing `success_chance = 1.0` while resolving with a matching-skill survivor triggers the actual skill-bonus math (`minf(1.0 + 0.15, 0.95)`), which *reduces* an intended certainty to 95% - a ~1-in-20 chance of spurious failure. Fixed here (and retroactively in `smoke_test_greybridge.gd`, which had the same latent issue) by resolving with a non-matching survivor for the deterministic forced-outcome checks, while the skill-match itself is proven separately via a direct assertion that never touches `randf()`.
- **smoke_test_main_story** (Phase 13) - marks every hotspot on all 5 residences COMPLETED directly (bypassing the merge-board flow those residences' own tests already cover) so it can focus on the cross-residence capstone logic: `DefenceManager.all_events_survived()` is checked after each of the 5 events is individually forced to succeed, asserting it stays false until the very last one (not just "eventually true") to guard against an off-by-one; the `signal_keeper_01`-`05` dialogue chain's `next_id` links are verified end to end via `DialogueManager` directly (not by simulating Haven actually becoming the active scene - see the test's own docstring for why no test in this project does that) and its final entry's branching choice is confirmed real; the capstone's chapter advance and one-time trigger flag both persist through a save/reload round trip.

## What these do NOT cover

They run with Godot's headless server backend - no window, no real touch
input, no on-screen rendering. They catch script/logic errors, not visual
bugs, gesture timing, or layout issues on an actual device. Use
`PHASE1_MANUAL_CHECKLIST.md` for Phase 1 screens on a real Android device
or in the editor's running game view; an equivalent Phase 2 checklist for
drag/merge/producer gestures hasn't been written yet (see DEVELOPMENT_LOG.md
Known issues).

Results as of Phase 13 (Godot 4.3.stable, downloaded fresh into this
development container - see DEVELOPMENT_LOG.md Known issues about it not
persisting between sessions): all fourteen pass, deterministically (see
`smoke_test_northgate`'s entry above for a flakiness bug two tests had
until Phase 12). Run each with a `timeout`
wrapper if you're scripting this - both `smoke_test.tscn` (Phase 4) and
the one-off `generate_scavenging.gd` content script (Phase 5) genuinely
hung from real bugs during development (see DEVELOPMENT_LOG.md for both),
and while those specific bugs are fixed, a `timeout` around any headless
run here is cheap insurance against a future regression doing the same
thing.
