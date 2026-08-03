extends Control
## Running-game verification that the real embedded Haven board's chain
## legend shows final producer art, not the old procedural swatches.

const OUTPUT := "res://docs/producer-state-captures/live_chain_legend.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	var haven: Control = load("res://scenes/haven/haven.tscn").instantiate()
	haven.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(haven)
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit(0)
