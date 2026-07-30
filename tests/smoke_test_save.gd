extends Node
## SmokeTestSave
##
## Exercises SaveManager: new game -> save -> mutate -> load -> verify,
## plus corrupted-primary-falls-back-to-backup. Not wired up as the
## default main scene - run directly:
##   godot4 --headless --path . tests/smoke_test_save.tscn

func _ready() -> void:
	GameManager.new_game()
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
