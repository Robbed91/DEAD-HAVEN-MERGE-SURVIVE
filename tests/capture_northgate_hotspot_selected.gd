extends Control
## Clean-process proof of the selected illustrated hotspot plus its real
## dynamic task panel (kept separate from the six-state capture loop).

const OUTPUT := "res://docs/northgate-captures/07_selected_control_room.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.profile.story_flags["northgate_unlocked"] = true
	ResidenceManager.reset_new_game()
	BoardState.reset_new_board()
	BoardState.discovered_item_ids["electronics_4"] = true
	BoardState.spawn_item("electronics_4", BoardState.find_empty_cell())
	var scene: Control = load("res://scenes/northgate/northgate.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	scene.call("_set_selected_hotspot", "control_room")
	var panel: TaskPanel = scene.get_node("TaskPanel")
	panel.show_for_hotspot("control_room", "northgate_prison")
	await get_tree().create_timer(0.8).timeout
	if not panel.visible:
		push_error("NORTHGATE_SELECTED_CAPTURE: task panel did not open")
		get_tree().quit(1)
		return
	var center: Control = panel.get_node("CenterContainer")
	# The direct scene harness has no Main-scene sizing parent, so pin this
	# CanvasLayer child to the same logical viewport used by the running game.
	center.set_anchors_preset(Control.PRESET_TOP_LEFT)
	center.position = Vector2.ZERO
	center.size = get_viewport_rect().size
	await get_tree().process_frame
	var announcement_layer := get_node_or_null("/root/UIAnimationDirector")
	if announcement_layer != null and announcement_layer.get_child_count() > 0:
		for announcement in announcement_layer.get_child(0).get_children():
			announcement.queue_free()
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	print("NORTHGATE_SELECTED_CAPTURE_OK hotspot=control_room")
	get_tree().quit()
