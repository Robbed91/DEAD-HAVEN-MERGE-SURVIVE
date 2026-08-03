extends Node
## SmokeTestMerge
##
## Exercises BoardState/GameManager Phase 2 logic directly (no GUI, no
## simulated touch input - see tests/README.md for what headless mode
## cannot cover): starting layout, valid/invalid/max-level merges, producer
## tap with energy/cooldown, debug infinite energy, storage transfer,
## delete+undo, reward collection, and a full save/reload round trip.
##
## Run: godot4 --headless --path . tests/smoke_test_merge.tscn

func _fail(msg: String) -> void:
	print("SMOKE_MERGE_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()

	# -- Starting layout: junk-filled with four usable work cells ------------
	var producer_count := ItemDatabase.get_producer_ids().size()
	var expected_occupied := BoardState.COLUMNS * BoardState.ROWS - 4
	if BoardState.items.size() != expected_occupied or BoardState.grid.size() != expected_occupied:
		_fail("expected %d occupied starting cells, got %d" % [expected_occupied, BoardState.items.size()])
		return
	var producer_instance_ids: Array[String] = []
	var construction_producer_id := ""
	var tool_producer_id := ""
	for id in BoardState.items:
		var def := BoardState.get_item_def(id)
		if def != null and def.is_producer:
			producer_instance_ids.append(id)
			if def.chain_id == "construction": construction_producer_id = id
			if def.chain_id == "tool": tool_producer_id = id
	var covered_ids: Array[String] = []
	var cobweb_ids: Array[String] = []
	for id in BoardState.items:
		var board_item: BoardItem = BoardState.items[id]
		var item_def := BoardState.get_item_def(id)
		if item_def != null and not item_def.is_producer and board_item.is_locked:
			covered_ids.append(id)
		elif item_def != null and not item_def.is_producer and board_item.has_cobweb:
			cobweb_ids.append(id)
	if covered_ids.size() != 42 or cobweb_ids.size() != 6 or BoardState.find_empty_cell().x < 0:
		_fail("starting board should contain 42 boxes, 6 cobwebs and 4 work cells")
		return
	var blocked_id := covered_ids[0]
	var blocked_pos: Vector2i = BoardState.items[blocked_id].grid_position
	if BoardState.move_to_storage(blocked_id) or BoardState.move_to_cell(blocked_id, BoardState.find_empty_cell()) or BoardState.can_delete(blocked_id):
		_fail("box-covered item must not move, enter storage, or delete")
		return
	if BoardState.items[blocked_id].grid_position != blocked_pos:
		_fail("blocked interaction changed a covered item's position")
		return
	if _active_producer_count() != 1 or BoardState.items[construction_producer_id].is_locked:
		_fail("new board should activate only the construction producer")
		return
	var energy_before_locked_tap: int = GameManager.resources.energy
	var locked_tap := BoardState.tap_producer(tool_producer_id)
	if locked_tap.success or locked_tap.reason != "producer_locked" or GameManager.resources.energy != energy_before_locked_tap:
		_fail("locked tool producer should reject without spending energy, got %s" % str(locked_tap))
		return
	print("SMOKE_MERGE: starting layout OK (%d occupied, 42 boxes, 6 cobwebs, 1/%d producers active)" % [BoardState.items.size(), producer_count])

	# -- Valid merge + discovery reward -------------------------------------
	var construction_ids: Array[String] = []
	for id in BoardState.items:
		if BoardState.items[id].item_id == "construction_1" and not BoardState.is_item_blocked(id):
			construction_ids.append(id)
	if construction_ids.size() != 2:
		_fail("expected 2 starter construction_1 items, found %d" % construction_ids.size())
		return
	var coins_before: int = GameManager.resources.coins
	var merge_result := BoardState.try_merge(construction_ids[0], construction_ids[1])
	if not merge_result.success or merge_result.resulting_item_id != "construction_2":
		_fail("expected successful merge into construction_2, got %s" % str(merge_result))
		return
	if not merge_result.is_discovery:
		_fail("first-ever construction_2 should be a discovery")
		return
	if GameManager.resources.coins <= coins_before:
		_fail("discovery reward should have granted coins")
		return
	if BoardState.items.has(construction_ids[0]) or BoardState.items.has(construction_ids[1]):
		_fail("source instances should be gone after merging")
		return
	var revealed_ids: Array = merge_result.get("revealed_instance_ids", [])
	if revealed_ids.is_empty():
		_fail("starter merge should reveal at least one adjacent box")
		return
	var revealed_id: String = String(revealed_ids[0])
	if not BoardState.items[revealed_id].has_cobweb or BoardState.items[revealed_id].is_locked:
		_fail("revealed box should become a cobwebbed underlying item")
		return
	var revealed_item_id: String = BoardState.items[revealed_id].item_id
	var free_match := BoardState.spawn_item(revealed_item_id, BoardState.find_empty_cell())
	var cobweb_merge := BoardState.try_merge(free_match.instance_id, revealed_id)
	if not cobweb_merge.success or BoardState.items.has(revealed_id):
		_fail("matching free item should merge into and clear a cobwebbed item")
		return
	print("SMOKE_MERGE: valid merge reveals box and matching merge clears cobweb OK")

	# -- Progressive producer milestones -----------------------------------
	var repair_result := ResidenceManager.try_complete_quest("q_secure_front_door")
	if not repair_result.success or _active_producer_count() != 2 or BoardState.items[tool_producer_id].is_locked:
		_fail("securing the front door should unlock only the tool producer")
		return
	ResidenceManager.completed_quest_ids["q_clear_living_room"] = true
	BoardState.refresh_producer_locks(false)
	if _active_producer_count() != 3:
		_fail("clearing the living room should unlock the food producer")
		return
	ResidenceManager.completed_quest_ids["q_repair_pantry"] = true
	BoardState.refresh_producer_locks(false)
	if _active_producer_count() != 4:
		_fail("repairing the pantry should unlock the medical producer")
		return
	ResidenceManager.completed_quest_ids["q_rescue_noah"] = true
	BoardState.refresh_producer_locks(false)
	if _active_producer_count() != 5:
		_fail("rescuing Noah should unlock the trap producer")
		return
	VehicleManager.discover_vehicle("delivery_van")
	if _active_producer_count() != 6:
		_fail("discovering the delivery van should unlock vehicle parts")
		return
	GameManager.set_story_flag("redwater_unlocked", true)
	if _active_producer_count() != 8:
		_fail("unlocking Redwater should unlock fuel and electronics")
		return
	GameManager.set_story_flag("greybridge_unlocked", true)
	if _active_producer_count() != 9:
		_fail("unlocking Greybridge should unlock clothing and complete producer progression")
		return
	print("SMOKE_MERGE: producer progression milestones unlock 1 -> 9 without replacing instances OK")

	# -- Invalid merges: producers, and mismatched chain/level --------------
	var producer_merge := BoardState.try_merge(producer_instance_ids[0], producer_instance_ids[1])
	if producer_merge.success or producer_merge.reason != "producers_do_not_merge":
		_fail("merging two producers should fail with producers_do_not_merge, got %s" % str(producer_merge))
		return

	var mismatch_a := BoardState.spawn_item("food_1", BoardState.find_empty_cell())
	var mismatch_b := BoardState.spawn_item("tool_1", BoardState.find_empty_cell())
	var mismatch_result := BoardState.try_merge(mismatch_a.instance_id, mismatch_b.instance_id)
	if mismatch_result.success or mismatch_result.reason != "not_matching":
		_fail("merging different chains should fail with not_matching, got %s" % str(mismatch_result))
		return
	print("SMOKE_MERGE: invalid merges correctly rejected OK")

	# -- Max level merge rejection -------------------------------------------
	var chain := ItemDatabase.get_chain("construction")
	var max_level_id: String = chain.item_ids[chain.item_ids.size() - 1]
	var max_a := BoardState.spawn_item(max_level_id, BoardState.find_empty_cell())
	var max_b := BoardState.spawn_item(max_level_id, BoardState.find_empty_cell())
	var max_result := BoardState.try_merge(max_a.instance_id, max_b.instance_id)
	if max_result.success or not max_result.get("is_max_level", false):
		_fail("merging two max-level items should fail as max_level, got %s" % str(max_result))
		return
	if not BoardState.soft_delete(max_a.instance_id):
		_fail("could not free a work cell after max-level rejection")
		return
	print("SMOKE_MERGE: max-level merge correctly rejected OK")

	# -- Producer tap: energy spend + cooldown blocks immediate re-tap ------
	var energy_before: int = GameManager.resources.energy
	var tap_result := BoardState.tap_producer(construction_producer_id)
	if not tap_result.success:
		_fail("first producer tap should succeed, got %s" % str(tap_result))
		return
	if GameManager.resources.energy != energy_before - BoardState.PRODUCER_ENERGY_COST:
		_fail("producer tap should spend %d energy" % BoardState.PRODUCER_ENERGY_COST)
		return
	var second_tap := BoardState.tap_producer(construction_producer_id)
	if second_tap.success or second_tap.reason != "cooldown":
		_fail("immediate re-tap should fail with cooldown, got %s" % str(second_tap))
		return
	GameManager.debug_reset_all_cooldowns()
	var third_tap := BoardState.tap_producer(construction_producer_id)
	if not third_tap.success:
		_fail("tap after debug_reset_all_cooldowns should succeed, got %s" % str(third_tap))
		return
	print("SMOKE_MERGE: producer energy + cooldown + debug reset OK")

	# -- Debug infinite energy -----------------------------------------------
	GameManager.set_debug_infinite_energy(true)
	var energy_snapshot: int = GameManager.resources.energy
	if not GameManager.spend_energy(9999):
		_fail("spend_energy should always succeed under debug_infinite_energy")
		return
	if GameManager.resources.energy != energy_snapshot:
		_fail("debug_infinite_energy should not actually deduct energy")
		return
	GameManager.set_debug_infinite_energy(false)
	print("SMOKE_MERGE: debug infinite energy OK")

	# -- Storage transfer -----------------------------------------------------
	var storable_id: String = mismatch_a.instance_id
	if not BoardState.move_to_storage(storable_id):
		_fail("move_to_storage should succeed for a normal on-board item")
		return
	if BoardState.items[storable_id].is_on_board() or not BoardState.storage_order.has(storable_id):
		_fail("item should be off-board and in storage_order after move_to_storage")
		return
	if not BoardState.move_to_cell(storable_id, BoardState.find_empty_cell()):
		_fail("move_to_cell should succeed moving the item back from storage")
		return
	if not BoardState.items[storable_id].is_on_board() or BoardState.storage_order.has(storable_id):
		_fail("item should be back on board and out of storage_order")
		return
	print("SMOKE_MERGE: storage transfer OK")

	# -- Delete + undo ---------------------------------------------------------
	var delete_target_id: String = mismatch_b.instance_id
	var delete_pos: Vector2i = BoardState.items[delete_target_id].grid_position
	if BoardState.requires_delete_confirmation(delete_target_id):
		_fail("a common level-1 item should not require delete confirmation")
		return
	if not BoardState.soft_delete(delete_target_id):
		_fail("soft_delete should succeed for a deletable item")
		return
	if BoardState.items.has(delete_target_id) or BoardState.grid.has(delete_pos):
		_fail("item should be off the board immediately after soft_delete")
		return
	if not BoardState.can_undo_delete(delete_target_id):
		_fail("can_undo_delete should be true within the undo window")
		return
	if not BoardState.undo_delete(delete_target_id):
		_fail("undo_delete should succeed within the undo window")
		return
	if not BoardState.grid.has(delete_pos):
		_fail("undo_delete should restore an item to the original cell")
		return
	print("SMOKE_MERGE: delete + undo OK")

	# -- Reward-chain collection ------------------------------------------------
	var reward_item := BoardState.spawn_item("energy_reward_1", BoardState.find_empty_cell())
	var energy_before_collect: int = GameManager.resources.energy
	if not BoardState.collect_reward(reward_item.instance_id):
		_fail("collect_reward should succeed for a reward-chain item")
		return
	if GameManager.resources.energy != mini(energy_before_collect + 5, GameManager.resources.energy_max):
		_fail("collecting energy_reward_1 should grant 5 energy (capped at max)")
		return
	if BoardState.items.has(reward_item.instance_id):
		_fail("collected reward item should be removed from play")
		return
	print("SMOKE_MERGE: reward-chain collection OK")

	# -- Per-residence board isolation -----------------------------------------
	var hollow_marker := BoardState.spawn_item("construction_3", BoardState.find_empty_cell())
	var hollow_marker_pos: Vector2i = hollow_marker.grid_position
	var hollow_count: int = BoardState.items.size()
	if not BoardState.activate_residence_board("redwater_service_station"):
		_fail("could not activate Redwater board")
		return
	if BoardState.active_residence_id != "redwater_service_station" or BoardState.items.size() != expected_occupied:
		_fail("Redwater should activate its own untouched starting board")
		return
	var redwater_marker := BoardState.spawn_item("food_2", BoardState.find_empty_cell())
	if redwater_marker == null:
		_fail("could not add Redwater isolation marker")
		return
	BoardState.activate_residence_board("hollow_creek_farmhouse")
	if BoardState.items.size() != hollow_count or BoardState.count_item("food_2") != 0:
		_fail("Redwater mutation leaked into Hollow Creek")
		return
	if not BoardState.items.has(hollow_marker.instance_id) or BoardState.items[hollow_marker.instance_id].grid_position != hollow_marker_pos:
		_fail("Hollow Creek item position did not survive board switching")
		return
	BoardState.activate_residence_board("redwater_service_station")
	if BoardState.count_item("food_2") != 1:
		_fail("Redwater board mutation did not survive switching")
		return
	BoardState.activate_residence_board("hollow_creek_farmhouse")
	var board_preview := BoardState.to_save_data()
	if board_preview.residences.size() != BoardState.RESIDENCE_IDS.size():
		_fail("version-2 board save must contain all five residences")
		return
	print("SMOKE_MERGE: five residence boards remain isolated across switching OK")
	# -- Save / reload round trip ------------------------------------------------
	var items_before: int = BoardState.items.size()
	var storage_before: int = BoardState.storage_order.size()
	var discovered_before: int = BoardState.discovered_item_ids.size()
	var save_data := GameManager.to_save_data()
	SaveManager.save_game()

	# Simulate a fresh app start.
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if BoardState.items.size() != items_before:
		_fail("reloaded item count %d != saved %d" % [BoardState.items.size(), items_before])
		return
	if BoardState.storage_order.size() != storage_before:
		_fail("reloaded storage count %d != saved %d" % [BoardState.storage_order.size(), storage_before])
		return
	if BoardState.discovered_item_ids.size() != discovered_before:
		_fail("reloaded discovery count %d != saved %d" % [BoardState.discovered_item_ids.size(), discovered_before])
		return
	print("SMOKE_MERGE: save/reload round trip OK (%d items, %d storage, %d discovered)" % [items_before, storage_before, discovered_before])

	print("SMOKE_MERGE_TEST_OK")
	get_tree().quit(0)

func _active_producer_count() -> int:
	var count := 0
	for instance_id in BoardState.items:
		var def := BoardState.get_item_def(instance_id)
		if def != null and def.is_producer and not BoardState.items[instance_id].is_locked:
			count += 1
	return count
