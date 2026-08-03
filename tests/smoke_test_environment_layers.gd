extends Node
## Verifies each residence gets its own combination of ambient effect
## layers (not one exclusive preset shared by every screen), that low
## graphics quality zeroes particle-based layers without erroring, that an
## unknown layer name degrades gracefully, and that hidden/off-screen
## still stops processing exactly as before this rewrite.

const UIAnimationDirectorScript = preload("res://scripts/ui/ui_animation_director.gd")

func _ready() -> void:
	if not _check_residence_layer_assignment():
		return
	if not await _check_low_quality_disables_particles():
		return
	if not await _check_unknown_layer_is_ignored():
		return
	if not await _check_visibility_gating_unchanged():
		return
	print("SMOKE_ENVIRONMENT_LAYERS_OK")
	get_tree().quit(0)

func _check_residence_layer_assignment() -> bool:
	var director := UIAnimationDirectorScript.new()
	var cases := {
		"res://scenes/haven/haven.tscn": ["rain", "foliage", "dust", "smoke", "embers"],
		"res://scenes/redwater/redwater.tscn": ["rain", "dust", "sparks", "smoke"],
		"res://scenes/greybridge/greybridge.tscn": ["rain", "leaves", "radio_pulse", "smoke", "foliage"],
		"res://scenes/saint_mercy/saint_mercy.tscn": ["fog", "rain", "sparks", "smoke"],
		"res://scenes/northgate/northgate.tscn": ["rain", "dust", "sparks"],
	}
	for path in cases:
		var expected: Array = cases[path]
		var actual: Array[String] = director._layers_for_scene(path)
		if actual != expected:
			_fail("%s expected layers %s, got %s" % [path, expected, actual])
			director.free()
			return false
	director.free()
	print("SMOKE_ENVIRONMENT_LAYERS: each residence gets its own distinct layer combination OK")
	return true

func _check_low_quality_disables_particles() -> bool:
	GameManager.new_game()
	GameManager.update_setting("graphics_quality", "low")
	var ambience := AmbientVFX.new()
	ambience.layers = ["rain", "smoke", "sparks"]
	ambience.size = Vector2(360, 480)
	add_child(ambience)
	await get_tree().process_frame
	for layer in ambience.layers:
		var particles: Array = ambience._layer_particles.get(layer, [])
		if particles.size() != 0:
			_fail("low graphics quality should produce zero particles for '%s', got %d" % [layer, particles.size()])
			ambience.free()
			GameManager.update_setting("graphics_quality", "standard")
			return false
	ambience.free()
	GameManager.update_setting("graphics_quality", "standard")
	print("SMOKE_ENVIRONMENT_LAYERS: low graphics quality disables particle-based layers OK")
	return true

func _check_unknown_layer_is_ignored() -> bool:
	var ambience := AmbientVFX.new()
	ambience.layers = ["rain", "not_a_real_layer"]
	ambience.size = Vector2(360, 480)
	add_child(ambience)
	await get_tree().process_frame
	ambience.queue_redraw()
	await get_tree().process_frame
	var still_valid := is_instance_valid(ambience)
	ambience.free()
	if not still_valid:
		_fail("an unknown layer name should be ignored, not crash the node")
		return false
	print("SMOKE_ENVIRONMENT_LAYERS: unknown layer name degrades gracefully OK")
	return true

func _check_visibility_gating_unchanged() -> bool:
	var ambience := AmbientVFX.new()
	ambience.layers = ["rain"]
	ambience.size = Vector2(360, 480)
	add_child(ambience)
	await get_tree().process_frame
	if not ambience.is_processing():
		_fail("visible ambience should process")
		ambience.free()
		return false
	ambience.hide()
	await get_tree().process_frame
	if ambience.is_processing():
		_fail("hidden ambience must stop processing")
		ambience.free()
		return false
	ambience.free()
	print("SMOKE_ENVIRONMENT_LAYERS: visibility gating unchanged OK")
	return true

func _fail(message: String) -> void:
	print("SMOKE_ENVIRONMENT_LAYERS_FAIL: %s" % message)
	get_tree().quit(1)
