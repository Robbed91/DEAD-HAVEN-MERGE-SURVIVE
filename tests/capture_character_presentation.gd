extends Control
## Running-game verification capture for final survivor portraits/dialogue.

const OUTPUT_DIR := "res://docs/character-captures"
const IDS := ["mara_vale", "noah_vance", "lena_ortiz", "imogen_shaw", "riley_chen", "caleb_rusk"]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.profile.unlocked_survivor_ids = IDS.duplicate()
	GameManager.profile.story_flags["chapter_1_intro_seen"] = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var roster: Control = load("res://scenes/survivors/survivors.tscn").instantiate()
	roster.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(roster)
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	_save("survivor_roster_final.png")
	roster.queue_free()
	await get_tree().process_frame

	var dialogue: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
	dialogue.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dialogue)
	await get_tree().process_frame
	dialogue._show_entry("intro_01")
	await get_tree().create_timer(1.0).timeout
	_save("mara_dialogue_final.png")
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()

func _save(filename: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename]))
