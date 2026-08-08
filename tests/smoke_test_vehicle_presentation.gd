extends Node
## Verifies the delivery van's nine final visual states without mutating
## vehicle definitions or exercising alternative progression code.

const STAGE_ROOT := "res://assets/art/vehicles/delivery_van/runtime/"

func _fail(message: String) -> void:
	print("SMOKE_VEHICLE_PRESENTATION_FAIL: %s" % message)
	get_tree().quit(1)

func _ready() -> void:
	for stage in 9:
		var path := "%sstage_%d.png" % [STAGE_ROOT, stage]
		if not ResourceLoader.exists(path):
			_fail("missing final art for stage %d" % stage)
			return
		var texture: Texture2D = load(path)
		if texture.get_width() != 512 or texture.get_height() != 512:
			_fail("stage %d must be 512x512, got %dx%d" % [stage, texture.get_width(), texture.get_height()])
			return

	var visual := VehicleVisual.new()
	visual.custom_minimum_size = Vector2(512, 512)
	add_child(visual)
	await get_tree().process_frame
	for stage in 9:
		visual.stage = stage
		await get_tree().process_frame
		var current: TextureRect = visual.get_node("IllustratedVanRig/CurrentStage")
		if current.texture == null:
			_fail("stage %d was not assigned to the live visual" % stage)
			return
	visual.stage = 4
	visual.play_upgrade_sequence()
	if visual.stage != 4:
		_fail("presentation sequence changed authoritative stage")
		return
	visual.queue_free()

	GameManager.new_game()
	VehicleManager.discovered_vehicle_ids["delivery_van"] = true
	for saved_stage in 9:
		VehicleManager.current_stages["delivery_van"] = saved_stage
		SaveManager.save_game()
		var loaded := SaveManager.load_game()
		VehicleManager.current_stages["delivery_van"] = -1
		GameManager.apply_save_data(loaded)
		if VehicleManager.get_current_stage("delivery_van") != saved_stage:
			_fail("save round trip did not preserve stage %d" % saved_stage)
			return
	print("SMOKE_VEHICLE_PRESENTATION_OK stages=9 runtime=512 layered=1 state_neutral=1 save_states=9")
	get_tree().quit(0)
