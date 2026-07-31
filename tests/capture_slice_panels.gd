extends Control

const OUTPUT_DIR := "res://docs/vertical-slice-captures"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.profile.story_flags["chapter_1_intro_seen"] = true
	ResidenceManager.reset_new_game()
	BoardState.reset_new_board()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	var panel: TaskPanel = haven.get_node("TaskPanel")
	panel.show_for_hotspot("front_door", "hollow_creek_farmhouse")
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/task_panel_final_running.png"))
	remove_child(haven)
	haven.queue_free()
	await get_tree().process_frame

	SceneRouter.pending_params = {"start_id": "intro_02", "return_scene_key": "haven"}
	var dialogue: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
	dialogue.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dialogue)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/dialogue_final_running.png"))
	get_tree().quit()
