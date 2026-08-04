extends Control
## Running-game layout check at whatever resolution Godot was launched
## with (see the xvfb-run invocations that pass --resolution). Captures
## Haven - the most visually dense screen (top bar, board, hotspots, nav) -
## so clipping/overlap issues at each target width are visible directly,
## without needing an Android device or emulator.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame
	var w := int(get_window().size.x)
	var h := int(get_window().size.y)
	var out := "res://docs/layout-captures/haven_%dx%d.png" % [w, h]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out))
	get_tree().quit(0)
