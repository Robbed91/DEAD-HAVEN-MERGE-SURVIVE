extends Node
## SmokeTestNorthgate
##
## Phase 12: exercises Northgate Prison end to end - residence data loads
## with 8 hotspots, Caleb Rusk's rescue quest, chapter advancement to
## chapter_8_old_debts, and "northgate_defence" - DefenceManager's fifth
## event. The payoff this test is really here to prove: Caleb's real
## skills (trap/defence/combat) match the STANDARD ["trap", "defence"]
## tags used by every defence event except Greybridge's - so recruiting
## him doesn't just make his own event's bonus live, it retroactively
## makes hollow_creek_first_wave's, redwater_defence's, and
## saint_mercy_defence's bonuses live too, closing the "skill bonus
## mechanism real but nobody currently unlocked matches it" situation
## every phase since 6 has carried, for every remaining event at once.
##
## Run: godot4 --headless --path . tests/smoke_test_northgate.tscn

const RESIDENCE_ID := "northgate_prison"
const DEFENCE_EVENT_ID := "northgate_defence"
const STANDARD_TAG_EVENTS := ["hollow_creek_first_wave", "redwater_defence", "saint_mercy_defence", "northgate_defence"]

func _fail(msg: String) -> void:
	print("SMOKE_NORTHGATE_FAIL: %s" % msg)
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
		_fail("northgate_prison should load with 8 hotspots, got %s" % str(residence))
		return
	print("SMOKE_NORTHGATE: residence data loaded OK (8 hotspots)")

	# -- Repair every hotspot except the rescue one first -------------------
	for hotspot in residence.hotspots:
		if hotspot.id == "warden_office":
			continue
		_complete_hotspot(hotspot.id)

	if DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("northgate_defence should not be attemptable before the warden_office hotspot is done")
		return

	# -- Caleb rescue: unlock_survivor + dialogue_trigger + chapter --------
	if GameManager.get_unlocked_survivor_ids().has("caleb_rusk"):
		_fail("caleb_rusk should not be unlocked yet")
		return
	var caleb_quest := ResidenceManager.get_active_quest_for_hotspot("warden_office", RESIDENCE_ID)
	if caleb_quest == null or caleb_quest.id != "q_rescue_caleb" or caleb_quest.dialogue_trigger_id != "caleb_01":
		_fail("warden_office should resolve to q_rescue_caleb with dialogue_trigger_id caleb_01, got %s" % str(caleb_quest))
		return
	var chapter_before: String = GameManager.profile.current_chapter_id
	_complete_hotspot("warden_office")
	if not GameManager.get_unlocked_survivor_ids().has("caleb_rusk"):
		_fail("completing q_rescue_caleb should unlock caleb_rusk")
		return
	if GameManager.profile.current_chapter_id == chapter_before or GameManager.profile.current_chapter_id != "chapter_8_old_debts":
		_fail("expected chapter_8_old_debts after the Caleb rescue, got %s" % GameManager.profile.current_chapter_id)
		return
	print("SMOKE_NORTHGATE: Caleb rescue unlocks survivor + advances chapter OK")

	# -- The payoff: Caleb's real skills match every standard-tag event -----
	var caleb := CharacterDatabase.get_survivor("caleb_rusk")
	for event_id in STANDARD_TAG_EVENTS:
		var event: Dictionary = DefenceManager.events[event_id]
		var matches := false
		for skill in caleb.skills:
			if event.skill_tags.has(skill):
				matches = true
				break
		if not matches:
			_fail("caleb_rusk's real skills should match %s's skill_tags (%s), got skills=%s" % [event_id, str(event.skill_tags), str(caleb.skills)])
			return
	print("SMOKE_NORTHGATE: recruiting Caleb makes the skill bonus live for all 4 standard-tag defence events at once OK")

	# -- northgate_defence itself resolves normally --------------------------
	# Deliberately launched/resolved with "mara_vale", NOT "caleb_rusk",
	# below: her skills don't match northgate_defence's tags, so forcing
	# success_chance to 1.0 stays exactly 1.0. Using a matching survivor
	# here would trigger the real +0.15-capped-at-0.95 skill bonus math
	# (minf(1.0 + 0.15, 0.95) == 0.95), silently turning a "forced"
	# certainty into a 95% chance and making this section flaky - the
	# skill-match itself is already proven deterministically above via
	# the direct CharacterDatabase check, so nothing is lost by not
	# re-proving it through a randomised resolve_choice() call too.
	if not DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("northgate_defence should be attemptable once all 8 hotspots are COMPLETED")
		return
	var energy_cost: int = int(DefenceManager.events[DEFENCE_EVENT_ID].energy_cost)
	var energy_before: int = GameManager.resources.energy
	var launch_result := DefenceManager.launch(DEFENCE_EVENT_ID, "mara_vale")
	if not launch_result.success or GameManager.resources.energy != energy_before - energy_cost:
		_fail("launch() should spend northgate_defence's own energy_cost (%d), got %s" % [energy_cost, str(launch_result)])
		return

	DefenceManager.event_choices[DEFENCE_EVENT_ID][0].success_chance = 1.0
	var success_result := DefenceManager.resolve_choice(DEFENCE_EVENT_ID, 0, "mara_vale")
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice on northgate_defence should report outcome_success=true, got %s" % str(success_result))
		return
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("a successful northgate_defence should mark that event survived")
		return
	print("SMOKE_NORTHGATE: northgate_defence resolves normally OK")

	# -- Save / reload round trip -------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("reloaded northgate_defence survived state should still be true")
		return
	if not GameManager.get_unlocked_survivor_ids().has("caleb_rusk"):
		_fail("reloaded caleb_rusk unlock should still be true")
		return
	print("SMOKE_NORTHGATE: save/reload round trip OK")

	print("SMOKE_NORTHGATE_TEST_OK")
	get_tree().quit(0)
