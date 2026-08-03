extends Control
## Running-game verification that a real high-threat scavenging location
## shows the restrained edge glow and corner threat indicator - never a
## full-screen filter - and that petrol_station additionally shows the gas
## cloud, the one real fuel context in the current roster.

const OUTPUT_DIR := "res://docs/producer-state-captures/"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	SceneRouter.pending_params = {"mission_id": "police_checkpoint"}
	var checkpoint: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	checkpoint.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(checkpoint)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "live_danger_police_checkpoint.png"))
	checkpoint.queue_free()
	await get_tree().process_frame

	SceneRouter.pending_params = {"mission_id": "petrol_station"}
	var petrol: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	petrol.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(petrol)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "live_danger_petrol_station.png"))

	get_tree().quit(0)
