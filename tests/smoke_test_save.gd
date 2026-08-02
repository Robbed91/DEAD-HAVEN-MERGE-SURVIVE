extends Node
## SmokeTestSave
##
## Exercises SaveManager: new game -> save -> mutate -> load -> verify,
## plus corrupted-primary-falls-back-to-backup. Not wired up as the
## default main scene - run directly:
##   godot4 --headless --path . tests/smoke_test_save.tscn

func _ready() -> void:
	GameManager.new_game()
	# Version-1 migration preserves the legacy board once and materializes
	# four independent new residence boards without duplicating its contents.
	var legacy_marker := BoardState.spawn_item("tool_2", BoardState.find_empty_cell())
	var legacy_marker_pos: Vector2i = legacy_marker.grid_position
	var legacy_board: Dictionary = BoardState._active_board_to_data()
	legacy_board["discovered_item_ids"] = BoardState.discovered_item_ids.keys()
	var legacy_root := {
		"save_version": 1,
		"profile": {"current_residence_id": "redwater_service_station"},
		"board": legacy_board,
	}
	var migrated: Dictionary = SaveManager._migrate_if_needed(legacy_root)
	if migrated.get("save_version", 0) != 2 or migrated.board.active_residence_id != "redwater_service_station":
		print("SMOKE_SAVE_FAIL: version-1 board did not migrate to its saved residence")
		get_tree().quit(1)
		return
	if migrated.board.residences.size() != 1 or not migrated.board.residences.has("redwater_service_station"):
		print("SMOKE_SAVE_FAIL: migration duplicated the legacy board")
		get_tree().quit(1)
		return
	GameManager.profile.current_residence_id = "redwater_service_station"
	BoardState.apply_save_data(migrated.board)
	if BoardState.active_residence_id != "redwater_service_station" or not BoardState.items.has(legacy_marker.instance_id):
		print("SMOKE_SAVE_FAIL: migrated legacy item is missing")
		get_tree().quit(1)
		return
	if BoardState.items[legacy_marker.instance_id].grid_position != legacy_marker_pos:
		print("SMOKE_SAVE_FAIL: migrated legacy item position changed")
		get_tree().quit(1)
		return
	var migrated_board_save := BoardState.to_save_data()
	if migrated_board_save.residences.size() != BoardState.RESIDENCE_IDS.size():
		print("SMOKE_SAVE_FAIL: migrated save did not materialize all five boards")
		get_tree().quit(1)
		return
	print("SMOKE_SAVE: version-1 board migrated once with exact item position and five isolated boards")
	# Baseline captured AFTER new_game(), not hardcoded: Phase 2's starting
	# board grants first-discovery coin rewards for the starter producers/
	# items, so the post-new-game total isn't a fixed constant - only the
	# delta this test itself applies is.
	var baseline_coins: int = GameManager.resources.coins
	var baseline_energy: int = GameManager.resources.energy
	GameManager.add_coins(123)
	GameManager.add_energy(-30)
	SaveManager.save_game()
	print("SMOKE_SAVE: saved coins=%d energy=%d" % [GameManager.resources.coins, GameManager.resources.energy])

	# Simulate a fresh app start reading the save back.
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		print("SMOKE_SAVE_FAIL: load_game returned empty after a normal save")
		get_tree().quit(1)
		return
	GameManager.apply_save_data(loaded)
	if GameManager.resources.coins != baseline_coins + 123 or GameManager.resources.energy != baseline_energy - 30:
		print("SMOKE_SAVE_FAIL: reloaded values wrong: coins=%d energy=%d" % [GameManager.resources.coins, GameManager.resources.energy])
		get_tree().quit(1)
		return
	print("SMOKE_SAVE: reload verified coins=%d energy=%d" % [GameManager.resources.coins, GameManager.resources.energy])

	# Corrupt the primary save and confirm backup fallback works.
	var f := FileAccess.open(SaveManager.SAVE_FILE, FileAccess.WRITE)
	f.store_string("{ this is not valid json")
	f.close()
	var recovered := SaveManager.load_game()
	if recovered.is_empty():
		print("SMOKE_SAVE_FAIL: backup fallback did not recover a save")
		get_tree().quit(1)
		return
	print("SMOKE_SAVE: backup fallback recovered save_version=%s" % str(recovered.get("save_version")))

	print("SMOKE_SAVE_TEST_OK")
	get_tree().quit(0)
