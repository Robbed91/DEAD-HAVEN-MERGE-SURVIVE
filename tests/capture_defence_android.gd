extends Node
## Captures preparation, encounter and resolved-success presentation using a
## disposable test state. The manager remains the source of the real result.

const LOGICAL_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(1080, 2400)
const OUTPUT_DIR := "res://docs/defence-captures"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	GameManager.new_game()
	GameManager.settings.reduced_motion = true
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	for hotspot in residence.hotspots:
		ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED
	SceneRouter.pending_params = {"event_id": "hollow_creek_first_wave", "return_scene_key": "haven"}
	var viewport := SubViewport.new()
	viewport.size = LOGICAL_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)
	var screen: Control = load("res://scenes/defence/defence.tscn").instantiate()
	screen.theme = ThemeFactory.build_theme(1.0, false, false)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(screen)
	await get_tree().process_frame
	await _capture(viewport, "defence_preparation_1080x2400")
	screen.call("_on_send_pressed")
	await get_tree().process_frame
	await _capture(viewport, "defence_encounter_1080x2400")
	var choice: Dictionary = DefenceManager.event_choices.hollow_creek_first_wave[0]
	var original_chance: float = float(choice.success_chance)
	DefenceManager.event_choices.hollow_creek_first_wave[0].success_chance = 1.0
	screen.call("_on_choice_pressed", 0)
	DefenceManager.event_choices.hollow_creek_first_wave[0].success_chance = original_chance
	await get_tree().process_frame
	await _capture(viewport, "defence_success_1080x2400")
	print("DEFENCE_ANDROID_CAPTURE_OK states=3 logical=720x1600 output=1080x2400")
	get_tree().quit()

func _capture(viewport: SubViewport, filename: String) -> void:
	await get_tree().create_timer(0.25).timeout
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var output := "%s/%s.png" % [OUTPUT_DIR, filename]
	if image.save_png(ProjectSettings.globalize_path(output)) != OK:
		push_error("Could not save %s" % output)
		get_tree().quit(1)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
