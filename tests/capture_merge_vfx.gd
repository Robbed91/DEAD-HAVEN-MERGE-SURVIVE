extends Control
## Running-game verification that a real merge on the embedded Haven board
## shows chain-specific burst particles (not the old hardcoded wood/dust
## look) for a non-Construction chain.

const OUTPUT := "res://docs/producer-state-captures/live_merge_vfx_electronics.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame

	var board: MergeBoard = haven.get_node("%BoardPanel")
	var pos := BoardState.find_empty_cell()
	board._play_merge_reward(pos, 3, "electronics")
	await get_tree().create_timer(0.18).timeout

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit(0)
