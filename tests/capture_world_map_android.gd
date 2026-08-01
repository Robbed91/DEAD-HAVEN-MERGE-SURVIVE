extends Node
## Captures locked and fully revealed running-game map states through the
## project's expanded 720x1600 canvas, scaled to a 1080x2400 device reference.

const LOGICAL_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(1080, 2400)
const OUTPUT_DIR := "res://docs/world-map-captures"
const FLAGS := ["redwater_unlocked", "greybridge_unlocked", "saint_mercy_unlocked", "northgate_unlocked"]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for state in ["locked", "fully_revealed"]:
		GameManager.new_game()
		# Capture the settled final state deterministically; animation triggering
		# is covered by the presentation smoke test and runtime scene itself.
		GameManager.settings.reduced_motion = true
		if state == "fully_revealed":
			for flag in FLAGS:
				GameManager.profile.story_flags[flag] = true
			VehicleManager.discovered_vehicle_ids["delivery_van"] = true
		var viewport := SubViewport.new()
		viewport.size = LOGICAL_SIZE
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = false
		add_child(viewport)
		var screen: Control = load("res://scenes/world_map/world_map.tscn").instantiate()
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(screen)
		await get_tree().process_frame
		await get_tree().create_timer(1.2).timeout
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var output := "%s/world_map_%s_1080x2400.png" % [OUTPUT_DIR, state]
		var error := image.save_png(ProjectSettings.globalize_path(output))
		if error != OK:
			push_error("Could not save %s: %s" % [output, error])
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("WORLD_MAP_ANDROID_CAPTURE_OK states=2 logical=720x1600 output=1080x2400")
	get_tree().quit()
