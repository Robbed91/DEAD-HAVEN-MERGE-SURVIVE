extends Node
## SmokeTestSaintMercy
##
## Phase 11: exercises Saint Mercy Hospital end to end - residence data
## loads with 8 hotspots, Dr Imogen Shaw's rescue quest (unlock_survivor +
## dialogue_trigger_id, chapter advancement to chapter_7_do_no_harm), and
## "saint_mercy_defence" - DefenceManager's fourth event, using the
## standard ["trap", "defence"] skill_tags (unlike greybridge_defence,
## deliberately NOT matched to Imogen's own medical skills - a doctor's
## skills don't make her better at holding a barricade; the standard tags
## are there for whichever future survivor - Caleb Rusk - actually has
## them).
##
## Run: godot4 --headless --path . tests/smoke_test_saint_mercy.tscn

const RESIDENCE_ID := "saint_mercy_hospital"
const DEFENCE_EVENT_ID := "saint_mercy_defence"

func _fail(msg: String) -> void:
	print("SMOKE_SAINT_MERCY_FAIL: %s" % msg)
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
		_fail("saint_mercy_hospital should load with 8 hotspots, got %s" % str(residence))
		return
	print("SMOKE_SAINT_MERCY: residence data loaded OK (8 hotspots)")

	# -- Repair every hotspot except the rescue one first -------------------
	for hotspot in residence.hotspots:
		if hotspot.id == "isolation_ward":
			continue
		_complete_hotspot(hotspot.id)

	if DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("saint_mercy_defence should not be attemptable before the isolation_ward hotspot is done")
		return

	# -- Imogen rescue: unlock_survivor + dialogue_trigger + chapter -------
	if GameManager.get_unlocked_survivor_ids().has("imogen_shaw"):
		_fail("imogen_shaw should not be unlocked yet")
		return
	var imogen_quest := ResidenceManager.get_active_quest_for_hotspot("isolation_ward", RESIDENCE_ID)
	if imogen_quest == null or imogen_quest.id != "q_rescue_imogen" or imogen_quest.dialogue_trigger_id != "imogen_01":
		_fail("isolation_ward should resolve to q_rescue_imogen with dialogue_trigger_id imogen_01, got %s" % str(imogen_quest))
		return
	var chapter_before: String = GameManager.profile.current_chapter_id
	_complete_hotspot("isolation_ward")
	if not GameManager.get_unlocked_survivor_ids().has("imogen_shaw"):
		_fail("completing q_rescue_imogen should unlock imogen_shaw")
		return
	if GameManager.profile.current_chapter_id == chapter_before or GameManager.profile.current_chapter_id != "chapter_7_do_no_harm":
		_fail("expected chapter_7_do_no_harm after the Imogen rescue, got %s" % GameManager.profile.current_chapter_id)
		return
	print("SMOKE_SAINT_MERCY: Imogen rescue unlocks survivor + advances chapter OK")

	# -- saint_mercy_defence: standard trap/defence tags, not Imogen's own -
	if not DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("saint_mercy_defence should be attemptable once all 8 hotspots are COMPLETED")
		return
	var event: Dictionary = DefenceManager.events[DEFENCE_EVENT_ID]
	if event.skill_tags != ["trap", "defence"]:
		_fail("saint_mercy_defence should use the standard trap/defence skill_tags, got %s" % str(event.skill_tags))
		return
	var imogen := CharacterDatabase.get_survivor("imogen_shaw")
	var imogen_matches := false
	for skill in imogen.skills:
		if event.skill_tags.has(skill):
			imogen_matches = true
			break
	if imogen_matches:
		_fail("Imogen's own medical skills should NOT match saint_mercy_defence's combat tags, got skills=%s" % str(imogen.skills))
		return
	print("SMOKE_SAINT_MERCY: saint_mercy_defence uses standard tags, correctly not matching Imogen's own medical skills OK")

	var energy_cost: int = int(event.energy_cost)
	var energy_before: int = GameManager.resources.energy
	var launch_result := DefenceManager.launch(DEFENCE_EVENT_ID, "imogen_shaw")
	if not launch_result.success or GameManager.resources.energy != energy_before - energy_cost:
		_fail("launch() should spend saint_mercy_defence's own energy_cost (%d), got %s" % [energy_cost, str(launch_result)])
		return

	DefenceManager.event_choices[DEFENCE_EVENT_ID][0].success_chance = 1.0
	var success_result := DefenceManager.resolve_choice(DEFENCE_EVENT_ID, 0, "imogen_shaw")
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice on saint_mercy_defence should report outcome_success=true, got %s" % str(success_result))
		return
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("a successful saint_mercy_defence should mark that event survived")
		return
	if not GameManager.get_story_flag("northgate_unlocked", false):
		_fail("a successful saint_mercy_defence should set the northgate_unlocked story flag")
		return
	print("SMOKE_SAINT_MERCY: saint_mercy_defence success unlocks Northgate flag OK")

	# -- Save / reload round trip -------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("reloaded saint_mercy_defence survived state should still be true")
		return
	if not GameManager.get_unlocked_survivor_ids().has("imogen_shaw"):
		_fail("reloaded imogen_shaw unlock should still be true")
		return
	if not GameManager.get_story_flag("northgate_unlocked", false):
		_fail("reloaded northgate_unlocked flag should still be true")
		return
	print("SMOKE_SAINT_MERCY: save/reload round trip OK")

	print("SMOKE_SAINT_MERCY_TEST_OK")
	get_tree().quit(0)
