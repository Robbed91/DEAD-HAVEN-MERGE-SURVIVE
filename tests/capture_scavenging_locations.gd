extends Control
## Android-portrait running-game captures for all final scavenging locations,
## plus the encounter and resolved presentation states.

const OUTPUT_DIR := "res://docs/scavenging-captures"
const IDS := [
	"abandoned_grocery_store", "clothing_outlet", "electronics_workshop",
	"farm_shed", "medical_clinic", "petrol_station", "police_checkpoint",
	"radio_relay_station", "roadside_wreck", "warehouse_depot",
]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	GameManager.new_game()
	GameManager.profile.story_flags["saint_mercy_unlocked"] = true
	for survivor_id in ["noah_vance", "lena_ortiz", "imogen_shaw", "riley_chen", "caleb_rusk"]:
		if survivor_id not in GameManager.profile.unlocked_survivor_ids:
			GameManager.profile.unlocked_survivor_ids.append(survivor_id)
	await get_tree().create_timer(1.8).timeout
	for index in IDS.size():
		var mission_id: String = IDS[index]
		var scene := await _make_scene(mission_id)
		await get_tree().create_timer(0.35).timeout
		_save("%02d_%s" % [index + 1, mission_id])
		scene.queue_free()
		await get_tree().process_frame

	var state_scene := await _make_scene("abandoned_grocery_store")
	state_scene.call("_on_send_pressed")
	await get_tree().create_timer(0.35).timeout
	_save("11_grocery_encounter")
	var mission = ScavengingManager.get_mission("abandoned_grocery_store")
	mission.encounter_choices[0].success_chance = 1.0
	state_scene.call("_on_choice_pressed", 0)
	await get_tree().create_timer(0.45).timeout
	_save("12_grocery_success")
	state_scene.queue_free()
	print("SCAVENGING_CAPTURE_OK locations=10 states=3 resolution=%dx%d" % [get_viewport_rect().size.x, get_viewport_rect().size.y])
	get_tree().quit(0)

func _make_scene(mission_id: String) -> Control:
	SceneRouter.pending_params = {"mission_id": mission_id}
	var scene: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
	await get_tree().process_frame
	Input.warp_mouse(Vector2(6, 6))
	return scene

func _save(name: String) -> void:
	var output_dir := OUTPUT_DIR + ("/tall_android" if get_viewport_rect().size.y > 1400.0 else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [output_dir, name]))
