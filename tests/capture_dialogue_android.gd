extends Node
## Captures representative narration, survivor and radio-speaker states.

const LOGICAL_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(1080, 2400)
const OUTPUT_DIR := "res://docs/dialogue-captures"
const CASES := ["intro_01", "lena_02", "signal_keeper_02"]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for entry_id in CASES:
		GameManager.new_game()
		GameManager.settings.reduced_motion = true
		SceneRouter.pending_params = {"start_id": entry_id, "return_scene_key": "haven"}
		var viewport := SubViewport.new()
		viewport.size = LOGICAL_SIZE
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = false
		add_child(viewport)
		var screen: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
		screen.theme = ThemeFactory.build_theme(1.0, false, false)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(screen)
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var output := "%s/%s_1080x2400.png" % [OUTPUT_DIR, entry_id]
		if image.save_png(ProjectSettings.globalize_path(output)) != OK:
			push_error("Could not save %s" % output)
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("DIALOGUE_ANDROID_CAPTURE_OK states=3 logical=720x1600 output=1080x2400")
	get_tree().quit()
