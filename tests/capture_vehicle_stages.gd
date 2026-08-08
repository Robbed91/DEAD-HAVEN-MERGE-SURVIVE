extends Control
## Running-game screenshots of all nine delivery-van stages and one active
## event-driven upgrade transition.

const OUTPUT_DIR := "res://docs/vehicle-captures"
const VEHICLE_ID := "delivery_van"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	VehicleManager.discovered_vehicle_ids[VEHICLE_ID] = true
	await get_tree().create_timer(1.2).timeout
	for stage in 9:
		VehicleManager.current_stages[VEHICLE_ID] = stage
		var scene := await _make_scene()
		await get_tree().create_timer(0.3).timeout
		_save("%02d_stage_%d" % [stage + 1, stage])
		scene.queue_free()
		await get_tree().process_frame

	VehicleManager.current_stages[VEHICLE_ID] = 0
	BoardState.spawn_item("vehicle_parts_3", BoardState.find_empty_cell())
	var upgrade_scene := await _make_scene()
	upgrade_scene.call("_on_upgrade_pressed")
	await get_tree().create_timer(0.16).timeout
	_save("10_upgrade_transition")
	upgrade_scene.queue_free()
	print("VEHICLE_CAPTURE_OK stages=9 transition=1 resolution=%dx%d" % [get_viewport_rect().size.x, get_viewport_rect().size.y])
	get_tree().quit(0)

func _make_scene() -> Control:
	var scene: Control = load("res://scenes/vehicle/vehicle.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	Input.warp_mouse(Vector2(6, 6))
	return scene

func _save(name: String) -> void:
	var output_dir := OUTPUT_DIR + ("/tall_android" if get_viewport_rect().size.y > 1400.0 else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [output_dir, name]))
