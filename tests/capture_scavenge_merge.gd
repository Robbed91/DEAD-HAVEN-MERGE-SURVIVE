extends Control
## Live capture of the scavenging merge challenge actually running inside
## the real scavenging.tscn flow (not just the state logic in isolation) -
## selects a survivor, sends them, picks the first encounter choice, and
## captures the resulting merge-challenge grid.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	SceneRouter.pending_params = {"mission_id": "abandoned_grocery_store"}
	var scene: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	scene.get_node("%SendButton").pressed.emit()
	await get_tree().process_frame
	var choices := scene.get_node("%ChoicesBox")
	choices.get_child(0).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var w := int(get_window().size.x)
	var h := int(get_window().size.y)
	var out := "res://docs/layout-captures/scavenge_merge_%dx%d.png" % [w, h]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out))
	get_tree().quit(0)
