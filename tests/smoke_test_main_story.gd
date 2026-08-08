extends Node
## SmokeTestMainStory
##
## Phase 13's connecting main-story thread: DefenceManager.all_events_survived()
## flips true only once every event in the roster is survived (not just
## most of them), and the "Signal Keeper" capstone dialogue - triggered
## from scenes/haven/haven.gd once that happens - is real, complete
## content: a 5-entry chain with correct next_id links, a working
## branching choice, and it plausibly advances the story
## (GameManager.advance_chapter to chapter_9_the_signal_keeper). This
## test exercises the DialogueManager/DefenceManager/GameManager layer
## directly rather than simulating Haven's own scene-navigation trigger -
## same approach smoke_test_dialogue.gd uses for the Chapter 1 intro,
## since no existing test simulates a screen actually becoming the active
## scene in this headless environment (see scenes/haven/haven.gd's own
## active-scene guard for why that's deliberately never done here).
##
## Run: godot4 --headless --path . tests/smoke_test_main_story.tscn

func _fail(msg: String) -> void:
	print("SMOKE_MAIN_STORY_FAIL: %s" % msg)
	get_tree().quit(1)

## Marks every hotspot on every residence COMPLETED directly (bypassing
## the merge-board item flow, which Phase 3/8/10/11/12's own tests
## already cover in full) so this test can focus purely on the
## cross-residence capstone logic without re-proving each residence's
## repair mechanics from scratch.
func _complete_every_residence() -> void:
	for residence_id in ["hollow_creek_farmhouse", "redwater_service_station", "greybridge_school", "saint_mercy_hospital", "northgate_prison"]:
		var residence := ResidenceManager.get_residence(residence_id)
		for hotspot in residence.hotspots:
			ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED

func _ready() -> void:
	GameManager.new_game()
	_complete_every_residence()

	# -- all_events_survived() requires every event, not just most --------
	var event_ids: Array = DefenceManager.events.keys()
	if event_ids.size() != 5:
		_fail("expected 5 defence events in the current roster, got %d" % event_ids.size())
		return
	if DefenceManager.all_events_survived():
		_fail("all_events_survived() should be false before any event is survived")
		return

	for i in event_ids.size():
		var event_id: String = event_ids[i]
		GameManager.resources.energy = GameManager.resources.energy_max
		DefenceManager.launch(event_id, "")
		DefenceManager.event_choices[event_id][0].success_chance = 1.0
		var result := DefenceManager.resolve_choice(event_id, 0, "")
		if not result.outcome_success:
			_fail("forced-success resolve_choice on %s should succeed, got %s" % [event_id, str(result)])
			return
		var expect_all_done: bool = (i == event_ids.size() - 1)
		if DefenceManager.all_events_survived() != expect_all_done:
			_fail("all_events_survived() should only be true once every event is survived (after %d/%d, got %s)" % [i + 1, event_ids.size(), str(DefenceManager.all_events_survived())])
			return
	print("SMOKE_MAIN_STORY: all_events_survived() correctly requires every event, not just most OK")

	# -- The capstone dialogue is a real, complete 5-entry chain ------------
	var chain_ids := ["signal_keeper_01", "signal_keeper_02", "signal_keeper_03", "signal_keeper_04", "signal_keeper_05"]
	for i in chain_ids.size():
		if not DialogueManager.has_entry(chain_ids[i]):
			_fail("missing dialogue entry %s" % chain_ids[i])
			return
		var entry := DialogueManager.get_entry(chain_ids[i])
		var expected_next: String = chain_ids[i + 1] if i < chain_ids.size() - 1 else ""
		if entry.next_id != expected_next:
			_fail("%s.next_id should be '%s', got '%s'" % [chain_ids[i], expected_next, entry.next_id])
			return
	var final_entry := DialogueManager.get_entry("signal_keeper_05")
	if final_entry.branching_options.size() != 2:
		_fail("signal_keeper_05 should offer a real branching choice, got %d options" % final_entry.branching_options.size())
		return
	print("SMOKE_MAIN_STORY: signal_keeper dialogue is a complete, correctly-linked 5-entry chain OK")

	# -- The capstone plausibly advances the story --------------------------
	var chapter_before: String = GameManager.profile.current_chapter_id
	GameManager.set_story_flag("signal_keeper_triggered", true)
	GameManager.advance_chapter("chapter_9_the_signal_keeper")
	if GameManager.profile.current_chapter_id == chapter_before or GameManager.profile.current_chapter_id != "chapter_9_the_signal_keeper":
		_fail("expected chapter_9_the_signal_keeper, got %s" % GameManager.profile.current_chapter_id)
		return
	if not GameManager.get_story_flag("signal_keeper_triggered", false):
		_fail("signal_keeper_triggered story flag should be set")
		return
	print("SMOKE_MAIN_STORY: capstone advances the chapter and sets its one-time trigger flag OK")

	# -- Save / reload round trip -------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if GameManager.profile.current_chapter_id != "chapter_9_the_signal_keeper":
		_fail("reloaded chapter should still be chapter_9_the_signal_keeper")
		return
	if not GameManager.get_story_flag("signal_keeper_triggered", false):
		_fail("reloaded signal_keeper_triggered flag should still be true")
		return
	if not DefenceManager.all_events_survived():
		_fail("reloaded defence state should still show all_events_survived()")
		return
	print("SMOKE_MAIN_STORY: save/reload round trip OK")

	print("SMOKE_MAIN_STORY_TEST_OK")
	get_tree().quit(0)
