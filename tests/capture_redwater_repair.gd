extends Control
## Short running-game capture of a task-driven Redwater repair transition.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	GameManager.profile.current_chapter_id = "chapter_5_the_station"
	GameManager.profile.story_flags["redwater_unlocked"] = true
	var scene: Control = load("res://scenes/redwater/redwater.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	Input.warp_mouse(Vector2(6, 6))
	await get_tree().create_timer(1.0).timeout
	ResidenceManager.hotspot_states["fuel_pumps"] = ResidenceHotspot.State.COMPLETED
	EventBus.hotspot_state_changed.emit("fuel_pumps", ResidenceHotspot.State.COMPLETED)
	var environment := scene.get_node("Layout/Scene/Background") as RedwaterEnvironment
	environment.play_repair("fuel_pumps")
	await get_tree().create_timer(2.6).timeout
	get_tree().quit()
