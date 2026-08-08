extends Node
## Presentation regression: shared effects remain state-neutral and honour
## reduced-motion/off-screen policy.

const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
const AmbientVFXScript = preload("res://scripts/vfx/ambient_vfx.gd")
const VehicleVisualScript = preload("res://scripts/vehicle/vehicle_visual.gd")

var _failed := false

func _ready() -> void:
	GameManager.new_game()
	var resources_before := GameManager.resources.duplicate(true)
	var profile_before := GameManager.profile.duplicate(true)

	var button := Button.new()
	button.size = Vector2(160, 52)
	add_child(button)
	await get_tree().process_frame
	GameManager.settings.reduced_motion = true
	MotionFXScript.press(button, true)
	_assert(button.scale == Vector2.ONE, "reduced motion must leave button transform neutral")

	GameManager.settings.reduced_motion = false
	GameManager.settings.graphics_quality = "standard"
	MotionFXScript.press(button, true)
	_assert(button.has_meta("motion_fx_tween"), "button press animation did not create an interruptible tween")
	await get_tree().create_timer(0.04).timeout
	MotionFXScript.stop(button)
	button.scale = Vector2.ONE

	var ambience := AmbientVFXScript.new()
	ambience.size = Vector2(360, 480)
	add_child(ambience)
	await get_tree().process_frame
	_assert(ambience.is_processing(), "visible ambience should process")
	ambience.hide()
	await get_tree().process_frame
	_assert(not ambience.is_processing(), "hidden ambience must stop processing")

	var vehicle := VehicleVisualScript.new()
	vehicle.size = Vector2(320, 180)
	vehicle.stage = 3
	add_child(vehicle)
	vehicle.play_upgrade_sequence()
	await get_tree().process_frame
	_assert(vehicle.stage == 3, "vehicle presentation changed gameplay stage")

	_assert(GameManager.resources == resources_before, "animation layer mutated resources")
	_assert(GameManager.profile == profile_before, "animation layer mutated profile")
	if _failed:
		push_error("SMOKE_ANIMATION_LAYER_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_ANIMATION_LAYER_OK reduced_motion=pass offscreen=pass state_neutral=pass")
		get_tree().quit()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("SMOKE_ANIMATION_LAYER: %s" % message)
