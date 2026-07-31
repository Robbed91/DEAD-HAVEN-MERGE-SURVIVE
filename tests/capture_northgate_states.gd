
extends Control
## Running-game screenshots of all six Northgate visual milestones.

const OUTPUT_DIR := "res://docs/northgate-captures"
const RESIDENCE_ID := "northgate_prison"
const EVENT_ID := "northgate_defence"
const COUNTS := [0, 1, 3, 5, 8, 8]
const NAMES := ["01_destroyed", "02_cleared", "03_temporarily_repaired", "04_habitable", "05_defended", "06_fully_upgraded"]

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	for state_index in COUNTS.size():
		GameManager.new_game()
		GameManager.profile.current_chapter_id = "chapter_8_old_debts"
		GameManager.profile.story_flags["northgate_unlocked"] = true
		for hotspot_index in residence.hotspots.size():
			var hotspot = residence.hotspots[hotspot_index]
			ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED if hotspot_index < COUNTS[state_index] else ResidenceHotspot.State.DESTROYED
		if state_index == 5:
			DefenceManager.survived_events[EVENT_ID] = true
			GameManager.profile.unlocked_survivor_ids.append("caleb_rusk")
		var scene: Control = load("res://scenes/northgate/northgate.tscn").instantiate()
		scene.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(scene)
		await get_tree().process_frame
		Input.warp_mouse(Vector2(6, 6))
		# Let new-game discovery banners clear so the residence title is visible.
		await get_tree().create_timer(2.4).timeout
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, NAMES[state_index]]))
		scene.queue_free()
		await get_tree().process_frame
	print("NORTHGATE_CAPTURE_OK states=6")
	get_tree().quit()


