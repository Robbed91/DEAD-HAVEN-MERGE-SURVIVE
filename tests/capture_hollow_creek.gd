extends Control
## Visual-only capture harness. It mutates in-memory presentation state and
## never invokes quest completion, economy, progression, or save methods.

const OUTPUT_DIR := "res://docs/vertical-slice-captures"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.profile.current_chapter_id = "chapter_4_the_first_wave"
	GameManager.profile.unlocked_survivor_ids = ["mara_vale", "noah_vance"]
	GameManager.profile.story_flags["chapter_1_intro_seen"] = true
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	for hotspot in residence.hotspots:
		ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED

	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/hollow_creek_final_running.png"))

	await get_tree().create_timer(1.0).timeout
	var background := haven.get_node("Layout/Scene/Background") as HollowCreekEnvironment
	background.play_window_boarding()
	await get_tree().create_timer(3.5).timeout
	get_tree().quit()
