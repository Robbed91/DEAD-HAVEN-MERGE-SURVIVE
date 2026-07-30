extends Node
## SmokeTestScavenging
##
## Exercises ScavengingManager directly (no GUI - see tests/README.md):
## mission content loads, launching spends energy and refuses when there
## isn't enough, resolve_choice grants the mission's base loot_table plus
## the rolled choice's success/failure outcome, and it all persists
## through save/reload. Success/failure branches are forced deterministic
## by temporarily overriding a loaded mission's success_chance in memory
## (not touching the .tres file) rather than relying on randomness.
##
## Run: godot4 --headless --path . tests/smoke_test_scavenging.tscn

func _fail(msg: String) -> void:
	print("SMOKE_SCAVENGING_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()

	# -- Content loads -----------------------------------------------------------
	var mission_ids := ScavengingManager.get_all_mission_ids()
	if mission_ids.size() != 5:
		_fail("expected 5 scavenging missions, got %d" % mission_ids.size())
		return
	var mission := ScavengingManager.get_mission("abandoned_grocery_store")
	if mission == null or mission.encounter_choices.size() != 2:
		_fail("abandoned_grocery_store should have 2 encounter choices, got %s" % str(mission))
		return
	print("SMOKE_SCAVENGING: mission content loads OK (%d missions)" % mission_ids.size())

	# -- Launch requires energy ---------------------------------------------------
	var energy_before: int = GameManager.resources.energy
	var launch_result := ScavengingManager.launch_mission("abandoned_grocery_store")
	if not launch_result.success:
		_fail("launch_mission should succeed with full energy, got %s" % str(launch_result))
		return
	if GameManager.resources.energy != energy_before - mission.energy_cost:
		_fail("launch_mission should spend energy_cost (%d)" % mission.energy_cost)
		return

	GameManager.resources.energy = 0
	var starved_result := ScavengingManager.launch_mission("abandoned_grocery_store")
	if starved_result.success or starved_result.reason != "no_energy":
		_fail("launch_mission with 0 energy should fail with no_energy, got %s" % str(starved_result))
		return
	GameManager.resources.energy = GameManager.resources.energy_max
	print("SMOKE_SCAVENGING: launch energy cost + no_energy rejection OK")

	# -- Forced success path: base loot + success_loot granted -----------------
	var loot_item_id: String = mission.loot_table.keys()[0]
	var loot_before: int = BoardState.count_item(loot_item_id)
	mission.encounter_choices[0].success_chance = 1.0
	var success_result := ScavengingManager.resolve_choice("abandoned_grocery_store", 0)
	if not success_result.success or not success_result.outcome_success:
		_fail("forced-success resolve_choice should report outcome_success, got %s" % str(success_result))
		return
	if BoardState.count_item(loot_item_id) <= loot_before:
		_fail("base loot_table item should be granted on resolve_choice")
		return
	print("SMOKE_SCAVENGING: forced success grants base loot + success_loot OK")

	# -- Forced failure path: penalty applied, still non-blocking ---------------
	var coins_before: int = GameManager.resources.coins
	mission.encounter_choices[0].success_chance = 0.0
	mission.encounter_choices[0].failure_penalty = {"coins": 12}
	var failure_result := ScavengingManager.resolve_choice("abandoned_grocery_store", 0)
	if not failure_result.success or failure_result.outcome_success:
		_fail("forced-failure resolve_choice should report outcome_success=false, got %s" % str(failure_result))
		return
	if GameManager.resources.coins != coins_before - 12:
		_fail("failure_penalty should deduct exactly the configured coin amount")
		return
	if not GameManager.is_game_active:
		_fail("a failed mission must never end/block the game session")
		return
	print("SMOKE_SCAVENGING: forced failure applies penalty without blocking the game OK")

	# -- Mission completion tracking ---------------------------------------------
	if int(ScavengingManager.completed_mission_ids.get("abandoned_grocery_store", 0)) != 2:
		_fail("abandoned_grocery_store should show 2 completions by now, got %s" % str(ScavengingManager.completed_mission_ids.get("abandoned_grocery_store")))
		return
	print("SMOKE_SCAVENGING: completion tracking OK")

	# -- Save / reload round trip ------------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if int(ScavengingManager.completed_mission_ids.get("abandoned_grocery_store", 0)) != 2:
		_fail("reloaded completed_mission_ids should still show 2 completions")
		return
	print("SMOKE_SCAVENGING: save/reload round trip OK")

	print("SMOKE_SCAVENGING_TEST_OK")
	get_tree().quit(0)
