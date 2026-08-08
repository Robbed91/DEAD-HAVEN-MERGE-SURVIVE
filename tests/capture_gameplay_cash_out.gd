extends Control
## Running-game verification that the item info panel's Collect button
## really shows for a gameplay-chain item on the real embedded Haven board,
## not just the four reward chains it used to be limited to.

const OUTPUT_DIR := "res://docs/producer-state-captures/"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame

	var item_id := ""
	for chain_id in ["tool", "food", "medical", "trap", "fuel", "vehicle_parts", "electronics", "clothing", "construction"]:
		var chain := ItemDatabase.get_chain(chain_id)
		for candidate in chain.get("item_ids", []):
			var def := ItemDatabase.get_item(String(candidate))
			if def == null or def.sell_value <= 0:
				continue
			if ResidenceManager.is_item_reserved_for_active_task(def.id, "hollow_creek_farmhouse", 0):
				continue
			item_id = def.id
			break
		if item_id != "":
			break
	if item_id == "":
		push_error("no freely-collectible gameplay item found for the capture")
		get_tree().quit(1)
		return
	var spawned := BoardState.spawn_item(item_id, BoardState.find_empty_cell(), false)
	if spawned == null:
		push_error("could not spawn %s for the capture" % item_id)
		get_tree().quit(1)
		return

	var board: MergeBoard = haven.get_node("%BoardPanel")
	board._info_panel.show_for(spawned.instance_id, true)
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "live_gameplay_chain_collect_button.png"))
	get_tree().quit(0)
