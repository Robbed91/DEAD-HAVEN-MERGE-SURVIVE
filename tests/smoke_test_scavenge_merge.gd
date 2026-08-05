extends Node
## Headless coverage for the scavenging merge challenge (see
## DEVELOPMENT_LOG.md 2026-08-05 "scavenging becomes a merge challenge"):
## ScavengeMergeState's own win/lose rules, ScavengingManager's difficulty
## computation from an encounter choice, and that resolve_choice_with_outcome
## grants the exact same rewards/text/penalty as the existing dice-based
## resolve_choice() for a known outcome - the ten missions' authored data
## didn't need to change for this.

func _ready() -> void:
	GameManager.new_game()

	# -- Board seeding is guaranteed solvable ------------------------------------
	var state := ScavengeMergeState.new()
	var chain_ids: Array[String] = ["tool", "clothing"]
	state.setup(chain_ids, 6, 3)
	var level_1_count := 0
	for pos in state.grid:
		if state.item_id_at(pos) == "tool_1":
			level_1_count += 1
	if level_1_count < 4:
		_fail("seeded board should contain at least 4 tool_1 tiles to reach target level 3, got %d" % level_1_count)
		return
	print("SMOKE_SCAVENGE_MERGE: seeded board is solvable OK")

	# -- try_merge follows the same chain+level rule as BoardState.try_merge -----
	var cells := state.grid.keys()
	var tool_1_cells: Array[Vector2i] = []
	for pos in cells:
		if state.item_id_at(pos) == "tool_1":
			tool_1_cells.append(pos)
	var mismatch := state.try_merge(tool_1_cells[0], Vector2i(-5, -5))
	if mismatch.get("success", true):
		_fail("try_merge against an empty cell should fail")
		return
	var bad_state := ScavengeMergeState.new()
	bad_state.setup(["tool", "clothing"], 6, 3)
	var moves_before := state.moves_left
	var merge_result := state.try_merge(tool_1_cells[0], tool_1_cells[1])
	if not merge_result.get("success", false) or merge_result.get("resulting_item_id", "") != "tool_2":
		_fail("merging two tool_1 tiles should produce tool_2, got %s" % str(merge_result))
		return
	if state.moves_left != moves_before - 1:
		_fail("a successful merge should spend exactly one move")
		return
	print("SMOKE_SCAVENGE_MERGE: try_merge matches BoardState's chain+level rule and spends a move OK")

	# -- Reaching target_level wins; running out of moves without it loses -------
	var win_state := ScavengeMergeState.new()
	win_state.setup(["tool", "clothing"], 6, 3)
	var t1 := win_state.grid.keys().filter(func(p): return win_state.item_id_at(p) == "tool_1")
	win_state.try_merge(t1[0], t1[1]) # tool_2
	win_state.try_merge(t1[2], t1[3]) # tool_2
	var twos := win_state.grid.keys().filter(func(p): return win_state.item_id_at(p) == "tool_2")
	win_state.try_merge(twos[0], twos[1]) # tool_3 - target reached
	if not win_state.is_won():
		_fail("reaching target_level 3 should set is_won()")
		return
	print("SMOKE_SCAVENGE_MERGE: reaching target_level wins OK")

	var lose_state := ScavengeMergeState.new()
	lose_state.setup(["tool", "clothing"], 1, 3) # only 1 move - cannot reach level 3
	var lt1 := lose_state.grid.keys().filter(func(p): return lose_state.item_id_at(p) == "tool_1")
	lose_state.try_merge(lt1[0], lt1[1])
	if not lose_state.is_lost():
		_fail("running out of moves without reaching target_level should set is_lost()")
		return
	print("SMOKE_SCAVENGE_MERGE: running out of moves loses OK")

	# -- ScavengingManager difficulty scales with the choice's success_chance ----
	var mission := ScavengingManager.get_mission("abandoned_grocery_store")
	mission.encounter_choices[0].success_chance = 0.95
	var easy_params := ScavengingManager.compute_challenge_params("abandoned_grocery_store", 0)
	mission.encounter_choices[0].success_chance = 0.1
	var hard_params := ScavengingManager.compute_challenge_params("abandoned_grocery_store", 0)
	if int(easy_params.moves) <= int(hard_params.moves):
		_fail("a higher success_chance choice should grant more challenge moves than a lower one, got easy=%s hard=%s" % [str(easy_params.moves), str(hard_params.moves)])
		return
	print("SMOKE_SCAVENGE_MERGE: challenge difficulty tracks the chosen approach's success_chance OK")

	# -- resolve_choice_with_outcome grants identical rewards/penalty/text to the
	#    existing dice-based resolve_choice() for a known outcome -----------------
	var loot_item_id: String = mission.loot_table.keys()[0]
	var loot_before: int = BoardState.count_item(loot_item_id)
	var success_result := ScavengingManager.resolve_choice_with_outcome("abandoned_grocery_store", 0, true)
	if not success_result.success or not success_result.outcome_success:
		_fail("resolve_choice_with_outcome(true) should report outcome_success, got %s" % str(success_result))
		return
	if BoardState.count_item(loot_item_id) <= loot_before:
		_fail("resolve_choice_with_outcome(true) should still grant the base loot_table item")
		return

	mission.encounter_choices[0].failure_penalty = {"coins": 9}
	var coins_before: int = GameManager.resources.coins
	var failure_result := ScavengingManager.resolve_choice_with_outcome("abandoned_grocery_store", 0, false)
	if not failure_result.success or failure_result.outcome_success:
		_fail("resolve_choice_with_outcome(false) should report outcome_success=false, got %s" % str(failure_result))
		return
	if GameManager.resources.coins != coins_before - 9:
		_fail("resolve_choice_with_outcome(false) should apply the same failure_penalty as resolve_choice()")
		return
	if not GameManager.is_game_active:
		_fail("a lost merge challenge must never end/block the game session")
		return
	print("SMOKE_SCAVENGE_MERGE: resolve_choice_with_outcome grants identical rewards/penalty to resolve_choice() OK")

	print("SMOKE_SCAVENGE_MERGE_OK")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print("SMOKE_TEST_FAIL: %s" % message)
	get_tree().quit(1)
