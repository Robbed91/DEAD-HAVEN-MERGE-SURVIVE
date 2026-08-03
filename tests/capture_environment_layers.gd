extends Control
## Running-game verification that a real residence screen's background gets
## its own combination of ambient layers (via ui_animation_director.gd's
## automatic per-scene scan), not the old single exclusive preset.

const OUTPUT := "res://docs/producer-state-captures/live_environment_layers_hollow_creek.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame

	var director: Node = load("res://scripts/ui/ui_animation_director.gd").new()
	var background := haven.find_child("Background", true, false)
	var ambience: AmbientVFX = AmbientVFX.new()
	ambience.layers = director._layers_for_scene(haven.scene_file_path)
	background.add_child(ambience)
	director.free()

	var board_panel: Control = haven.get_node("%BoardPanel")
	board_panel.visible = false # the embedded board otherwise covers most of the background this is capturing
	await get_tree().create_timer(0.6).timeout

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit(0)
