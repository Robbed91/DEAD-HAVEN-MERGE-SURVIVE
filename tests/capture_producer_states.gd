extends Control
## Running-game verification that the real embedded Haven board resolves
## authored producer state art for a non-construction chain, not just the
## chain the old construction-only special case already covered.

const OUTPUT_DIR := "res://docs/producer-state-captures/"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame

	var board: MergeBoard = haven.get_node("%BoardPanel")
	var tool_producer_instance := ""
	for instance_id in BoardState.items:
		var bi: BoardItem = BoardState.items[instance_id]
		if bi.item_id == "tool_producer":
			tool_producer_instance = instance_id
			break
	if tool_producer_instance == "":
		push_error("tool_producer not found on the fresh Hollow Creek board")
		get_tree().quit(1)
		return
	var view: ItemView = board._find_item_view(tool_producer_instance)
	if view == null:
		push_error("tool_producer has no live ItemView on the embedded board")
		get_tree().quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture(view, "active", "live_embedded_tool_active.png")
	await _capture(view, "empty", "live_embedded_tool_empty.png")
	await _capture(view, "recharge", "live_embedded_tool_recharge.png")
	get_tree().quit(0)

func _capture(view: ItemView, state: String, filename: String) -> void:
	view.play_producer_visual_state(state, 0.0)
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + filename))
