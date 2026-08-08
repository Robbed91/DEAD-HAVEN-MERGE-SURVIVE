extends Node
## SmokeTestDialogue
##
## Exercises DialogueManager/ResidenceManager's story wiring directly (no
## GUI - see tests/README.md for what headless mode can't cover): dialogue
## content loads, the linear intro chain resolves id-to-id correctly, the
## Noah rescue quest's dialogue_trigger_id is wired, a branching choice
## applies its reward and relationship_changes, chapter advancement fires
## on the front-door quest, and it all persists through save/reload.
##
## Run: godot4 --headless --path . tests/smoke_test_dialogue.tscn

func _fail(msg: String) -> void:
	print("SMOKE_DIALOGUE_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()

	# -- Content loads and chains correctly -------------------------------------
	if not DialogueManager.has_entry("intro_01"):
		_fail("intro_01 not found")
		return
	var e1 := DialogueManager.get_entry("intro_01")
	if e1.next_id != "intro_02":
		_fail("intro_01.next_id should be intro_02, got '%s'" % e1.next_id)
		return
	var e2 := DialogueManager.get_entry("intro_02")
	if e2.speaker_id != "mara_vale" or e2.next_id != "intro_03":
		_fail("intro_02 shape wrong: speaker=%s next=%s" % [e2.speaker_id, e2.next_id])
		return
	var e3 := DialogueManager.get_entry("intro_03")
	if not e3.next_id.is_empty():
		_fail("intro_03 should be the end of the chain (empty next_id)")
		return
	print("SMOKE_DIALOGUE: intro chain loads and links correctly OK")

	# -- Noah quest is wired to noah_01 ------------------------------------------
	var noah_quest := ResidenceManager.get_quest("q_rescue_noah")
	if noah_quest == null or noah_quest.dialogue_trigger_id != "noah_01":
		_fail("q_rescue_noah.dialogue_trigger_id should be noah_01, got %s" % str(noah_quest))
		return
	var noah_03 := DialogueManager.get_entry("noah_03")
	if noah_03.branching_options.size() != 2:
		_fail("noah_03 should have 2 branching options, got %d" % noah_03.branching_options.size())
		return
	print("SMOKE_DIALOGUE: Noah quest dialogue wiring OK")

	# -- Branching choice effects (simulating what dialogue.gd applies) --------
	var trusting_option: Dictionary = noah_03.branching_options[0]
	var coins_before: int = GameManager.resources.coins
	if GameManager.get_story_flag("noah_trusted", null) != null:
		_fail("noah_trusted should be unset before any choice is made")
		return
	GameManager.add_coins(int(trusting_option.reward.coins))
	for key in trusting_option.relationship_changes:
		GameManager.set_story_flag(String(key), trusting_option.relationship_changes[key])
	if GameManager.resources.coins != coins_before + 20:
		_fail("trusting choice should grant +20 coins")
		return
	if GameManager.get_story_flag("noah_trusted", false) != true:
		_fail("trusting choice should set story flag noah_trusted=true")
		return
	print("SMOKE_DIALOGUE: branching choice reward + relationship_changes OK")

	# -- Chapter advancement on front-door completion ---------------------------
	if GameManager.profile.current_chapter_id != "chapter_1_the_open_door":
		_fail("should start in chapter_1_the_open_door, got %s" % GameManager.profile.current_chapter_id)
		return
	BoardState.spawn_item("construction_2", BoardState.find_empty_cell())
	var door_result := ResidenceManager.try_complete_quest("q_secure_front_door")
	if not door_result.success:
		_fail("q_secure_front_door should complete, got %s" % str(door_result))
		return
	if GameManager.profile.current_chapter_id != "chapter_2_someone_upstairs":
		_fail("completing the front door should advance to chapter_2_someone_upstairs, got %s" % GameManager.profile.current_chapter_id)
		return
	# Re-advancing (e.g. a duplicate signal) must not error or regress.
	GameManager.advance_chapter("chapter_2_someone_upstairs")
	if GameManager.profile.current_chapter_id != "chapter_2_someone_upstairs":
		_fail("re-advancing to the same chapter should be a no-op, not change state")
		return
	print("SMOKE_DIALOGUE: chapter advancement OK")

	# -- Save / reload round trip ------------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if GameManager.profile.current_chapter_id != "chapter_2_someone_upstairs":
		_fail("reloaded chapter should still be chapter_2_someone_upstairs")
		return
	if GameManager.get_story_flag("noah_trusted", false) != true:
		_fail("reloaded noah_trusted story flag should still be true")
		return
	print("SMOKE_DIALOGUE: save/reload round trip OK")

	print("SMOKE_DIALOGUE_TEST_OK")
	get_tree().quit(0)
