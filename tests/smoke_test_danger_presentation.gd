extends Node
## Verifies gameplay-neutral danger presentation: the pulse rate is a
## documented safe frequency (not a strobe), the edge glow can never become
## a full-screen filter, reduced motion keeps warning information static
## instead of removing it, real scavenging/defence triggers produce the
## right presentation without touching any gameplay data, and the gas
## cloud is restricted to the one real fuel context in the current roster.

func _ready() -> void:
	if not _check_pulse_rate_is_safe():
		return
	if not _check_edge_never_full_screen():
		return
	if not _check_reduced_motion_keeps_static_warning():
		return
	if not _check_scavenging_danger_wiring():
		return
	if not await _check_defence_danger_wiring():
		return
	if not _check_gameplay_neutral():
		return
	print("SMOKE_DANGER_PRESENTATION_OK")
	get_tree().quit(0)

func _check_pulse_rate_is_safe() -> bool:
	var hz := DangerOverlay.PULSE_ANGULAR_SPEED / TAU
	if hz >= DangerOverlay.PULSE_SAFE_MAX_HZ:
		_fail("pulse rate %.2f Hz is at or above the %.1f Hz photosensitivity-risk threshold" % [hz, DangerOverlay.PULSE_SAFE_MAX_HZ])
		return false
	print("SMOKE_DANGER_PRESENTATION: pulse rate %.2f Hz is well under the safe threshold OK" % hz)
	return true

func _check_edge_never_full_screen() -> bool:
	var max_edge := DangerOverlay.EDGE_BASE + DangerOverlay.EDGE_PER_INTENSITY * 1.0
	var short_side := 720.0 # narrowest supported portrait width
	if max_edge / short_side > DangerOverlay.MAX_EDGE_FRACTION:
		_fail("max edge glow %.1fpx is more than %.0f%% of a %dpx-wide screen - too close to a full-screen filter" % [max_edge, DangerOverlay.MAX_EDGE_FRACTION * 100.0, short_side])
		return false
	print("SMOKE_DANGER_PRESENTATION: edge glow stays a border effect even at maximum intensity OK")
	return true

func _check_reduced_motion_keeps_static_warning() -> bool:
	var overlay := DangerOverlay.new()
	add_child(overlay)
	GameManager.update_setting("reduced_motion", true)
	overlay.set_danger(0.8)
	var still_has_intensity := overlay.intensity > 0.0
	var not_processing := not overlay.is_processing()
	GameManager.update_setting("reduced_motion", false)
	overlay.free()
	if not still_has_intensity:
		_fail("reduced motion should not remove the warning information (intensity became 0)")
		return false
	if not not_processing:
		_fail("reduced motion should stop the pulse from animating (is_processing() should be false)")
		return false
	print("SMOKE_DANGER_PRESENTATION: reduced motion keeps the warning as a static tint instead of removing it OK")
	return true

func _check_scavenging_danger_wiring() -> bool:
	GameManager.new_game()
	SceneRouter.pending_params = {"mission_id": "petrol_station"}
	var scene: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	add_child(scene)
	var petrol := ScavengingManager.get_mission("petrol_station")
	if petrol == null:
		_fail("petrol_station mission not found")
		scene.free()
		return false
	scene._apply_danger_presentation(petrol)
	if not scene._danger_overlay._show_gas_cloud:
		_fail("petrol_station should show the gas cloud - it's the one real fuel/petrol context")
		scene.free()
		return false
	if scene._danger_overlay.intensity <= 0.0:
		_fail("petrol_station (human_threat=1) should register some danger intensity")
		scene.free()
		return false

	var low_threat := ScavengingManager.get_mission("abandoned_grocery_store")
	scene._apply_danger_presentation(low_threat)
	if scene._danger_overlay._show_gas_cloud:
		_fail("a non-fuel location should never show the gas cloud")
		scene.free()
		return false
	if scene._danger_overlay.intensity > 0.0:
		_fail("abandoned_grocery_store (danger_rating=1, human_threat=0) should register zero danger intensity")
		scene.free()
		return false
	scene.free()
	print("SMOKE_DANGER_PRESENTATION: scavenging wires real danger_rating/human_threat/fuel-context data OK")
	return true

func _check_defence_danger_wiring() -> bool:
	GameManager.new_game()
	for hotspot in ResidenceManager.get_residence("hollow_creek_farmhouse").hotspots:
		ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED
	SceneRouter.pending_params = {"event_id": "hollow_creek_first_wave"}
	var scene: Control = load("res://scenes/defence/defence.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	scene._on_send_pressed()
	if scene._danger_overlay.intensity <= 0.0:
		_fail("launching a defence event should raise the danger overlay (defence warning/start)")
		scene.free()
		return false
	scene._play_outcome(false)
	if scene._danger_overlay.intensity <= 0.0:
		_fail("a failed/dangerous defence choice should keep the danger overlay raised")
		scene.free()
		return false
	scene._play_outcome(true)
	if scene._danger_overlay.intensity > 0.0:
		_fail("a successful defence outcome should clear the danger overlay")
		scene.free()
		return false
	scene.free()
	print("SMOKE_DANGER_PRESENTATION: defence warning/start and failed-choice triggers wire correctly OK")
	return true

func _check_gameplay_neutral() -> bool:
	GameManager.new_game()
	var resources_before := GameManager.resources.duplicate(true)
	var overlay := DangerOverlay.new()
	add_child(overlay)
	overlay.set_danger(1.0, true)
	overlay.set_danger(0.0)
	overlay.free()
	if GameManager.resources != resources_before:
		_fail("danger presentation must never mutate GameManager resources")
		return false
	print("SMOKE_DANGER_PRESENTATION: presentation never mutates gameplay resources OK")
	return true

func _fail(message: String) -> void:
	print("SMOKE_DANGER_PRESENTATION_FAIL: %s" % message)
	get_tree().quit(1)
