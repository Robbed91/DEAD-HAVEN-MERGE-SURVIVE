extends Control

const OUTPUT_DIR := "res://docs/vertical-slice-captures"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	BoardState.reset_new_board()
	# Keep this presentation capture focused on the requested construction
	# vertical slice. Moving unrelated producers to storage uses the public
	# board API and is test-only; production starting-layout rules are untouched.
	for instance_id in BoardState.items.keys():
		var def := BoardState.get_item_def(instance_id)
		if def != null and def.is_producer and def.chain_id != "construction":
			BoardState.move_to_storage(instance_id)
	var locked_item := BoardState.spawn_item("construction_3", Vector2i(1, 6))
	if locked_item != null:
		locked_item.is_locked = true
		locked_item.has_cobweb = true
	var board: Control = load("res://scenes/merge_board/merge_board.tscn").instantiate()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(board)
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await get_tree().create_timer(0.8).timeout
	var producer_view: ItemView
	for child in board.find_children("*", "ItemView", true, false):
		var node := child as ItemView
		var item_def: ItemDefinition = node.get_def()
		if item_def != null and item_def.id == "construction_producer":
			producer_view = node
			break
	if producer_view != null:
		producer_view.set_selected_visual(true)
	var locked_view: ItemView
	for child in board.find_children("*", "ItemView", true, false):
		var candidate := child as ItemView
		if candidate.instance_id == locked_item.instance_id:
			locked_view = candidate
			break
	if locked_view == null or not locked_view.has_node("LockPlate") or not locked_view.has_node("Cobweb"):
		push_error("MERGE_CAPTURE: final lock/cobweb texture overlays are not integrated")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/merge_board_construction_ready.png"))

	var construction_ones: Array[String] = []
	for instance_id in BoardState.items:
		if BoardState.items[instance_id].item_id == "construction_1":
			construction_ones.append(instance_id)
	if construction_ones.size() != 2:
		push_error("MERGE_CAPTURE: expected two construction_1 items")
		get_tree().quit(1)
		return
	var target_item: BoardItem = BoardState.items[construction_ones[1]]
	var target_cell: BoardCell
	for child in board.find_children("*", "BoardCell", true, false):
		var node := child as BoardCell
		if node.grid_pos == target_item.grid_position:
			target_cell = node
			break
	if target_cell == null:
		push_error("MERGE_CAPTURE: target cell not found")
		get_tree().quit(1)
		return
	board.call("_on_drop_attempted", construction_ones[0], target_cell)
	await get_tree().create_timer(0.75).timeout
	if BoardState.count_item("construction_1") != 0 or BoardState.count_item("construction_2") != 1:
		push_error("MERGE_CAPTURE: real construction merge did not produce construction_2")
		get_tree().quit(1)
		return
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/merge_board_construction_merged.png"))
	await get_tree().create_timer(2.1).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/merge_board_final_running.png"))
	await get_tree().create_timer(0.35).timeout
	get_tree().quit()
