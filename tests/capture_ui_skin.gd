extends Control
## Deterministic running-game captures for interface-skin and safe-area QA.

const SCENES := {
	"haven": "res://scenes/haven/haven.tscn",
	"redwater": "res://scenes/redwater/redwater.tscn",
	"greybridge": "res://scenes/greybridge/greybridge.tscn",
	"saint_mercy": "res://scenes/saint_mercy/saint_mercy.tscn",
	"northgate": "res://scenes/northgate/northgate.tscn",
	"map": "res://scenes/world_map/world_map.tscn",
	"survivors": "res://scenes/survivors/survivors.tscn",
	"settings": "res://scenes/settings/settings.tscn",
	"dialogue": "res://scenes/dialogue/dialogue.tscn",
}

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	var width := maxi(360, _env_int("DEAD_HAVEN_CAPTURE_WIDTH", 720))
	var height := maxi(640, _env_int("DEAD_HAVEN_CAPTURE_HEIGHT", 1280))
	get_window().size = Vector2i(width, height)
	GameManager.new_game()
	BoardState.reset_new_board()

	var capture_key := OS.get_environment("DEAD_HAVEN_CAPTURE_SCENE")
	if capture_key.is_empty():
		capture_key = "haven"
	var scene_path: String = SCENES.get(capture_key, SCENES.haven)
	if capture_key == "dialogue":
		SceneRouter.pending_params = {"start_id": "intro_01", "return_scene_key": "haven"}
	var screen: Control = load(scene_path).instantiate()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	if capture_key == "task":
		var panel := screen.get_node_or_null("TaskPanel") as TaskPanel
		if panel != null:
			panel.show_for_hotspot("front_door")
			await get_tree().process_frame
			var center := panel.get_node("CenterContainer") as Control
			var card := panel.get_node("CenterContainer/Panel") as Control
			print("UI_CAPTURE_TASK_GEOMETRY viewport=%s center_local=%s center_global=%s scale=%s card=%s" % [str(get_viewport_rect()), str(Rect2(center.position, center.size)), str(center.get_global_rect()), str(center.get_global_transform_with_canvas().get_scale()), str(card.get_global_rect())])
	# Wait through the longest new-game announcement so evidence captures the
	# stable screen rather than a transient banner covering the residence title.
	await get_tree().create_timer(1.6).timeout

	var filename := OS.get_environment("DEAD_HAVEN_CAPTURE_FILE")
	if filename.is_empty():
		filename = "ui_%s_%dx%d.png" % [capture_key, width, height]
	var output := "res://docs/ui-skin-captures/%s" % filename
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(output))
	print("UI_CAPTURE_OK scene=%s size=%dx%d output=%s" % [capture_key, width, height, output])
	get_tree().quit()

func _env_int(key: String, fallback: int) -> int:
	var value := OS.get_environment(key)
	return fallback if value.is_empty() else int(value)
