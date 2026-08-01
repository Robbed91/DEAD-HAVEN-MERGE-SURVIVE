extends Node
## Captures through the project's 720-wide canvas at a tall Android aspect,
## then scales to a 1080x2400 device reference. This matches canvas_items
## stretch behaviour instead of laying the UI out at device pixels.

const OUTPUT_DIR := "res://docs/hotspot-captures"
const LOGICAL_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(1080, 2400)
const SETS := [
	{
		"name": "redwater_available_1080x2400",
		"scene": "res://scenes/redwater/redwater.tscn",
		"residence": "redwater_service_station",
		"chapter": "chapter_5_the_station",
		"flag": "redwater_unlocked",
	},
	{
		"name": "greybridge_available_1080x2400",
		"scene": "res://scenes/greybridge/greybridge.tscn",
		"residence": "greybridge_school",
		"chapter": "chapter_6_the_signal",
		"flag": "greybridge_unlocked",
	},
	{
		"name": "saint_mercy_available_1080x2400",
		"scene": "res://scenes/saint_mercy/saint_mercy.tscn",
		"residence": "saint_mercy_hospital",
		"chapter": "chapter_7_do_no_harm",
		"flag": "saint_mercy_unlocked",
	},
]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for entry in SETS:
		GameManager.new_game()
		GameManager.settings.reduced_motion = true
		GameManager.profile.current_chapter_id = entry.chapter
		GameManager.profile.story_flags[entry.flag] = true
		var residence := ResidenceManager.get_residence(entry.residence)
		for hotspot in residence.hotspots:
			ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.DESTROYED

		var viewport := SubViewport.new()
		viewport.size = LOGICAL_SIZE
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = false
		add_child(viewport)
		var scene: Control = load(entry.scene).instantiate()
		scene.set_anchors_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(scene)
		await get_tree().process_frame
		await get_tree().create_timer(2.4).timeout
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var output := "%s/%s.png" % [OUTPUT_DIR, entry.name]
		var image := viewport.get_texture().get_image()
		image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var error := image.save_png(ProjectSettings.globalize_path(output))
		if error != OK:
			push_error("Could not save %s: %s" % [output, error])
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("ANDROID_HOTSPOT_CAPTURE_OK residences=3 logical=%dx%d output=%dx%d" % [LOGICAL_SIZE.x, LOGICAL_SIZE.y, OUTPUT_SIZE.x, OUTPUT_SIZE.y])
	get_tree().quit()
