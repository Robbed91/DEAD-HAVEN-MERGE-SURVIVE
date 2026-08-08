extends Node
## Verifies illustrated defence staging while the established manager test
## remains authoritative for costs, odds, damage, rewards and persistence.

const CASES := {
	"hollow_creek_first_wave": ["hollow_creek_farmhouse", "hollow_creek_state_04_defended.png"],
	"redwater_defence": ["redwater_service_station", "redwater_state_05_defended.jpg"],
	"greybridge_defence": ["greybridge_school", "greybridge_state_05_defended.jpg"],
	"saint_mercy_defence": ["saint_mercy_hospital", "saint_mercy_state_05_defended.jpg"],
	"northgate_defence": ["northgate_prison", "northgate_state_05_defended.jpg"],
}
var failed := false

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	for event_id in CASES:
		GameManager.new_game()
		GameManager.settings.reduced_motion = true
		_complete_residence(CASES[event_id][0])
		SceneRouter.pending_params = {"event_id": event_id, "return_scene_key": "haven"}
		var screen: Control = load("res://scenes/defence/defence.tscn").instantiate()
		add_child(screen)
		await get_tree().process_frame
		var art := screen.get_node("SceneArt") as TextureRect
		var leader := screen.get_node("CombatStage/SelectedSurvivor") as LayeredCharacterRig
		var hollow := screen.get_node("CombatStage/DrifterHollow") as LayeredCharacterRig
		_check(art.texture != null and art.texture.resource_path.ends_with(CASES[event_id][1]), "%s background wrong" % event_id)
		_check(leader != null and leader.get_node("FinalArtwork").texture != null, "%s leader artwork missing" % event_id)
		_check(hollow != null and hollow.get_node("FinalArtwork").texture != null, "%s Drifter artwork missing" % event_id)
		var first_button := screen.get_node("Layout/Margin/Content/PrepPanel/SurvivorBox").get_child(0) as Button
		_check(first_button.icon != null, "%s illustrated leader card missing" % event_id)
		_check(not DefenceManager.has_survived(event_id), "%s presentation mutated result state" % event_id)
		screen.queue_free()
		await get_tree().process_frame

	# Exercise only the presentation hooks around the existing real launch.
	GameManager.new_game()
	GameManager.settings.reduced_motion = false
	_complete_residence("hollow_creek_farmhouse")
	SceneRouter.pending_params = {"event_id": "hollow_creek_first_wave", "return_scene_key": "haven"}
	var animated: Control = load("res://scenes/defence/defence.tscn").instantiate()
	add_child(animated)
	await get_tree().process_frame
	animated.call("_on_send_pressed")
	_check(animated.get_node("Layout/Margin/Content/EncounterPanel").visible, "encounter state did not reveal")
	_check((animated.get_node("CombatStage/SelectedSurvivor") as LayeredCharacterRig)._current_state == "defensive_action", "leader defensive action did not trigger")
	_check((animated.get_node("CombatStage/DrifterHollow") as LayeredCharacterRig)._current_state == "detect_target", "Drifter detection did not trigger")
	animated.queue_free()
	await get_tree().process_frame

	if failed:
		push_error("SMOKE_DEFENCE_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_DEFENCE_PRESENTATION_OK events=5 leaders=5 drifter=5 encounter_animation=1 gameplay_mutations=0")
		get_tree().quit()

func _complete_residence(residence_id: String) -> void:
	var residence := ResidenceManager.get_residence(residence_id)
	for hotspot in residence.hotspots:
		ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SMOKE_DEFENCE_PRESENTATION: %s" % message)
