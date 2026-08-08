extends Node
## SmokeTestResidence
##
## Exercises ResidenceManager (Phase 3) directly: requirement detection,
## item consumption, reward delivery (including the unlock_survivor
## special-case), hotspot state changes, duplicate-completion prevention,
## prerequisite/insufficient-materials handling, and a full save/reload
## round trip.
##
## Run: godot4 --headless --path . tests/smoke_test_residence.tscn

func _fail(msg: String) -> void:
	print("SMOKE_RESIDENCE_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()

	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	if residence == null or residence.hotspots.size() != 9:
		_fail("expected hollow_creek_farmhouse with 9 hotspots, got %s" % str(residence))
		return
	print("SMOKE_RESIDENCE: residence data loaded OK (%d hotspots)" % residence.hotspots.size())

	# -- Requirement not met yet ------------------------------------------------
	var quest_id := "q_secure_front_door"
	var quest := ResidenceManager.get_quest(quest_id)
	if quest == null:
		_fail("q_secure_front_door not found")
		return
	var item_id: String = quest.requirements.keys()[0]
	if ResidenceManager.requirements_met(quest_id):
		_fail("requirements should not be met before the item exists")
		return
	var early_attempt := ResidenceManager.try_complete_quest(quest_id)
	if early_attempt.success:
		_fail("try_complete_quest should fail without the required item")
		return
	print("SMOKE_RESIDENCE: requirement-not-met correctly rejected OK")

	# -- Complete a normal repair task -----------------------------------------
	BoardState.spawn_item(item_id, BoardState.find_empty_cell())
	if not ResidenceManager.requirements_met(quest_id):
		_fail("requirements should be met once the item exists")
		return
	var coins_before: int = GameManager.resources.coins
	var xp_before: int = GameManager.profile.xp
	var result := ResidenceManager.try_complete_quest(quest_id)
	if not result.success:
		_fail("try_complete_quest should succeed once requirements are met, got %s" % str(result))
		return
	if BoardState.count_item(item_id) != 0:
		_fail("required item should be consumed on completion")
		return
	if GameManager.resources.coins <= coins_before or GameManager.profile.xp <= xp_before:
		_fail("completing a quest should grant coin and xp rewards")
		return
	if ResidenceManager.get_hotspot_state("front_door") != ResidenceHotspot.State.COMPLETED:
		_fail("front_door hotspot should be COMPLETED after its quest finishes")
		return
	print("SMOKE_RESIDENCE: task completion consumes item + grants reward + advances hotspot OK")

	# -- Duplicate completion prevention -----------------------------------------
	var duplicate := ResidenceManager.try_complete_quest(quest_id)
	if duplicate.success or duplicate.reason != "already_complete":
		_fail("re-completing the same quest should fail with already_complete, got %s" % str(duplicate))
		return
	print("SMOKE_RESIDENCE: duplicate completion correctly rejected OK")

	# -- Noah rescue unlocks the survivor -----------------------------------------
	if GameManager.is_survivor_unlocked("noah_vance"):
		_fail("noah_vance should not be unlocked yet")
		return
	var noah_quest := ResidenceManager.get_quest("q_rescue_noah")
	var noah_item: String = noah_quest.requirements.keys()[0]
	BoardState.spawn_item(noah_item, BoardState.find_empty_cell())
	var noah_result := ResidenceManager.try_complete_quest("q_rescue_noah")
	if not noah_result.success:
		_fail("q_rescue_noah should succeed once medical_3 exists, got %s" % str(noah_result))
		return
	if not GameManager.is_survivor_unlocked("noah_vance"):
		_fail("completing q_rescue_noah should unlock noah_vance")
		return
	print("SMOKE_RESIDENCE: unlock_survivor reward OK")

	# -- get_active_quest_for_hotspot reflects completion -----------------------
	if ResidenceManager.get_active_quest_for_hotspot("front_door") != null:
		_fail("front_door should have no active quest left after completion")
		return
	print("SMOKE_RESIDENCE: get_active_quest_for_hotspot OK")

	# -- Save / reload round trip ------------------------------------------------
	var completed_before: int = ResidenceManager.completed_quest_ids.size()
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if ResidenceManager.completed_quest_ids.size() != completed_before:
		_fail("reloaded completed_quest_ids size %d != saved %d" % [ResidenceManager.completed_quest_ids.size(), completed_before])
		return
	if ResidenceManager.get_hotspot_state("front_door") != ResidenceHotspot.State.COMPLETED:
		_fail("reloaded front_door hotspot state should still be COMPLETED")
		return
	if not GameManager.is_survivor_unlocked("noah_vance"):
		_fail("reloaded noah_vance unlock should persist")
		return
	print("SMOKE_RESIDENCE: save/reload round trip OK")

	print("SMOKE_RESIDENCE_TEST_OK")
	get_tree().quit(0)
