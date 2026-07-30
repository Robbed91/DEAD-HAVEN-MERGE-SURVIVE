extends Node
## SmokeTestDefence
##
## Exercises DefenceManager directly (no GUI - see tests/README.md) using
## Hollow Creek's "hollow_creek_first_wave" event: the gate (can't attempt
## before all 9 hotspots are done), energy cost, forced success (chapter
## advances, Redwater unlocks, survived flag sticks), forced failure (a
## hotspot reverts to DESTROYED and can be re-repaired, the attempt stays
## retriable, GameManager.is_game_active never goes false), and it all
## persisting through save/reload. Phase 8's smoke_test_redwater.gd
## exercises the generalized multi-event support this test doesn't cover
## (a second event, "redwater_defence", on a different residence).
##
## Run: godot4 --headless --path . tests/smoke_test_defence.tscn

const EVENT_ID := "hollow_creek_first_wave"

func _fail(msg: String) -> void:
	print("SMOKE_DEFENCE_FAIL: %s" % msg)
	get_tree().quit(1)

func _complete_all_hotspots(residence_id: String) -> void:
	var residence := ResidenceManager.get_residence(residence_id)
	for hotspot in residence.hotspots:
		var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot.id, residence_id)
		if quest == null:
			continue
		var item_id: String = quest.requirements.keys()[0]
		var needed: int = int(quest.requirements[item_id])
		for i in needed:
			BoardState.spawn_item(item_id, BoardState.find_empty_cell())
		ResidenceManager.try_complete_quest(quest.id)

func _ready() -> void:
	GameManager.new_game()

	# -- Gated on all hotspots complete -------------------------------------------
	if DefenceManager.can_attempt(EVENT_ID):
		_fail("can_attempt should be false before any hotspot is repaired")
		return
	var early := DefenceManager.launch(EVENT_ID, "mara_vale")
	if early.success or early.reason != "not_ready":
		_fail("launch() before hotspots are done should fail with not_ready, got %s" % str(early))
		return
	print("SMOKE_DEFENCE: gated on residence completion OK")

	_complete_all_hotspots("hollow_creek_farmhouse")
	if not DefenceManager.can_attempt(EVENT_ID):
		_fail("can_attempt should be true once all 9 hotspots are COMPLETED")
		return

	# -- Energy cost -----------------------------------------------------------
	var energy_cost: int = int(DefenceManager.events[EVENT_ID].energy_cost)
	var energy_before: int = GameManager.resources.energy
	var launch_result := DefenceManager.launch(EVENT_ID, "mara_vale")
	if not launch_result.success:
		_fail("launch() should succeed with full energy once ready, got %s" % str(launch_result))
		return
	if GameManager.resources.energy != energy_before - energy_cost:
		_fail("launch() should spend its event's energy_cost (%d)" % energy_cost)
		return
	print("SMOKE_DEFENCE: energy cost OK")

	# -- Forced failure: non-blocking, reverts a hotspot, stays retriable --------
	DefenceManager.event_choices[EVENT_ID][0].success_chance = 0.0
	var failure_result := DefenceManager.resolve_choice(EVENT_ID, 0, "mara_vale")
	if not failure_result.success or failure_result.outcome_success:
		_fail("forced-failure resolve_choice should report outcome_success=false, got %s" % str(failure_result))
		return
	if DefenceManager.has_survived(EVENT_ID):
		_fail("a failed defence must not mark the event survived")
		return
	if not GameManager.is_game_active:
		_fail("a failed defence must never end/block the game session")
		return
	var reverted_id: String = failure_result.get("reverted_hotspot_id", "")
	if reverted_id.is_empty() or ResidenceManager.get_hotspot_state(reverted_id) != ResidenceHotspot.State.DESTROYED:
		_fail("forced failure should revert exactly one hotspot to DESTROYED, got reverted_id=%s" % reverted_id)
		return
	if ResidenceManager.get_active_quest_for_hotspot(reverted_id) == null:
		_fail("the reverted hotspot's quest should be completable again")
		return
	print("SMOKE_DEFENCE: forced failure reverts one hotspot, stays non-blocking and retriable OK")

	# -- Re-repair the reverted hotspot, then forced success ----------------------
	var quest := ResidenceManager.get_active_quest_for_hotspot(reverted_id)
	var item_id: String = quest.requirements.keys()[0]
	BoardState.spawn_item(item_id, BoardState.find_empty_cell())
	ResidenceManager.try_complete_quest(quest.id)
	if not DefenceManager.can_attempt(EVENT_ID):
		_fail("re-repairing the reverted hotspot should make the defence attemptable again")
		return

	GameManager.resources.energy = GameManager.resources.energy_max
	DefenceManager.launch(EVENT_ID, "mara_vale")
	DefenceManager.event_choices[EVENT_ID][0].success_chance = 1.0
	var chapter_before: String = GameManager.profile.current_chapter_id
	var success_result := DefenceManager.resolve_choice(EVENT_ID, 0, "mara_vale")
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice should report outcome_success=true, got %s" % str(success_result))
		return
	if not DefenceManager.has_survived(EVENT_ID):
		_fail("a successful defence should mark the event survived")
		return
	if GameManager.profile.current_chapter_id == chapter_before:
		_fail("a successful defence should advance the chapter")
		return
	if not GameManager.get_story_flag("redwater_unlocked", false):
		_fail("a successful defence should set the redwater_unlocked story flag")
		return
	if DefenceManager.can_attempt(EVENT_ID):
		_fail("can_attempt should be false again once already survived")
		return
	print("SMOKE_DEFENCE: forced success advances chapter, unlocks Redwater flag, sets survived OK")

	# -- Save / reload round trip ------------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not DefenceManager.has_survived(EVENT_ID):
		_fail("reloaded survived-event state should still be true")
		return
	if not GameManager.get_story_flag("redwater_unlocked", false):
		_fail("reloaded redwater_unlocked flag should still be true")
		return
	print("SMOKE_DEFENCE: save/reload round trip OK")

	print("SMOKE_DEFENCE_TEST_OK")
	get_tree().quit(0)
