extends Control
## Running-game verification of the real starting board with all producers.

const OUTPUT := "res://docs/vertical-slice-captures/merge_board_all_producers.png"

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	BoardState.reset_new_board()
	var board: Control = load("res://scenes/merge_board/merge_board.tscn").instantiate()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(board)
	await get_tree().process_frame
	Input.warp_mouse(Vector2(6, 6))
	await get_tree().create_timer(1.0).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT))
	get_tree().quit()
