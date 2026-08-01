extends Node
## Verifies that every implemented dialogue speaker uses approved portrait
## artwork and the correct illustrated location without touching dialogue data.

const CASES := [
	["intro_02", "mara_vale", "intro_farmhouse_approach_concept.png", "neutral"],
	["noah_02", "noah_vance", "hollow_creek_state_03_habitable.png", "injured"],
	["lena_02", "lena_ortiz", "redwater_state_03_temporary.jpg", "angry"],
	["riley_02", "riley_chen", "greybridge_state_03_temporary.jpg", "concerned"],
	["imogen_02", "imogen_shaw", "saint_mercy_state_03_temporary.jpg", "concerned"],
	["caleb_02", "caleb_rusk", "northgate_state_03_temporary.jpg", "concerned"],
	["signal_keeper_02", "signal_keeper", "radio_relay_station.png", "neutral"],
]
var failed := false

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	GameManager.settings.reduced_motion = true
	for test_case in CASES:
		SceneRouter.pending_params = {"start_id": test_case[0], "return_scene_key": "haven"}
		var screen: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
		add_child(screen)
		await get_tree().process_frame
		var portrait: SurvivorSilhouette = screen.get_node("Layout/Row/PortraitMargin/Portrait")
		var art := screen.get_node("SceneArt") as TextureRect
		_check(portrait.visible, "%s portrait hidden" % test_case[0])
		_check(portrait.is_using_texture_portrait(), "%s final portrait missing" % test_case[1])
		_check(not portrait.is_using_procedural_fallback(), "%s reached geometric fallback" % test_case[1])
		_check(portrait.expression == test_case[3], "%s authored expression state wrong" % test_case[0])
		_check(art.texture != null and art.texture.resource_path.ends_with(test_case[2]), "%s location background wrong" % test_case[0])
		screen.queue_free()
		await get_tree().process_frame

	SceneRouter.pending_params = {"start_id": "intro_01", "return_scene_key": "haven"}
	var narration: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
	add_child(narration)
	await get_tree().process_frame
	_check(not narration.get_node("Layout/Row/PortraitMargin").visible, "narration left an empty portrait column")
	_check((narration.get_node("Layout/Row/TextPanel/TextMargin/TextLayout/TextLabel") as Label).visible_ratio == 1.0, "reduced motion did not disable text reveal")
	narration.queue_free()
	await get_tree().process_frame

	GameManager.settings.reduced_motion = false
	SceneRouter.pending_params = {"start_id": "intro_02", "return_scene_key": "haven"}
	var animated: Control = load("res://scenes/dialogue/dialogue.tscn").instantiate()
	add_child(animated)
	await get_tree().process_frame
	var animated_text := animated.get_node("Layout/Row/TextPanel/TextMargin/TextLayout/TextLabel") as Label
	_check(animated_text.visible_ratio < 1.0, "text reveal did not trigger when effects are enabled")
	animated.queue_free()
	await get_tree().process_frame

	if failed:
		push_error("SMOKE_DIALOGUE_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_DIALOGUE_PRESENTATION_OK speakers=7 backgrounds=7 geometric_fallback=0 reduced_motion=1 reveal_animation=1")
		get_tree().quit()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SMOKE_DIALOGUE_PRESENTATION: %s" % message)
