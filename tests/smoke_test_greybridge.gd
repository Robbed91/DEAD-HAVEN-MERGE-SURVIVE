extends Node
## SmokeTestGreybridge
##
## Phase 10: exercises Greybridge School end to end - residence data loads
## with 8 hotspots, Riley Chen's rescue quest (set_story_flag-free this
## time - unlock_survivor + dialogue_trigger_id only, same as Noah's),
## chapter advancement to chapter_6_the_signal, and "greybridge_defence" -
## DefenceManager's third event, on a third residence, with skill_tags
## that specifically match Riley's own skills (electronics/communications)
## so her scavenging/defence bonus is live immediately on her own rescue
## rather than remaining the "real but inert for now" situation every
## prior phase's skill bonus documented.
##
## Run: godot4 --headless --path . tests/smoke_test_greybridge.tscn

const RESIDENCE_ID := "greybridge_school"
const DEFENCE_EVENT_ID := "greybridge_defence"

func _fail(msg: String) -> void:
	print("SMOKE_GREYBRIDGE_FAIL: %s" % msg)
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
		_fail("greybridge_school should load with 8 hotspots, got %s" % str(residence))
		return
	print("SMOKE_GREYBRIDGE: residence data loaded OK (8 hotspots)")

	# -- Repair every hotspot except the rescue one first -------------------
	for hotspot in residence.hotspots:
		if hotspot.id == "radio_tower":
			continue
		_complete_hotspot(hotspot.id)

	if DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("greybridge_defence should not be attemptable before the radio_tower hotspot is done")
		return

	# -- Riley rescue: unlock_survivor + dialogue_trigger + chapter --------
	if GameManager.get_unlocked_survivor_ids().has("riley_chen"):
		_fail("riley_chen should not be unlocked yet")
		return
	var riley_quest := ResidenceManager.get_active_quest_for_hotspot("radio_tower", RESIDENCE_ID)
	if riley_quest == null or riley_quest.id != "q_rescue_riley" or riley_quest.dialogue_trigger_id != "riley_01":
		_fail("radio_tower should resolve to q_rescue_riley with dialogue_trigger_id riley_01, got %s" % str(riley_quest))
		return
	var chapter_before: String = GameManager.profile.current_chapter_id
	_complete_hotspot("radio_tower")
	if not GameManager.get_unlocked_survivor_ids().has("riley_chen"):
		_fail("completing q_rescue_riley should unlock riley_chen")
		return
	if GameManager.profile.current_chapter_id == chapter_before or GameManager.profile.current_chapter_id != "chapter_6_the_signal":
		_fail("expected chapter_6_the_signal after the Riley rescue, got %s" % GameManager.profile.current_chapter_id)
		return
	print("SMOKE_GREYBRIDGE: Riley rescue unlocks survivor + advances chapter OK")

	# -- greybridge_defence: skill_tags match Riley's own skills ------------
	if not DefenceManager.can_attempt(DEFENCE_EVENT_ID):
		_fail("greybridge_defence should be attemptable once all 8 hotspots are COMPLETED")
		return
	var event: Dictionary = DefenceManager.events[DEFENCE_EVENT_ID]
	var riley := CharacterDatabase.get_survivor("riley_chen")
	var matches := false
	for skill in riley.skills:
		if event.skill_tags.has(skill):
			matches = true
			break
	if not matches:
		_fail("greybridge_defence's skill_tags should match at least one of riley_chen's own skills, got tags=%s skills=%s" % [str(event.skill_tags), str(riley.skills)])
		return
	print("SMOKE_GREYBRIDGE: greybridge_defence skill_tags match Riley's own skills (bonus is live, not inert) OK")

	var energy_cost: int = int(event.energy_cost)
	var energy_before: int = GameManager.resources.energy
	var launch_result := DefenceManager.launch(DEFENCE_EVENT_ID, "riley_chen")
	if not launch_result.success or GameManager.resources.energy != energy_before - energy_cost:
		_fail("launch() should spend greybridge_defence's own energy_cost (%d), got %s" % [energy_cost, str(launch_result)])
		return

	DefenceManager.event_choices[DEFENCE_EVENT_ID][0].success_chance = 1.0
	var success_result := DefenceManager.resolve_choice(DEFENCE_EVENT_ID, 0, "riley_chen")
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice on greybridge_defence should report outcome_success=true, got %s" % str(success_result))
		return
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("a successful greybridge_defence should mark that event survived")
		return
	if not GameManager.get_story_flag("saint_mercy_unlocked", false):
		_fail("a successful greybridge_defence should set the saint_mercy_unlocked story flag")
		return
	print("SMOKE_GREYBRIDGE: greybridge_defence success unlocks Saint Mercy flag OK")

	# -- Save / reload round trip -------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not DefenceManager.has_survived(DEFENCE_EVENT_ID):
		_fail("reloaded greybridge_defence survived state should still be true")
		return
	if not GameManager.get_unlocked_survivor_ids().has("riley_chen"):
		_fail("reloaded riley_chen unlock should still be true")
		return
	if not GameManager.get_story_flag("saint_mercy_unlocked", false):
		_fail("reloaded saint_mercy_unlocked flag should still be true")
		return
	print("SMOKE_GREYBRIDGE: save/reload round trip OK")

	print("SMOKE_GREYBRIDGE_TEST_OK")
	get_tree().quit(0)
