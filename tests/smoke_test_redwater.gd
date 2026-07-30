extends Node
## SmokeTestRedwater
##
## Phase 8: exercises Redwater Service Station end to end - residence data
## loads with 8 hotspots, get_active_quest_for_hotspot resolves correctly
## with an explicit residence_id (the bug this test guards: TaskPanel used
## to default to "hollow_creek_farmhouse" and would silently 404 every
## Redwater hotspot - see DEVELOPMENT_LOG.md Phase 8), the Lena Ortiz
## rescue quest's set_story_flag/unlock_survivor/dialogue_trigger_id
## rewards, chapter advancement to chapter_5_the_station, and finally the
## "redwater_defence" event - the second entry in DefenceManager.events,
## proving Phase 8's generalization actually supports more than one
## residence's defence event at once (smoke_test_defence.gd only exercises
## "hollow_creek_first_wave").
##
## Run: godot4 --headless --path . tests/smoke_test_redwater.tscn

const RESIDENCE_ID := "redwater_service_station"
const DEFENCE_EVENT_ID := "redwater_defence"

func _fail(msg: String) -> void:
	print("SMOKE_REDWATER_FAIL: %s" % msg)
	get_tree().quit(1)

func _complete_hotspot(hotspot_id: String) -> void:
	var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot_id, RESIDENCE_ID)
	if quest == null:
		_fail("expected an active quest for hotspot %s" % hotspot_id)
		return
	var item_id: String = quest.requirements.keys()[0]
	var needed: int = int(quest.requirements[item_id])
	for i in needed:
		BoardState.spawn_item(item_id, BoardState.find_empty_cell())
	ResidenceManager.try_complete_quest(quest.id)

func _ready() -> void:
	GameManager.new_game()

	# -- Residence data ----------------------------------------------------
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null or residence.hotspots.size() != 8:
		_fail("redwater_service_station should load with 8 hotspots, got %s" % str(residence))
		return
	print("SMOKE_REDWATER: residence data loaded OK (8 hotspots)")

	# -- Explicit residence_id resolves hotspot quests correctly -----------
	# Redwater's own "fuel_pumps" id would silently resolve against
	# Hollow Creek's hotspot list (and fail) if residence_id weren't
	# threaded through - this is the exact regression TaskPanel had.
	var wrong_residence := ResidenceManager.get_active_quest_for_hotspot("fuel_pumps", "hollow_creek_farmhouse")
	if wrong_residence != null:
		_fail("fuel_pumps should not resolve against hollow_creek_farmhouse's hotspot list")
		return
	var right_residence := ResidenceManager.get_active_quest_for_hotspot("fuel_pumps", RESIDENCE_ID)
	if right_residence == null or right_residence.id != "q_clear_fuel_pumps":
		_fail("fuel_pumps should resolve to q_clear_fuel_pumps against redwater_service_station, got %s" % str(right_residence))
		return
	print("SMOKE_REDWATER: explicit residence_id resolves the correct hotspot quest OK")

	# -- Repair every hotspot except the rescue one first -------------------
	for hotspot in residence.hotspots:
		if hotspot.id == "garage_workshop":
			continue
		_complete_hotspot(hotspot.id)

	if DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("redwater_defence should not be attemptable before the rescue hotspot is done")
		return

	# -- Lena rescue: unlock_survivor + set_story_flag + dialogue_trigger --
	if GameManager.get_unlocked_survivor_ids().has("lena_ortiz"):
		_fail("lena_ortiz should not be unlocked yet")
		return
	var lena_quest := ResidenceManager.get_active_quest_for_hotspot("garage_workshop", RESIDENCE_ID)
	if lena_quest == null or lena_quest.id != "q_rescue_lena" or lena_quest.dialogue_trigger_id != "lena_01":
		_fail("garage_workshop should resolve to q_rescue_lena with dialogue_trigger_id lena_01, got %s" % str(lena_quest))
		return
	var chapter_before: String = GameManager.profile.current_chapter_id
	_complete_hotspot("garage_workshop")
	if not GameManager.get_unlocked_survivor_ids().has("lena_ortiz"):
		_fail("completing q_rescue_lena should unlock lena_ortiz")
		return
	if GameManager.profile.current_chapter_id == chapter_before:
		_fail("completing q_rescue_lena should advance the chapter")
		return
	if GameManager.profile.current_chapter_id != "chapter_5_the_station":
		_fail("expected chapter_5_the_station after the Lena rescue, got %s" % GameManager.profile.current_chapter_id)
		return
	print("SMOKE_REDWATER: Lena rescue unlocks survivor + advances chapter OK")

	# -- redwater_defence: a second DefenceManager event on a different residence --
	if not DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("redwater_defence should be attemptable once all 8 hotspots are COMPLETED")
		return
	if DefenceManager.has_survived("hollow_creek_first_wave"):
		_fail("completing redwater's hotspots must not affect hollow_creek_first_wave's survived state")
		return

	var energy_cost: int = int(DefenceManager.events[DEFENCE_EVENT_ID].energy_cost)
	var energy_before: int = GameManager.resources.energy
	var launch_result := DefenceManager.launch(DEFENCE_EVENT_ID, "lena_ortiz")
	if not launch_result.success or GameManager.resources.energy != energy_before - energy_cost:
		_fail("launch() should spend redwater_defence's own energy_cost (%d), got %s" % [energy_cost, str(launch_result)])
		return

	DefenceManager.event_choices[DEFENCE_EVENT_ID][0].success_chance = 1.0
	var success_result := DefenceManager.resolve_choice(DEFENCE_EVENT_ID, 0, "lena_ortiz")
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice on redwater_defence should report outcome_success=true, got %s" % str(success_result))
		return
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("a successful redwater_defence should mark that event survived")
		return
	if DefenceManager.has_survived("hollow_creek_first_wave"):
		_fail("surviving redwater_defence must not mark hollow_creek_first_wave as survived too")
		return
	print("SMOKE_REDWATER: redwater_defence resolves independently of hollow_creek_first_wave OK")

	# -- Save / reload round trip -------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("reloaded redwater_defence survived state should still be true")
		return
	if not GameManager.get_unlocked_survivor_ids().has("lena_ortiz"):
		_fail("reloaded lena_ortiz unlock should still be true")
		return
	if ResidenceManager.get_hotspot_state("garage_workshop") != ResidenceHotspot.State.COMPLETED:
		_fail("reloaded garage_workshop hotspot state should still be COMPLETED")
		return
	print("SMOKE_REDWATER: save/reload round trip OK")

	print("SMOKE_REDWATER_TEST_OK")
	get_tree().quit(0)
