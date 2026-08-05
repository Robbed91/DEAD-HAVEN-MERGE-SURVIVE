extends Control
## One-off visual capture confirming the New Game overwrite confirmation
## no longer overflows the screen at real device resolutions now that it
## uses AppConfirmDialog instead of the native (non-canvas_items-stretched)
## ConfirmationDialog. Not part of the regular smoke suite.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	SaveManager.save_game()
	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	await get_tree().process_frame
	menu.get_node("%NewGameButton").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var w := int(get_window().size.x)
	var h := int(get_window().size.y)
	var out := "res://docs/layout-captures/overwrite_dialog_%dx%d.png" % [w, h]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out))
	get_tree().quit(0)
