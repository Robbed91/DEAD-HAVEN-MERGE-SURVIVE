extends Control
## Approval-gate capture: every final construction level and its producer
## shown through the real merge-board scene and ItemView integration.

const OUTPUT := "res://docs/vertical-slice-captures/merge_board_construction_chain_final.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	BoardState.reset_new_board()
	for instance_id in BoardState.items.keys():
		BoardState.move_to_storage(instance_id)
	for level in 8:
		var pos := Vector2i(level % 7, 1 + int(level / 7))
		if BoardState.spawn_item("construction_%d" % (level + 1), pos) == null:
			push_error("CONSTRUCTION_CAPTURE: could not place level %d" % (level + 1))
			get_tree().quit(1)
			return
	if BoardState.spawn_item("construction_producer", Vector2i(3, 3)) == null:
		push_error("CONSTRUCTION_CAPTURE: could not place producer")
		get_tree().quit(1)
		return
	var board: Control = load("res://scenes/merge_board/merge_board.tscn").instantiate()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(board)
	await get_tree().process_frame
	Input.warp_mouse(Vector2(6, 6))
	await get_tree().create_timer(2.6).timeout
	var visible_ids: Dictionary = {}
	for child in board.find_children("*", "ItemView", true, false):
		var view := child as ItemView
		var definition := view.get_def()
		if definition != null and definition.chain_id == "construction":
			visible_ids[definition.id] = true
	for level in 8:
		if not visible_ids.has("construction_%d" % (level + 1)):
			push_error("CONSTRUCTION_CAPTURE: level %d is not rendered" % (level + 1))
			get_tree().quit(1)
			return
	if not visible_ids.has("construction_producer"):
		push_error("CONSTRUCTION_CAPTURE: producer is not rendered")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	print("CONSTRUCTION_CHAIN_CAPTURE_OK levels=8 producer=1")
	get_tree().quit()
