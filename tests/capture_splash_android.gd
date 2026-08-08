extends Node

const LOGICAL_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(1080, 2400)
const OUTPUT_DIR := "res://docs/splash-captures"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	GameManager.settings.reduced_motion = false
	var viewport := SubViewport.new()
	viewport.size = LOGICAL_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)
	var splash: Control = load("res://scenes/splash/splash.tscn").instantiate()
	splash.theme = ThemeFactory.build_theme(1.0, false, false)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(splash)
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var output := "%s/splash_final_1080x2400.png" % OUTPUT_DIR
	if image.save_png(ProjectSettings.globalize_path(output)) != OK:
		push_error("Could not save %s" % output)
		get_tree().quit(1)
		return
	print("SPLASH_ANDROID_CAPTURE_OK logical=720x1600 output=1080x2400")
	get_tree().quit()
