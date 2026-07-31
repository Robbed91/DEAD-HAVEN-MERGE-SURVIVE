extends Control
## Android-portrait running-game proof for the approved Hollow Creek objects.

const OUTPUT_DIR := "res://docs/hollow-creek-captures"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.profile.story_flags["chapter_1_intro_seen"] = true
	ResidenceManager.reset_new_game()
	BoardState.reset_new_board()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture(false, "01_available.png")
	await _capture(true, "02_completed.png")
	print("HOLLOW_CREEK_HOTSPOT_CAPTURE_OK states=2 resolution=%s" % get_viewport_rect().size)
	get_tree().quit()

func _capture(completed: bool, filename: String) -> void:
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	for hotspot in residence.hotspots:
		ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED if completed else ResidenceHotspot.State.DESTROYED
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var director := get_node_or_null("/root/UIAnimationDirector")
	if director != null:
		for announcement in director.find_children("*", "PanelContainer", true, false):
			announcement.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/" + filename))
	haven.queue_free()
	await get_tree().process_frame
