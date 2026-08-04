extends Control
## Layout check for the Scavenging screen (hero panel, threat badge, danger
## overlay, survivor selection, send button) at whatever resolution Godot
## was launched with.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	SceneRouter.pending_params = {"mission_id": "police_checkpoint"}
	var scene: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var w := int(get_window().size.x)
	var h := int(get_window().size.y)
	var out := "res://docs/layout-captures/scavenging_%dx%d.png" % [w, h]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out))
	get_tree().quit(0)
